import 'package:flutter/material.dart';
import 'package:nexora/data/local/profile_images.dart';

/// Шторка «Из галереи / Сделать фото». Возвращает null, если закрыли.
Future<ProfileImageSource?> showImageSourceSheet(BuildContext context) {
  return showModalBottomSheet<ProfileImageSource>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Из галереи'),
            onTap: () =>
                Navigator.of(sheetContext).pop(ProfileImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Сделать фото'),
            onTap: () =>
                Navigator.of(sheetContext).pop(ProfileImageSource.camera),
          ),
        ],
      ),
    ),
  );
}
