import 'package:flutter/material.dart';

/// Нижняя шторка для выбора одного значения (с пунктом «Любой»).
Future<void> showOptionSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  required String? selected,
  required ValueChanged<String?> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.6,
    ),
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;

      void choose(String? value) {
        onSelected(value);
        Navigator.of(sheetContext).pop();
      }

      Widget? check(bool isSelected) => isSelected
          ? Icon(Icons.check_rounded, color: scheme.primary)
          : null;

      final totalItems = options.length + 1;

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: totalItems,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      title: const Text('Любой'),
                      trailing: check(selected == null),
                      onTap: () => choose(null),
                    );
                  }
                  final option = options[index - 1];
                  return ListTile(
                    title: Text(option),
                    trailing: check(option == selected),
                    onTap: () => choose(option),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
