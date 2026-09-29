import 'package:flutter/material.dart';

import '../../models/survey.dart';
import '../../repositories/response_repository.dart';
import '../../repositories/survey_repository.dart';
import '../../viewmodels/response_analysis_view_model.dart';

class ResponseAnalysisView extends StatefulWidget {
  final SurveyRepository surveyRepository;
  final ResponseRepository responseRepository;
  final String surveyId;

  const ResponseAnalysisView({
    super.key,
    required this.surveyRepository,
    required this.responseRepository,
    required this.surveyId,
  });

  @override
  State<ResponseAnalysisView> createState() =>
      _ResponseAnalysisViewState();
}

class _ResponseAnalysisViewState extends State<ResponseAnalysisView> {
  late final ResponseAnalysisViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    _viewModel = ResponseAnalysisViewModel(
      surveyRepository: widget.surveyRepository,
      responseRepository: widget.responseRepository,
      surveyId: widget.surveyId,
    );

    _viewModel.loadAnalysis();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (_viewModel.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Response Analysis'),
            ),
            body: Center(
              child: Text(_viewModel.errorMessage!),
            ),
          );
        }

        final survey = _viewModel.survey;

        if (survey == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Response Analysis'),
            ),
            body: const Center(
              child: Text('Survey not found.'),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(survey.title),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Individual Responses'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildOverview(survey),
                _buildIndividualResponses(survey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverview(Survey survey) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Responses',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_viewModel.responseCount}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Question Responses',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...survey.questions.map(_buildQuestionSummary),
      ],
    );
  }

  Widget _buildQuestionSummary(Question question) {
    final responses = _viewModel.responses;

    final answers = responses
        .map((response) => response.answers[question.id])
        .where((answer) => answer != null)
        .toList();

    if (question.type == QuestionType.shortAnswer ||
        question.type == QuestionType.paragraph) {
      return _buildOpenEndedQuestion(question, answers);
    }

    if (question.type == QuestionType.multipleChoice ||
        question.type == QuestionType.checkboxes ||
        question.type == QuestionType.linearScale) {
      return _buildChoiceChart(question, answers);
    }

    return const SizedBox.shrink();
  }

  Widget _buildOpenEndedQuestion(
      Question question,
      List<dynamic> answers,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.text,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (answers.isEmpty)
              const Text('No responses yet.')
            else
              ...answers.map(
                    (answer) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(answer.toString()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChart(
      Question question,
      List<dynamic> answers,
      ) {
    final counts = <String, int>{};

    for (final option in question.options) {
      counts[option] = 0;
    }

    if (question.type == QuestionType.linearScale) {
      for (var value = question.scaleMin;
      value <= question.scaleMax;
      value++) {
        final description = question.scaleLabels[value];

        final label = description == null || description.isEmpty
            ? value.toString()
            : '$value — $description';

        counts[label] = 0;
      }
    }

    for (final answer in answers) {
      if (question.type == QuestionType.checkboxes && answer is List) {
        for (final selected in answer) {
          final key = selected.toString();
          counts[key] = (counts[key] ?? 0) + 1;
        }
      } else {
        String key;

        if (question.type == QuestionType.linearScale) {
          final value = int.tryParse(answer.toString());
          final description =
          value == null ? null : question.scaleLabels[value];

          key = value != null &&
              description != null &&
              description.isNotEmpty
              ? '$value — $description'
              : answer.toString();
        } else {
          key = answer.toString();
        }

        counts[key] = (counts[key] ?? 0) + 1;
      }
    }

    final maxCount = counts.values.isEmpty
        ? 1
        : counts.values.reduce(
          (a, b) => a > b ? a : b,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.text,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (counts.isEmpty)
              const Text('No responses yet.')
            else
              ...counts.entries.map(
                    (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(entry.key),
                          ),
                          Text(
                            '${entry.value}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: entry.value / maxCount,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualResponses(Survey survey) {
    final responses = _viewModel.responses;

    if (responses.isEmpty) {
      return const Center(
        child: Text('No responses yet.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: responses.length,
      itemBuilder: (context, index) {
        final response = responses[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(
              _respondentTitle(response),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(response.submittedAt),
                ),
                if (response.respondentEmail != null &&
                    response.respondentEmail!.trim().isNotEmpty)
                  Text(
                    response.respondentEmail!,
                  ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: survey.questions.map((question) {
                    final answer = response.answers[question.id];

                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question.text,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            answer == null
                                ? 'No answer'
                                : _formatAnswer(question, answer),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _respondentTitle(dynamic response) {
    if (response.respondentName != null &&
        response.respondentName!.trim().isNotEmpty) {
      return response.respondentName!;
    }

    if (response.respondentEmail != null &&
        response.respondentEmail!.trim().isNotEmpty) {
      return response.respondentEmail!;
    }

    return 'Anonymous respondent';
  }

  String _formatAnswer(Question question, dynamic answer) {
    if (answer == null) {
      return 'No answer';
    }

    if (question.type == QuestionType.linearScale && answer is int) {
      final label = question.scaleLabels[answer];

      if (label != null && label.isNotEmpty) {
        return '$answer — $label';
      }
    }

    if (answer is List) {
      return answer.join(', ');
    }

    return answer.toString();
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();

    return '${local.month}/${local.day}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}