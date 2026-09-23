import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/document.dart';
import '../../../shared/models/driver_invite.dart';
import '../../../shared/models/user.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/entity_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/info_grid.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/record_actions.dart';
import '../../../shared/widgets/record_details_dialog.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../documents/presentation/required_documents_section.dart';
import '../../fleet/presentation/fleet_screen.dart';
import 'import_drivers_sheet.dart';

final driverPageProvider = StateProvider<int>((ref) => 1);
final driverSearchProvider = StateProvider<String>((ref) => '');
final driverStatusProvider = StateProvider<String?>((ref) => null);
final driversListProvider = FutureProvider.autoDispose((ref) {
  return ref
      .watch(fleetRepositoryProvider)
      .drivers(
        page: ref.watch(driverPageProvider),
        search: ref.watch(driverSearchProvider),
        status: ref.watch(driverStatusProvider),
      );
});

class DriversScreen extends ConsumerWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.permissions.can(AppPermissions.driversView)) {
      return const NoPermissionState();
    }
    final locale = Localizations.localeOf(context).languageCode;
    final canManage = session.permissions.can(AppPermissions.driversManage);
    return AppPage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: context.tr('drivers.title'),
            subtitle: context.tr('drivers.companyStaff'),
            actions: [
              if (canManage) ...[
                AppButton(
                  label: context.tr('drivers.import'),
                  outlined: true,
                  icon: Icons.table_view_outlined,
                  onPressed: () => showImportDriversSheet(context, ref),
                ),
                AppButton(
                  label: context.tr('drivers.add'),
                  icon: Icons.add,
                  onPressed: () => _openForm(context, ref),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          FilterBar(
            children: [
              FilterSearchField(
                onChanged: (value) {
                  ref.read(driverSearchProvider.notifier).state = value;
                  ref.read(driverPageProvider.notifier).state = 1;
                },
              ),
              FilterSelect(
                options: AppConfig.driverStatuses,
                value: ref.watch(driverStatusProvider),
                onChanged: (value) {
                  ref.read(driverStatusProvider.notifier).state = value;
                  ref.read(driverPageProvider.notifier).state = 1;
                },
                labelOf: context.l10n.status,
              ),
            ],
          ),
          AsyncBody(
            value: ref.watch(driversListProvider),
            onRetry: () => ref.invalidate(driversListProvider),
            isEmpty: (data) => data.isEmpty,
            empty: EmptyState(message: context.tr('drivers.empty')),
            builder: (data) {
              return ResponsiveDataView<AppUser>(
                items: data.items,
                onRowTap: (item) => _showDriverDetails(
                  context,
                  item,
                  locale: locale,
                  onEdit: canManage
                      ? () => _openForm(context, ref, item)
                      : null,
                ),
                columns: [
                  DataColumnSpec(context.tr('auth.name')),
                  DataColumnSpec(context.tr('auth.phone')),
                  DataColumnSpec(context.tr('auth.email')),
                  DataColumnSpec(context.tr('drivers.license')),
                  DataColumnSpec(context.tr('drivers.licenseExpiry')),
                  DataColumnSpec(context.tr('drivers.lastLogin')),
                  DataColumnSpec(context.tr('common.status')),
                  DataColumnSpec(context.tr('common.actions')),
                ],
                rowCells: (item) => [
                  Text(item.name ?? ''),
                  Text(item.phone ?? '—'),
                  Text(item.email ?? '—'),
                  Text(item.driverProfile?.licenseNumber ?? '—'),
                  Text(
                    Formatters.date(
                      item.driverProfile?.licenseExpiresAt,
                      locale: locale,
                    ),
                  ),
                  Text(Formatters.dateTime(item.lastLoginAt, locale: locale)),
                  StatusBadge(status: item.displayStatus),
                  _DriverRowActions(
                    driver: item,
                    canManage: canManage,
                    onView: () => _showDriverDetails(
                      context,
                      item,
                      locale: locale,
                      onEdit: canManage
                          ? () => _openForm(context, ref, item)
                          : null,
                    ),
                    onEdit: canManage
                        ? () => _openForm(context, ref, item)
                        : null,
                  ),
                ],
                cardBuilder: (item) => EntityCard(
                  title: item.name ?? '',
                  icon: Icons.badge_outlined,
                  tone: IconTone.success,
                  trailing: StatusBadge(status: item.displayStatus),
                  meta: [
                    item.phone ?? '',
                    item.email ?? '',
                    item.driverProfile?.licenseNumber ?? '',
                  ],
                  onTap: () => _showDriverDetails(
                    context,
                    item,
                    locale: locale,
                    onEdit: canManage
                        ? () => _openForm(context, ref, item)
                        : null,
                  ),
                  footer: _DriverRowActions(
                    driver: item,
                    canManage: canManage,
                    onView: () => _showDriverDetails(
                      context,
                      item,
                      locale: locale,
                      onEdit: canManage
                          ? () => _openForm(context, ref, item)
                          : null,
                    ),
                    onEdit: canManage
                        ? () => _openForm(context, ref, item)
                        : null,
                  ),
                ),
                pagination: TablePagination(
                  currentPage: data.currentPage,
                  lastPage: data.lastPage,
                  total: data.total,
                  onPage: (page) =>
                      ref.read(driverPageProvider.notifier).state = page,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, [
    AppUser? existing,
  ]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final phone = TextEditingController(text: existing?.phone ?? '');
    final email = TextEditingController(text: existing?.email ?? '');
    final license = TextEditingController(
      text: existing?.driverProfile?.licenseNumber ?? '',
    );
    final expiry = TextEditingController(
      text: _dateInput(existing?.driverProfile?.licenseExpiresAt),
    );
    var status = existing?.driverProfile?.status ?? 'available';
    final formKey = GlobalKey<FormState>();
    var saving = false;
    var documents = List<CompanyDocument>.from(existing?.documents ?? const []);
    final pendingDocuments = <String, PendingUpload>{};
    DriverInviteResult? createdInvite;
    var saved = false;
    var closing = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                dialogContext.tr(existing == null ? 'drivers.add' : 'drivers.edit'),
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        AppTextField(
                          label: context.tr('auth.name'),
                          controller: name,
                          required: true,
                          validator: (value) => AppValidators.required(
                            value,
                            context.tr('validation.required'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: context.tr('auth.phone'),
                          controller: phone,
                          required: true,
                          validator: (value) => AppValidators.required(
                            value,
                            context.tr('validation.required'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: context.tr('drivers.emailOptional'),
                          controller: email,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            return AppValidators.email(
                              value,
                              context.tr('validation.email'),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: context.tr('drivers.license'),
                          controller: license,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: context.tr('drivers.licenseExpiry'),
                          controller: expiry,
                          hint: 'YYYY-MM-DD',
                        ),
                        if (existing != null) ...[
                          const SizedBox(height: 12),
                          AppDropdown<String>(
                            label: context.tr('common.status'),
                            value: status,
                            items: [
                              for (final item in AppConfig.driverStatuses)
                                DropdownMenuItem(
                                  value: item,
                                  child: Text(context.l10n.status(item)),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => status = value ?? status),
                          ),
                        ],
                        const SizedBox(height: 16),
                        RequiredDocumentsSection(
                          types: const ['driver_license', 'identity'],
                          documents: documents,
                          pending: pendingDocuments,
                          canUpload: !saving,
                          onUpload: (type, bytes, filename) async {
                            final driver = existing;
                            if (driver == null) {
                              setState(() {
                                pendingDocuments[type] = PendingUpload(
                                  bytes: bytes,
                                  filename: filename,
                                );
                              });
                              return;
                            }
                            final saved = await ref
                                .read(fleetRepositoryProvider)
                                .uploadDriverDocument(
                                  driverId: driver.id,
                                  type: type,
                                  bytes: bytes,
                                  filename: filename,
                                );
                            setState(() {
                              documents = [
                                for (final item in documents)
                                  if (item.type != type) item,
                                saved,
                              ];
                            });
                            if (context.mounted) {
                              showAppSnack(context, context.tr('documents.uploaded'));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: Text(context.tr('common.cancel')),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          setState(() => saving = true);
                          try {
                            final repository = ref.read(
                              fleetRepositoryProvider,
                            );
                            if (existing == null) {
                              createdInvite ??= await repository.createDriver({
                                'name': name.text.trim(),
                                'phone': phone.text.trim(),
                                if (email.text.trim().isNotEmpty)
                                  'email': email.text.trim(),
                                if (license.text.isNotEmpty)
                                  'license_number': license.text.trim(),
                                if (expiry.text.isNotEmpty)
                                  'license_expires_at': expiry.text.trim(),
                              });
                              final result = createdInvite!;
                              for (final entry in pendingDocuments.entries) {
                                await repository.uploadDriverDocument(
                                  driverId: result.driver.id,
                                  type: entry.key,
                                  bytes: entry.value.bytes,
                                  filename: entry.value.filename,
                                );
                              }
                              pendingDocuments.clear();
                              saved = true;
                              closing = true;
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } else {
                              await repository.updateDriver(existing.id, {
                                'name': name.text.trim(),
                                'phone': phone.text.trim(),
                                'email': email.text.trim(),
                                'license_number': license.text.trim(),
                                'license_expires_at': expiry.text.trim(),
                                'status': status,
                              });
                              saved = true;
                              closing = true;
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          } on ApiException catch (error) {
                            if (context.mounted) {
                              showAppSnack(
                                context,
                                error.firstFieldError('phone') ??
                                    error.firstFieldError('email') ??
                                    error.message,
                              );
                            }
                          } finally {
                            if (!closing && context.mounted) {
                              setState(() => saving = false);
                            }
                          }
                        },
                  child: Text(context.tr('common.save')),
                ),
              ],
            );
          },
        );
      },
    );
    name.dispose();
    phone.dispose();
    email.dispose();
    license.dispose();
    expiry.dispose();
    if (!saved || !context.mounted) {
      return;
    }
    ref.invalidate(driversListProvider);
    ref.invalidate(fleetDriversProvider);
    final invite = createdInvite;
    if (invite != null) {
      await _showInviteResult(context, invite);
      return;
    }
    showAppSnack(context, context.tr('drivers.updated'));
  }
}

class _DriverRowActions extends ConsumerWidget {
  const _DriverRowActions({
    required this.driver,
    required this.canManage,
    required this.onView,
    required this.onEdit,
  });

  final AppUser driver;
  final bool canManage;
  final VoidCallback onView;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RecordActions(onView: onView, onEdit: onEdit),
        if (canManage && driver.mustSetPassword)
          RecordIconButton(
            tooltip: context.tr('drivers.resendInvite'),
            icon: Icons.send_outlined,
            onPressed: () => _resendInvite(context, ref, driver),
          ),
      ],
    );
  }
}

void _showDriverDetails(
  BuildContext context,
  AppUser driver, {
  required String locale,
  VoidCallback? onEdit,
}) {
  String text(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '—';
    }
    return value;
  }

  showRecordDetails(
    context,
    title: context.tr('drivers.details'),
    onEdit: onEdit,
    fields: [
      InfoField(label: context.tr('auth.name'), value: text(driver.name)),
      InfoField(label: context.tr('auth.phone'), value: text(driver.phone)),
      InfoField(label: context.tr('auth.email'), value: text(driver.email)),
      InfoField(
        label: context.tr('drivers.license'),
        value: text(driver.driverProfile?.licenseNumber),
      ),
      InfoField(
        label: context.tr('drivers.licenseExpiry'),
        value: Formatters.date(
          driver.driverProfile?.licenseExpiresAt,
          locale: locale,
        ),
      ),
      InfoField(
        label: context.tr('common.status'),
        value: context.l10n.status(driver.displayStatus),
      ),
      InfoField(
        label: context.tr('drivers.lastLogin'),
        value: Formatters.dateTime(driver.lastLoginAt, locale: locale),
      ),
    ],
    extra: RequiredDocumentsSection(
      types: const ['driver_license', 'identity'],
      documents: driver.documents,
    ),
  );
}

String _dateInput(String? raw) {
  if (raw == null || raw.isEmpty) {
    return '';
  }
  final match = RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(raw);
  if (match != null) {
    return match.group(1)!;
  }
  return raw;
}

Future<void> _resendInvite(
  BuildContext context,
  WidgetRef ref,
  AppUser driver,
) async {
  try {
    final result = await ref
        .read(fleetRepositoryProvider)
        .resendDriverInvite(driver.id);
    ref.invalidate(driversListProvider);
    if (context.mounted) {
      await _showInviteResult(context, result, resent: true);
    }
  } on ApiException catch (error) {
    if (context.mounted) {
      showAppSnack(context, error.firstFieldError('driver') ?? error.message);
    }
  }
}

Future<void> _showInviteResult(
  BuildContext context,
  DriverInviteResult result, {
  bool resent = false,
}) async {
  if (result.whatsappSent) {
    showAppSnack(context, context.tr('drivers.whatsappSent'));
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          resent
              ? context.tr('drivers.inviteResent')
              : context.tr('drivers.saved'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.tr('drivers.inviteReady')),
            const SizedBox(height: 12),
            SelectableText(result.inviteUrl),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: result.inviteUrl));
              if (context.mounted) {
                showAppSnack(context, context.tr('drivers.inviteCopied'));
              }
            },
            child: Text(context.tr('drivers.copyInvite')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('common.close')),
          ),
        ],
      );
    },
  );
}
