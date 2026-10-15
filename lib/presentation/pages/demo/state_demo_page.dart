import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Учебная страница недели 3: один и тот же счётчик просмотренных серий,
/// сделанный тремя способами управления состоянием.
/// Основное приложение использует Riverpod (почему, см. README).
class StateDemoPage extends StatelessWidget {
  const StateDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Состояние: 3 способа')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SetStateDemo(),
          SizedBox(height: 16),
          _InheritedDemo(),
          SizedBox(height: 16),
          _ProviderDemo(),
        ],
      ),
    );
  }
}

/// Общая рамка для каждого способа: заголовок, пояснение и сам счётчик.
class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Строка «Серий просмотрено: N [+]». Сама ничего не хранит, только рисует.
class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.count,
    required this.onAdd,
    required this.keyPrefix,
  });

  final int count;
  final VoidCallback onAdd;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Серий просмотрено: $count',
            key: Key('$keyPrefix-count'),
          ),
        ),
        IconButton.filledTonal(
          key: Key('$keyPrefix-add'),
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Способ 1. setState: состояние в ближайшем StatefulWidget,
// вниз передаём через конструкторы (prop drilling).
// ---------------------------------------------------------------------------

class _SetStateDemo extends StatefulWidget {
  const _SetStateDemo();

  @override
  State<_SetStateDemo> createState() => _SetStateDemoState();
}

class _SetStateDemoState extends State<_SetStateDemo> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: '1. setState',
      description: 'Счётчик хранится здесь и спускается вниз через '
          'параметры каждого виджета по пути. Удобно для одного экрана, '
          'неудобно, когда виджетов между ними много.',
      child: _Middle(
        count: _count,
        onAdd: () => setState(() => _count++),
      ),
    );
  }
}

/// Промежуточный виджет, которому самому счётчик не нужен, но он вынужден
/// принимать и пересылать его дальше. Это и есть prop drilling.
class _Middle extends StatelessWidget {
  const _Middle({required this.count, required this.onAdd});

  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _CounterRow(count: count, onAdd: onAdd, keyPrefix: 'setstate');
  }
}

// ---------------------------------------------------------------------------
// Способ 2. InheritedWidget: данные «висят» над деревом, любой потомок
// достаёт их через context без передачи по цепочке.
// ---------------------------------------------------------------------------

class _CountScope extends InheritedWidget {
  const _CountScope({
    required this.count,
    required this.onAdd,
    required super.child,
  });

  final int count;
  final VoidCallback onAdd;

  static _CountScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_CountScope>();
    assert(scope != null, 'Над виджетом нет _CountScope');
    return scope!;
  }

  /// Потомки, которые вызвали of(), перестроятся только если число изменилось.
  @override
  bool updateShouldNotify(_CountScope oldWidget) => count != oldWidget.count;
}

class _InheritedDemo extends StatefulWidget {
  const _InheritedDemo();

  @override
  State<_InheritedDemo> createState() => _InheritedDemoState();
}

class _InheritedDemoState extends State<_InheritedDemo> {
  // InheritedWidget неизменяем, поэтому значение всё равно живёт в State
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return _CountScope(
      count: _count,
      onAdd: () => setState(() => _count++),
      child: const _DemoCard(
        title: '2. InheritedWidget',
        description: 'Данные лежат над деревом, нужный виджет сам берёт их '
            'через context. Промежуточные виджеты ничего не знают. '
            'Но код приходится писать вручную, поэтому появился provider.',
        child: _ScopeCounter(),
      ),
    );
  }
}

class _ScopeCounter extends StatelessWidget {
  const _ScopeCounter();

  @override
  Widget build(BuildContext context) {
    final scope = _CountScope.of(context);
    return _CounterRow(
      count: scope.count,
      onAdd: scope.onAdd,
      keyPrefix: 'inherited',
    );
  }
}

// ---------------------------------------------------------------------------
// Способ 3. provider: то же самое, но InheritedWidget и перестроения
// за нас делает пакет. Модель сообщает об изменении через notifyListeners().
// ---------------------------------------------------------------------------

class _CounterModel extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void add() {
    _count++;
    notifyListeners();
  }
}

class _ProviderDemo extends StatelessWidget {
  const _ProviderDemo();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _CounterModel(),
      child: const _DemoCard(
        title: '3. provider',
        description: 'ChangeNotifierProvider создаёт модель, watch() '
            'подписывает виджет на изменения, read() только вызывает метод. '
            'Минимум кода и нет ручного InheritedWidget.',
        child: _ProviderCounter(),
      ),
    );
  }
}

class _ProviderCounter extends StatelessWidget {
  const _ProviderCounter();

  @override
  Widget build(BuildContext context) {
    // watch: перестроить этот виджет при каждом notifyListeners()
    final count = context.watch<_CounterModel>().count;
    return _CounterRow(
      count: count,
      // read: просто вызвать метод, подписка не нужна
      onAdd: context.read<_CounterModel>().add,
      keyPrefix: 'provider',
    );
  }
}