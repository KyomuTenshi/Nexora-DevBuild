import 'package:nexora/domain/entities/media_item.dart';

/// Тестовые тайтлы. На этапе 5 их заменит реальный API.
class MockData {
  MockData._();

  static const onePiece = MediaItem(
    id: 1, title: 'One Piece', type: MediaType.anime, rating: 8.9,
    totalUnits: 1150, studio: 'Fuji TV', year: 1999, season: 'Осень',
    genres: ['Adventure', 'Fantasy', 'Shounen'],
    status: AiringStatus.airing, popularity: 1, votes: 412000,
    synopsis:
        'Юный пират Луффи собирает команду и отправляется через Гранд Лайн '
        'на поиски легендарного сокровища, чтобы стать королём пиратов.',
  );
  static const jujutsu = MediaItem(
    id: 2, title: 'Jujutsu Kaisen', type: MediaType.anime, rating: 8.6,
    totalUnits: 47, studio: 'MAPPA', year: 2020, season: 'Осень',
    genres: ['Action', 'Fantasy', 'Shounen'], popularity: 2, votes: 128000,
    synopsis:
        'Старшеклассник Юдзи съедает проклятый палец и оказывается втянут '
        'в тайный мир шаманов, где люди сражаются с проклятиями. '
        'Ему предстоит выбрать, ради чего рисковать.',
  );
  static const soloLeveling = MediaItem(
    id: 3, title: 'Solo Leveling', type: MediaType.anime, rating: 8.5,
    totalUnits: 12, studio: 'A-1 Pictures', year: 2024, season: 'Зима',
    genres: ['Action', 'Fantasy'],
    status: AiringStatus.airing, popularity: 3, votes: 96000,
    synopsis:
        'Самый слабый охотник мира получает шанс прокачиваться без предела '
        'и в одиночку спускается в подземелья, полные монстров.',
  );
  static const vinland = MediaItem(
    id: 4, title: 'Vinland Saga', type: MediaType.anime, rating: 8.7,
    totalUnits: 24, studio: 'MAPPA', year: 2019, season: 'Лето',
    genres: ['Action', 'Drama', 'Historical'], popularity: 4, votes: 84000,
    synopsis:
        'Молодой викинг Торфинн идёт по следам убийцы своего отца и находит '
        'в бесконечной войне нечто большее, чем месть.',
  );
  static const edgerunners = MediaItem(
    id: 5, title: 'Edgerunners', type: MediaType.anime, rating: 8.6,
    totalUnits: 10, studio: 'Trigger', year: 2022, season: 'Осень',
    genres: ['Sci-Fi', 'Action'], popularity: 6, votes: 61000,
    synopsis:
        'Парень из трущоб Найт-Сити получает имплант, который даёт огромную '
        'силу, но шаг за шагом отнимает человечность.',
  );
  static const codeGeass = MediaItem(
    id: 6, title: 'Code Geass', type: MediaType.anime, rating: 8.7,
    totalUnits: 50, studio: 'Sunrise', year: 2006, season: 'Осень',
    genres: ['Mecha', 'Drama', 'Sci-Fi'], popularity: 5, votes: 73000,
    synopsis:
        'Изгнанный принц получает силу приказывать людям и начинает '
        'восстание против империи, не зная, чем придётся пожертвовать.',
  );
  static const attackOnTitan = MediaItem(
    id: 7, title: 'Attack on Titan', type: MediaType.anime, rating: 9.0,
    totalUnits: 87, studio: 'Wit Studio', year: 2013, season: 'Весна',
    genres: ['Action', 'Drama'], popularity: 7, votes: 350000,
    synopsis:
        'Человечество прячется за стенами от гигантов. Эрен клянётся '
        'уничтожить их всех, но правда о мире оказывается страшнее врага.',
  );
  static const demonSlayer = MediaItem(
    id: 9, title: 'Demon Slayer', type: MediaType.anime, rating: 8.5,
    totalUnits: 63, studio: 'ufotable', year: 2019, season: 'Весна',
    genres: ['Action', 'Fantasy', 'Shounen'], popularity: 8, votes: 210000,
    synopsis:
        'После гибели семьи Танджиро берётся за меч, чтобы вернуть сестре '
        'человечность и сразиться с демонами.',
  );
  static const frieren = MediaItem(
    id: 10, title: 'Frieren', type: MediaType.anime, rating: 9.3,
    totalUnits: 28, studio: 'Madhouse', year: 2023, season: 'Осень',
    genres: ['Adventure', 'Fantasy', 'Drama'], popularity: 9, votes: 140000,
    synopsis:
        'Эльфийка-маг Фрирен отправляется в новое путешествие, чтобы лучше '
        'понять людей, рядом с которыми прошла десять незабываемых лет.',
  );
  static const chainsawMan = MediaItem(
    id: 11, title: 'Chainsaw Man', type: MediaType.anime, rating: 8.5,
    totalUnits: 12, studio: 'MAPPA', year: 2022, season: 'Осень',
    genres: ['Action', 'Horror'], popularity: 10, votes: 118000,
    synopsis:
        'Бедный охотник за демонами Дэндзи сливается с питомцем-демоном '
        'и превращается в человека-бензопилу.',
  );
  static const spyFamily = MediaItem(
    id: 12, title: 'Spy x Family', type: MediaType.anime, rating: 8.6,
    totalUnits: 37, studio: 'CloverWorks', year: 2022, season: 'Весна',
    genres: ['Comedy', 'Action'], popularity: 11, votes: 99000,
    synopsis:
        'Шпион, убийца и телепатка притворяются семьёй, скрывая друг от '
        'друга свои секреты ради спокойного мира.',
  );
  static const dandadan = MediaItem(
    id: 13, title: 'Dandadan', type: MediaType.anime, rating: 8.5,
    totalUnits: 12, studio: 'Science SARU', year: 2024, season: 'Осень',
    genres: ['Action', 'Comedy', 'Fantasy'],
    status: AiringStatus.airing, popularity: 12, votes: 70000,
    synopsis:
        'Школьники спорят, существуют ли призраки или пришельцы, и очень '
        'скоро выясняют, что правы оба.',
  );

  static const berserk = MediaItem(
    id: 14, title: 'Berserk', type: MediaType.manga, rating: 9.4,
    totalUnits: 380, genres: ['Fantasy', 'Seinen', 'Horror'],
    popularity: 13, votes: 160000,
    synopsis:
        'Наёмник Гатс с огромным мечом идёт сквозь мрачный мир, где демоны '
        'ходят среди людей, а судьба безжалостна.',
  );
  static const vagabond = MediaItem(
    id: 15, title: 'Vagabond', type: MediaType.manga, rating: 9.2,
    totalUnits: 327, genres: ['Action', 'Historical', 'Seinen'],
    popularity: 14, votes: 90000,
    synopsis:
        'История Миямото Мусаси: юноша идёт путём меча, чтобы стать '
        'сильнейшим и понять, что на самом деле значит сила.',
  );
  static const monster = MediaItem(
    id: 16, title: 'Monster', type: MediaType.manga, rating: 9.1,
    totalUnits: 162, genres: ['Drama', 'Seinen'],
    popularity: 15, votes: 75000,
    synopsis:
        'Талантливый хирург спасает мальчика, а годы спустя узнаёт, что '
        'спас настоящее чудовище.',
  );

  /// Всё, что показывает каталог.
  static const List<MediaItem> catalog = [
    onePiece, jujutsu, soloLeveling, vinland, edgerunners, codeGeass,
    attackOnTitan, demonSlayer, frieren, chainsawMan, spyFamily, dandadan,
    berserk, vagabond, monster,
  ];
}
