import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfilePhotoService {
  static const _fileName = 'profile_photo.jpg';

  static Future<String> _photoPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_fileName';
  }

  static Future<File?> load() async {
    final path = await _photoPath();
    final file = File(path);
    return await file.exists() ? file : null;
  }

        static Future<File?> pick({required ImageSource source}) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked == null) return null;
      final dest = File(await _photoPath());
      final bytes = await picked.readAsBytes();
      await dest.writeAsBytes(bytes, flush: true);
      return dest;
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied' ||
          e.code == 'camera_access_denied' ||
          e.code == 'PHPhotosErrorDomain') {
        throw PhotoPermissionDeniedException();
      }
      rethrow;
    }
  }

  static Future<void> delete() async {
    final path = await _photoPath();
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}

class PhotoPermissionDeniedException implements Exception {}
