import 'package:flutter/foundation.dart';

import '../models/survey.dart';
import '../repositories/survey_repository.dart';
import '../repositories/auth_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final SurveyRepository _surveyRepository;
  final AuthRepository _authRepository;

  DashboardViewModel({
    required SurveyRepository surveyRepository,
    required AuthRepository authRepository,
  }) : _surveyRepository = surveyRepository,
       _authRepository = authRepository;

  List<Survey> _surveys = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Survey> get surveys => List.unmodifiable(_surveys);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSurveys() async {
    final user = _authRepository.currentUser;
    if (user == null) {
      _errorMessage = 'User not authenticated.';
      notifyListeners();
      return;
    }

    _setLoading(true);

    try {
      _errorMessage = null;
      _surveys = await _surveyRepository.getSurveysForUser(user.id);
    } catch (e) {
      debugPrint('Error loading surveys: $e');
      _errorMessage = 'Unable to load surveys: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteSurvey(String id) async {
    try {
      _errorMessage = null;
      await _surveyRepository.deleteSurvey(id);
      await loadSurveys();
    } catch (e) {
      debugPrint('Error deleting survey: $e');
      _errorMessage = 'Unable to delete survey: $e';
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
