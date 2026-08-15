import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paceup/app/dependencies.dart';
import 'package:paceup/features/home/domain/entities/marathon.dart';

final marathonListProvider = FutureProvider<List<Marathon>>(
  (ref) async =>
      (await ref.watch(marathonRepositoryProvider).fetchAll()).unwrap(),
);

final marathonProvider = FutureProvider.family<Marathon, String>(
  (ref, id) async =>
      (await ref.watch(marathonRepositoryProvider).fetchById(id)).unwrap(),
);
