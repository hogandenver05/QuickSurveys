
import '../models/survey_response.dart';

abstract interface class ResponseRepository {
  Future<List<SurveyResponse>> getResponsesForSurvey(
      String surveyId,
      String creatorId,
      );

  Future<void> submitResponse(SurveyResponse response);

  Future<void> deleteResponsesForSurvey(
      String surveyId,
      String creatorId,
      );
}

