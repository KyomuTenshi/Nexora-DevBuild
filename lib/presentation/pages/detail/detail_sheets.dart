import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/pages/library/library_labels.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/ratings_provider.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';
import 'package:nexora/presentation/widgets/star_rating.dart';

/// Шторка «В какой список добавить».
Future<void> showStatusSheet(BuildContext context, MediaItem item) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      return Consumer(
        builder: (_, ref, _) {
          final scheme = Theme.of(context).colorScheme;
          final current =
              ref.watch(libraryProvider.select((m) => m[item.id]?.status));

          void choose(LibraryStatus status) {
            ref.read(libraryProvider.notifier).setStatus(item, status);
            Navigator.of(sheetContext).pop();
            showInfo(
              context,
              '«${item.title}»: ${status.labelFor(item.type)}',
            );
          }

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'Добавить в список',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                for (final status in LibraryStatus.values)
                  ListTile(
                    leading: Icon(
                      status.icon,
                      color:
                          status == current ? scheme.primary : scheme.onSurface,
                    ),
                    title: Text(status.labelFor(item.type)),
                    trailing: status == current
                        ? Icon(Icons.check_rounded, color: scheme.primary)
                        : null,
                    onTap: () => choose(status),
                  ),
                if (current != null)
                  ListTile(
                    leading: Icon(Icons.delete_outline_rounded,
                        color: scheme.error),
                    title: Text(
                      'Убрать из списков',
                      style: TextStyle(color: scheme.error),
                    ),
                    onTap: () {
                      ref.read(libraryProvider.notifier).remove(item.id);
                      Navigator.of(sheetContext).pop();
                      showInfo(context, '«${item.title}» убран из списков');
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Шторка «Оцените тайтл». Тап по звезде сохраняет оценку и закрывает шторку.
Future<void> showRateSheet(BuildContext context, MediaItem item) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      return Consumer(
        builder: (_, ref, _) {
          final scheme = Theme.of(context).colorScheme;
          final value = ref.watch(
            ratingsProvider.select((m) => m[item.id] ?? 0),
          );

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ваша оценка',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  StarRating(
                    value: value,
                    size: 40,
                    onChanged: (v) {
                      ref.read(ratingsProvider.notifier).set(item.id, v);
                      Navigator.of(sheetContext).pop();
                      showInfo(
                        context,
                        v == 0 ? 'Оценка снята' : 'Оценка сохранена: $v из 5',
                      );
                    },
                  ),
                  if (value > 0)
                    TextButton(
                      onPressed: () {
                        ref.read(ratingsProvider.notifier).set(item.id, 0);
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('Снять оценку'),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
