import 'package:flutter/material.dart';

import 'repositories/in_memory_survey_repository.dart';
import 'views/dashboard/dashboard_view.dart';

void main() {
  final surveyRepository = InMemorySurveyRepository();

  runApp(
    QuickSurveysApp(
      surveyRepository: surveyRepository,
    ),
  );
}

class QuickSurveysApp extends StatelessWidget {
  final InMemorySurveyRepository surveyRepository;

  const QuickSurveysApp({
    super.key,
    required this.surveyRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickSurveys',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: DashboardView(
        surveyRepository: surveyRepository,
      ),
    );
  }
}
