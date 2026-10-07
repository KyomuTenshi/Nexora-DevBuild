import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/constants/catalog_filters.dart';
import 'package:nexora/presentation/providers/catalog_provider.dart';
import 'package:nexora/presentation/widgets/option_sheet.dart';

class FilterRow extends ConsumerWidget {
  const FilterRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(catalogQueryProvider);
    final notifier = ref.read(catalogQueryProvider.notifier);

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        children: [
          _FilterPill(
            label: 'Жанры',
            value: query.genre,
            options: kGenres,
            onSelected: notifier.setGenre,
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'Год',
            value: query.year?.toString(),
            options: kYears,
            onSelected: (v) => notifier.setYear(v == null ? null : int.tryParse(v)),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'Сезон',
            value: query.season,
            options: kSeasons,
            onSelected: notifier.setSeason,
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = value != null;
    final color = active ? scheme.primary : scheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => showOptionSheet(
        context,
        title: label,
        options: options,
        selected: value,
        onSelected: onSelected,
      ),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(left: 14, right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? scheme.primary : scheme.outlineVariant,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value ?? label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: active ? scheme.primary : scheme.onSurface,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: color),
          ],
        ),
      ),
    );
  }
}