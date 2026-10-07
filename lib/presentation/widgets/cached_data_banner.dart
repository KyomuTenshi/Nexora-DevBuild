import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/cache_status.dart';

/// Полоска «Используются сохранённые данные». Видна только тогда, когда сети
/// нет и экран показывает последние сохранённые ответы.
class CachedDataBanner extends ConsumerWidget {
  const CachedDataBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usingCache = ref.watch(cacheStatusProvider);
    if (!usingCache) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Нет сети. Используются сохранённые данные',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}