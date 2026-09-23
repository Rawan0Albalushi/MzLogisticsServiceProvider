import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_badge.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(sessionProvider).user;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final locale = ref.watch(localeControllerProvider);
    final locked = !session.canOperate;
    return AppPage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: context.tr('profile.title')),
          if (locked) ...[
            const SizedBox(height: 12),
            const PendingReviewBanner(),
          ],
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              children: [
                AppTextField(label: context.tr('auth.name'), controller: _name, required: true, enabled: !locked),
                const SizedBox(height: 12),
                AppTextField(label: context.tr('auth.phone'), controller: _phone, enabled: !locked),
                const SizedBox(height: 12),
                InfoRow(label: context.tr('auth.email'), value: session.user?.email ?? '—'),
                InfoRow(label: context.tr('users.roles'), value: session.user?.primaryRole ?? '—'),
                Row(
                  children: [
                    Text(context.tr('profile.organizationStatus')),
                    const SizedBox(width: 12),
                    StatusBadge(status: session.user?.organization?.status, organization: true),
                  ],
                ),
                if (!locked) ...[
                const SizedBox(height: 16),
                AppButton(
                  label: context.tr('profile.update'),
                  loading: _loading,
                  expanded: true,
                  onPressed: () async {
                    setState(() => _loading = true);
                    try {
                      final user = await ref.read(authRepositoryProvider).updateMe(
                            name: _name.text.trim(),
                            phone: _phone.text.trim(),
                            locale: locale.languageCode,
                          );
                      ref.read(sessionProvider.notifier).updateUser(user);
                      if (context.mounted) {
                        showAppSnack(context, context.tr('profile.updated'));
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
          const SizedBox(height: 12),
          SectionCard(
            title: context.tr('profile.language'),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(context.tr('common.english')),
                  selected: locale.languageCode == 'en',
                  onSelected: (_) => ref.read(localeControllerProvider.notifier).setLocale(const Locale('en')),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(context.tr('common.arabic')),
                  selected: locale.languageCode == 'ar',
                  onSelected: (_) => ref.read(localeControllerProvider.notifier).setLocale(const Locale('ar')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
