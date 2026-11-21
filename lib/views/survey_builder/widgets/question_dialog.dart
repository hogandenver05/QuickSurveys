import 'package:flutter/material.dart';
import '../../../models/survey.dart';

class QuestionDialog extends StatefulWidget {
  final Question? existingQuestion;

  const QuestionDialog({super.key, this.existingQuestion});

  @override
  State<QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<QuestionDialog> {
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

  final TextEditingController _scaleMinLabelController =
      TextEditingController();
  final TextEditingController _scaleMaxLabelController =
      TextEditingController();

  // Keep controllers keyed by numeric scale value so labels survive range edits.
  final Map<int, TextEditingController> _scaleLabelControllers = {};

  TextEditingController _labelControllerFor(int value) =>
      _scaleLabelControllers.putIfAbsent(value, () => TextEditingController());

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
      _scaleMinLabelController.text = question.scaleMinLabel;
      _scaleMaxLabelController.text = question.scaleMaxLabel;
      for (var value = question.scaleMin; value <= question.scaleMax; value++) {
        final index = value - question.scaleMin;
        final label = index < question.scaleLabels.length
            ? question.scaleLabels[index]
            : (value == question.scaleMin
                  ? question.scaleMinLabel
                  : value == question.scaleMax
                  ? question.scaleMaxLabel
                  : '');
        _labelControllerFor(value).text = label;
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();

    for (final controller in _optionControllers) {
      controller.dispose();
    }

    _scaleMinController.dispose();
    _scaleMaxController.dispose();
    _scaleMinLabelController.dispose();
    _scaleMaxLabelController.dispose();
    for (final controller in _scaleLabelControllers.values) {
      controller.dispose();
    }

    super.dispose();
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
              initialValue: _type,
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
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Minimum',
                        border: OutlineInputBorder(),
                      ),
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
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Maximum',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Builder(
                builder: (context) {
                  final min = int.tryParse(_scaleMinController.text);
                  final max = int.tryParse(_scaleMaxController.text);
                  if (min == null ||
                      max == null ||
                      min >= max ||
                      max - min > 20) {
                    return const Text(
                      'Enter a valid range (maximum greater than minimum, up to 21 values).',
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var value = min; value <= max; value++) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(
                            key: ValueKey('scale-label-$value'),
                            controller: _labelControllerFor(value),
                            decoration: InputDecoration(
                              labelText: 'Label for $value',
                              hintText: 'Optional description',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
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
    String scaleMinLabel = '';
    String scaleMaxLabel = '';
    List<String> scaleLabels = const [];

    if (_hasLinearScale) {
      scaleMin = int.tryParse(_scaleMinController.text) ?? 1;
      scaleMax = int.tryParse(_scaleMaxController.text) ?? 5;
      scaleLabels = [
        for (
          var value = scaleMin;
          value <= scaleMax && value <= scaleMin + 20;
          value++
        )
          _labelControllerFor(value).text.trim(),
      ];
      scaleMinLabel = scaleLabels.isNotEmpty ? scaleLabels.first : '';
      scaleMaxLabel = scaleLabels.isNotEmpty ? scaleLabels.last : '';

      if (scaleMin >= scaleMax || scaleMax - scaleMin > 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Maximum must be greater than minimum (up to 21 values).',
            ),
          ),
        );
        return;
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
      scaleMinLabel: scaleMinLabel,
      scaleMaxLabel: scaleMaxLabel,
      scaleLabels: scaleLabels,
    );

    Navigator.of(context).pop(question);
  }
}
