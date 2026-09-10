import 'package:flutter_test/flutter_test.dart';
import 'package:mz_logistics_service_provider_app/core/utils/validators.dart';

void main() {
  test('required validator rejects empty values', () {
    expect(AppValidators.required('', 'required'), 'required');
    expect(AppValidators.required('Oman Haulers', 'required'), isNull);
  });

  test('email validator accepts company emails', () {
    expect(AppValidators.email('bad', 'email'), 'email');
    expect(AppValidators.email('provider@omanhaulers.om', 'email'), isNull);
  });

  test('positive number validator', () {
    expect(AppValidators.positiveNumber('0', 'positive'), 'positive');
    expect(AppValidators.positiveNumber('12.5', 'positive'), isNull);
  });
}
