import '../models/survey_response.dart';
import 'response_repository.dart';

class InMemoryResponseRepository implements ResponseRepository {
  final List<SurveyResponse> _responses = [];

  List<SurveyResponse> get responses =>
      List.unmodifiable(_responses);

  @override
  Future<void> submitResponse(SurveyResponse response) async {
    _responses.add(response);
  }

  @override
  Future<List<SurveyResponse>> getResponses(String surveyId) async {
    return _responses
        .where((response) => response.surveyId == surveyId)
        .toList();
  }
}