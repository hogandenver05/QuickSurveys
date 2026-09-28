import 'package:flutter/material.dart';

import '../../models/survey.dart';
import '../../viewmodels/survey_response_view_model.dart';

class SurveyResponseView extends StatefulWidget {
  final SurveyResponseViewModel viewModel;

  const SurveyResponseView({
    super.key,
    required this.viewModel,
  });

  @override
  State<SurveyResponseView> createState() => _SurveyResponseViewState();
}

class _SurveyResponseViewState extends State<SurveyResponseView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadSurvey();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        if (widget.viewModel.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (widget.viewModel.submitted) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Thank you!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Your response has been recorded.'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Back to Dashboard'),
                  ),
                ],
              ),
            ),
          );
        }

        final survey = widget.viewModel.survey;

        if (survey == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Survey'),
            ),
            body: Center(
              child: Text(
                widget.viewModel.errorMessage ??
                    'This survey is unavailable.',
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(survey.title),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 700,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      survey.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),

                    if (survey.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        survey.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],

                    const SizedBox(height: 24),

                    if (survey.requireRespondentName)
                      _buildNameField(),

                    if (survey.requireRespondentEmail)
                      _buildEmailField(),

                    if (survey.requireRespondentName ||
                        survey.requireRespondentEmail)
                      const SizedBox(height: 16),

                    ...survey.questions.asMap().entries.map(
                          (entry) {
                        final index = entry.key;
                        final question = entry.value;

                        return _buildQuestion(
                          question,
                          index,
                        );
                      },
                    ),

                    if (widget.viewModel.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        widget.viewModel.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        onPressed: widget.viewModel.isSubmitting
                            ? null
                            : () async {
                          await widget.viewModel.submit();
                        },
                        child: widget.viewModel.isSubmitting
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Text('Submit Response'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNameField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Name',
          border: OutlineInputBorder(),
        ),
        onChanged: widget.viewModel.setRespondentName,
      ),
    );
  }

  Widget _buildEmailField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Email',
          border: OutlineInputBorder(),
        ),
        onChanged: widget.viewModel.setRespondentEmail,
      ),
    );
  }

  Widget _buildQuestion(
      Question question,
      int index,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ${question.text}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (question.isRequired)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Required',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            _buildQuestionInput(question),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput(Question question) {
    switch (question.type) {
      case QuestionType.shortAnswer:
        return TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Your answer',
          ),
          onChanged: (value) {
            widget.viewModel.setAnswer(question.id, value);
          },
        );

      case QuestionType.paragraph:
        return TextField(
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Your answer',
          ),
          onChanged: (value) {
            widget.viewModel.setAnswer(question.id, value);
          },
        );

      case QuestionType.multipleChoice:
        final selected =
        widget.viewModel.answers[question.id] as String?;

        return Column(
          children: question.options.map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: selected,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                if (value != null) {
                  widget.viewModel.setAnswer(
                    question.id,
                    value,
                  );
                }
              },
            );
          }).toList(),
        );

      case QuestionType.checkboxes:
        final selected = List<String>.from(
          widget.viewModel.answers[question.id] as List? ?? [],
        );

        return Column(
          children: question.options.map((option) {
            return CheckboxListTile(
              title: Text(option),
              value: selected.contains(option),
              contentPadding: EdgeInsets.zero,
              onChanged: (checked) {
                if (checked == true) {
                  selected.add(option);
                } else {
                  selected.remove(option);
                }

                widget.viewModel.setAnswer(
                  question.id,
                  selected,
                );
              },
            );
          }).toList(),
        );

      case QuestionType.linearScale:
        final selected =
        widget.viewModel.answers[question.id] as int?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  question.scaleMinLabel.isEmpty
                      ? question.scaleMin.toString()
                      : question.scaleMinLabel,
                ),
                Text(
                  question.scaleMaxLabel.isEmpty
                      ? question.scaleMax.toString()
                      : question.scaleMaxLabel,
                ),
              ],
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              children: [
                for (
                var value = question.scaleMin;
                value <= question.scaleMax;
                value++
                )
                  ChoiceChip(
                    label: Text(value.toString()),
                    selected: selected == value,
                    onSelected: (_) {
                      widget.viewModel.setAnswer(
                        question.id,
                        value,
                      );
                    },
                  ),
              ],
            ),
          ],
        );
    }
  }
}