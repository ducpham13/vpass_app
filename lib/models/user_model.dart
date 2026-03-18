class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String avatar;
  final double balance;
  final String role; // "customer", "gym_partner", "super_admin"
  final String? fcmToken;
  final String? gymId;
  final bool isLocked;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.avatar,
    required this.balance,
    required this.role,
    this.fcmToken,
    this.gymId,
    this.isLocked = false,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    final profile = data['profile'] as Map<String, dynamic>? ?? {};
    final wallet = data['wallet'] as Map<String, dynamic>? ?? {};

    return UserModel(
      uid: uid,
      name: profile['name'] ?? '',
      phone: profile['phone'] ?? '',
      email: profile['email'] ?? '',
      avatar: profile['avatar'] ?? '',
      balance: (wallet['balance'] ?? 0).toDouble(),
      role: data['role'] ?? 'customer',
      fcmToken: data['fcmToken'],
      gymId: data['gymId'],
      isLocked: data['isLocked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profile': {
        'name': name,
        'phone': phone,
        'email': email,
        'avatar': avatar,
      },
      'wallet': {
        'balance': balance,
      },
      'role': role,
      'fcmToken': fcmToken,
      'isLocked': isLocked,
      if (gymId != null) 'gymId': gymId,
    };
  }

  bool get isCustomer => role == 'customer';
  bool get isGymPartner => role == 'gym_partner';
  bool get isSuperAdmin => role == 'super_admin';
}
