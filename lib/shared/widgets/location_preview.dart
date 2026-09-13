import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/maps/google_maps_links.dart';
import '../../core/theme/app_colors.dart';

class LocationPreview extends StatelessWidget {
  const LocationPreview({
    super.key,
    required this.title,
    this.address,
    this.city,
    this.lat,
    this.lng,
  });

  final String title;
  final String? address;
  final String? city;
  final double? lat;
  final double? lng;

  @override
  Widget build(BuildContext context) {
    final line = [
      if ((city ?? '').trim().isNotEmpty) city!.trim(),
      if ((address ?? '').trim().isNotEmpty) address!.trim(),
    ].join(' · ');
    final hasCoords = lat != null && lng != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.trim().isNotEmpty) ...[
            Text(title, style: const TextStyle(color: AppColors.muted, height: 1.4)),
            const SizedBox(height: 4),
          ],
          Text(
            line.isEmpty ? '—' : line,
            style: const TextStyle(fontWeight: FontWeight.w500, height: 1.4),
          ),
          if (hasCoords) ...[
            const SizedBox(height: 4),
            Text(
              GoogleMapsLinks.format(lat, lng),
              style: const TextStyle(color: AppColors.muted),
            ),
            TextButton.icon(
              onPressed: () => GoogleMapsLinks.open(lat: lat!, lng: lng!),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(context.tr('common.openInGoogleMaps')),
            ),
          ],
        ],
      ),
    );
  }
}
