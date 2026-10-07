import 'package:flutter/material.dart';

import '../../models/survey.dart';
import '../../repositories/response_repository.dart';
import '../../repositories/survey_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../viewmodels/dashboard_view_model.dart';
import '../../viewmodels/survey_response_view_model.dart';
import '../survey_builder/survey_builder_view.dart';
import '../survey_response/survey_response_view.dart';
import '../response_analysis/response_analysis_view.dart';

class DashboardView extends StatefulWidget {
  final SurveyRepository surveyRepository;
  final ResponseRepository responseRepository;
  final AuthRepository authRepository;

  const DashboardView({
    super.key,
    required this.surveyRepository,
    required this.responseRepository,
    required this.authRepository,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
    with SingleTickerProviderStateMixin {
  late final DashboardViewModel _viewModel;
  late final TabController _tabController;

  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();

    _viewModel = DashboardViewModel(
      surveyRepository: widget.surveyRepository,
      authRepository: widget.authRepository,
    );

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _tabController.addListener(_handleTabChange);

    _viewModel.loadSurveys();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      return;
    }

    if (_currentTabIndex != _tabController.index) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _createSurvey() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurveyBuilderView(
          surveyRepository: widget.surveyRepository,
          authRepository: widget.authRepository,
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
          authRepository: widget.authRepository,
          survey: survey,
        ),
      ),
    );

    await _viewModel.loadSurveys();
  }

  Future<void> _openSurvey(Survey survey) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurveyResponseView(
          viewModel: SurveyResponseViewModel(
            surveyRepository: widget.surveyRepository,
            responseRepository: widget.responseRepository,
            authRepository: widget.authRepository,
            surveyId: survey.id,
          ),
        ),
      ),
    );

    await _viewModel.loadSurveys();
  }

  Future<void> _analyzeResponses(Survey survey) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResponseAnalysisView(
          surveyRepository: widget.surveyRepository,
          responseRepository: widget.responseRepository,
          surveyId: survey.id,
        ),
      ),
    );
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
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => _viewModel.signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.assignment_outlined),
              text: 'My Surveys',
            ),
            Tab(
              icon: Icon(Icons.explore_outlined),
              text: 'Explore Surveys',
            ),
          ],
        ),
      ),

      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton.extended(
        onPressed: _createSurvey,
        icon: const Icon(Icons.add),
        label: const Text('Create Survey'),
      )
          : null,

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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _viewModel.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _viewModel.loadSurveys,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildMySurveys(),
              _buildExploreSurveys(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMySurveys() {
    if (_viewModel.surveys.isEmpty) {
      return const _EmptyDashboard();
    }

    return RefreshIndicator(
      onRefresh: _viewModel.loadSurveys,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _viewModel.surveys.length,
        itemBuilder: (context, index) {
          final survey = _viewModel.surveys[index];

          return _SurveyCard(
            survey: survey,
            onEdit: () => _editSurvey(survey),
            onDelete: () => _deleteSurvey(survey),
            onAnalyze: () => _analyzeResponses(survey),
          );
        },
      ),
    );
  }

  Widget _buildExploreSurveys() {
    final surveys = _viewModel.filteredOtherSurveys;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: _viewModel.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search surveys or creators...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _viewModel.searchQuery.isNotEmpty
                  ? IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _viewModel.setSearchQuery('');
                },
                icon: const Icon(Icons.clear),
              )
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
        ),

        Expanded(
          child: surveys.isEmpty
              ? _ExploreEmptyState(
            isSearching: _viewModel.searchQuery.isNotEmpty,
          )
              : RefreshIndicator(
            onRefresh: _viewModel.loadSurveys,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: surveys.length,
              itemBuilder: (context, index) {
                final survey = surveys[index];

                return _ExploreSurveyCard(
                  survey: survey,
                  creatorName: _viewModel.getCreatorName(
                    survey.createdBy,
                  ),
                  onTakeSurvey: () => _openSurvey(survey),
                );
              },
            ),
          ),
        ),
      ],
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
          Text(
            'Create your first survey to get started.',
          ),
        ],
      ),
    );
  }
}

class _ExploreEmptyState extends StatelessWidget {
  final bool isSearching;

  const _ExploreEmptyState({
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearching
                  ? Icons.search_off
                  : Icons.explore_outlined,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? 'No matching surveys'
                  : 'No surveys to explore',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try searching for another survey or creator.'
                  : 'Published surveys from other users will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SurveyCard extends StatelessWidget {
  final Survey survey;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAnalyze;

  const _SurveyCard({
    required this.survey,
    required this.onEdit,
    required this.onDelete,
    required this.onAnalyze,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                survey.description.isEmpty
                    ? 'No description'
                    : survey.description,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    survey.isPublished
                        ? Icons.public
                        : Icons.edit_note,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    survey.isPublished
                        ? 'Published'
                        : 'Draft',
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {

              case 'analyze':
                onAnalyze();
                break;

              case 'edit':
                onEdit();
                break;

              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) {
            return const [

              PopupMenuItem(
                value: 'analyze',
                child: Text('Analyze Responses'),
              ),
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

class _ExploreSurveyCard extends StatelessWidget {
  final Survey survey;
  final String creatorName;
  final VoidCallback onTakeSurvey;

  const _ExploreSurveyCard({
    required this.survey,
    required this.creatorName,
    required this.onTakeSurvey,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              survey.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Created by: $creatorName',
                  ),
                ),
              ],
            ),

            if (survey.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(survey.description),
            ],

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onTakeSurvey,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Take Survey'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}