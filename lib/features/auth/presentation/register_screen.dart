import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _company = TextEditingController();
  final _register = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  var _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _company.dispose();
    _register.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) {
      return;
    }
    setState(() => _loading = true);
    try {
      final locale = Localizations.localeOf(context).languageCode;
      final session = await ref.read(authRepositoryProvider).registerProvider(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            passwordConfirmation: _confirm.text,
            companyName: _company.text.trim(),
            commercialRegister: _register.text.trim(),
            phone: _phone.text.trim(),
            city: _city.text.trim(),
            locale: locale,
          );
      await ref.read(sessionProvider.notifier).apply(session);
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnack(
          context,
          error.firstFieldError('email') ??
              (error.message == 'network' ? context.tr('common.networkError') : error.message),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('auth.registerTitle'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(context.tr('auth.registerSubtitle')),
            const SizedBox(height: 24),
            AppTextField(
              label: context.tr('auth.name'),
              controller: _name,
              required: true,
              validator: (value) => AppValidators.required(value, context.tr('validation.required')),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: context.tr('auth.companyName'),
              controller: _company,
              required: true,
              validator: (value) => AppValidators.required(value, context.tr('validation.required')),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: context.tr('auth.email'),
              controller: _email,
              required: true,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => AppValidators.email(value, context.tr('validation.email')),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: context.tr('auth.password'),
              controller: _password,
              required: true,
              obscureText: true,
              validator: (value) => AppValidators.password(value, context.tr('validation.passwordLength')),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: context.tr('auth.confirmPassword'),
              controller: _confirm,
              required: true,
              obscureText: true,
              validator: (value) => AppValidators.match(value, _password.text, context.tr('validation.passwordMatch')),
            ),
            const SizedBox(height: 12),
            AppTextField(label: context.tr('auth.commercialRegister'), controller: _register),
            const SizedBox(height: 12),
            AppTextField(label: context.tr('auth.phone'), controller: _phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            AppTextField(label: context.tr('auth.city'), controller: _city),
            const SizedBox(height: 20),
            AppButton(
              label: _loading ? context.tr('auth.creatingAccount') : context.tr('auth.createAccount'),
              onPressed: _submit,
              loading: _loading,
              expanded: true,
              amber: true,
            ),
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text(context.tr('auth.loginCta')),
            ),
          ],
        ),
      ),
    );
  }
}
