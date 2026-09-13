import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/paginated.dart';
import '../../../core/utils/json_utils.dart';
import '../../../shared/models/quotation.dart';

class QuotationRepository {
  QuotationRepository(this._api);

  final ApiClient _api;

  Future<Paginated<Quotation>> list({
    int page = 1,
    String? status,
    String? search,
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _api.get(ApiEndpoints.quotations, query: {
      'page': page,
      'per_page': 15,
      if (status != null && status.isNotEmpty) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    });
    return Paginated.fromResponse(response, Quotation.fromJson);
  }

  Future<Quotation> show(int id) async {
    final response = await _api.get(ApiEndpoints.quotation(id));
    return Quotation.fromJson(asMap(response['data']));
  }

  Future<Quotation> submit(int shipmentId, QuotationDraft draft) async {
    final response = await _api.post(
      ApiEndpoints.shipmentQuotations(shipmentId),
      data: draft.toJson(),
    );
    return Quotation.fromJson(asMap(response['data']));
  }

  Future<Quotation> withdraw(int id) async {
    final response = await _api.post(ApiEndpoints.withdrawQuotation(id));
    return Quotation.fromJson(asMap(response['data']));
  }
}
