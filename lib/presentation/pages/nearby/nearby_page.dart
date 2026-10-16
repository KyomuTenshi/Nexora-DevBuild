import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/constants/places_constants.dart';
import 'package:nexora/core/di/places_providers.dart';
import 'package:nexora/domain/entities/geo_point.dart';
import 'package:nexora/domain/entities/place.dart';
import 'package:nexora/domain/errors/location_exception.dart';
import 'package:nexora/presentation/pages/nearby/nearby_map.dart';
import 'package:nexora/presentation/providers/nearby_provider.dart';
import 'package:nexora/presentation/widgets/empty_view.dart';
import 'package:nexora/presentation/widgets/error_view.dart';

/// Экран «Рядом»: карта и список ближайших кинотеатров и магазинов.
class NearbyPage extends ConsumerStatefulWidget {
  const NearbyPage({super.key, this.mapBuilder});

  /// В тестах сюда передают простой виджет вместо настоящей карты Google.
  final NearbyMapBuilder? mapBuilder;

  @override
  ConsumerState<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends ConsumerState<NearbyPage>
    with WidgetsBindingObserver {
  /// На экране планшета карта и список рядом, начиная с этой ширины.
  static const double _wideBreakpoint = 720;

  String? _selectedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Человек вернулся из настроек телефона: пробуем определить позицию снова.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ref.read(locationProvider).hasError) {
      ref.invalidate(locationProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final center = ref.watch(nearbyCenterProvider).value ?? kDefaultCenter;
    final category = ref.watch(placeCategoryProvider);
    final placesAsync = ref.watch(nearbyPlacesProvider);

    final places = placesAsync.value ?? const <Place>[];
    final selected = places.where((p) => p.id == _selectedId).firstOrNull;

    final args = NearbyMapArgs(
      center: center,
      places: places,
      selected: selected,
      showMyLocation: location.hasValue,
      onSelect: (place) => setState(() => _selectedId = place.id),
    );
    // Настоящая карта Google или заглушка из теста
    final NearbyMapBuilder buildMap =
        widget.mapBuilder ?? (_, a) => NearbyMap(args: a);
    final map = buildMap(context, args);

    final results = _Results(
      placesAsync: placesAsync,
      center: center,
      selectedId: _selectedId,
      onSelect: (place) => setState(() => _selectedId = place.id),
      onRetry: () => ref.invalidate(nearbyPlacesProvider),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Рядом')),
      body: Column(
        children: [
          _CategoryBar(
            selected: category,
            onSelected: (c) {
              setState(() => _selectedId = null);
              ref.read(placeCategoryProvider.notifier).select(c);
            },
          ),
          if (location.hasError)
            _LocationBanner(
              problem: _problemOf(location.error),
              onFix: () => _fixLocation(_problemOf(location.error)),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= _wideBreakpoint) {
                  // Планшет и ландшафт: карта слева, список справа
                  return Row(
                    children: [
                      Expanded(child: map),
                      SizedBox(width: 380, child: results),
                    ],
                  );
                }
                return Column(
                  children: [
                    Expanded(flex: 5, child: map),
                    Expanded(flex: 6, child: results),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  LocationProblem _problemOf(Object? error) =>
      error is LocationException ? error.problem : LocationProblem.unavailable;

  /// Что сделать, чтобы геолокация заработала, зависит от причины.
  Future<void> _fixLocation(LocationProblem problem) async {
    final repo = ref.read(locationRepositoryProvider);
    switch (problem) {
      case LocationProblem.servicesOff:
        await repo.openLocationSettings();
      case LocationProblem.deniedForever:
        await repo.openAppSettings();
      case LocationProblem.denied:
      case LocationProblem.unavailable:
        ref.invalidate(locationProvider);
    }
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.selected, required this.onSelected});

  final PlaceCategory selected;
  final ValueChanged<PlaceCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final category in PlaceCategory.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(category.icon, size: 18),
                label: Text(category.label),
                selected: category == selected,
                onSelected: (_) => onSelected(category),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationBanner extends StatelessWidget {
  const _LocationBanner({required this.problem, required this.onFix});

  final LocationProblem problem;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (message, action) = switch (problem) {
      LocationProblem.servicesOff => (
      'Геолокация выключена на телефоне',
      'Включить',
      ),
      LocationProblem.denied => ('Нет доступа к местоположению', 'Разрешить'),
      LocationProblem.deniedForever => (
      'Доступ к местоположению запрещён',
      'Настройки',
      ),
      LocationProblem.unavailable => (
      'Не удалось определить местоположение',
      'Повторить',
      ),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off_outlined, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Показываем места рядом с центром Алматы',
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onFix, child: Text(action)),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.placesAsync,
    required this.center,
    required this.selectedId,
    required this.onSelect,
    required this.onRetry,
  });

  final AsyncValue<List<Place>> placesAsync;
  final GeoPoint center;
  final String? selectedId;
  final ValueChanged<Place> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return placesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(error: error, onRetry: onRetry),
      data: (places) {
        if (places.isEmpty) {
          return const EmptyView(
            icon: Icons.location_searching_rounded,
            title: 'Ничего не найдено',
            message: 'В радиусе 5 км нет таких мест. Попробуйте другую категорию.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: places.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final place = places[index];
            return ListTile(
              selected: place.id == selectedId,
              leading: CircleAvatar(child: Icon(place.category.icon)),
              title: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(place.address ?? place.category.label),
              trailing: Text(
                formatDistance(center.distanceTo(place.position)),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: () => onSelect(place),
            );
          },
        );
      },
    );
  }
}

/// 850 -> «850 м», 2300 -> «2,3 км».
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} м';
  return '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} км';
}

extension PlaceCategoryView on PlaceCategory {
  String get label => switch (this) {
    PlaceCategory.cinema => 'Кинотеатры',
    PlaceCategory.books => 'Книги и комиксы',
    PlaceCategory.games => 'Игры',
  };

  IconData get icon => switch (this) {
    PlaceCategory.cinema => Icons.local_movies_outlined,
    PlaceCategory.books => Icons.menu_book_outlined,
    PlaceCategory.games => Icons.sports_esports_outlined,
  };
}