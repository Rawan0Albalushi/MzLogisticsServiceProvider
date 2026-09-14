import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/settlement.dart';
import '../../../shared/models/wallet.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/confirm_dialog.dart';

Future<Settlement?> showRequestWithdrawalDialog(
  BuildContext context, {
  required Wallet wallet,
}) {
  return showDialog<Settlement>(
    context: context,
    builder: (context) => _RequestWithdrawalDialog(wallet: wallet),
  );
}

class _RequestWithdrawalDialog extends ConsumerStatefulWidget {
  const _RequestWithdrawalDialog({required this.wallet});

  final Wallet wallet;

  @override
  ConsumerState<_RequestWithdrawalDialog> createState() => _RequestWithdrawalDialogState();
}

class _RequestWithdrawalDialogState extends ConsumerState<_RequestWithdrawalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  var _submitting = false;

  double get _available => widget.wallet.availableBalance;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: _available > 0 ? _available.toStringAsFixed(3) : '',
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    final requiredError = AppValidators.required(value, context.tr('validation.required'));
    if (requiredError != null) {
      return requiredError;
    }
    final parsed = double.tryParse(value!.trim());
    if (parsed == null || parsed < 0.001) {
      return context.tr('finance.withdrawInvalidAmount');
    }
    if (parsed > _available + 0.0005) {
      return context.tr('finance.withdrawExceedsAvailable');
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final settlement = await ref.read(financeRepositoryProvider).requestWithdrawal(amount: amount);
      if (mounted) {
        Navigator.of(context).pop(settlement);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      showAppSnack(
        context,
        error.firstFieldError('amount') ??
            (error.message == 'network' ? context.tr('common.networkError') : error.message),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final canSubmit = _available >= 0.001 && !_submitting;

    return AlertDialog(
      title: Text(context.tr('finance.withdrawTitle')),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('finance.withdrawHint'),
                style: const TextStyle(color: AppColors.muted, height: 1.45),
              ),
              const SizedBox(height: 14),
              Text(
                context.tr(
                  'finance.withdrawAvailable',
                  {
                    'amount': Formatters.money(
                      _available,
                      currency: widget.wallet.currency,
                      locale: locale,
                    ),
                  },
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: context.tr('finance.withdrawAmount'),
                controller: _amount,
                required: true,
                enabled: canSubmit,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                validator: _validateAmount,
                hint: context.tr('finance.withdrawAmountHint'),
              ),
              if (_available < 0.001) ...[
                const SizedBox(height: 8),
                Text(
                  context.tr('finance.withdrawNoneAvailable'),
                  style: const TextStyle(color: AppColors.danger, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(context.tr('common.cancel')),
        ),
        AppButton(
          label: context.tr('finance.withdrawSubmit'),
          loading: _submitting,
          onPressed: canSubmit ? _submit : null,
        ),
      ],
    );
  }
}
