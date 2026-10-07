import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/presentation/providers/profile_layout_provider.dart';

/// Необязательные данные под именем: настоящее имя, город, статус.
class ProfileInfoPage extends ConsumerStatefulWidget {
  const ProfileInfoPage({super.key});

  @override
  ConsumerState<ProfileInfoPage> createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends ConsumerState<ProfileInfoPage> {
  late final TextEditingController _realName;
  late final TextEditingController _location;
  late final TextEditingController _status;

  @override
  void initState() {
    super.initState();
    final l = ref.read(profileLayoutProvider);
    _realName = TextEditingController(text: l.realName);
    _location = TextEditingController(text: l.location);
    _status = TextEditingController(text: l.status);
  }

  @override
  void dispose() {
    _realName.dispose();
    _location.dispose();
    _status.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(profileLayoutProvider.notifier).edit(
          (l) => l.copyWith(
        realName: _realName.text.trim(),
        location: _location.text.trim(),
        status: _status.text.trim(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Информация'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Сохранить')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _realName,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'Настоящее имя (необязательно)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'Город или страна (необязательно)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _status,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Статус',
              hintText: 'Например: ночью смотрю, днём читаю',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Что из этого видно на странице, настраивается в разделе «Приватность».',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}