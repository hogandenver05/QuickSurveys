import 'package:cloud_firestore/cloud_firestore.dart';
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
  List<Survey> _otherSurveys = [];

  final Map<String, String> _creatorNames = {};

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<Survey> get surveys => List.unmodifiable(_surveys);

  List<Survey> get otherSurveys => List.unmodifiable(_otherSurveys);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;

  List<Survey> get filteredOtherSurveys {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return List.unmodifiable(_otherSurveys);
    }

    return _otherSurveys.where((survey) {
      final title = survey.title.toLowerCase();
      final creatorName = getCreatorName(survey.createdBy).toLowerCase();

      return title.contains(query) || creatorName.contains(query);
    }).toList();
  }

  String getCreatorName(String userId) {
    return _creatorNames[userId] ?? 'Unknown user';
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

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

  Future<void> _loadCreatorNames() async {
    _creatorNames.clear();

    final creatorIds = _otherSurveys
        .map((survey) => survey.createdBy)
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final creatorId in creatorIds) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(creatorId)
            .get();

        if (doc.exists) {
          final data = doc.data();
          final name = data?['name']?.toString().trim();

          if (name != null && name.isNotEmpty) {
            _creatorNames[creatorId] = name;
          } else {
            _creatorNames[creatorId] = 'Unknown user';
          }
        } else {
          _creatorNames[creatorId] = 'Unknown user';
        }
      } catch (e) {
        debugPrint('Error loading creator $creatorId: $e');
        _creatorNames[creatorId] = 'Unknown user';
      }
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