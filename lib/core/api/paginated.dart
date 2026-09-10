import '../utils/json_utils.dart';

class Paginated<T> {
  const Paginated({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
  bool get isEmpty => items.isEmpty;

  factory Paginated.fromResponse(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) parse,
  ) {
    final data = json['data'];
    if (data is List) {
      final meta = asMap(json['meta']);
      return Paginated<T>(
        items: data.whereType<Map>().map((e) => parse(asMap(e))).toList(),
        currentPage: asInt(meta['current_page']) ?? 1,
        lastPage: asInt(meta['last_page']) ?? 1,
        perPage: asInt(meta['per_page']) ?? data.length,
        total: asInt(meta['total']) ?? data.length,
      );
    }

    final nested = asMap(data);
    final rows = nested['data'];
    if (rows is List) {
      return Paginated<T>(
        items: rows.whereType<Map>().map((e) => parse(asMap(e))).toList(),
        currentPage: asInt(nested['current_page']) ?? 1,
        lastPage: asInt(nested['last_page']) ?? 1,
        perPage: asInt(nested['per_page']) ?? rows.length,
        total: asInt(nested['total']) ?? rows.length,
      );
    }

    return Paginated<T>(
      items: const [],
      currentPage: 1,
      lastPage: 1,
      perPage: 15,
      total: 0,
    );
  }
}
