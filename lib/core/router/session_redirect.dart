import '../../shared/providers/session_provider.dart';

const authEntryPaths = {'/login', '/register'};

/// Decides where startup should go once the saved session is known.
///
/// While the session is still restoring, every route stays on the splash and
/// the original location is kept in `next` so a refresh or deep link is not lost.
String? resolveSessionRedirect({
  required SessionState session,
  required String location,
  required Uri uri,
}) {
  if (location == '/' || location.isEmpty) {
    if (!session.ready) {
      return '/splash';
    }
    return session.isAuthenticated ? '/dashboard' : '/login';
  }

  if (!session.ready) {
    if (location == '/splash') {
      return null;
    }
    return '/splash?next=${Uri.encodeQueryComponent(uri.toString())}';
  }

  if (location == '/splash') {
    if (!session.isAuthenticated) {
      return '/login';
    }
    final next = safeInternalPath(uri.queryParameters['next']);
    if (next == null) {
      return '/dashboard';
    }
    final nextPath = Uri.parse(next).path;
    if (session.isAccountRestricted &&
        !session.allowsRestrictedPath(nextPath)) {
      return '/dashboard';
    }
    if (nextPath == '/fleet') {
      return '/trucks';
    }
    return next;
  }

  final loggingIn = authEntryPaths.contains(location);
  if (!session.isAuthenticated && !loggingIn) {
    return '/login';
  }
  if (session.isAuthenticated && loggingIn) {
    return '/dashboard';
  }
  if (session.isAccountRestricted && !session.allowsRestrictedPath(location)) {
    return '/dashboard';
  }
  if (session.isAuthenticated && location == '/fleet') {
    return '/trucks';
  }
  return null;
}

/// Allows only same-app paths. Rejects external URLs and auth screens.
String? safeInternalPath(String? value) {
  if (value == null) {
    return null;
  }
  final candidate = value.trim();
  if (candidate.isEmpty) {
    return null;
  }

  final parsed = Uri.tryParse(candidate);
  if (parsed == null || parsed.hasScheme || parsed.hasAuthority) {
    return null;
  }

  if (candidate.contains('..') || candidate.contains('\\')) {
    return null;
  }

  final path = parsed.path;
  if (path == '/' || !path.startsWith('/') || path.startsWith('//')) {
    return null;
  }
  if (path == '/splash' || authEntryPaths.contains(path)) {
    return null;
  }
  return candidate;
}
