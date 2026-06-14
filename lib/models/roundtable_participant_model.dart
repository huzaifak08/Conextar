import 'dart:convert';

enum ParticipantStatus {
  joined,
  left;

  String toMapString() => name;

  static ParticipantStatus fromMapString(String? statusValue) {
    return ParticipantStatus.values.firstWhere(
      (element) => element.name == statusValue,
      orElse: () => ParticipantStatus.joined,
    );
  }
}

class RoundtableParticipantModel {
  final String id;
  final String userId;
  final String roundtableId;
  final ParticipantStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  RoundtableParticipantModel({
    required this.id,
    required this.userId,
    required this.roundtableId,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  RoundtableParticipantModel copyWith({
    String? id,
    String? userId,
    String? roundtableId,
    ParticipantStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return RoundtableParticipantModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roundtableId: roundtableId ?? this.roundtableId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'roundtableId': roundtableId,
      'status': status.toMapString(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory RoundtableParticipantModel.fromMap(Map<String, dynamic> map) {
    return RoundtableParticipantModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      roundtableId: map['roundtableId']?.toString() ?? '',
      status: ParticipantStatus.fromMapString(map['status']),
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

  factory RoundtableParticipantModel.fromJson(String source) =>
      RoundtableParticipantModel.fromMap(json.decode(source));
}
