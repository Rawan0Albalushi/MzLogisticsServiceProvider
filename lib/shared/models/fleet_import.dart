import '../../core/utils/json_utils.dart';

class FleetImportItem {
  const FleetImportItem({required this.row, required this.label});

  final int row;
  final String label;

  factory FleetImportItem.fromJson(Map<String, dynamic> json) {
    return FleetImportItem(
      row: asInt(json['row']) ?? 0,
      label: asString(json['label']) ?? '',
    );
  }
}

class FleetImportError {
  const FleetImportError({
    required this.row,
    required this.field,
    required this.message,
    this.details = const [],
  });

  final int row;
  final String field;
  final String message;
  final List<String> details;

  String get detailText => details.join(' · ');

  factory FleetImportError.fromJson(
    Map<String, dynamic> json, {
    required List<String> detailKeys,
  }) {
    return FleetImportError(
      row: asInt(json['row']) ?? 0,
      field: asString(json['field']) ?? '',
      message: asString(json['message']) ?? '',
      details: [
        for (final key in detailKeys)
          if ((asString(json[key]) ?? '').trim().isNotEmpty) asString(json[key])!.trim(),
      ],
    );
  }
}

class FleetImportResult {
  const FleetImportResult({
    required this.created,
    required this.failed,
    required this.items,
    required this.errors,
  });

  final int created;
  final int failed;
  final List<FleetImportItem> items;
  final List<FleetImportError> errors;

  factory FleetImportResult.fromJson(
    Map<String, dynamic> json, {
    required List<String> errorDetailKeys,
  }) {
    return FleetImportResult(
      created: asInt(json['created']) ?? 0,
      failed: asInt(json['failed']) ?? 0,
      items: (json['items'] as List? ?? [])
          .whereType<Map>()
          .map((item) => FleetImportItem.fromJson(asMap(item)))
          .toList(),
      errors: (json['errors'] as List? ?? [])
          .whereType<Map>()
          .map(
            (item) => FleetImportError.fromJson(
              asMap(item),
              detailKeys: errorDetailKeys,
            ),
          )
          .toList(),
    );
  }
}
