import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../shared/models/organization.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_badge.dart';

final organizationProvider = FutureProvider.autoDispose.family<Organization, int>((ref, id) {
  return ref.watch(organizationRepositoryProvider).show(id);
});

class CompanyScreen extends ConsumerStatefulWidget {
  const CompanyScreen({super.key});

  @override
  ConsumerState<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends ConsumerState<CompanyScreen> {
  final _name = TextEditingController();
  final _nameAr = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _cr = TextEditingController();
  final _tax = TextEditingController();
  var _hydrated = false;
  var _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _nameAr.dispose();
    _email.dispose();
    _phone.dispose();
    _city.dispose();
    _address.dispose();
    _cr.dispose();
    _tax.dispose();
    super.dispose();
  }

  void _hydrate(Organization org) {
    if (_hydrated) {
      return;
    }
    _hydrated = true;
    _name.text = org.name ?? '';
    _nameAr.text = org.nameAr ?? '';
    _email.text = org.email ?? '';
    _phone.text = org.phone ?? '';
    _city.text = org.city ?? '';
    _address.text = org.address ?? '';
    _cr.text = org.commercialRegister ?? '';
    _tax.text = org.taxNumber ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (!session.permissions.can(AppPermissions.companyManage) || session.user?.organizationId == null) {
      return const NoPermissionState();
    }
    final id = session.user!.organizationId!;
    return AppPage(
      child: AsyncBody(
        value: ref.watch(organizationProvider(id)),
        onRetry: () => ref.invalidate(organizationProvider(id)),
        builder: (org) {
          _hydrate(org);
          final locked = !session.canOperate;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: context.tr('company.title'),
                subtitle: context.tr('company.settings'),
                actions: [StatusBadge(status: org.status, organization: true)],
              ),
              if (locked) ...[
                const SizedBox(height: 12),
                const PendingReviewBanner(),
              ],
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  children: [
                    AppTextField(label: context.tr('auth.companyName'), controller: _name, required: true, enabled: !locked),
                    const SizedBox(height: 12),
                    AppTextField(label: context.tr('company.nameAr'), controller: _nameAr, enabled: !locked),
                    const SizedBox(height: 12),
                    AppTextField(label: context.tr('common.email'), controller: _email, enabled: !locked),
                    const SizedBox(height: 12),
                    AppTextField(label: context.tr('common.phone'), controller: _phone, enabled: !locked),
                    const SizedBox(height: 12),
                    AppTextField(label: context.tr('common.city'), controller: _city, enabled: !locked),
                    const SizedBox(height: 12),
                    AppTextField(label: context.tr('common.address'), controller: _address, maxLines: 3, enabled: !locked),
                    const SizedBox(height: 12),
                    AppTextField(label: context.tr('auth.commercialRegister'), controller: _cr, enabled: !locked),
                    const SizedBox(height: 12),
                    AppTextField(label: context.tr('common.taxNumber'), controller: _tax, enabled: !locked),
                    if (!locked) ...[
                    const SizedBox(height: 20),
                    AppButton(
                      label: context.tr('common.save'),
                      loading: _loading,
                      expanded: true,
                      onPressed: () async {
                        setState(() => _loading = true);
                        try {
                          final updated = await ref.read(organizationRepositoryProvider).update(id, {
                            'name': _name.text.trim(),
                            'name_ar': _nameAr.text.trim(),
                            'email': _email.text.trim(),
                            'phone': _phone.text.trim(),
                            'city': _city.text.trim(),
                            'address': _address.text.trim(),
                            'commercial_register': _cr.text.trim(),
                            'tax_number': _tax.text.trim(),
                          });
                          final user = session.user?.copyWith(organization: updated);
                          if (user != null) {
                            ref.read(sessionProvider.notifier).updateUser(user);
                          }
                          ref.invalidate(organizationProvider(id));
                          if (context.mounted) {
                            showAppSnack(context, context.tr('company.updated'));
                          }
                        } on ApiException catch (error) {
                          if (context.mounted) {
                            showAppSnack(context, error.message);
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _loading = false);
                          }
                        }
                      },
                    ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
