import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfilePhotoService {
  static Future<String> _photoPath(String userId) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/profile_photo_$userId.jpg';
  }

  static Future<File?> load(String userId) async {
    final path = await _photoPath(userId);
    final file = File(path);
    return await file.exists() ? file : null;
  }

  static Future<File?> pick({required ImageSource source, required String userId}) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked == null) return null;
      final dest = File(await _photoPath(userId));
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

  static Future<void> delete(String userId) async {
    final path = await _photoPath(userId);
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  static Future<void> moveToUser(String fromUserId, String toUserId) async {
    final src = File(await _photoPath(fromUserId));
    if (!await src.exists()) return;
    final dest = File(await _photoPath(toUserId));
    await src.rename(dest.path);
  }
}

class PhotoPermissionDeniedException implements Exception {}
