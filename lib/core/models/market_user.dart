/// A marketplace account, as returned by `/api/market/auth/me` and inside every auth response.
///
/// One phone number can hold several accounts — the backend allows the same number to register
/// separately as a user, agent, designer, master and developer — so [role] is part of the
/// identity, not a flag on it. That is why login can ask which role to sign in as.
class MarketUser {
  const MarketUser({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.role,
    this.region,
    this.district,
    this.avatar,
    this.isVerified = false,
    this.createdAt,
  });

  final int id;
  final String phone;
  final String fullName;
  final String? region;
  final String? district;
  final MarketRole role;
  final String? avatar;
  final bool isVerified;
  final DateTime? createdAt;

  factory MarketUser.fromJson(Map<String, dynamic> json) => MarketUser(
    id: (json['id'] as num?)?.toInt() ?? 0,
    phone: json['phone']?.toString() ?? '',
    fullName: json['full_name']?.toString() ?? '',
    region: json['region']?.toString(),
    district: json['district']?.toString(),
    role: MarketRole.parse(json['role']?.toString()),
    avatar: json['avatar']?.toString(),
    isVerified: json['is_verified'] == true,
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
  );
}

/// `Role = Literal["user", "agent", "designer", "master", "developer"]` in the backend schema.
enum MarketRole {
  user('user', 'Foydalanuvchi'),
  agent('agent', 'Agent'),
  designer('designer', 'Dizayner'),
  master('master', 'Usta'),
  developer('developer', 'Quruvchi');

  const MarketRole(this.wire, this.label);

  /// The value the API sends and expects.
  final String wire;

  /// How the site labels the role in Uzbek.
  final String label;

  static MarketRole parse(String? value) =>
      MarketRole.values.firstWhere((r) => r.wire == value, orElse: () => MarketRole.user);
}

/// One entry of `/auth/login/available-roles` — shown when a phone+password pair matches more
/// than one account and the user has to pick which one to enter.
class AvailableRole {
  const AvailableRole({required this.role, required this.fullName, required this.isVerified});

  final MarketRole role;
  final String fullName;
  final bool isVerified;

  factory AvailableRole.fromJson(Map<String, dynamic> json) => AvailableRole(
    role: MarketRole.parse(json['role']?.toString()),
    fullName: json['full_name']?.toString() ?? '',
    isVerified: json['is_verified'] == true,
  );
}
