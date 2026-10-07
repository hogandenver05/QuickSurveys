import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/survey.dart';
import 'survey_repository.dart';

class FirestoreSurveyRepository implements SurveyRepository {
  final FirebaseFirestore _firestore;

  FirestoreSurveyRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
}