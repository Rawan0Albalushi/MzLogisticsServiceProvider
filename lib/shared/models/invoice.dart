import '../../core/utils/json_utils.dart';
import 'job.dart';
import 'payment.dart';

class Invoice {
  const Invoice({
    required this.id,
    this.reference,
    this.type,
    this.amount,
    this.currency,
    this.status,
    this.issuedAt,
    this.dueAt,
    this.job,
    this.payment,
  });

  final int id;
  final String? reference;
  final String? type;
  final double? amount;
  final String? currency;
  final String? status;
  final String? issuedAt;
  final String? dueAt;
  final TransportJob? job;
  final Payment? payment;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: asInt(json['id']) ?? 0,
      reference: asString(json['reference']),
      type: asString(json['type']),
      amount: asDouble(json['amount']),
      currency: asString(json['currency']),
      status: asString(json['status']),
      issuedAt: asString(json['issued_at']),
      dueAt: asString(json['due_at']),
      job: json['job'] is Map ? TransportJob.fromJson(asMap(json['job'])) : null,
      payment: json['payment'] is Map ? Payment.fromJson(asMap(json['payment'])) : null,
    );
  }
}
