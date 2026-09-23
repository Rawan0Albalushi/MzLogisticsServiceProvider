import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
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
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../../../shared/widgets/status_badge.dart';
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
                columns: [
                  DataColumnSpec(context.tr('auth.name')),
                  DataColumnSpec(context.tr('auth.phone')),
                  DataColumnSpec(context.tr('auth.email')),
                  DataColumnSpec(context.tr('drivers.license')),
                  DataColumnSpec(context.tr('drivers.licenseExpiry')),
                  DataColumnSpec(context.tr('drivers.lastLogin')),
                  DataColumnSpec(context.tr('common.status')),
                  if (canManage) DataColumnSpec(context.tr('common.actions')),
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
                  if (canManage) _DriverActions(driver: item),
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
                  footer: canManage && item.mustSetPassword
                      ? Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(
                            onPressed: () => _resendInvite(context, ref, item),
                            child: Text(context.tr('drivers.resendInvite')),
                          ),
                        )
                      : null,
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

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    final license = TextEditingController();
    final expiry = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr('drivers.add')),
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
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('common.cancel')),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                try {
                  final result = await ref
                      .read(fleetRepositoryProvider)
                      .createDriver({
                        'name': name.text.trim(),
                        'phone': phone.text.trim(),
                        if (email.text.trim().isNotEmpty)
                          'email': email.text.trim(),
                        if (license.text.isNotEmpty)
                          'license_number': license.text.trim(),
                        if (expiry.text.isNotEmpty)
                          'license_expires_at': expiry.text.trim(),
                      });
                  ref.invalidate(driversListProvider);
                  ref.invalidate(fleetDriversProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    await _showInviteResult(context, result);
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
                }
              },
              child: Text(context.tr('common.save')),
            ),
          ],
        );
      },
    );
    name.dispose();
    phone.dispose();
    email.dispose();
    license.dispose();
    expiry.dispose();
  }
}

class _DriverActions extends ConsumerWidget {
  const _DriverActions({required this.driver});

  final AppUser driver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!driver.mustSetPassword) {
      return const Text('—');
    }
    return TextButton(
      onPressed: () => _resendInvite(context, ref, driver),
      child: Text(context.tr('drivers.resendInvite')),
    );
  }
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
