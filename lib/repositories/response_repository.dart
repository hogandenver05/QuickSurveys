import '../models/survey_response.dart';

abstract interface class ResponseRepository {
  Future<void> submitResponse(SurveyResponse response);

  Future<List<SurveyResponse>> getResponses(String surveyId);
}
