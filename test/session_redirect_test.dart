import 'package:flutter_test/flutter_test.dart';
import 'package:mz_logistics_service_provider_app/core/router/session_redirect.dart';
import 'package:mz_logistics_service_provider_app/shared/models/organization.dart';
import 'package:mz_logistics_service_provider_app/shared/models/user.dart';
import 'package:mz_logistics_service_provider_app/shared/providers/session_provider.dart';

void main() {
  const restoring = SessionState(ready: false);

  test('startup keeps the requested route until the session is ready', () {
    expect(
      resolveSessionRedirect(
        session: restoring,
        location: '/jobs/12',
        uri: Uri.parse('/jobs/12'),
      ),
      '/splash?next=%2Fjobs%2F12',
    );
    expect(
      resolveSessionRedirect(
        session: restoring,
        location: '/splash',
        uri: Uri.parse('/splash?next=%2Fjobs%2F12'),
      ),
      isNull,
    );
  });

  test('a signed-out session leaves the splash for sign in', () {
    expect(
      resolveSessionRedirect(
        session: const SessionState(ready: true),
        location: '/splash',
        uri: Uri.parse('/splash'),
      ),
      '/login',
    );
  });

  test('a signed-in session returns to the saved deep link', () {
    expect(
      resolveSessionRedirect(
        session: _session(),
        location: '/splash',
        uri: Uri.parse(
          '/splash?next=${Uri.encodeQueryComponent('/shipments/4?status=open')}',
        ),
      ),
      '/shipments/4?status=open',
    );
  });

  test('restricted companies cannot resume an operational deep link', () {
    expect(
      resolveSessionRedirect(
        session: _session(status: 'pending'),
        location: '/splash',
        uri: Uri.parse('/splash?next=%2Ffinance'),
      ),
      '/dashboard',
    );
    expect(
      resolveSessionRedirect(
        session: _session(status: 'pending'),
        location: '/splash',
        uri: Uri.parse('/splash?next=%2Fprofile'),
      ),
      '/profile',
    );
  });

  test('the platform root opens the splash, then the right home', () {
    expect(
      resolveSessionRedirect(
        session: const SessionState(ready: false),
        location: '/',
        uri: Uri.parse('/'),
      ),
      '/splash',
    );
    expect(
      resolveSessionRedirect(
        session: _session(),
        location: '/',
        uri: Uri.parse('/'),
      ),
      '/dashboard',
    );
  });

  test('external and auth targets are not resumed', () {
    expect(safeInternalPath('https://example.com'), isNull);
    expect(safeInternalPath('//example.com'), isNull);
    expect(safeInternalPath('/'), isNull);
    expect(safeInternalPath('/login'), isNull);
    expect(safeInternalPath('/../dashboard'), isNull);
  });

  test('signed-in users are sent to the dashboard from sign in', () {
    expect(
      resolveSessionRedirect(
        session: _session(),
        location: '/login',
        uri: Uri.parse('/login'),
      ),
      '/dashboard',
    );
  });
}

SessionState _session({String status = 'active'}) {
  return SessionState(
    ready: true,
    token: 'token',
    user: AppUser(id: 1, organization: Organization(id: 1, status: status)),
  );
}
