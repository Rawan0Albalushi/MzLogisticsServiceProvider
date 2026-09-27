import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/job.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/entity_card.dart';
import '../../../shared/widgets/info_grid.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_badge.dart';
import 'projects_screen.dart';

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(sessionProvider).permissions.can(AppPermissions.jobsView)) {
      return const NoPermissionState();
    }
    final locale = Localizations.localeOf(context).languageCode;
    return AppPage(
      child: AsyncBody(
        value: ref.watch(projectDetailProvider(id)),
        onRetry: () => ref.invalidate(projectDetailProvider(id)),
        builder: (details) {
          final project = details.project;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DetailBackLink(label: context.tr('projects.backToList'), path: '/projects'),
              const SizedBox(height: 4),
              PageHeader(
                title: project.label(locale),
                subtitle: project.projectId,
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: context.tr('projects.detailTitle'),
                icon: Icons.folder_outlined,
                tone: IconTone.info,
                child: InfoGrid(
                  fields: [
                    InfoField(
                      label: context.tr('projects.projectId'),
                      value: project.projectId,
                      icon: Icons.tag_outlined,
                      tone: IconTone.info,
                    ),
                    InfoField(
                      label: context.tr('projects.nameEn'),
                      value: project.nameEn,
                      icon: Icons.translate_outlined,
                    ),
                    InfoField(
                      label: context.tr('projects.nameAr'),
                      value: project.nameAr,
                      icon: Icons.translate_outlined,
                    ),
                    InfoField(
                      label: context.tr('projects.jobsCount'),
                      value: '${details.jobs.length}',
                      icon: Icons.work_outline_rounded,
                      tone: IconTone.warning,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: context.tr('projects.jobs'),
                icon: Icons.work_outline_rounded,
                tone: IconTone.warning,
                child: details.jobs.isEmpty
                    ? EmptyState(
                        message: context.tr('projects.noJobs'),
                        icon: Icons.work_outline,
                      )
                    : ResponsiveDataView<TransportJob>(
                        items: details.jobs,
                        columns: [
                          DataColumnSpec(context.tr('common.reference')),
                          DataColumnSpec(context.tr('common.customer')),
                          DataColumnSpec(context.tr('common.status')),
                        ],
                        onRowTap: (item) => context.go('/jobs/${item.id}'),
                        rowCells: (item) => [
                          Text(item.reference ?? ''),
                          Text(item.customer?.name ?? '—'),
                          StatusBadge(status: item.status),
                        ],
                        cardBuilder: (item) => EntityCard(
                          title: item.reference ?? '',
                          icon: Icons.work_outline_rounded,
                          tone: IconTone.warning,
                          trailing: StatusBadge(status: item.status),
                          subtitle: item.customer?.name,
                          meta: [
                            Formatters.percent(item.progressPercent),
                          ],
                          onTap: () => context.go('/jobs/${item.id}'),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
