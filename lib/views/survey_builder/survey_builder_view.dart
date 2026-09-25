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
                onPressed: _viewModel.isSaving ? null : _saveSurvey,
                child: _viewModel.isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  isEditing ? 'Save Changes' : 'Create Survey',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
