import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/craving_label.dart';
import '../../data/repositories/label_repository.dart';
import 'goal_providers.dart';

final labelRepositoryProvider = Provider<LabelRepository>((ref) {
  return LabelRepository(ref.watch(isarProvider));
});

final shortlistProvider = StreamProvider<List<CravingLabel>>((ref) {
  return ref.watch(labelRepositoryProvider).watchShortlist();
});
