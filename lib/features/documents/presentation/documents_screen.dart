import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/document.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../company/presentation/company_screen.dart';
import '../../fleet/presentation/fleet_screen.dart';
import 'document_preview.dart';
import 'required_documents_section.dart';

final documentSearchProvider = StateProvider<String>((ref) => '');
final documentCategoryProvider = StateProvider<String?>((ref) => null);
final documentExpiryProvider = StateProvider<String?>((ref) => null);

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  String _expiryBucket(String? date) {
    if (date == null || date.isEmpty) {
      return 'valid';
    }
    final parsed = DateTime.tryParse(date);
    if (parsed == null) {
      return 'valid';
    }
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    if (parsed.isBefore(startOfToday)) {
      return 'expired';
    }
    if (parsed.difference(startOfToday).inDays <= 30) {
      return 'expiringSoon';
    }
    return 'valid';
  }

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
    CompanyDocument? fileOf(List<CompanyDocument> documents, String type) {
      for (final document in documents) {
        if (document.type == type) {
          return document;
        }
      }
      return null;
    }

    for (final truck in trucks.asData?.value.items ?? const []) {
      final insurance = fileOf(truck.documents, 'insurance');
      final registration = fileOf(truck.documents, 'vehicle_registration');
      if (insurance != null || truck.insuranceExpiresAt != null) {
        items.add(ComplianceItem(
          title: truck.plateNumber ?? context.tr('common.truck'),
          category: context.tr('documents.insurance'),
          expiresAt: insurance?.expiresAt ?? truck.insuranceExpiresAt,
          status: insurance?.status ?? truck.status,
          owner: truck.plateNumber,
          file: insurance,
        ));
      }
      if (registration != null) {
        items.add(ComplianceItem(
          title: '${truck.plateNumber ?? context.tr('common.truck')} · ${context.tr('documents.types.vehicle_registration')}',
          category: context.tr('documents.insurance'),
          expiresAt: registration.expiresAt,
          status: registration.status,
          owner: truck.plateNumber,
          file: registration,
        ));
      }
    }
    for (final driver in drivers.asData?.value.items ?? const []) {
      final license = fileOf(driver.documents, 'driver_license');
      final identity = fileOf(driver.documents, 'identity');
      if (license != null || driver.driverProfile?.licenseExpiresAt != null) {
        items.add(ComplianceItem(
          title: driver.name ?? context.tr('common.driver'),
          category: context.tr('documents.license'),
          expiresAt: license?.expiresAt ?? driver.driverProfile?.licenseExpiresAt,
          status: license?.status ?? driver.driverProfile?.status,
          owner: driver.name,
          file: license,
        ));
      }
      if (identity != null) {
        items.add(ComplianceItem(
          title: '${driver.name ?? context.tr('common.driver')} · ${context.tr('documents.types.identity')}',
          category: context.tr('documents.license'),
          expiresAt: identity.expiresAt,
          status: identity.status,
          owner: driver.name,
          file: identity,
        ));
      }
    }
    for (final doc in organization?.asData?.value.documents ?? const []) {
      items.add(ComplianceItem(
        title: doc.type == null
            ? (doc.title ?? context.tr('documents.companyDocs'))
            : context.tr('documents.types.${doc.type}'),
        category: context.tr('documents.companyDocs'),
        expiresAt: doc.expiresAt,
        status: doc.status,
        file: doc,
      ));
    }

    final search = ref.watch(documentSearchProvider).trim().toLowerCase();
    final category = ref.watch(documentCategoryProvider);
    final expiry = ref.watch(documentExpiryProvider);
    final categoryLabel = {
      'insurance': context.tr('documents.insurance'),
      'license': context.tr('documents.license'),
      'companyDocs': context.tr('documents.companyDocs'),
    };
    final visible = items.where((item) {
      if (category != null && item.category != categoryLabel[category]) {
        return false;
      }
      if (expiry != null && _expiryBucket(item.expiresAt) != expiry) {
        return false;
      }
      if (search.isNotEmpty) {
        final haystack = '${item.title} ${item.category} ${item.owner ?? ''}'.toLowerCase();
        if (!haystack.contains(search)) {
          return false;
        }
      }
      return true;
    }).toList();

    return AppPage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: context.tr('documents.title'), subtitle: context.tr('documents.subtitle')),
          const SizedBox(height: 12),
          FilterBar(
            children: [
              FilterSearchField(
                onChanged: (value) => ref.read(documentSearchProvider.notifier).state = value,
              ),
              FilterSelect(
                options: const ['insurance', 'license', 'companyDocs'],
                value: category,
                onChanged: (value) => ref.read(documentCategoryProvider.notifier).state = value,
                labelOf: (value) => context.tr('documents.$value'),
                allLabel: context.tr('common.allTypes'),
              ),
              FilterSelect(
                options: const ['valid', 'expiringSoon', 'expired'],
                value: expiry,
                onChanged: (value) => ref.read(documentExpiryProvider.notifier).state = value,
                labelOf: (value) => context.tr('documents.$value'),
                allLabel: context.tr('common.allStatuses'),
              ),
            ],
          ),
          if (trucks.isLoading || drivers.isLoading)
            const LoadingState()
          else if (visible.isEmpty)
            EmptyState(message: context.tr('documents.empty'))
          else
            SectionCard(
              child: Column(
                children: [
                  for (final item in visible)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: item.file != null && isDocumentImage(item.file!.title)
                          ? SizedBox(
                              width: 56,
                              height: 56,
                              child: DocumentImagePreview(
                                documentId: item.file!.id,
                                height: 56,
                                onTap: () => showDocumentImage(
                                  context,
                                  documentId: item.file!.id,
                                  filename: item.file!.title,
                                ),
                              ),
                            )
                          : null,
                      title: Text(item.title),
                      subtitle: Text(
                        [
                          item.category,
                          if (item.file?.title != null && !isDocumentImage(item.file!.title)) item.file!.title!,
                          '${context.tr('documents.expires')} ${Formatters.date(item.expiresAt, locale: locale)}',
                        ].join(' · '),
                      ),
                      onTap: item.file != null && isDocumentImage(item.file!.title)
                          ? () => showDocumentImage(
                                context,
                                documentId: item.file!.id,
                                filename: item.file!.title,
                              )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.file != null && !isDocumentImage(item.file!.title))
                            IconButton(
                              tooltip: context.tr('documents.open'),
                              onPressed: () => openStoredDocument(ref, context, item.file!),
                              icon: const Icon(Icons.open_in_new),
                            ),
                          StatusBadge(status: item.status),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
