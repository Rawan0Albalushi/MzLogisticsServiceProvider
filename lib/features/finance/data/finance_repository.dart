import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/paginated.dart';
import '../../../shared/models/invoice.dart';
import '../../../shared/models/payment.dart';
import '../../../shared/models/settlement.dart';

class FinanceRepository {
  FinanceRepository(this._api);

  final ApiClient _api;

  Future<Paginated<Payment>> payments({int page = 1}) async {
    final response = await _api.get(ApiEndpoints.payments, query: {
      'page': page,
      'per_page': 15,
    });
    return Paginated.fromResponse(response, Payment.fromJson);
  }

  Future<Paginated<Invoice>> invoices({int page = 1}) async {
    final response = await _api.get(ApiEndpoints.invoices, query: {
      'page': page,
      'per_page': 15,
    });
    return Paginated.fromResponse(response, Invoice.fromJson);
  }

  Future<Paginated<Settlement>> settlements({int page = 1}) async {
    final response = await _api.get(ApiEndpoints.settlements, query: {
      'page': page,
      'per_page': 15,
    });
    return Paginated.fromResponse(response, Settlement.fromJson);
  }
}
