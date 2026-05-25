import 'dart:io';
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

  /// Opens the image picker with [source], copies the result to the app
  /// documents directory, and returns the saved [File]. Returns null if the
  /// user cancelled or an error occurred.
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
      await File(picked.path).copy(dest.path);
      return dest;
    } catch (_) {
      return null;
    }
  }

  static Future<void> delete() async {
    final path = await _photoPath();
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
