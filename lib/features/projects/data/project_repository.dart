import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/paginated.dart';
import '../../../core/utils/json_utils.dart';
import '../../../shared/models/job.dart';
import 'project.dart';

class ProjectDetails {
  const ProjectDetails({required this.project, required this.jobs});

  final Project project;
  final List<TransportJob> jobs;
}

class ProjectRepository {
  ProjectRepository(this._api);

  final ApiClient _api;

  Future<Paginated<Project>> list({int page = 1, String? search}) async {
    final response = await _api.get(ApiEndpoints.projects, query: {
      'page': page,
      'per_page': 15,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return Paginated.fromResponse(response, Project.fromJson);
  }

  Future<ProjectDetails> show(int id) async {
    final response = await _api.get(ApiEndpoints.project(id));
    final data = asMap(response['data']);
    return ProjectDetails(
      project: Project.fromJson(data),
      jobs: asMapList(data['jobs']).map(TransportJob.fromJson).toList(),
    );
  }
}
