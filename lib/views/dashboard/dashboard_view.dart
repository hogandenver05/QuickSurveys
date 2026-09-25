import 'package:flutter/material.dart';

import '../../models/survey.dart';
import '../../repositories/survey_repository.dart';
import '../../viewmodels/dashboard_view_model.dart';
import '../survey_builder/survey_builder_view.dart';

class DashboardView extends StatefulWidget {
  final SurveyRepository surveyRepository;

  const DashboardView({
    super.key,
    required this.surveyRepository,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    _viewModel = DashboardViewModel(
      surveyRepository: widget.surveyRepository,
    );

    _viewModel.loadSurveys();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _createSurvey() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurveyBuilderView(
          surveyRepository: widget.surveyRepository,
        ),
      ),
    );

    await _viewModel.loadSurveys();
  }

  Future<void> _editSurvey(Survey survey) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurveyBuilderView(
          surveyRepository: widget.surveyRepository,
          survey: survey,
        ),
      ),
    );

    await _viewModel.loadSurveys();
  }

  Future<void> _deleteSurvey(Survey survey) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete survey?'),
          content: Text(
            'This will permanently delete "${survey.title}".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await _viewModel.deleteSurvey(survey.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickSurveys'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSurvey,
        icon: const Icon(Icons.add),
        label: const Text('Create Survey'),
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (_viewModel.errorMessage != null) {
            return Center(
              child: Text(_viewModel.errorMessage!),
            );
          }

          if (_viewModel.surveys.isEmpty) {
            return const _EmptyDashboard();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _viewModel.surveys.length,
            itemBuilder: (context, index) {
              final survey = _viewModel.surveys[index];

              return _SurveyCard(
                survey: survey,
                onEdit: () => _editSurvey(survey),
                onDelete: () => _deleteSurvey(survey),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'No surveys yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text('Create your first survey to get started.'),
        ],
      ),
    );
  }
}

class _SurveyCard extends StatelessWidget {
  final Survey survey;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SurveyCard({
    required this.survey,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          survey.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            survey.description.isEmpty
                ? 'No description'
                : survey.description,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (context) {
            return const [
              PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ];
          },
        ),
      ),
    );
  }
}
