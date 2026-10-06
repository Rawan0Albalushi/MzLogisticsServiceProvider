import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Path URLs let a hosted web build open routes such as /login directly.
  // This is a no-op on Android and iOS.
  usePathUrlStrategy();
  runApp(const ProviderScope(child: MzProviderApp()));
}
