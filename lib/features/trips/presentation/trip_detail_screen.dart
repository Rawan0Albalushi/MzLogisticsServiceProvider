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
import '../../../shared/widgets/location_preview.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../dispatch/presentation/assign_sheet.dart';
import 'trips_screen.dart';

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final locale = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: AsyncBody(
        value: ref.watch(tripDetailProvider(id)),
        onRetry: () => ref.invalidate(tripDetailProvider(id)),
        builder: (trip) {
          return ListView(
            children: [
              PageHeader(
                title: trip.reference ?? context.tr('trips.detailTitle'),
                subtitle: context.tr('trips.notAJob'),
                actions: [
                  StatusBadge(status: trip.status),
                  if (session.permissions.can(AppPermissions.tripsAssign) && trip.canAssign)
                    AppButton(
                      label: context.tr('common.assign'),
                      amber: true,
                      onPressed: () => showAssignSheet(context, ref, trip: trip),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: context.tr('trips.detailTitle'),
                child: Column(
                  children: [
                    InfoRow(label: context.tr('trips.sequence'), value: '${trip.sequence ?? ''}'),
                    LocationPreview(
                      title: context.tr('shipments.pickup'),
                      address: trip.pickupAddress,
                      city: trip.pickupCity,
                      lat: trip.pickupLat,
                      lng: trip.pickupLng,
                    ),
                    LocationPreview(
                      title: context.tr('shipments.delivery'),
                      address: trip.deliveryAddress,
                      city: trip.deliveryCity,
                      lat: trip.deliveryLat,
                      lng: trip.deliveryLng,
                    ),
                    InfoRow(label: context.tr('trips.planned'), value: Formatters.number(trip.plannedQuantity, locale: locale)),
                    InfoRow(label: context.tr('jobs.delivered'), value: Formatters.number(trip.deliveredQuantity, locale: locale)),
                    if (trip.otpCode != null) InfoRow(label: context.tr('trips.otp'), value: trip.otpCode!),
                    if (trip.etaAt != null) InfoRow(label: context.tr('trips.eta'), value: Formatters.dateTime(trip.etaAt, locale: locale)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: context.tr('trips.assignedTo'),
                child: Column(
                  children: [
                    InfoRow(label: context.tr('common.truck'), value: trip.truck?.plateNumber ?? '—'),
                    InfoRow(label: context.tr('common.driver'), value: trip.driver?.name ?? '—'),
                    if (trip.job != null)
                      TextButton(
                        onPressed: () => context.go('/jobs/${trip.job!.id}'),
                        child: Text(context.tr('trips.openJob')),
                      ),
                  ],
                ),
              ),
              if (trip.proofOfDelivery != null) ...[
                const SizedBox(height: 12),
                SectionCard(
                  title: context.tr('trips.pod'),
                  child: Column(
                    children: [
                      InfoRow(label: context.tr('auth.name'), value: trip.proofOfDelivery!.receiverName ?? '—'),
                      InfoRow(label: context.tr('common.quantity'), value: Formatters.number(trip.proofOfDelivery!.receivedQuantity, locale: locale)),
                    ],
                  ),
                ),
              ],
              if (session.permissions.can(AppPermissions.tripsUpdate) && trip.nextStatus != null) ...[
                const SizedBox(height: 16),
                AppButton(
                  label: '${context.tr('trips.nextStatus')}: ${context.l10n.status(trip.nextStatus)}',
                  onPressed: () async {
                    try {
                      await ref.read(tripRepositoryProvider).updateStatus(id, trip.nextStatus!);
                      ref.invalidate(tripDetailProvider(id));
                      ref.invalidate(tripsProvider);
                      if (context.mounted) {
                        showAppSnack(context, context.tr('trips.statusUpdated'));
                      }
                    } on ApiException catch (error) {
                      if (context.mounted) {
                        showAppSnack(context, error.message);
                      }
                    }
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
