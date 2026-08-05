/// A region (viloyat) and its districts, from `/api/market/regions`.
///
/// The API keys everything off [value] — that is what registration and every listing filter
/// sends back — while [label] is the Uzbek name shown to the user.
class Region {
  const Region({required this.value, required this.label, this.districts = const []});

  final String value;
  final String label;
  final List<District> districts;

  factory Region.fromJson(Map<String, dynamic> json) => Region(
    value: json['value']?.toString() ?? '',
    label: json['label']?.toString() ?? '',
    districts:
        (json['districts'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(District.fromJson)
            .toList() ??
        const [],
  );
}

class District {
  const District({required this.value, required this.label});

  final String value;
  final String label;

  factory District.fromJson(Map<String, dynamic> json) =>
      District(value: json['value']?.toString() ?? '', label: json['label']?.toString() ?? '');
}
