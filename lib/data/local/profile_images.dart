import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

enum ProfileImageKind { avatar, banner }

/// Выбор фото из галереи и хранение его копии в папке приложения.
/// Копия нужна, потому что исходный файл из галереи может исчезнуть.
class ProfileImages {
  ProfileImages._();

  /// Открывает галерею и возвращает путь к сохранённой копии
  /// (или null, если пользователь ничего не выбрал).
  static Future<String?> pick(ProfileImageKind kind) async {
    final isAvatar = kind == ProfileImageKind.avatar;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Уменьшаем фото при выборе: аватару хватает 800 px, фону 1600 px
      maxWidth: isAvatar ? 800 : 1600,
      maxHeight: isAvatar ? 800 : 1600,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final docs = await getApplicationDocumentsDirectory();
    final folder = Directory('${docs.path}/profile');
    await folder.create(recursive: true);
    // Имя с временем: новый файл не путается в кэше с предыдущим
    final target = File(
      '${folder.path}/${kind.name}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(picked.path).copy(target.path);
    return target.path;
  }

  /// Удаляет старую копию. Пустой путь или ошибка не страшны.
  static Future<void> delete(String path) async {
    if (path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Не вышло удалить файл: он просто останется на диске
    }
  }
}