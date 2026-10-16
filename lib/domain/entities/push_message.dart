/// Push-сообщение. «Чистая» модель без Firebase.
class PushMessage {
  const PushMessage({
    required this.title,
    required this.body,
    this.data = const {},
  });

  final String title;
  final String body;

  /// Дополнительные данные сообщения, например {'route': '/library'}.
  final Map<String, String> data;
}
