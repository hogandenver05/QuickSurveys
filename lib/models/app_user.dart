import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final List<String> surveyIds;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.surveyIds = const [],
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    final createdAtData = map['createdAt'];
    DateTime createdAt;
    if (createdAtData is Timestamp) {
      createdAt = createdAtData.toDate();
    } else if (createdAtData is DateTime) {
      createdAt = createdAtData;
    } else {
      createdAt = DateTime.now();
    }

    return AppUser(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      createdAt: createdAt,
      surveyIds: List<String>.from(map['surveyIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': createdAt,
      'surveyIds': surveyIds,
    };
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? createdAt,
    List<String>? surveyIds,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      surveyIds: surveyIds ?? this.surveyIds,
    );
  }
}
