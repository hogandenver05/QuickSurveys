import '../models/survey.dart';
import 'survey_repository.dart';

class InMemorySurveyRepository implements SurveyRepository {
  final List<Survey> _surveys = [];

  @override
  Future<List<Survey>> getSurveys() async {
    return List.unmodifiable(_surveys);
  }

  @override
  Future<Survey?> getSurvey(String id) async {
    for (final survey in _surveys) {
      if (survey.id == id) {
        return survey;
      }
    }

    return null;
  }

  @override
  Future<void> createSurvey(Survey survey) async {
    _surveys.add(survey);
  }

  @override
  Future<void> updateSurvey(Survey survey) async {
    final index = _surveys.indexWhere(
          (existingSurvey) => existingSurvey.id == survey.id,
    );

    if (index == -1) {
      throw StateError('Survey not found: ${survey.id}');
    }

    _surveys[index] = survey;
  }

  @override
  Future<void> deleteSurvey(String id) async {
    _surveys.removeWhere((survey) => survey.id == id);
  }
}
