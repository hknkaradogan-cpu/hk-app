class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool active;
  final String? fcmToken;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        role: map['role'] as String,
        active: map['active'] as bool? ?? true,
        fcmToken: map['fcm_token'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'active': active,
        'fcm_token': fcmToken,
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    bool? active,
    String? fcmToken,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        active: active ?? this.active,
        fcmToken: fcmToken ?? this.fcmToken,
      );
}
