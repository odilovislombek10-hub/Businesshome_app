/// A construction company as listed by `/api/market/developers`.
///
/// The API answers with `projects_count`; the site normalises it to `projects` before rendering,
/// so the model reads either.
class DeveloperSummary {
  const DeveloperSummary({
    required this.id,
    required this.name,
    this.code,
    this.logo,
    this.phone,
    this.projectsCount = 0,
  });

  final int id;
  final String name;
  final String? code;
  final String? logo;
  final String? phone;
  final int projectsCount;

  /// First letter, used for the coloured placeholder when a company has no logo.
  String get initial => name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

  factory DeveloperSummary.fromJson(Map<String, dynamic> json) => DeveloperSummary(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name']?.toString() ?? '',
    code: json['code']?.toString(),
    logo: json['logo']?.toString(),
    phone: json['phone']?.toString(),
    projectsCount:
        (json['projects_count'] as num?)?.toInt() ?? (json['projects'] as num?)?.toInt() ?? 0,
  );
}
