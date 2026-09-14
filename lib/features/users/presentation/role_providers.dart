import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/access_role.dart';
import '../../../shared/providers/session_provider.dart';

final accessCatalogProvider = FutureProvider.autoDispose<AccessCatalog>((ref) {
  return ref.watch(roleRepositoryProvider).catalog();
});
