import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/paginated.dart';
import '../../../core/utils/json_utils.dart';
import '../../../shared/models/invoice.dart';
import '../../../shared/models/payment.dart';
import '../../../shared/models/settlement.dart';
import '../../../shared/models/wallet.dart';

class FinanceRepository {
  FinanceRepository(this._api);

  final ApiClient _api;

  Future<Paginated<Payment>> payments({
    int page = 1,
    String? status,
    String? method,
    String? search,
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _api.get(ApiEndpoints.payments, query: {
      'page': page,
      'per_page': 15,
      if (status != null && status.isNotEmpty) 'status': status,
      if (method != null && method.isNotEmpty) 'method': method,
      if (search != null && search.isNotEmpty) 'search': search,
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    });
    return Paginated.fromResponse(response, Payment.fromJson);
  }

  Future<Paginated<Invoice>> invoices({
    int page = 1,
    String? status,
    String? type,
    String? search,
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _api.get(ApiEndpoints.invoices, query: {
      'page': page,
      'per_page': 15,
      if (status != null && status.isNotEmpty) 'status': status,
      if (type != null && type.isNotEmpty) 'type': type,
      if (search != null && search.isNotEmpty) 'search': search,
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    });
    return Paginated.fromResponse(response, Invoice.fromJson);
  }

  Future<Wallet?> wallet() async {
    final response = await _api.get(ApiEndpoints.wallets, query: {
      'page': 1,
      'per_page': 1,
    });
    final page = Paginated.fromResponse(response, Wallet.fromJson);
    return page.items.isEmpty ? null : page.items.first;
  }

  Future<Paginated<WalletTransaction>> walletTransactions(
    int walletId, {
    int page = 1,
    String? type,
    String? search,
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _api.get(ApiEndpoints.walletTransactions(walletId), query: {
      'page': page,
      'per_page': 15,
      if (type != null && type.isNotEmpty) 'type': type,
      if (search != null && search.isNotEmpty) 'search': search,
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    });
    return Paginated.fromResponse(response, WalletTransaction.fromJson);
  }

  Future<Paginated<Settlement>> settlements({
    int page = 1,
    String? status,
    String? search,
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _api.get(ApiEndpoints.settlements, query: {
      'page': page,
      'per_page': 15,
      if (status != null && status.isNotEmpty) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    });
    return Paginated.fromResponse(response, Settlement.fromJson);
  }

  Future<Settlement> requestWithdrawal({required double amount}) async {
    final response = await _api.post(ApiEndpoints.requestSettlement, data: {
      'amount': amount,
    });
    return Settlement.fromJson(asMap(response['data']));
  }
}
