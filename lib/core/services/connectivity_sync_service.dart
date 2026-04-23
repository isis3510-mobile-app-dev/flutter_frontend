import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'sync_retry_service.dart';

class ConnectivitySyncService {
  ConnectivitySyncService._();

  static final ConnectivitySyncService _instance = ConnectivitySyncService._();

  factory ConnectivitySyncService() => _instance;

  static const Duration _internetProbeTimeout = Duration(seconds: 3);
  static const Duration _minRetryInterval = Duration(seconds: 5);

  final Connectivity _connectivity = Connectivity();
  final SyncRetryService _syncRetryService = SyncRetryService();

  StreamSubscription<dynamic>? _subscription;
  bool _initialized = false;
  bool _wasConnected = false;
  bool _isRetryInProgress = false;
  DateTime _lastRetryAt = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _wasConnected = await _hasInternetAccess();

    _subscription = _connectivity.onConnectivityChanged.listen((_) async {
      final hasInternet = await _hasInternetAccess();

      if (hasInternet && !_wasConnected) {
        await _retryPendingWritesSafely();
      }

      _wasConnected = hasInternet;
    });
  }

  Future<void> retryNowIfOnline() async {
    final hasInternet = await _hasInternetAccess();
    if (!hasInternet) {
      return;
    }
    await _retryPendingWritesSafely();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }

  Future<void> _retryPendingWritesSafely() async {
    if (_isRetryInProgress) {
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastRetryAt) < _minRetryInterval) {
      return;
    }

    _isRetryInProgress = true;
    _lastRetryAt = now;

    try {
      await _syncRetryService.retryPendingWrites();
    } catch (_) {
      // Sync retries are best effort and should not crash the app.
    } finally {
      _isRetryInProgress = false;
    }
  }

  Future<bool> _hasInternetAccess() async {
    final connectivityState = await _connectivity.checkConnectivity();
    if (!_hasNetworkInterface(connectivityState)) {
      return false;
    }

    try {
      final result = await InternetAddress.lookup(
        'one.one.one.one',
      ).timeout(_internetProbeTimeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool _hasNetworkInterface(dynamic state) {
    final states = <ConnectivityResult>[];

    if (state is ConnectivityResult) {
      states.add(state);
    } else if (state is Iterable) {
      states.addAll(state.whereType<ConnectivityResult>());
    }

    if (states.isEmpty) {
      return false;
    }

    return states.any((item) => item != ConnectivityResult.none);
  }
}
