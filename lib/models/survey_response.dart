class SurveyResponse {
  final String id;
  final String surveyId;
  final String? respondentName;
  final String? respondentEmail;
  final Map<String, dynamic> answers;
  final DateTime submittedAt;

  const SurveyResponse({
    required this.id,
    required this.surveyId,
    this.respondentName,
    this.respondentEmail,
    required this.answers,
    required this.submittedAt,
  });
}
