import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String? profilePic;
  final String email;
  final String? deviceToken;
  final bool isVerified;
  final String? refreshToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  UserModel({
    required this.id,
    required this.name,
    this.profilePic,
    required this.email,
    this.deviceToken,
    required this.isVerified,
    this.refreshToken,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? profilePic,
    String? email,
    String? deviceToken,
    bool? isVerified,
    String? refreshToken,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      profilePic: profilePic ?? this.profilePic,
      email: email ?? this.email,
      deviceToken: deviceToken ?? this.deviceToken,
      isVerified: isVerified ?? this.isVerified,
      refreshToken: refreshToken ?? this.refreshToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'profilePic': profilePic,
      'email': email,
      'deviceToken': deviceToken,
      'isVerified': isVerified,
      'refreshToken': refreshToken,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '', // Safe string typing fallback
      name: map['name'] ?? '',
      profilePic: map['profilePic'],
      email: map['email'] ?? '',
      deviceToken: map['deviceToken'],
      isVerified: map['isVerified'] ?? false,
      refreshToken: map['refreshToken'],
      // FIX: Parses standard ISO date strings returned natively by Express/Sequelize JSON payloads
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'])
          : null,
      deletedAt: map['deletedAt'] != null
          ? DateTime.tryParse(map['deletedAt'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));
}
