import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: AppConfig.demoEmail);
  final _password = TextEditingController();
  var _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) {
      return;
    }
    setState(() => _loading = true);
    try {
      final session = await ref.read(authRepositoryProvider).login(
            _email.text.trim(),
            _password.text,
          );
      await ref.read(sessionProvider.notifier).apply(session);
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnack(context, error.message == 'network' ? context.tr('common.networkError') : error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('auth.loginTitle'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(context.tr('auth.loginSubtitle'), style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 24),
          AppTextField(
            label: context.tr('auth.email'),
            controller: _email,
            required: true,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => AppValidators.email(value, context.tr('validation.email')),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: context.tr('auth.password'),
            controller: _password,
            required: true,
            obscureText: true,
            validator: (value) => AppValidators.required(value, context.tr('validation.required')),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: _loading ? context.tr('auth.signingIn') : context.tr('auth.signIn'),
            onPressed: _submit,
            loading: _loading,
            expanded: true,
            amber: true,
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('auth.demoHint', {'email': AppConfig.demoEmail}),
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => context.go('/register'),
            child: Text(context.tr('auth.registerCta')),
          ),
        ],
      ),
    );

    return AuthScaffold(child: form);
  }
}
