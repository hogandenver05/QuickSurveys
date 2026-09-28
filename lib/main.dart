import 'package:flutter/material.dart';

import 'repositories/in_memory_response_repository.dart';
import 'repositories/in_memory_survey_repository.dart';
import 'views/dashboard/dashboard_view.dart';

void main() {
  final surveyRepository = InMemorySurveyRepository();
  final responseRepository = InMemoryResponseRepository();

  runApp(
    QuickSurveysApp(
      surveyRepository: surveyRepository,
      responseRepository: responseRepository,
    ),
  );
}

class QuickSurveysApp extends StatelessWidget {
  final InMemorySurveyRepository surveyRepository;
  final InMemoryResponseRepository responseRepository;

  const QuickSurveysApp({
    super.key,
    required this.surveyRepository,
    required this.responseRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickSurveys',
      home: DashboardView(
        surveyRepository: surveyRepository,
        responseRepository: responseRepository,
      ),
    );
  }
}
