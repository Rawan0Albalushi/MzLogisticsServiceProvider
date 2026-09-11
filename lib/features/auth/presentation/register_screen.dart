import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'auth_scaffold.dart';

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
      contentMaxWidth: 720,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: _loading ? context.tr('auth.creatingAccount') : context.tr('auth.createAccount'),
            onPressed: _submit,
            loading: _loading,
            expanded: true,
            amber: true,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text(
              context.tr('auth.loginCta'),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoCol = constraints.maxWidth >= 540;
            final compact = constraints.maxWidth < 480;
            final theme = Theme.of(context);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('auth.registerTitle'),
                  style: (compact ? theme.textTheme.titleLarge : theme.textTheme.headlineSmall)
                      ?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('auth.registerSubtitle'),
                  style: const TextStyle(color: AppColors.muted, height: 1.5, fontSize: 13.5),
                ),
                const SizedBox(height: 14),
                const _ReviewNote(),
                const SizedBox(height: 28),
                _FormSection(
                  step: '1',
                  title: context.tr('auth.companySection'),
                  hint: context.tr('auth.companySectionHint'),
                ),
                const SizedBox(height: 16),
                _FieldRow(
                  twoCol: twoCol,
                  children: [
                    AppTextField(
                      label: context.tr('auth.companyName'),
                      controller: _company,
                      required: true,
                      showRequiredHint: false,
                      validator: (value) => AppValidators.required(value, context.tr('validation.required')),
                    ),
                    AppTextField(
                      label: context.tr('auth.commercialRegister'),
                      controller: _register,
                      showRequiredHint: false,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _FieldRow(
                  twoCol: twoCol,
                  children: [
                    AppTextField(
                      label: context.tr('auth.phone'),
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      showRequiredHint: false,
                    ),
                    AppTextField(
                      label: context.tr('auth.city'),
                      controller: _city,
                      showRequiredHint: false,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _FormSection(
                  step: '2',
                  title: context.tr('auth.accountSection'),
                  hint: context.tr('auth.accountSectionHint'),
                ),
                const SizedBox(height: 16),
                _FieldRow(
                  twoCol: twoCol,
                  children: [
                    AppTextField(
                      label: context.tr('auth.name'),
                      controller: _name,
                      required: true,
                      showRequiredHint: false,
                      validator: (value) => AppValidators.required(value, context.tr('validation.required')),
                    ),
                    AppTextField(
                      label: context.tr('auth.email'),
                      controller: _email,
                      required: true,
                      showRequiredHint: false,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => AppValidators.email(value, context.tr('validation.email')),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _FieldRow(
                  twoCol: twoCol,
                  children: [
                    AppTextField(
                      label: context.tr('auth.password'),
                      controller: _password,
                      required: true,
                      showRequiredHint: false,
                      obscureText: true,
                      validator: (value) => AppValidators.password(value, context.tr('validation.passwordLength')),
                    ),
                    AppTextField(
                      label: context.tr('auth.confirmPassword'),
                      controller: _confirm,
                      required: true,
                      showRequiredHint: false,
                      obscureText: true,
                      validator: (value) => AppValidators.match(value, _password.text, context.tr('validation.passwordMatch')),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReviewNote extends StatelessWidget {
  const _ReviewNote();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.schedule, size: 16, color: AppColors.info),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr('auth.reviewNote'),
                style: const TextStyle(color: AppColors.ink, fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.step,
    required this.title,
    required this.hint,
  });

  final String step;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            step,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.children, required this.twoCol});

  final List<Widget> children;
  final bool twoCol;

  @override
  Widget build(BuildContext context) {
    if (!twoCol || children.length == 1) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            children[i],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}
