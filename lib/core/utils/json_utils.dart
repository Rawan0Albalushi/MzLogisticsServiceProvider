int? asInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}

double? asDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

bool asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value == 1 || value == '1' || value == 'true') {
    return true;
  }
  if (value == 0 || value == '0' || value == 'false') {
    return false;
  }
  return fallback;
}

String? asString(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString();
  return text.isEmpty ? null : text;
}

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> asMapList(dynamic value) {
  if (value is! List) {
    return const [];
  }
  return value.whereType<Map>().map(asMap).toList();
}

List<String> asStringList(dynamic value) {
  if (value is! List) {
    return const [];
  }
  return value.map((item) => item.toString()).toList();
}
