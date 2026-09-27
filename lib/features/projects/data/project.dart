import '../../../core/utils/json_utils.dart';

class Project {
  const Project({
    required this.id,
    required this.projectId,
    required this.nameEn,
    required this.nameAr,
    this.jobsCount = 0,
  });

  final int id;
  final String projectId;
  final String nameEn;
  final String nameAr;
  final int jobsCount;

  String label(String languageCode) {
    if (languageCode.startsWith('ar') && nameAr.isNotEmpty) {
      return nameAr;
    }
    if (nameEn.isNotEmpty) {
      return nameEn;
    }
    return nameAr;
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: asInt(json['id']) ?? 0,
      projectId: asString(json['project_id']) ?? '',
      nameEn: asString(json['name_en']) ?? '',
      nameAr: asString(json['name_ar']) ?? '',
      jobsCount: asInt(json['jobs_count']) ?? 0,
    );
  }
}
