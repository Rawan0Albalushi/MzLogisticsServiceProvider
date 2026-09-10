import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/document.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../company/presentation/company_screen.dart';
import '../../fleet/presentation/fleet_screen.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.permissions.can(AppPermissions.fleetView)) {
      return const NoPermissionState();
    }
    final locale = Localizations.localeOf(context).languageCode;
    final orgId = session.user?.organizationId;
    final trucks = ref.watch(fleetTrucksProvider);
    final drivers = ref.watch(fleetDriversProvider);
    final organization = orgId == null ? null : ref.watch(organizationProvider(orgId));

    final items = <ComplianceItem>[];
    for (final truck in trucks.asData?.value.items ?? const []) {
      if (truck.insuranceExpiresAt != null) {
        items.add(ComplianceItem(
          title: truck.plateNumber ?? context.tr('common.truck'),
          category: context.tr('documents.insurance'),
          expiresAt: truck.insuranceExpiresAt,
          status: truck.status,
          owner: truck.plateNumber,
        ));
      }
    }
    for (final driver in drivers.asData?.value.items ?? const []) {
      if (driver.driverProfile?.licenseExpiresAt != null) {
        items.add(ComplianceItem(
          title: driver.name ?? context.tr('common.driver'),
          category: context.tr('documents.license'),
          expiresAt: driver.driverProfile?.licenseExpiresAt,
          status: driver.driverProfile?.status,
          owner: driver.name,
        ));
      }
    }
    for (final doc in organization?.asData?.value.documents ?? const []) {
      items.add(ComplianceItem(
        title: doc.title ?? doc.type ?? context.tr('documents.companyDocs'),
        category: context.tr('documents.companyDocs'),
        expiresAt: doc.expiresAt,
        status: doc.status,
      ));
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          PageHeader(title: context.tr('documents.title'), subtitle: context.tr('documents.subtitle')),
          const SizedBox(height: 16),
          if (trucks.isLoading || drivers.isLoading)
            const LoadingState()
          else if (items.isEmpty)
            EmptyState(message: context.tr('documents.empty'))
          else
            SectionCard(
              child: Column(
                children: [
                  for (final item in items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.title),
                      subtitle: Text(
                        '${item.category} · ${context.tr('documents.expires')} ${Formatters.date(item.expiresAt, locale: locale)}',
                      ),
                      trailing: StatusBadge(status: item.status),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
