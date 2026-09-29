import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/survey.dart';
import '../../repositories/survey_repository.dart';
import '../../viewmodels/survey_builder_view_model.dart';

class SurveyBuilderView extends StatefulWidget {
  final SurveyRepository surveyRepository;
  final Survey? survey;

  const SurveyBuilderView({
    super.key,
    required this.surveyRepository,
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

    final surveyId = _viewModel.savedSurveyId;

    if (surveyId == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final surveyUrl =
            'https://quicksurveys.app/survey/${_viewModel.savedSurveyId}';

        return AlertDialog(
          title: const Text('Survey Published'),
          content: SelectableText(surveyUrl),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: surveyUrl));

                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Survey link copied.')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Link'),
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
        return const _QuestionDialog();
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
        return _QuestionDialog(existingQuestion: existingQuestion);
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
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _titleController,
                enabled: !_viewModel.isSaving,
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
                enabled: !_viewModel.isSaving,
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

              OutlinedButton.icon(
                onPressed: _viewModel.isSaving
                    ? null
                    : () => _showAddQuestionDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Question'),
              ),

              if (_viewModel.questions.isNotEmpty) ...[
                const SizedBox(height: 16),

                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _viewModel.questions.length,
                  onReorder: _viewModel.reorderQuestions,
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
                                  : () =>
                                        _showEditQuestionDialog(context, index),
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

              const SizedBox(height: 24),

              Card(
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

              if (_viewModel.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _viewModel.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],

              const SizedBox(height: 24),

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
          );
        },
      ),
    );
  }
}

class _QuestionDialog extends StatefulWidget {
  final Question? existingQuestion;

  const _QuestionDialog({this.existingQuestion});

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  late final TextEditingController _questionController;

  late QuestionType _type;
  late bool _required;

  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  final TextEditingController _scaleMinController = TextEditingController(
    text: '1',
  );

  final TextEditingController _scaleMaxController = TextEditingController(
    text: '5',
  );

  final Map<int, TextEditingController> _scaleLabelControllers = {};

  bool get _hasOptions =>
      _type == QuestionType.multipleChoice || _type == QuestionType.checkboxes;

  bool get _hasLinearScale => _type == QuestionType.linearScale;

  @override
  void initState() {
    super.initState();

    final question = widget.existingQuestion;

    _questionController = TextEditingController(text: question?.text ?? '');

    _type = question?.type ?? QuestionType.shortAnswer;
    _required = question?.isRequired ?? false;

    if (question != null && question.options.isNotEmpty) {
      for (final controller in _optionControllers) {
        controller.dispose();
      }

      _optionControllers.clear();

      for (final option in question.options) {
        _optionControllers.add(TextEditingController(text: option));
      }

      while (_optionControllers.length < 2) {
        _optionControllers.add(TextEditingController());
      }
    }

    if (question != null) {
      _scaleMinController.text = question.scaleMin.toString();
      _scaleMaxController.text = question.scaleMax.toString();
    }

    _syncScaleLabelControllers(question?.scaleLabels ?? const {});
  }

  @override
  void dispose() {
    _questionController.dispose();

    for (final controller in _optionControllers) {
      controller.dispose();
    }

    _scaleMinController.dispose();
    _scaleMaxController.dispose();
    for (final controller in _scaleLabelControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  List<int> get _scaleValues {
    final min = int.tryParse(_scaleMinController.text) ?? 1;
    final max = int.tryParse(_scaleMaxController.text) ?? 5;

    if (min >= max || max - min > 20) {
      return const [1, 2, 3, 4, 5];
    }

    return [for (var value = min; value <= max; value++) value];
  }

  void _syncScaleLabelControllers([Map<int, String> initialLabels = const {}]) {
    final values = _scaleValues.toSet();

    for (final value in values) {
      _scaleLabelControllers.putIfAbsent(
        value,
        () => TextEditingController(text: initialLabels[value] ?? ''),
      );
    }

    final staleValues = _scaleLabelControllers.keys
        .where((value) => !values.contains(value))
        .toList();

    for (final value in staleValues) {
      _scaleLabelControllers.remove(value)?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingQuestion == null ? 'Add Question' : 'Edit Question',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _questionController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Question',
                hintText: 'What would you like to ask?',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<QuestionType>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Question type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: QuestionType.shortAnswer,
                  child: Text('Short answer'),
                ),
                DropdownMenuItem(
                  value: QuestionType.paragraph,
                  child: Text('Paragraph'),
                ),
                DropdownMenuItem(
                  value: QuestionType.multipleChoice,
                  child: Text('Multiple choice'),
                ),
                DropdownMenuItem(
                  value: QuestionType.checkboxes,
                  child: Text('Checkboxes'),
                ),
                DropdownMenuItem(
                  value: QuestionType.linearScale,
                  child: Text('Linear scale'),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _type = value;
                });
              },
            ),

            if (_hasOptions) ...[
              const SizedBox(height: 16),

              ...List.generate(_optionControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _optionControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Option ${index + 1}',
                      border: const OutlineInputBorder(),
                      suffixIcon: _optionControllers.length > 2
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                setState(() {
                                  final controller = _optionControllers
                                      .removeAt(index);
                                  controller.dispose();
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                );
              }),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _optionControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add option'),
                ),
              ),
            ],

            if (_hasLinearScale) ...[
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _scaleMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minimum',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(_syncScaleLabelControllers);
                      },
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('to'),
                  ),

                  Expanded(
                    child: TextField(
                      controller: _scaleMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Maximum',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(_syncScaleLabelControllers);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Description for each scale value',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),

              const SizedBox(height: 8),

              ..._scaleValues.map((value) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: _scaleLabelControllers[value],
                    decoration: InputDecoration(
                      labelText: 'Value $value description',
                      hintText: value == _scaleValues.first
                          ? 'Not satisfied'
                          : value == _scaleValues.last
                          ? 'Very satisfied'
                          : 'Describe this value',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }),
            ],

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Required'),
              value: _required,
              onChanged: (value) {
                setState(() {
                  _required = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _createQuestion,
          child: Text(
            widget.existingQuestion == null ? 'Add Question' : 'Save Changes',
          ),
        ),
      ],
    );
  }

  void _createQuestion() {
    final text = _questionController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question text is required.')),
      );
      return;
    }

    final options = _hasOptions
        ? _optionControllers
              .map((controller) => controller.text.trim())
              .where((option) => option.isNotEmpty)
              .toList()
        : <String>[];

    if (_hasOptions && options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least two options.')),
      );
      return;
    }

    int scaleMin = 1;
    int scaleMax = 5;
    final scaleLabels = <int, String>{};

    if (_hasLinearScale) {
      scaleMin = int.tryParse(_scaleMinController.text) ?? 1;
      scaleMax = int.tryParse(_scaleMaxController.text) ?? 5;

      if (scaleMin >= scaleMax) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum must be greater than minimum.'),
          ),
        );
        return;
      }

      for (var value = scaleMin; value <= scaleMax; value++) {
        final label = _scaleLabelControllers[value]?.text.trim() ?? '';
        if (label.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please provide a description for scale value $value.',
              ),
            ),
          );
          return;
        }
        scaleLabels[value] = label;
      }
    }

    final question = Question(
      id:
          widget.existingQuestion?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      type: _type,
      isRequired: _required,
      options: options,
      scaleMin: scaleMin,
      scaleMax: scaleMax,
      scaleLabels: scaleLabels,
    );

    Navigator.of(context).pop(question);
  }
}
