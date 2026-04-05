// sights_view_model.dart
import 'package:eballistica/core/models/sight.dart';
import 'package:eballistica/core/providers/app_state_provider.dart';
import 'package:riverpod/riverpod.dart';

sealed class SightsUiState {
  const SightsUiState();
}

class SightsLoading extends SightsUiState {
  const SightsLoading();
}

class SightsReady extends SightsUiState {
  final List<Sight> sights;

  const SightsReady({required this.sights});
}

class SightsViewModel extends AsyncNotifier<SightsUiState> {
  @override
  Future<SightsUiState> build() async {
    final appState = await ref.watch(appStateProvider.future);
    return SightsReady(sights: appState.sights);
  }

  Future<void> deleteSight(String id) async {
    final appStateNotifier = ref.read(appStateProvider.notifier);
    await appStateNotifier.deleteSight(id);

    final current = state.value;
    if (current is SightsReady) {
      state = AsyncData(
        SightsReady(sights: current.sights.where((s) => s.id != id).toList()),
      );
    }
  }
}

final sightsViewModelProvider =
    AsyncNotifierProvider<SightsViewModel, SightsUiState>(SightsViewModel.new);
