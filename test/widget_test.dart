import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:surveys/repositories/in_memory_response_repository.dart';
import 'package:surveys/repositories/in_memory_survey_repository.dart';
import 'package:surveys/views/dashboard/dashboard_view.dart';

void main() {
  testWidgets('QuickSurveys dashboard loads', (tester) async {
    final surveyRepository = InMemorySurveyRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardView(
          surveyRepository: surveyRepository,
          responseRepository: InMemoryResponseRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('QuickSurveys'), findsOneWidget);
  });
}