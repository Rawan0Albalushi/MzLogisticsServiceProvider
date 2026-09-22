import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(_warmBrandFonts());
  runApp(const ProviderScope(child: MzProviderApp()));
}

Future<void> _warmBrandFonts() async {
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.ibmPlexSans(),
      GoogleFonts.ibmPlexSansArabic(),
    ]);
  } catch (_) {
    // The theme already falls back to system fonts if the brand fonts are unavailable.
  }
}
