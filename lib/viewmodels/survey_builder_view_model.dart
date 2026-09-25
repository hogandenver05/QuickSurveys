import 'package:flutter/foundation.dart';

import '../models/survey.dart';
import '../repositories/survey_repository.dart';

class SurveyBuilderViewModel extends ChangeNotifier {
  final SurveyRepository _surveyRepository;
  final Survey? _existingSurvey;

  SurveyBuilderViewModel({
    required SurveyRepository surveyRepository,
    Survey? existingSurvey,
  }) : _surveyRepository = surveyRepository,
        _existingSurvey = existingSurvey {
    _title = existingSurvey?.title ?? '';
    _description = existingSurvey?.description ?? '';
  }

  late String _title;
  late String _description;

  bool _isSaving = false;
  String? _errorMessage;

  String get title => _title;
  String get description => _description;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  bool get isEditing => _existingSurvey != null;

  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    notifyListeners();
  }

  Future<bool> save() async {
    if (_title.trim().isEmpty) {
      _errorMessage = 'Survey title is required.';
      notifyListeners();
      return false;
    }

    _setSaving(true);

    try {
      _errorMessage = null;

      final survey = _existingSurvey?.copyWith(
        title: _title.trim(),
        description: _description.trim(),
      ) ??
          Survey(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: _title.trim(),
            description: _description.trim(),
            isPublished: false,
          );

      if (isEditing) {
        await _surveyRepository.updateSurvey(survey);
      } else {
        await _surveyRepository.createSurvey(survey);
      }

      return true;
    } catch (_) {
      _errorMessage = 'Unable to save survey.';
      return false;
    } finally {
      _setSaving(false);
    }
  }

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }
}
