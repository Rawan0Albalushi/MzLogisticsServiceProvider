import '../../core/utils/json_utils.dart';

class Settlement {
  const Settlement({
    required this.id,
    this.reference,
    this.amount,
    this.commissionAmount,
    this.netAmount,
    this.currency,
    this.status,
    this.periodStart,
    this.periodEnd,
    this.settledAt,
  });

  final int id;
  final String? reference;
  final double? amount;
  final double? commissionAmount;
  final double? netAmount;
  final String? currency;
  final String? status;
  final String? periodStart;
  final String? periodEnd;
  final String? settledAt;

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: asInt(json['id']) ?? 0,
      reference: asString(json['reference']),
      amount: asDouble(json['amount']),
      commissionAmount: asDouble(json['commission_amount']),
      netAmount: asDouble(json['net_amount']),
      currency: asString(json['currency']),
      status: asString(json['status']),
      periodStart: asString(json['period_start']),
      periodEnd: asString(json['period_end']),
      settledAt: asString(json['settled_at']),
    );
  }
}
