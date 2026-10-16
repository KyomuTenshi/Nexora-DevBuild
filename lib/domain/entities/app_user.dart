/// Вошедший пользователь. «Чистая» модель без Firebase.
class AppUser {
  const AppUser({required this.uid, required this.email, this.displayName});

  final String uid;
  final String email;
  final String? displayName;

  /// Имя для показа: если имени нет, берём часть почты до «@».
  String get shownName {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email.split('@').first;
  }
}
