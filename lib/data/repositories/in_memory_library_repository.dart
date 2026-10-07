import 'package:nexora/data/mock/mock_data.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/repositories/library_repository.dart';

/// Библиотека в памяти с демо-данными, чтобы при первом запуске
/// экраны выглядели как в макете. На этапе 6 заменим на Hive.
class InMemoryLibraryRepository implements LibraryRepository {
  InMemoryLibraryRepository({bool seeded = true}) {
    if (seeded) _seed();
  }

  final Map<int, LibraryEntry> _entries = {};

  void _seed() {
    final now = DateTime.now();

    void add(MediaItem item, LibraryStatus status, int progress, int minutes) {
      _entries[item.id] = LibraryEntry(
        item: item,
        status: status,
        progress: progress,
        updatedAt: now.subtract(Duration(minutes: minutes)),
      );
    }

    add(MockData.onePiece, LibraryStatus.inProgress, 1142, 5);
    add(MockData.jujutsu, LibraryStatus.inProgress, 38, 60);
    add(MockData.soloLeveling, LibraryStatus.inProgress, 9, 180);
    add(MockData.vinland, LibraryStatus.inProgress, 4, 400);
    add(MockData.codeGeass, LibraryStatus.inProgress, 22, 900);
    add(MockData.spyFamily, LibraryStatus.inProgress, 14, 1500);
    add(MockData.edgerunners, LibraryStatus.completed, 10, 3000);
    add(MockData.demonSlayer, LibraryStatus.completed, 63, 4000);
    add(MockData.frieren, LibraryStatus.completed, 28, 5000);
    add(MockData.attackOnTitan, LibraryStatus.paused, 40, 6000);
    add(MockData.chainsawMan, LibraryStatus.planned, 0, 7000);
    add(MockData.dandadan, LibraryStatus.planned, 0, 7500);
    add(MockData.berserk, LibraryStatus.inProgress, 376, 30);
    add(MockData.vagabond, LibraryStatus.planned, 0, 8000);
  }

  @override
  List<LibraryEntry> getAll() => _entries.values.toList();

  @override
  Future<void> upsert(LibraryEntry entry) async {
    _entries[entry.item.id] = entry;
  }

  @override
  Future<void> remove(int itemId) async {
    _entries.remove(itemId);
  }
}
