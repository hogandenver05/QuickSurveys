
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/survey.dart';
import '../repositories/survey_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/response_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final SurveyRepository _surveyRepository;
  final AuthRepository _authRepository;
  final ResponseRepository _responseRepository;
  final FirebaseFirestore _firestore;

  DashboardViewModel({
    required SurveyRepository surveyRepository,
    required AuthRepository authRepository,
    required ResponseRepository responseRepository,
    FirebaseFirestore? firestore,
  }) : _surveyRepository = surveyRepository,
        _authRepository = authRepository,
        _responseRepository = responseRepository,
        _firestore = firestore ?? FirebaseFirestore.instance;

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

  bool get requiresPasswordForAccountDeletion =>
      _authRepository.supportsPasswordReauthentication;

  List<Survey> get filteredOtherSurveys {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return List.unmodifiable(_otherSurveys);
    }

    return _otherSurveys.where((survey) {
      final title = survey.title.toLowerCase();
      final creatorName =
      getCreatorName(survey.createdBy).toLowerCase();
      final shareCode = survey.shareCode.toLowerCase();

      return title.contains(query) ||
          creatorName.contains(query) ||
          shareCode.contains(query);
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

      _otherSurveys = await _surveyRepository.getPublishedSurveys(
        excludeUserId: user.id,
      );

      await _loadCreatorNames();
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
        final doc = await _firestore.collection('users').doc(creatorId).get();

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

  Future<void> deleteAllSurveysForCurrentUser() async {
    final user = _authRepository.currentUser;

    if (user == null) {
      _errorMessage = 'User not authenticated.';
      notifyListeners();
      return;
    }

    _setLoading(true);

    try {
      _errorMessage = null;

      await _surveyRepository.deleteAllSurveysForUser(user.id);

      _surveys = await _surveyRepository.getSurveysForUser(user.id);

      _otherSurveys = await _surveyRepository.getPublishedSurveys(
        excludeUserId: user.id,
      );

      await _loadCreatorNames();
    } catch (e) {
      debugPrint('Error deleting all surveys: $e');
      _errorMessage = 'Unable to delete all surveys: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount({String? password}) async {
    final user = _authRepository.currentUser;

    if (user == null) {
      _errorMessage = 'User not authenticated.';
      notifyListeners();
      throw Exception('User not authenticated.');
    }

    _setLoading(true);

    try {
      _errorMessage = null;

      // Reauthenticate before performing irreversible operations.
      if (_authRepository.supportsPasswordReauthentication) {
        if (password == null || password.isEmpty) {
          throw Exception('Password is required to delete this account.');
        }

        await _authRepository.reauthenticateWithPassword(password);
      } else if (_authRepository.supportsGoogleReauthentication) {
        await _authRepository.reauthenticateWithGoogle();
      } else {
        throw Exception(
          'No supported reauthentication method is available.',
        );
      }

      // Delete responses to surveys created by this user,
      // followed by the surveys themselves.
      await _surveyRepository.deleteAllSurveysForUser(user.id);

      // Delete responses this user submitted to other creators' surveys.
      await _responseRepository.deleteResponsesByRespondent(user.id);

      // Delete the Firestore profile and Firebase Authentication account.
      await _authRepository.deleteAccount();

      // Clear dashboard data after successful deletion.
      _surveys = [];
      _otherSurveys = [];
      _creatorNames.clear();
    } on FirebaseAuthException catch (e) {
      debugPrint('Error deleting account: ${e.code}');

      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password') {
        _errorMessage = 'The password you entered is incorrect.';
      } else if (e.code == 'requires-recent-login') {
        _errorMessage =
        'Please sign in again before deleting your account.';
      } else {
        _errorMessage = 'Unable to delete account: ${e.message}';
      }

      rethrow;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      _errorMessage = 'Unable to delete account: $e';
      rethrow;
    } finally {
      _setLoading(false);
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
