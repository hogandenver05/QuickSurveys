import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'models/app_user.dart';
import 'repositories/auth_repository.dart';
import 'repositories/firebase_auth_repository.dart';
import 'repositories/survey_repository.dart';
import 'repositories/firestore_survey_repository.dart';
import 'repositories/response_repository.dart';
import 'repositories/firestore_response_repository.dart';
import 'views/dashboard/dashboard_view.dart';
import 'views/auth/auth_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authRepository = FirebaseAuthRepository();
  final surveyRepository = FirestoreSurveyRepository();
  final responseRepository = FirestoreResponseRepository();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<SurveyRepository>.value(value: surveyRepository),
        Provider<ResponseRepository>.value(value: responseRepository),
      ],
      child: const QuickSurveysApp(),
    ),
  );
}

class QuickSurveysApp extends StatelessWidget {
  const QuickSurveysApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();

    return MaterialApp(
      title: 'QuickSurveys',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: StreamBuilder<AppUser?>(
        initialData: authRepository.currentUser,
        stream: authRepository.user,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const AuthView();
          }

          return DashboardView(
            surveyRepository: context.read<SurveyRepository>(),
            responseRepository: context.read<ResponseRepository>(),
            authRepository: authRepository,
          );
        },
      ),
    );
  }
}