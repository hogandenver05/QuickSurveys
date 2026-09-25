import 'package:flutter/foundation.dart';

import '../models/survey.dart';
import '../repositories/survey_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final SurveyRepository _surveyRepository;

  DashboardViewModel({
    required SurveyRepository surveyRepository,
  }) : _surveyRepository = surveyRepository;

  List<Survey> _surveys = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Survey> get surveys => List.unmodifiable(_surveys);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSurveys() async {
    _setLoading(true);

    try {
      _errorMessage = null;
      _surveys = await _surveyRepository.getSurveys();
    } catch (_) {
      _errorMessage = 'Unable to load surveys.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteSurvey(String id) async {
    try {
      _errorMessage = null;
      await _surveyRepository.deleteSurvey(id);
      await loadSurveys();
    } catch (_) {
      _errorMessage = 'Unable to delete survey.';
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
