
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

_questions = List<Question>.from(
existingSurvey?.questions ?? const [],
);

_allowAnonymousResponses =
    existingSurvey?.allowAnonymousResponses ?? true;

_requireRespondentName =
    existingSurvey?.requireRespondentName ?? false;

_requireRespondentEmail =
    existingSurvey?.requireRespondentEmail ?? false;

}

late String _title;
late String _description;
late List<Question> _questions;
late bool _allowAnonymousResponses;
late bool _requireRespondentName;
late bool _requireRespondentEmail;

bool _isSaving = false;
String? _errorMessage;
String? _savedSurveyId;

String get title => _title;
String get description => _description;
bool get isSaving => _isSaving;
String? get errorMessage => _errorMessage;
String? get savedSurveyId => _savedSurveyId;

bool get isEditing => _existingSurvey != null;

List<Question> get questions => List.unmodifiable(_questions);

bool get allowAnonymousResponses => _allowAnonymousResponses;
bool get requireRespondentName => _requireRespondentName;
bool get requireRespondentEmail => _requireRespondentEmail;

void setTitle(String value) {
_title = value;
notifyListeners();
}

void setDescription(String value) {
_description = value;
notifyListeners();
}

void setAllowAnonymousResponses(bool value) {
  _allowAnonymousResponses = value;
  notifyListeners();
}

void setRequireRespondentName(bool value) {
  _requireRespondentName = value;
  notifyListeners();
}

void setRequireRespondentEmail(bool value) {
  _requireRespondentEmail = value;
  notifyListeners();
}

void addQuestion(Question question) {
_questions.add(question);
notifyListeners();
}

void updateQuestion(int index, Question question) {
if (index < 0 || index >= _questions.length) {
return;
}

_questions[index] = question;
notifyListeners();
}

void deleteQuestion(int index) {
if (index < 0 || index >= _questions.length) {
return;
}

_questions.removeAt(index);
notifyListeners();
}

void reorderQuestions(int oldIndex, int newIndex) {
if (newIndex > oldIndex) {
newIndex -= 1;
}

final question = _questions.removeAt(oldIndex);
_questions.insert(newIndex, question);

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
  questions: List<Question>.from(_questions),
  allowAnonymousResponses: _allowAnonymousResponses,
  requireRespondentName: _requireRespondentName,
  requireRespondentEmail: _requireRespondentEmail,
) ??
    Survey(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _title.trim(),
      description: _description.trim(),
      isPublished: false,
      questions: List<Question>.from(_questions),
      allowAnonymousResponses: _allowAnonymousResponses,
      requireRespondentName: _requireRespondentName,
      requireRespondentEmail: _requireRespondentEmail,
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

Future<bool> publish() async {
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
      questions: List<Question>.from(_questions),
      allowAnonymousResponses: _allowAnonymousResponses,
      requireRespondentName: _requireRespondentName,
      requireRespondentEmail: _requireRespondentEmail,
      isPublished: true,
    ) ??
        Survey(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: _title.trim(),
          description: _description.trim(),
          isPublished: true,
          questions: List<Question>.from(_questions),
          allowAnonymousResponses: _allowAnonymousResponses,
          requireRespondentName: _requireRespondentName,
          requireRespondentEmail: _requireRespondentEmail,
        );

    if (isEditing) {
      await _surveyRepository.updateSurvey(survey);
    } else {
      await _surveyRepository.createSurvey(survey);
    }

    _savedSurveyId = survey.id;

    return true;
  } catch (_) {
    _errorMessage = 'Unable to publish survey.';
    notifyListeners();
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

