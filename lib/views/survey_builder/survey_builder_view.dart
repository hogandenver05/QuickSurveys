import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/survey.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/survey_repository.dart';
import '../../viewmodels/survey_builder_view_model.dart';
import 'widgets/question_dialog.dart';

class SurveyBuilderView extends StatefulWidget {
  final SurveyRepository surveyRepository;
  final AuthRepository authRepository;
  final Survey? survey;

  const SurveyBuilderView({
    super.key,
    required this.surveyRepository,
    required this.authRepository,
    this.survey,
  });

  @override
  State<SurveyBuilderView> createState() => _SurveyBuilderViewState();
}

class _SurveyBuilderViewState extends State<SurveyBuilderView> {
  late final SurveyBuilderViewModel _viewModel;

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  bool get isEditing => _viewModel.isEditing;

  @override
  void initState() {
    super.initState();

    _viewModel = SurveyBuilderViewModel(
      surveyRepository: widget.surveyRepository,
      existingSurvey: widget.survey,
      currentUserId: widget.authRepository.currentUser?.id ?? '',
    );

    _titleController = TextEditingController(text: _viewModel.title);

    _descriptionController = TextEditingController(
      text: _viewModel.description,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _saveSurvey() async {
    final saved = await _viewModel.save();

    if (!mounted || !saved) {
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> _publishSurvey() async {
    final published = await _viewModel.publish();

    if (!mounted || !published) {
      return;
    }

    final shareCode = _viewModel.publishedShareCode;

    if (shareCode == null || shareCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to retrieve survey share code.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Survey Published'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your survey has been published!',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Share this code with others so they can find your survey:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SelectableText(
                shareCode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: shareCode));

                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Survey code copied!')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Code'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showAddQuestionDialog(BuildContext context) async {
    final question = await showDialog<Question>(
      context: context,
      builder: (context) {
        return const QuestionDialog();
      },
    );

    if (question != null) {
      _viewModel.addQuestion(question);
    }
  }

  Future<void> _showEditQuestionDialog(BuildContext context, int index) async {
    final existingQuestion = _viewModel.questions[index];

    final updatedQuestion = await showDialog<Question>(
      context: context,
      builder: (context) {
        return QuestionDialog(existingQuestion: existingQuestion);
      },
    );

    if (updatedQuestion != null) {
      _viewModel.updateQuestion(index, updatedQuestion);
    }
  }

  String _questionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.shortAnswer:
        return 'Short answer';
      case QuestionType.paragraph:
        return 'Paragraph';
      case QuestionType.multipleChoice:
        return 'Multiple choice';
      case QuestionType.checkboxes:
        return 'Checkboxes';
      case QuestionType.linearScale:
        return 'Linear scale';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Survey' : 'Create Survey')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Survey Title',
              hintText: 'Enter a title for your survey',
              border: OutlineInputBorder(),
            ),
            onChanged: _viewModel.setTitle,
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _descriptionController,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Tell respondents what this survey is about.',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            onChanged: _viewModel.setDescription,
          ),

          const SizedBox(height: 24),

          AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) => OutlinedButton.icon(
              onPressed: _viewModel.isSaving
                  ? null
                  : () => _showAddQuestionDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
            ),
          ),

          AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) {
              if (_viewModel.questions.isEmpty) return const SizedBox.shrink();
              
              return Column(
                children: [
                  const SizedBox(height: 16),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _viewModel.questions.length,
                    onReorderItem: _viewModel.reorderQuestions,
                    itemBuilder: (context, index) {
                      final question = _viewModel.questions[index];

                      return Card(
                        key: ValueKey(question.id),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                          title: Text(question.text),
                          subtitle: Text(_questionTypeLabel(question.type)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (question.isRequired)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Text(
                                    'Required',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              IconButton(
                                tooltip: 'Edit question',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: _viewModel.isSaving
                                    ? null
                                    : () => _showEditQuestionDialog(context, index),
                              ),
                              IconButton(
                                tooltip: 'Delete question',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: _viewModel.isSaving
                                    ? null
                                    : () => _viewModel.deleteQuestion(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Survey Settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    const SizedBox(height: 8),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Allow anonymous responses'),
                      subtitle: const Text(
                        'Respondents can submit without providing their identity.',
                      ),
                      value: _viewModel.allowAnonymousResponses,
                      onChanged: _viewModel.isSaving
                          ? null
                          : _viewModel.setAllowAnonymousResponses,
                    ),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Require respondent name'),
                      subtitle: const Text(
                        'Ask respondents to provide their name.',
                      ),
                      value: _viewModel.requireRespondentName,
                      onChanged: _viewModel.allowAnonymousResponses
                          ? null
                          : _viewModel.setRequireRespondentName,
                    ),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Require respondent email'),
                      subtitle: const Text(
                        'Ask respondents to provide their email address.',
                      ),
                      value: _viewModel.requireRespondentEmail,
                      onChanged: _viewModel.allowAnonymousResponses
                          ? null
                          : _viewModel.setRequireRespondentEmail,
                    ),
                  ],
                ),
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) {
              if (_viewModel.errorMessage == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _viewModel.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: _viewModel.isSaving ? null : _publishSurvey,
                  icon: const Icon(Icons.publish),
                  label: const Text('Publish Survey'),
                ),

                const SizedBox(height: 12),

                OutlinedButton(
                  onPressed: _viewModel.isSaving ? null : _saveSurvey,
                  child: Text(isEditing ? 'Save Changes' : 'Save Draft'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
