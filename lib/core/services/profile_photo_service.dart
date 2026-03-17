import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage local profile and pet photo storage and persistence.
class ProfilePhotoService {
  static const String _profilePhotoPathKey = 'profile_photo_path';
  static const String _petPhotoPathPrefix = 'pet_photo_path_';

  String _petPhotoPathKey(String petId) => '$_petPhotoPathPrefix$petId';

  /// Saves raw image bytes to the app documents directory and returns file path.
  Future<String> saveImageFileLocally({
    required Uint8List bytes,
    required String directoryName,
    required String fileNamePrefix,
    required String extension,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${directory.path}/$directoryName');

    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${imageDir.path}/${fileNamePrefix}_$timestamp.$extension';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    return filePath;
  }

  /// Save the local profile photo path to SharedPreferences.
  Future<void> saveLocalPhotoPath(String filePath) async {
    await saveProfilePhotoPath(filePath);
  }

  /// Get the saved local profile photo path from SharedPreferences.
  Future<String?> getLocalPhotoPath() async {
    return getProfilePhotoPath();
  }

  /// Clear the saved profile photo path.
  Future<void> clearLocalPhoto() async {
    await clearProfilePhotoPath();
  }

  Future<void> saveProfilePhotoPath(String filePath) async {
    await _savePath(_profilePhotoPathKey, filePath);
  }

  Future<String?> getProfilePhotoPath() async {
    return _getValidPath(_profilePhotoPathKey);
  }

  Future<void> clearProfilePhotoPath() async {
    await _clearPath(_profilePhotoPathKey);
  }

  Future<void> savePetPhotoPath({required String petId, required String filePath}) async {
    await _savePath(_petPhotoPathKey(petId), filePath);
  }

  Future<String?> getPetPhotoPath(String petId) async {
    return _getValidPath(_petPhotoPathKey(petId));
  }

  Future<void> clearPetPhotoPath(String petId) async {
    await _clearPath(_petPhotoPathKey(petId));
  }

  Future<void> _savePath(String key, String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, filePath);
    } catch (_) {
      // Silently fail if unable to save
    }
  }

  Future<String?> _getValidPath(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filePath = prefs.getString(key);

      if (filePath != null && await File(filePath).exists()) {
        return filePath;
      }

      await _clearPath(key);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearPath(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {
      // Silently fail if unable to clear
    }
  }
}
