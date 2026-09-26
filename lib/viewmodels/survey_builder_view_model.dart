
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
}

late String _title;
late String _description;
late List<Question> _questions;

bool _isSaving = false;
String? _errorMessage;

String get title => _title;
String get description => _description;
bool get isSaving => _isSaving;
String? get errorMessage => _errorMessage;

bool get isEditing => _existingSurvey != null;

List<Question> get questions => List.unmodifiable(_questions);

void setTitle(String value) {
_title = value;
notifyListeners();
}

void setDescription(String value) {
_description = value;
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
) ??
Survey(
id: DateTime.now().microsecondsSinceEpoch.toString(),
title: _title.trim(),
description: _description.trim(),
isPublished: false,
questions: List<Question>.from(_questions),
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

