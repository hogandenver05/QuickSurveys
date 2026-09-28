import '../models/survey_response.dart';

abstract class ResponseRepository {
  Future<void> submitResponse(SurveyResponse response);
}