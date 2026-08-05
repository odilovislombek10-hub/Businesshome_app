/// A short video from `/api/market/reels`, as the home page strip shows it.
class Reel {
  const Reel({
    required this.id,
    required this.title,
    this.thumbnail,
    this.author,
    this.authorAvatar,
    this.badge,
    this.price,
    this.location,
  });

  final int id;
  final String title;
  final String? thumbnail;
  final String? author;
  final String? authorAvatar;

  /// Small pill in the corner — the site prints the reel's category there.
  final String? badge;
  final String? price;
  final String? location;

  /// The card shows only the first word of the author's name.
  String get authorFirstName => (author ?? '').split(' ').first;

  /// The site trims long captions rather than letting them wrap past two lines.
  String get shortTitle => title.length <= 60 ? title : '${title.substring(0, 57)}…';

  factory Reel.fromJson(Map<String, dynamic> json) => Reel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: json['title']?.toString() ?? '',
    thumbnail: (json['thumbnail'] ?? json['cover'] ?? json['preview'])?.toString(),
    author: (json['author'] ?? json['author_name'])?.toString(),
    authorAvatar: (json['author_avatar'] ?? json['avatar'])?.toString(),
    badge: (json['badge'] ?? json['category'])?.toString(),
    price: json['price']?.toString(),
    location: (json['location'] ?? json['city'])?.toString(),
  );
}
