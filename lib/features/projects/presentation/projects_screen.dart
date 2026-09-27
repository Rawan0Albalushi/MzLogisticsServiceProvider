import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/entity_card.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../data/project.dart';

final projectSearchProvider = StateProvider<String>((ref) => '');
final projectPageProvider = StateProvider<int>((ref) => 1);

final projectsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(projectRepositoryProvider).list(
        page: ref.watch(projectPageProvider),
        search: ref.watch(projectSearchProvider),
      );
});

final projectDetailProvider = FutureProvider.autoDispose.family((ref, int id) {
  return ref.watch(projectRepositoryProvider).show(id);
});

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(sessionProvider).permissions.can(AppPermissions.jobsView)) {
      return const NoPermissionState();
    }
    final locale = Localizations.localeOf(context).languageCode;
    return AppPage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: context.tr('projects.title'),
            subtitle: context.tr('projects.subtitle'),
          ),
          const SizedBox(height: 12),
          FilterBar(
            children: [
              FilterSearchField(
                hint: context.tr('projects.search'),
                onChanged: (value) {
                  ref.read(projectSearchProvider.notifier).state = value;
                  ref.read(projectPageProvider.notifier).state = 1;
                },
              ),
            ],
          ),
          AsyncBody(
            value: ref.watch(projectsProvider),
            onRetry: () => ref.invalidate(projectsProvider),
            isEmpty: (data) => data.isEmpty,
            empty: EmptyState(
              message: context.tr('projects.empty'),
              icon: Icons.folder_outlined,
            ),
            builder: (data) {
              return ResponsiveDataView<Project>(
                items: data.items,
                columns: [
                  DataColumnSpec(context.tr('projects.projectId')),
                  DataColumnSpec(context.tr('projects.name')),
                  DataColumnSpec(context.tr('projects.jobsCount')),
                ],
                onRowTap: (item) => context.go('/projects/${item.id}'),
                rowCells: (item) => [
                  Text(item.projectId),
                  Text(item.label(locale)),
                  Text('${item.jobsCount}'),
                ],
                cardBuilder: (item) => EntityCard(
                  title: item.label(locale),
                  icon: Icons.folder_outlined,
                  tone: IconTone.info,
                  subtitle: item.projectId,
                  meta: [
                    '${item.jobsCount} ${context.tr('projects.jobsCount')}',
                  ],
                  onTap: () => context.go('/projects/${item.id}'),
                ),
                pagination: TablePagination(
                  currentPage: data.currentPage,
                  lastPage: data.lastPage,
                  total: data.total,
                  onPage: (page) => ref.read(projectPageProvider.notifier).state = page,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
