import 'dart:convert';

enum RoundtableStatus {
  active,
  inactive;

  String toMapString() => name;

  static RoundtableStatus fromMapString(String? statusValue) {
    return RoundtableStatus.values.firstWhere(
      (element) => element.name == statusValue,
      orElse: () => RoundtableStatus.active,
    );
  }
}

class RoundtableModel {
  final String id;
  final String name;
  final String code;
  final String createdById;
  final RoundtableStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  RoundtableModel({
    required this.id,
    required this.name,
    required this.code,
    required this.createdById,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  RoundtableModel copyWith({
    String? id,
    String? name,
    String? code,
    String? createdById,
    RoundtableStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return RoundtableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      createdById: createdById ?? this.createdById,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'createdById': createdById,
      'status': status.toMapString(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory RoundtableModel.fromMap(Map<String, dynamic> map) {
    return RoundtableModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      createdById: map['createdById']?.toString() ?? '',
      status: RoundtableStatus.fromMapString(map['status']),
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

  factory RoundtableModel.fromJson(String source) =>
      RoundtableModel.fromMap(json.decode(source));
}
