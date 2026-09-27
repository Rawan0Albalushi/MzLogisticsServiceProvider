import 'package:flutter/widgets.dart';

const _ltrIsolateStart = '\u2066';
const _isolateEnd = '\u2069';
const _ltrEmbed = '\u202A';
const _rtlEmbed = '\u202B';
const _embedEnd = '\u202C';

/// Pickup to delivery, following the reading direction.
///
/// The arrow glyph is isolated so a right-to-left paragraph does not mirror it again.
String directionalRoute({
  required bool rtl,
  String? from,
  String? to,
  String empty = '—',
}) {
  final start = _place(from, empty);
  final end = _place(to, empty);
  final arrow = rtl ? '$_ltrIsolateStart←$_isolateEnd' : '$_ltrIsolateStart→$_isolateEnd';
  final embed = rtl ? _rtlEmbed : _ltrEmbed;
  return '$embed$start $arrow $end$_embedEnd';
}

String directionalRouteOf(
  BuildContext context,
  String? from,
  String? to, {
  String empty = '—',
}) {
  return directionalRoute(
    rtl: Directionality.of(context) == TextDirection.rtl,
    from: from,
    to: to,
    empty: empty,
  );
}

/// One place only, or null when both sides are blank.
String? routeLabelOf(BuildContext context, String? from, String? to) {
  final start = from?.trim() ?? '';
  final end = to?.trim() ?? '';
  if (start.isEmpty && end.isEmpty) {
    return null;
  }
  if (start.isEmpty) {
    return end;
  }
  if (end.isEmpty) {
    return start;
  }
  return directionalRouteOf(context, start, end);
}

bool routeHasPlaces(String? from, String? to) {
  return (from?.trim().isNotEmpty ?? false) || (to?.trim().isNotEmpty ?? false);
}

String _place(String? value, String empty) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? empty : trimmed;
}
