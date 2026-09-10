class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  final String message;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isValidation => statusCode == 422;

  String? firstFieldError(String field) {
    final values = fieldErrors[field];
    if (values == null || values.isEmpty) {
      return null;
    }
    return values.first;
  }

  @override
  String toString() => message;
}
