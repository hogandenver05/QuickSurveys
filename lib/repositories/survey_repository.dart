import '../models/survey.dart';

abstract interface class SurveyRepository {
  Future<List<Survey>> getSurveys();

  Future<Survey?> getSurvey(String id);

  Future<void> createSurvey(Survey survey);

  Future<void> updateSurvey(Survey survey);

  Future<void> deleteSurvey(String id);
}
