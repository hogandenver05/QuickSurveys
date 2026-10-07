import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyResponse {
  final String id;
  final String surveyId;
  final String surveyCreatorId; // Added to facilitate security rules
  final String? respondentId;
  final String? respondentName;
  final String? respondentEmail;
  final DateTime submittedAt;
  final List<Answer> answers;

  const SurveyResponse({
    required this.id,
    required this.surveyId,
    required this.surveyCreatorId,
    this.respondentId,
    this.respondentName,
    this.respondentEmail,
    required this.submittedAt,
    this.answers = const [],
  });

  factory SurveyResponse.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return SurveyResponse(
      id: id,
      surveyId: map['surveyId'] ?? '',
      surveyCreatorId: map['surveyCreatorId'] ?? '',
      respondentId: map['respondentId'],
      respondentName: map['respondentName'],
      respondentEmail: map['respondentEmail'],
      submittedAt: parseDateTime(map['submittedAt']),
      answers:
      (map['answers'] as List<dynamic>?)
          ?.map((a) => Answer.fromMap(a as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'surveyId': surveyId,
      'surveyCreatorId': surveyCreatorId,
      'respondentId': respondentId,
      'respondentName': respondentName,
      'respondentEmail': respondentEmail,
      'submittedAt': submittedAt,
      'answers': answers.map((a) => a.toMap()).toList(),
    };
  }
}

class Answer {
  final String questionId;
  final dynamic value;

  const Answer({required this.questionId, required this.value});

  factory Answer.fromMap(Map<String, dynamic> map) {
    return Answer(questionId: map['questionId'] ?? '', value: map['value']);
  }

  Map<String, dynamic> toMap() {
    return {'questionId': questionId, 'value': value};
  }
}