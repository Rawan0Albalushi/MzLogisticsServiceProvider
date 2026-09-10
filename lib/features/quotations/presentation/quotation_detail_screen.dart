import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_badge.dart';
import 'quotations_screen.dart';

final quotationDetailProvider = FutureProvider.autoDispose.family((ref, int id) {
  return ref.watch(quotationRepositoryProvider).show(id);
});

class QuotationDetailScreen extends ConsumerWidget {
  const QuotationDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    final canManage = ref.watch(sessionProvider).permissions.can(AppPermissions.quotationsManage);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: AsyncBody(
        value: ref.watch(quotationDetailProvider(id)),
        onRetry: () => ref.invalidate(quotationDetailProvider(id)),
        builder: (item) {
          return ListView(
            children: [
              PageHeader(
                title: item.reference ?? context.tr('quotations.detailTitle'),
                subtitle: item.shipment?.reference,
                actions: [
                  StatusBadge(status: item.status),
                  if (canManage && item.canWithdraw)
                    AppButton(
                      label: context.tr('common.withdraw'),
                      outlined: true,
                      onPressed: () async {
                        final ok = await showConfirmDialog(context, message: context.tr('quotations.withdrawConfirm'));
                        if (!ok) {
                          return;
                        }
                        try {
                          await ref.read(quotationRepositoryProvider).withdraw(id);
                          ref.invalidate(quotationDetailProvider(id));
                          ref.invalidate(quotationsProvider);
                        } on ApiException catch (error) {
                          if (context.mounted) {
                            showAppSnack(context, error.message);
                          }
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  children: [
                    InfoRow(label: context.tr('quotations.totalPrice'), value: Formatters.money(item.totalPrice, currency: item.currency, locale: locale)),
                    InfoRow(label: context.tr('quotations.truckCount'), value: '${item.truckCount ?? 0}'),
                    InfoRow(label: context.tr('quotations.truckType'), value: context.l10n.truckType(item.truckType)),
                    InfoRow(label: context.tr('quotations.truckCapacity'), value: Formatters.number(item.truckCapacityTons, locale: locale)),
                    InfoRow(label: context.tr('quotations.tripCount'), value: '${item.tripCount ?? 0}'),
                    InfoRow(label: context.tr('quotations.quantityPerTrip'), value: Formatters.number(item.quantityPerTrip, locale: locale)),
                    InfoRow(label: context.tr('quotations.durationDays'), value: '${item.durationDays ?? 0}'),
                    InfoRow(label: context.tr('quotations.additionalCosts'), value: Formatters.money(item.additionalCosts, currency: item.currency, locale: locale)),
                    InfoRow(label: context.tr('quotations.validUntil'), value: Formatters.date(item.validUntil, locale: locale)),
                    if (item.conditions != null) InfoRow(label: context.tr('quotations.conditions'), value: item.conditions!),
                  ],
                ),
              ),
              if (item.shipment != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/shipments/${item.shipment!.id}'),
                  child: Text(item.shipment!.reference ?? context.tr('nav.shipments')),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
