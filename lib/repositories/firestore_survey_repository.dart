import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/survey.dart';
import 'survey_repository.dart';
import 'response_repository.dart';

class FirestoreSurveyRepository implements SurveyRepository {
  final FirebaseFirestore _firestore;
  final ResponseRepository _responseRepository;

  FirestoreSurveyRepository({
    FirebaseFirestore? firestore,
    required this._responseRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _surveysCollection =>
      _firestore.collection('surveys');

  @override
  Future<List<Survey>> getSurveys() async {
    final snapshot = await _surveysCollection.get();
    return snapshot.docs
        .map((doc) => Survey.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<List<Survey>> getSurveysForUser(String userId) async {
    // Temporarily removed .orderBy('createdAt', descending: true)
    // to avoid index requirement while debugging.
    final snapshot = await _surveysCollection
        .where('createdBy', isEqualTo: userId)
        .get();

    final surveys = snapshot.docs
        .map((doc) => Survey.fromMap(doc.data(), doc.id))
        .toList();

    // Sort in memory instead
    surveys.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return surveys;
  }

  @override
  Future<Survey?> getSurvey(String id) async {
    final doc = await _surveysCollection.doc(id).get();
    if (!doc.exists) return null;
    return Survey.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<void> createSurvey(Survey survey) async {
    await _surveysCollection.doc(survey.id).set(survey.toMap());
  }

  @override
  Future<void> updateSurvey(Survey survey) async {
    await _surveysCollection.doc(survey.id).update(survey.toMap());
  }

  @override
  Future<void> deleteSurvey(String id) async {
    await _surveysCollection.doc(id).delete();
  }

  @override
  Future<void> deleteAllSurveysForUser(String userId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('User ID cannot be empty.');
    }

    // Retrieve only surveys created by this user.
    final snapshot = await _surveysCollection
        .where('createdBy', isEqualTo: userId)
        .get();

    // Delete responses before deleting their surveys.
    for (final doc in snapshot.docs) {
      await _responseRepository.deleteResponsesForSurvey(
        doc.id,
        userId,
      );
    }

    // Delete surveys in batches of 450.
    for (var i = 0; i < snapshot.docs.length; i += 450) {
      final batch = _firestore.batch();

      final documents = snapshot.docs.skip(i).take(450);

      for (final doc in documents) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    }
  }

  @override
  Future<List<Survey>> getPublishedSurveys({
    required String excludeUserId,
  }) async {
    final snapshot = await _surveysCollection
        .where('isPublished', isEqualTo: true)
        .get();

    final surveys = snapshot.docs
        .map((doc) => Survey.fromMap(doc.data(), doc.id))
        .where((survey) => survey.createdBy != excludeUserId)
        .toList();

    surveys.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return surveys;
  }

  @override
  Future<Survey?> getSurveyByCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      return null;
    }

    final snapshot = await _surveysCollection
        .where('shareCode', isEqualTo: normalizedCode)
        .where('isPublished', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;

    return Survey.fromMap(doc.data(), doc.id);
  }
}
