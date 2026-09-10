class AppValidators {
  const AppValidators._();

  static String? required(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    final email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!email.hasMatch(value.trim())) {
      return message;
    }
    return null;
  }

  static String? password(String? value, String message) {
    if (value == null || value.length < 8) {
      return message;
    }
    return null;
  }

  static String? match(String? value, String? other, String message) {
    if (value != other) {
      return message;
    }
    return null;
  }

  static String? positiveNumber(String? value, String message) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) {
      return message;
    }
    return null;
  }

  static String? positiveInt(String? value, String message) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) {
      return message;
    }
    return null;
  }
}
