/// App 端用户资料（对应后端 `GET /api/v1/auth/me` 的 data，字段 snake_case）。
class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    this.nickname = '',
    this.avatar = '',
    this.status = 'active',
    this.createdAt,
  });

  final String id;
  final String phone;
  final String nickname;
  final String avatar;
  final String status;
  final DateTime? createdAt;

  bool get isActive => status == 'active';

  /// 展示名：有昵称用昵称，否则手机号打码（139****1234）
  String get displayName {
    if (nickname.isNotEmpty) return nickname;
    if (phone.length == 11) {
      return '${phone.substring(0, 3)}****${phone.substring(7)}';
    }
    return phone;
  }

  factory AppUser.fromJson(Map<String, dynamic> j) {
    return AppUser(
      id: (j['id'] ?? '') as String,
      phone: (j['phone'] ?? '') as String,
      nickname: (j['nickname'] ?? '') as String,
      avatar: (j['avatar'] ?? '') as String,
      status: (j['status'] ?? 'active') as String,
      createdAt: j['created_at'] == null
          ? null
          : DateTime.tryParse(j['created_at'] as String),
    );
  }
}
