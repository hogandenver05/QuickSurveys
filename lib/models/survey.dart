import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum QuestionType {
  shortAnswer,
  paragraph,
  multipleChoice,
  checkboxes,
  linearScale,
}

class Survey {
  final String id;
  final String title;
  final String description;
  final bool isPublished;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Question> questions;

  // Survey settings
  final bool allowAnonymousResponses;
  final bool requireRespondentName;
  final bool requireRespondentEmail;

  const Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.isPublished,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.questions = const [],
    this.allowAnonymousResponses = true,
    this.requireRespondentName = false,
    this.requireRespondentEmail = false,
  });

  factory Survey.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    try {
      return Survey(
        id: id,
        title: map['title']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        isPublished: map['isPublished'] == true,
        createdBy: map['createdBy']?.toString() ?? '',
        createdAt: parseDateTime(map['createdAt']),
        updatedAt: parseDateTime(map['updatedAt']),
        questions:
            (map['questions'] as Iterable?)
                ?.map(
                  (q) => Question.fromMap(Map<String, dynamic>.from(q as Map)),
                )
                .toList() ??
            [],
        allowAnonymousResponses:
            map['allowAnonymousResponses'] == true ||
            map['allowAnonymousResponses'] == null,
        requireRespondentName: map['requireRespondentName'] == true,
        requireRespondentEmail: map['requireRespondentEmail'] == true,
      );
    } catch (e) {
      debugPrint('Error parsing Survey $id: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'isPublished': isPublished,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'questions': questions.map((q) => q.toMap()).toList(),
      'allowAnonymousResponses': allowAnonymousResponses,
      'requireRespondentName': requireRespondentName,
      'requireRespondentEmail': requireRespondentEmail,
    };
  }

  Survey copyWith({
    String? id,
    String? title,
    String? description,
    bool? isPublished,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Question>? questions,
    bool? allowAnonymousResponses,
    bool? requireRespondentName,
    bool? requireRespondentEmail,
  }) {
    return Survey(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isPublished: isPublished ?? this.isPublished,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      questions: questions ?? this.questions,
      allowAnonymousResponses:
          allowAnonymousResponses ?? this.allowAnonymousResponses,
      requireRespondentName:
          requireRespondentName ?? this.requireRespondentName,
      requireRespondentEmail:
          requireRespondentEmail ?? this.requireRespondentEmail,
    );
  }
}

class Question {
  final String id;
  final String text;
  final QuestionType type;
  final bool isRequired;
  final List<String> options;

  // Linear scale settings
  final int scaleMin;
  final int scaleMax;
  final String scaleMinLabel;
  final String scaleMaxLabel;

  const Question({
    required this.id,
    required this.text,
    required this.type,
    required this.isRequired,
    required this.options,
    this.scaleMin = 1,
    this.scaleMax = 5,
    this.scaleMinLabel = '',
    this.scaleMaxLabel = '',
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      type: QuestionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => QuestionType.shortAnswer,
      ),
      isRequired: map['isRequired'] == true,
      options:
          (map['options'] as Iterable?)?.map((e) => e.toString()).toList() ??
          [],
      scaleMin: map['scaleMin'] is int ? map['scaleMin'] : 1,
      scaleMax: map['scaleMax'] is int ? map['scaleMax'] : 5,
      scaleMinLabel: map['scaleMinLabel']?.toString() ?? '',
      scaleMaxLabel: map['scaleMaxLabel']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'type': type.name,
      'isRequired': isRequired,
      'options': options,
      'scaleMin': scaleMin,
      'scaleMax': scaleMax,
      'scaleMinLabel': scaleMinLabel,
      'scaleMaxLabel': scaleMaxLabel,
    };
  }
}
