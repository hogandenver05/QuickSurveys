import 'package:flutter/foundation.dart';

import '../models/survey.dart';
import '../models/survey_response.dart';
import '../repositories/response_repository.dart';
import '../repositories/survey_repository.dart';

class ResponseAnalysisViewModel extends ChangeNotifier {
  final SurveyRepository _surveyRepository;
  final ResponseRepository _responseRepository;
  final String _surveyId;

  ResponseAnalysisViewModel({
    required SurveyRepository surveyRepository,
    required ResponseRepository responseRepository,
    required String surveyId,
  }) : _surveyRepository = surveyRepository,
       _responseRepository = responseRepository,
       _surveyId = surveyId;

  Survey? _survey;
  List<SurveyResponse> _responses = [];

  bool _isLoading = false;
  String? _errorMessage;

  Survey? get survey => _survey;

  List<SurveyResponse> get responses => List.unmodifiable(_responses);

  int get responseCount => _responses.length;

  List<dynamic> getAnswersForQuestion(String questionId) {
    return _responses
        .map((response) {
          try {
            final answer = response.answers.firstWhere(
              (a) => a.questionId == questionId,
            );
            return answer.value;
          } catch (_) {
            return null;
          }
        })
        .where((answer) => answer != null)
        .toList();
  }

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> loadAnalysis() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final survey = await _surveyRepository.getSurvey(_surveyId);

      if (survey == null) {
        _survey = null;
        _responses = [];
        _errorMessage = 'Survey not found.';
        return;
      }

      _survey = survey;

      // Pass the creator ID to the repository to satisfy security rules
      _responses = await _responseRepository.getResponsesForSurvey(
        _surveyId,
        survey.createdBy,
      );
    } catch (e) {
      debugPrint('Error loading analysis: $e');
      _errorMessage = 'Unable to load responses: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
