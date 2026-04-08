import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:riverpod/riverpod.dart';

class ShotProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final appState = await ref.watch(appStateProvider.future);
    return appState.activeProfile;
  }

  Future<void> selectProfile(Profile profile) async {
    await ref.read(appStateProvider.notifier).setActiveProfile(profile);
  }
}

final shotProfileProvider =
    AsyncNotifierProvider<ShotProfileNotifier, Profile?>(
      ShotProfileNotifier.new,
    );
