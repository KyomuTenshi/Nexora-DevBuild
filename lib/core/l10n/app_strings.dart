/// Языки интерфейса.
enum AppLanguage {
  ru('Русский'),
  en('English');

  const AppLanguage(this.label);

  final String label;
}

/// Строки интерфейса на двух языках. Без генерации кода: для учебного объёма
/// достаточно одного класса. Переведены нижняя панель, «Меню» и «Настройки».
class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  String _t(String ru, String en) => language == AppLanguage.en ? en : ru;

  // Нижняя панель
  String get navHome => _t('Главная', 'Home');
  String get navCatalog => _t('Каталог', 'Catalog');
  String get navLibrary => _t('Библиотека', 'Library');
  String get navNotifications => _t('Уведомления', 'Notifications');
  String get navMenu => _t('Меню', 'Menu');

  // Меню
  String get menuTitle => _t('Меню', 'Menu');
  String level(int level, String xp, String max) =>
      _t('Уровень $level · $xp / $max XP', 'Level $level · $xp / $max XP');
  String get catalog => _t('Каталог', 'Catalog');
  String get popular => _t('Популярное', 'Popular');
  String get airing => _t('Сейчас выходит', 'Airing now');
  String get completed => _t('Завершённые', 'Completed');
  String get newest => _t('Новинки', 'New releases');
  String get notifications => _t('Уведомления', 'Notifications');
  String get library => _t('Библиотека', 'Library');
  String get favorites => _t('Избранное', 'Favorites');
  String get achievements => _t('Достижения', 'Achievements');
  String achievementsValue(int done, int total) =>
      _t('$done из $total', '$done of $total');
  String get pointsStore => _t('Магазин очков', 'Points store');
  String get settings => _t('Настройки', 'Settings');
  String get rateApp =>
      _t('Оставить отзыв об этом приложении', 'Rate this app');
  String get support => _t('Поддержка', 'Support');
  String get aboutLegalese => _t(
    'Учебный проект по Flutter.\nДанные: Kitsu (kitsu.io)',
    'Flutter study project.\nData: Kitsu (kitsu.io)',
  );
  String get feedbackTitle => _t('Отзыв о приложении', 'App feedback');
  String get feedbackHint => _t(
    'Что понравилось, а что стоит улучшить?',
    'What did you like, and what could be better?',
  );
  String get feedbackThanks => _t(
    'Спасибо! Отправка отзывов заработает вместе с сервером',
    'Thanks! Sending feedback will work once there is a server',
  );
  String get cancel => _t('Отмена', 'Cancel');
  String get send => _t('Отправить', 'Send');

  // Настройки
  String get settingsTitle => _t('Настройки', 'Settings');
  String get appearance => _t('Внешний вид', 'Appearance');
  String get theme => _t('Тема', 'Theme');
  String get themeDark => _t('Тёмная', 'Dark');
  String get themeLight => _t('Светлая', 'Light');
  String get themeAuto => _t('Авто', 'Auto');
  String get accentColor => _t('Цвет приложения', 'Accent color');
  String get languageTitle => _t('Язык', 'Language');
  String get profileSection => _t('Профиль', 'Profile');
  String get editProfile => _t('Редактировать профиль', 'Edit profile');
  String get storeAndStyle =>
      _t('Оформление и магазин', 'Customization and store');
  String get dataSection => _t('Данные', 'Data');
  String get showWelcome => _t('Показать приветствие снова', 'Show welcome again');
  String get resetProfile =>
      _t('Сбросить профиль и очки', 'Reset profile and points');
  String get aboutSection => _t('О приложении', 'About');
  String get versionLine =>
      _t('Версия 1.0.0 · учебный проект', 'Version 1.0.0 · study project');
  String get developer => _t('Разработчик', 'Developer');
  String get resetTitle => _t('Сбросить профиль?', 'Reset profile?');
  String get resetText => _t(
    'Имя, оформление, очки и уровень вернутся к начальным значениям. '
        'Библиотека не изменится.',
    'Name, style, points and level will return to their initial values. '
        'Your library will not change.',
  );
  String get reset => _t('Сбросить', 'Reset');
  String get profileWasReset => _t('Профиль сброшен', 'Profile reset');
}