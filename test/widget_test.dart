import 'package:flutter_test/flutter_test.dart';

import '../lib/main.dart';
import '../lib/repositories/in_memory_survey_repository.dart';

void main() {
  testWidgets('QuickSurveys app loads', (WidgetTester tester) async {
    final surveyRepository = InMemorySurveyRepository();

    await tester.pumpWidget(
      QuickSurveysApp(
        surveyRepository: surveyRepository,
      ),
    );

    expect(find.text('QuickSurveys'), findsOneWidget);
  });
}