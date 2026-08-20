/// Images come back either absolute or as a server-relative path — normalise so widgets never
/// have to care which.
///
/// The uploads live under `businesshome.uz/api/media/...`, served by the same host as the site.
String? absoluteMediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return _encode(path);
  return _encode('https://businesshome.uz${path.startsWith('/') ? '' : '/'}$path');
}

/// Adminkadan yuklangan fayl nomida bo'shliq va kirill harflari bo'lishi mumkin (masalan
/// `ChatGPT Image 29 сент. 2026 г., 15_18_35.webp`). Brauzer bunday manzilni o'zi kodlaydi,
/// Dart esa yo'q — kodlanmasa rasm umuman yuklanmaydi.
String _encode(String url) {
  final uri = Uri.tryParse(url);
  // Allaqachon kodlangan bo'lsa (`%20` bor) qayta kodlamaymiz — aks holda `%` ikki marta
  // kodlanib, manzil buziladi.
  if (uri == null || url.contains('%')) return url;
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    pathSegments: uri.pathSegments,
    query: uri.query.isEmpty ? null : uri.query,
  ).toString();
}
