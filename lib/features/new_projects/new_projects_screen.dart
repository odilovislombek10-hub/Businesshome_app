import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/project.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/project_card.dart';
import 'new_projects_repository.dart';

/// New-build projects list — the `/new-projects` page of the website.
class NewProjectsScreen extends StatefulWidget {
  const NewProjectsScreen({super.key});

  @override
  State<NewProjectsScreen> createState() => _NewProjectsScreenState();
}

class _NewProjectsScreenState extends State<NewProjectsScreen> {
  final _repo = ProjectsRepository();
  late Future<List<Project>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchProjects();
  }

  Future<void> _refresh() async {
    final future = _repo.fetchProjects();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yangi loyihalar'),
        actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder<List<Project>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Show the real reason rather than a generic message — most failures here are network
            // or API-shape problems and the text is what makes them diagnosable.
            return ErrorView(message: '${snapshot.error}', onRetry: _refresh);
          }
          final projects = snapshot.data ?? const <Project>[];
          if (projects.isEmpty) {
            return ErrorView(message: 'Loyihalar topilmadi', onRetry: _refresh);
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: projects.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => ProjectCard(
                project: projects[i],
                onTap: () => context.go('/property/${projects[i].id}'),
              ),
            ),
          );
        },
      ),
    );
  }
}
