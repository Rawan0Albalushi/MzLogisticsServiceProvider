import '../../core/utils/json_utils.dart';

class Wallet {
  const Wallet({
    required this.id,
    this.organizationId,
    this.currency,
    this.pendingBalance = 0,
    this.availableBalance = 0,
    this.reservedBalance = 0,
    this.lifetimeEarned = 0,
    this.lifetimeWithdrawn = 0,
    this.outstandingBalance = 0,
  });

  final int id;
  final int? organizationId;
  final String? currency;
  final double pendingBalance;
  final double availableBalance;
  final double reservedBalance;
  final double lifetimeEarned;
  final double lifetimeWithdrawn;
  final double outstandingBalance;

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: asInt(json['id']) ?? 0,
      organizationId: asInt(json['organization_id']),
      currency: asString(json['currency']),
      pendingBalance: asDouble(json['pending_balance']) ?? 0,
      availableBalance: asDouble(json['available_balance']) ?? 0,
      reservedBalance: asDouble(json['reserved_balance']) ?? 0,
      lifetimeEarned: asDouble(json['lifetime_earned']) ?? 0,
      lifetimeWithdrawn: asDouble(json['lifetime_withdrawn']) ?? 0,
      outstandingBalance: asDouble(json['outstanding_balance']) ?? 0,
    );
  }
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    this.reference,
    this.type,
    this.amount,
    this.currency,
    this.description,
    this.paymentReference,
    this.jobReference,
    this.createdAt,
  });

  final int id;
  final String? reference;
  final String? type;
  final double? amount;
  final String? currency;
  final String? description;
  final String? paymentReference;
  final String? jobReference;
  final String? createdAt;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final payment = asMap(json['payment']);
    final job = asMap(json['job']);
    return WalletTransaction(
      id: asInt(json['id']) ?? 0,
      reference: asString(json['reference']),
      type: asString(json['type']),
      amount: asDouble(json['amount']),
      currency: asString(json['currency']),
      description: asString(json['description']),
      paymentReference: asString(payment['reference']),
      jobReference: asString(job['reference']),
      createdAt: asString(json['created_at']),
    );
  }
}
