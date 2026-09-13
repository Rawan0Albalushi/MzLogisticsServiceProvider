import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleMapsLinks {
  GoogleMapsLinks._();

  static Future<bool> open({
    required double lat,
    required double lng,
    bool navigate = false,
  }) {
    final uri = Uri.parse(
      navigate
          ? 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'
          : 'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    return launchUrl(
      uri,
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  static String format(double? lat, double? lng) {
    if (lat == null || lng == null) {
      return '—';
    }
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }
}
