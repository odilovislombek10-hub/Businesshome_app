import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import 'language_service.dart';

/// One turn of the conversation with Aziza.
class ChatMessage {
  const ChatMessage({required this.role, required this.text});

  /// `user` or `assistant`, the two roles the backend accepts.
  final String role;
  final String text;

  bool get isUser => role == 'user';

  /// Backend `ChatMessage(role, text)` kutadi — `content` emas
  /// (`market_ai_router.py`: `messages[].text` majburiy).
  Map<String, dynamic> toJson() => {'role': role, 'text': text};
}

/// Port of the site's `AiChatService` — the assistant behind the floating button.
///
/// Signed-out visitors are identified by an `X-Anon-Key` header the backend uses for rate
/// limiting; it is generated once and kept, so the conversation survives a restart the same way
/// it does in the browser.
class AiChatService extends ChangeNotifier {
  AiChatService._();
  static final AiChatService instance = AiChatService._();

  static const _anonKeyStorage = 'market_ai_anon_key';

  final _api = ApiClient.instance;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<String> _anonKey() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_anonKeyStorage);
    if (existing != null && existing.isNotEmpty) return existing;
    // Not a security token — just a stable id so rate limiting can tell visitors apart.
    final key = 'bh-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    await prefs.setString(_anonKeyStorage, key);
    return key;
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading) return;

    _messages.add(ChatMessage(role: 'user', text: trimmed));
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.post<dynamic>(
        '/market/ai/chat',
        data: {
          'messages': [for (final m in _messages) m.toJson()],
          // Til tanlovi bo'yicha javob bersin.
          'lang': LanguageService.instance.code,
        },
        headers: {'X-Anon-Key': await _anonKey()},
      );
      final data = res.data;
      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        // The backend's `detail` is already user-facing ("AI yordamchi sozlanmagan", rate limits).
        _error = (data is Map ? data['detail']?.toString() : null) ?? 'Xatolik yuz berdi';
      } else if (data is Map<String, dynamic>) {
        _messages.add(ChatMessage(role: 'assistant', text: data['text']?.toString() ?? ''));
      }
    } catch (e) {
      _error = 'Ulanishda xatolik';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }
}
