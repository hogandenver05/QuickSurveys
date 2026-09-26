
import 'package:flutter/material.dart';

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

@override
void initState() {
super.initState();

_viewModel = SurveyBuilderViewModel(
surveyRepository: widget.surveyRepository,
existingSurvey: widget.survey,
);

_titleController = TextEditingController(
text: _viewModel.title,
);

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
final isEditing = _viewModel.isEditing;

return Scaffold(
appBar: AppBar(
title: Text(
isEditing ? 'Edit Survey' : 'Create Survey',
),
),
body: AnimatedBuilder(
animation: _viewModel,
builder: (context, _) {
return ListView(
padding: const EdgeInsets.all(24),
children: [
TextField(
controller: _titleController,
enabled: !_viewModel.isSaving,
textInputAction: TextInputAction.next,
decoration: const InputDecoration(
labelText: 'Survey title',
hintText: 'Customer Feedback',
border: OutlineInputBorder(),
),
onChanged: _viewModel.setTitle,
),

const SizedBox(height: 20),

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
    subtitle: Text(
      _questionTypeLabel(question.type),
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (question.isRequired)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Text(
              'Required',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        IconButton(
          tooltip: 'Delete question',
          icon: const Icon(
            Icons.delete_outline,
          ),
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

if (_viewModel.errorMessage != null) ...[
const SizedBox(height: 16),
Text(
_viewModel.errorMessage!,
style: TextStyle(
color: Theme.of(context).colorScheme.error,
),
),
],

const SizedBox(height: 24),

FilledButton(
onPressed: _viewModel.isSaving
? null
    : _saveSurvey,
child: _viewModel.isSaving
? const SizedBox(
width: 20,
height: 20,
child: CircularProgressIndicator(
strokeWidth: 2,
),
)
    : Text(
isEditing
? 'Save Changes'
    : 'Create Survey',
),
),
],
);
},
),
);
}
}

class _QuestionDialog extends StatefulWidget {
const _QuestionDialog();

@override
State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
final TextEditingController _questionController =
TextEditingController();

QuestionType _type = QuestionType.shortAnswer;
bool _required = false;

final List<TextEditingController> _optionControllers = [
TextEditingController(),
TextEditingController(),
];

final TextEditingController _scaleMinController =
TextEditingController(text: '1');

final TextEditingController _scaleMaxController =
TextEditingController(text: '5');

final TextEditingController _scaleMinLabelController =
TextEditingController();

final TextEditingController _scaleMaxLabelController =
TextEditingController();

bool get _hasOptions =>
    _type == QuestionType.multipleChoice ||
        _type == QuestionType.checkboxes;

bool get _hasLinearScale =>
    _type == QuestionType.linearScale;

@override
void dispose() {
_questionController.dispose();

for (final controller in _optionControllers) {
  _scaleMinController.dispose();
  _scaleMaxController.dispose();
  _scaleMinLabelController.dispose();
  _scaleMaxLabelController.dispose();
controller.dispose();
}

super.dispose();
}

@override
Widget build(BuildContext context) {
return AlertDialog(
title: const Text('Add Question'),
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

...List.generate(
_optionControllers.length,
(index) {
return Padding(
padding: const EdgeInsets.only(bottom: 8),
child: TextField(
controller: _optionControllers[index],
decoration: InputDecoration(
labelText: 'Option ${index + 1}',
border: const OutlineInputBorder(),
suffixIcon:
_optionControllers.length > 2
? IconButton(
icon: const Icon(
Icons.remove_circle_outline,
),
onPressed: () {
setState(() {
final controller =
_optionControllers
    .removeAt(index);

controller.dispose();
});
},
)
    : null,
),
),
);
},
),

Align(
alignment: Alignment.centerLeft,
child: TextButton.icon(
onPressed: () {
setState(() {
_optionControllers.add(
TextEditingController(),
);
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
          ),
        ),
      ],
    ),

    const SizedBox(height: 12),

    TextField(
      controller: _scaleMinLabelController,
      decoration: const InputDecoration(
        labelText: 'Minimum label',
        hintText: 'Not satisfied',
        border: OutlineInputBorder(),
      ),
    ),

    const SizedBox(height: 12),

    TextField(
      controller: _scaleMaxLabelController,
      decoration: const InputDecoration(
        labelText: 'Maximum label',
        hintText: 'Very satisfied',
        border: OutlineInputBorder(),
      ),
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
child: const Text('Add Question'),
),
],
);
}

void _createQuestion() {
final text = _questionController.text.trim();

if (text.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Question text is required.'),
),
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
const SnackBar(
content: Text('Add at least two options.'),
),
);
return;
}

int scaleMin = 1;
int scaleMax = 5;

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
}

final question = Question(
  id: DateTime.now().microsecondsSinceEpoch.toString(),
  text: text,
  type: _type,
  isRequired: _required,
  options: options,
  scaleMin: scaleMin,
  scaleMax: scaleMax,
  scaleMinLabel: _scaleMinLabelController.text.trim(),
  scaleMaxLabel: _scaleMaxLabelController.text.trim(),
);

Navigator.of(context).pop(question);
}
}

