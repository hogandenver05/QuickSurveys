import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/survey_response.dart';
import 'response_repository.dart';

class FirestoreResponseRepository implements ResponseRepository {
  final FirebaseFirestore _firestore;

  FirestoreResponseRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _responsesCollection =>
      _firestore.collection('responses');

  @override
  Future<List<SurveyResponse>> getResponsesForSurvey(
    String surveyId,
    String creatorId,
  ) async {
    // Include creatorId in the query to satisfy security rules
    final snapshot = await _responsesCollection
        .where('surveyId', isEqualTo: surveyId)
        .where('surveyCreatorId', isEqualTo: creatorId)
        .get();

    final responses = snapshot.docs
        .map((doc) => SurveyResponse.fromMap(doc.data(), doc.id))
        .toList();

    // Sort in memory
    responses.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    return responses;
  }

  @override
  Future<void> submitResponse(SurveyResponse response) async {
    await _responsesCollection.doc(response.id).set(response.toMap());
  }
}
