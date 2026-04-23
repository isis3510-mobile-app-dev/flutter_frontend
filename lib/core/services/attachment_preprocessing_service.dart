import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class AttachmentPreprocessingService {
  const AttachmentPreprocessingService();

  Future<Uint8List> preprocessImageForUpload({
    required Uint8List bytes,
    required String fileName,
  }) {
    return compute(
      _preprocessImagePayload,
      _ImagePreprocessPayload(bytes: bytes, fileName: fileName),
    );
  }
}

class _ImagePreprocessPayload {
  const _ImagePreprocessPayload({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

Uint8List _preprocessImagePayload(_ImagePreprocessPayload payload) {
  final decoded = img.decodeImage(payload.bytes);
  if (decoded == null) {
    return payload.bytes;
  }

  final resized = decoded.width > 1600 || decoded.height > 1600
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? 1600 : null,
          height: decoded.height > decoded.width ? 1600 : null,
          interpolation: img.Interpolation.average,
        )
      : decoded;

  final extension = payload.fileName.trim().toLowerCase().split('.').last;
  switch (extension) {
    case 'png':
      return Uint8List.fromList(img.encodePng(resized));
    case 'jpg':
    case 'jpeg':
      return Uint8List.fromList(img.encodeJpg(resized, quality: 82));
    default:
      return payload.bytes;
  }
}
