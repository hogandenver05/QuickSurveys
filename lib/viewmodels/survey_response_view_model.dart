import 'package:flutter/foundation.dart';

import '../models/survey.dart';
import '../models/survey_response.dart';
import '../repositories/auth_repository.dart';
import '../repositories/response_repository.dart';
import '../repositories/survey_repository.dart';

class SurveyResponseViewModel extends ChangeNotifier {
  final SurveyRepository _surveyRepository;
  final ResponseRepository _responseRepository;
  final AuthRepository _authRepository;
  final String _surveyId;

  SurveyResponseViewModel({
    required this._surveyRepository,
    required this._responseRepository,
    required this._authRepository,
    required this._surveyId,
  });

  Survey? _survey;
  final Map<String, dynamic> _answers = {};

  String _respondentName = '';
  String _respondentEmail = '';

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _submitted = false;

  String? _errorMessage;

  Survey? get survey => _survey;

  Map<String, dynamic> get answers => Map.unmodifiable(_answers);

  String get respondentName => _respondentName;

  String get respondentEmail => _respondentEmail;

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  bool get submitted => _submitted;

  String? get errorMessage => _errorMessage;

  bool get isAvailable => _survey != null && _survey!.isPublished;

  Future<void> loadSurvey() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final survey = await _surveyRepository.getSurvey(_surveyId);

      if (survey == null || !survey.isPublished) {
        _survey = null;
        _errorMessage = 'This survey is unavailable.';
      } else {
        _survey = survey;
      }
    } catch (e) {
      debugPrint('Error loading survey: $e');
      _errorMessage = 'Unable to load survey: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setRespondentName(String value) {
    _respondentName = value;
    notifyListeners();
  }

  void setRespondentEmail(String value) {
    _respondentEmail = value;
    notifyListeners();
  }

  void setAnswer(String questionId, dynamic value) {
    _answers[questionId] = value;
    notifyListeners();
  }

  bool validate() {
    if (_survey == null) {
      _errorMessage = 'This survey is unavailable.';
      notifyListeners();
      return false;
    }

    if (_survey!.requireRespondentName && _respondentName.trim().isEmpty) {
      _errorMessage = 'Please enter your name.';
      notifyListeners();
      return false;
    }

    if (_survey!.requireRespondentEmail && _respondentEmail.trim().isEmpty) {
      _errorMessage = 'Please enter your email.';
      notifyListeners();
      return false;
    }

    for (final question in _survey!.questions) {
      if (!question.isRequired) {
        continue;
      }

      final answer = _answers[question.id];

      if (answer == null) {
        _errorMessage = 'Please answer all required questions.';
        notifyListeners();
        return false;
      }

      if (answer is String && answer.trim().isEmpty) {
        _errorMessage = 'Please answer all required questions.';
        notifyListeners();
        return false;
      }

      if (answer is List && answer.isEmpty) {
        _errorMessage = 'Please answer all required questions.';
        notifyListeners();
        return false;
      }
    }

    return true;
  }

  Future<bool> submit() async {
    if (!validate()) {
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final answerList = _answers.entries.map((entry) {
        return Answer(questionId: entry.key, value: entry.value);
      }).toList();

      final response = SurveyResponse(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        surveyId: _surveyId,
        surveyCreatorId: _survey!.createdBy, // Added this
        respondentId: _authRepository.currentUser?.id,
        respondentName: _survey!.requireRespondentName
            ? _respondentName.trim()
            : null,
        respondentEmail: _survey!.requireRespondentEmail
            ? _respondentEmail.trim()
            : null,
        answers: answerList,
        submittedAt: DateTime.now(),
      );

      await _responseRepository.submitResponse(response);

      _submitted = true;
      return true;
    } catch (e) {
      debugPrint('Error submitting response: $e');
      _errorMessage = 'Unable to submit response: $e';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}