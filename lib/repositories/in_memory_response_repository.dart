import '../models/survey_response.dart';
import 'response_repository.dart';

class InMemoryResponseRepository implements ResponseRepository {
  final List<SurveyResponse> _responses = [];

  @override
  Future<List<SurveyResponse>> getResponsesForSurvey(
    String surveyId,
    String creatorId,
  ) async {
    return _responses
        .where(
          (response) =>
              response.surveyId == surveyId &&
              response.surveyCreatorId == creatorId,
        )
        .toList();
  }

  @override
  Future<void> deleteResponsesForSurvey(
      String surveyId,
      String creatorId,
      ) async {
    _responses.removeWhere(
          (response) =>
      response.surveyId == surveyId &&
          response.surveyCreatorId == creatorId,
    );
  }

  @override
  Future<void> submitResponse(SurveyResponse response) async {
    _responses.add(response);
  }
}
