/// Images come back either absolute or as a server-relative path — normalise so widgets never
/// have to care which.
///
/// The uploads live under `businesshome.uz/api/media/...`, served by the same host as the site.
String? absoluteMediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return 'https://businesshome.uz${path.startsWith('/') ? '' : '/'}$path';
}
