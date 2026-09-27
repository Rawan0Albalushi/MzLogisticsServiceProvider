import 'package:flutter_test/flutter_test.dart';
import 'package:mz_logistics_service_provider_app/core/utils/directional_text.dart';

void main() {
  test('route arrow follows reading direction without a second mirror', () {
    final ltr = directionalRoute(rtl: false, from: 'Muscat', to: 'Salalah');
    final rtl = directionalRoute(rtl: true, from: 'مسقط', to: 'صلالة');

    expect(ltr, contains('\u2066→\u2069'));
    expect(ltr, isNot(contains('←')));
    expect(ltr.startsWith('\u202A'), isTrue);

    expect(rtl, contains('\u2066←\u2069'));
    expect(rtl, isNot(contains('→')));
    expect(rtl.startsWith('\u202B'), isTrue);
    expect(rtl.endsWith('\u202C'), isTrue);
  });

  test('blank route sides stay empty for callers', () {
    expect(routeHasPlaces(null, '  '), isFalse);
    expect(routeHasPlaces('Muscat', null), isTrue);
  });
}
