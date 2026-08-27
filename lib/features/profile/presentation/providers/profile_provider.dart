import 'package:camrun/app/dependencies.dart';
import 'package:camrun/core/error/failure.dart';
import 'package:camrun/features/profile/domain/entities/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async =>
      (await ref.watch(profileRepositoryProvider).fetch()).unwrap();

  /// Optimistic save: the UI shows the new values immediately and rolls back
  /// if the repository rejects them.
  Future<Failure?> save(UserProfile updated) async {
    final previous = state;
    state = AsyncData(updated);
    final result = await ref.read(profileRepositoryProvider).save(updated);
    return result.fold((_) => null, (failure) {
      state = previous;
      return failure;
    });
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile>(
  ProfileNotifier.new,
);
