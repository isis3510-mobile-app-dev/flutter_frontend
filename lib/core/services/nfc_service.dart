import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:nfc_manager/ndef_record.dart';

class NfcServiceException implements Exception {
  const NfcServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NfcService {
  NfcService._();

  static const MethodChannel _nfcDispatchChannel = MethodChannel(
    'com.example.flutter_frontend/nfc_dispatch',
  );

  static final NfcService _instance = NfcService._();

  factory NfcService() => _instance;

  Future<bool> isAvailable() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      return availability == NfcAvailability.enabled;
    } catch (_) {
      return false;
    }
  }

  Future<String> readTextTag({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    return _runSession<String>(
      timeout: timeout,
      alertMessage: 'Hold your phone near an NFC tag to read data.',
      onTagDiscovered: _readTextFromTag,
    );
  }

  Future<void> writeTextTag(
    String payload, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    await _runSession<void>(
      timeout: timeout,
      alertMessage: 'Hold your phone near an NFC tag to write data.',
      postDiscoveryCooldown: _postWriteCooldown,
      onTagDiscovered: (tag) => _writeTextToTag(tag, payload),
    );
  }

  Future<void> stopSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {
      // Ignore stop-session failures when no active session exists.
    }
  }

  Future<void> setTagIntentBlocked(bool blocked) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _nfcDispatchChannel.invokeMethod<void>('setBlocked', {
        'blocked': blocked,
      });
    } catch (_) {
      // Ignore native bridge failures to avoid breaking NFC flows.
    }
  }

  Future<T> _runSession<T>({
    required Duration timeout,
    required String alertMessage,
    required Future<T> Function(NfcTag tag) onTagDiscovered,
    Duration postDiscoveryCooldown = Duration.zero,
  }) async {
    final available = await isAvailable();
    if (!available) {
      throw const NfcServiceException('NFC is not available on this device.');
    }

    final completer = Completer<T>();

    await NfcManager.instance.startSession(
      pollingOptions: _pollingOptions,
      alertMessageIos: alertMessage,
      onDiscovered: (tag) async {
        if (completer.isCompleted) {
          return;
        }

        try {
          final result = await onTagDiscovered(tag);
          if (postDiscoveryCooldown > Duration.zero) {
            await Future<void>.delayed(postDiscoveryCooldown);
          }
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        } catch (error) {
          if (!completer.isCompleted) {
            completer.completeError(_normalizeError(error));
          }
        } finally {
          await stopSession();
        }
      },
    );

    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      throw const NfcServiceException(
        'NFC operation timed out. Please try again.',
      );
    } finally {
      await stopSession();
    }
  }

  Future<String> _readTextFromTag(NfcTag tag) async {
    final message = await _readNdefMessage(tag);
    if (message == null) {
      throw const NfcServiceException(
        'This NFC tag is not compatible with NDEF data.',
      );
    }

    if (message.records.isEmpty) {
      throw const NfcServiceException('This NFC tag is empty.');
    }

    final payload = _extractTextPayload(message);
    if (payload == null || payload.trim().isEmpty) {
      throw const NfcServiceException(
        'No readable text payload was found in this NFC tag.',
      );
    }

    return payload.trim();
  }

  Future<void> _writeTextToTag(NfcTag tag, String payload) async {
    final message = _buildTextMessage(payload);
    await _writeNdefMessage(tag, message);
  }

  Future<NdefMessage?> _readNdefMessage(NfcTag tag) async {
    final androidNdef = NdefAndroid.from(tag);
    if (androidNdef != null) {
      return androidNdef.cachedNdefMessage ?? await androidNdef.getNdefMessage();
    }

    final iosNdef = NdefIos.from(tag);
    if (iosNdef != null) {
      return iosNdef.cachedNdefMessage ?? await iosNdef.readNdef();
    }

    return null;
  }

  Future<void> _writeNdefMessage(NfcTag tag, NdefMessage message) async {
    final androidNdef = NdefAndroid.from(tag);
    if (androidNdef != null) {
      if (!androidNdef.isWritable) {
        throw const NfcServiceException('This NFC tag is read-only.');
      }
      await androidNdef.writeNdefMessage(message);
      return;
    }

    final iosNdef = NdefIos.from(tag);
    if (iosNdef != null) {
      final status = (await iosNdef.queryNdefStatus()).status;
      if (status != NdefStatusIos.readWrite) {
        throw const NfcServiceException('This NFC tag is read-only.');
      }
      await iosNdef.writeNdef(message);
      return;
    }

    throw const NfcServiceException(
      'This NFC tag is not compatible with NDEF data.',
    );
  }

  NdefMessage _buildTextMessage(String text) {
    const languageCode = 'en';
    final languageBytes = utf8.encode(languageCode);
    final textBytes = utf8.encode(text);

    final payload = Uint8List(
      1 + languageBytes.length + textBytes.length,
    )
      ..[0] = languageBytes.length
      ..setRange(1, 1 + languageBytes.length, languageBytes)
      ..setRange(1 + languageBytes.length, 1 + languageBytes.length + textBytes.length, textBytes);

    final record = NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList(const [0x54]),
      identifier: Uint8List(0),
      payload: payload,
    );

    return NdefMessage(records: [record]);
  }

  String? _extractTextPayload(NdefMessage message) {
    for (final record in message.records) {
      final text = _decodeRecordText(record);
      if (text != null && text.trim().isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  String? _decodeRecordText(NdefRecord record) {
    if (record.payload.isEmpty) {
      return null;
    }

    if (_isNdefTextRecord(record)) {
      return _decodeNdefTextPayload(record.payload);
    }

    final fallback = _decodeUtf8(record.payload);
    if (fallback.trim().isNotEmpty) {
      return fallback;
    }

    return null;
  }

  bool _isNdefTextRecord(NdefRecord record) {
    return record.typeNameFormat == TypeNameFormat.wellKnown &&
        record.type.length == 1 &&
        record.type.first == 0x54;
  }

  String _decodeNdefTextPayload(Uint8List payload) {
    final statusByte = payload.first;
    final languageCodeLength = statusByte & 0x3F;

    if (payload.length <= languageCodeLength + 1) {
      return _decodeUtf8(payload);
    }

    final textBytes = payload.sublist(languageCodeLength + 1);
    return _decodeUtf8(textBytes);
  }

  String _decodeUtf8(Uint8List bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return String.fromCharCodes(bytes);
    }
  }

  NfcServiceException _normalizeError(Object error) {
    if (error is NfcServiceException) {
      return error;
    }

    if (error is PlatformException) {
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return NfcServiceException(message);
      }
    }

    return const NfcServiceException('NFC operation failed. Please try again.');
  }

  Set<NfcPollingOption> get _pollingOptions {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      };
    }

    return const {
      NfcPollingOption.iso14443,
      NfcPollingOption.iso15693,
      NfcPollingOption.iso18092,
    };
  }

  Duration get _postWriteCooldown {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const Duration(seconds: 2);
    }

    return Duration.zero;
  }
}
