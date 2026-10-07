import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/entities/media_summary.dart';

MediaItem _item({String synopsis = '', String? tagline}) => MediaItem(
  id: 1,
  title: 'Тест',
  type: MediaType.anime,
  rating: 8,
  totalUnits: 12,
  synopsis: synopsis,
  tagline: tagline,
);

void main() {
  test('пустое описание даёт null', () {
    expect(digestOf(''), isNull);
    expect(digestOf('   \n  '), isNull);
    expect(shortSummary(_item()), isNull);
  });

  test('берутся первые два коротких предложения', () {
    expect(
      digestOf('First one. Second one. Third one.'),
      'First one. Second one.',
    );
  });

  test('одно предложение, если с двумя выйдет слишком длинно', () {
    final first = '${'A' * 100}.';
    final second = '${'B' * 200}.';

    expect(digestOf('$first $second'), first);
  });

  test('очень длинное предложение режется по слову с многоточием', () {
    final text = 'word ' * 80;
    final result = digestOf(text)!;

    expect(result.endsWith('word…'), isTrue);
    expect(result.length, lessThanOrEqualTo(kSummaryMaxChars + 1));
  });

  test('лишние пробелы и переносы схлопываются', () {
    expect(digestOf('One\n\n  two.   Three.'), 'One two. Three.');
  });

  test('своя фраза (tagline) главнее выжимки из описания', () {
    final item = _item(synopsis: 'Long text. More.', tagline: ' Свой текст ');

    expect(shortSummary(item), 'Свой текст');
  });

  test('без tagline берётся выжимка из описания', () {
    expect(shortSummary(_item(synopsis: 'Hello there. Bye.')), 'Hello there. Bye.');
  });
}