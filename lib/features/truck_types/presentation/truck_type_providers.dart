import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/truck_type.dart';
import '../../../shared/providers/session_provider.dart';

final catalogTruckTypesProvider = FutureProvider<List<TruckTypeOption>>((ref) {
  return ref.watch(truckTypeRepositoryProvider).catalog();
});

final managedTruckTypesProvider = FutureProvider.autoDispose<List<TruckTypeOption>>((ref) {
  return ref.watch(truckTypeRepositoryProvider).all();
});
