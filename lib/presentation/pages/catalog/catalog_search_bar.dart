import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/presentation/providers/catalog_provider.dart';
import 'package:nexora/presentation/providers/shell_provider.dart';

/// Поле поиска с задержкой (debounce): запрос уходит только когда
/// пользователь перестал печатать на 350 мс.
class CatalogSearchBar extends ConsumerStatefulWidget {
  const CatalogSearchBar({
    super.key,
    required this.filtersVisible,
    required this.onToggleFilters,
  });

  final bool filtersVisible;
  final VoidCallback onToggleFilters;

  @override
  ConsumerState<CatalogSearchBar> createState() => _CatalogSearchBarState();
}

class _CatalogSearchBarState extends ConsumerState<CatalogSearchBar> {
  late final TextEditingController _controller;
  final _focus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(catalogQueryProvider).text,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(catalogQueryProvider.notifier).setText(value);
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    ref.read(catalogQueryProvider.notifier).setText('');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasFilters =
        ref.watch(catalogQueryProvider.select((q) => q.hasFilters));

    // Текст изменили снаружи (например, «Сбросить»): обновляем поле.
    ref.listen<String>(catalogQueryProvider.select((q) => q.text),
        (previous, next) {
      if (_controller.text != next) {
        _controller.text = next;
        _controller.selection = TextSelection.collapsed(offset: next.length);
      }
    });

    // Тап по поиску на Главной просит поставить сюда курсор.
    ref.listen<int>(searchFocusProvider, (previous, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.only(left: 14, right: 8),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration.collapsed(
                  hintText: 'Найти аниме или мангу',
                  hintStyle: TextStyle(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, child) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  onPressed: _clear,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 20),
                );
              },
            ),
            const SizedBox(width: 4),
            Material(
              color: widget.filtersVisible
                  ? scheme.primary.withValues(alpha: 0.2)
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: widget.onToggleFilters,
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                    child: Badge(
                      isLabelVisible: hasFilters,
                      smallSize: 8,
                      child: const Icon(Icons.filter_alt_outlined, size: 22),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
