import 'package:eballistica/core/models/cartridge.dart';
import 'package:eballistica/core/providers/library_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

sealed class CartridgesUiState {
  const CartridgesUiState();
}

class CartridgesLoading extends CartridgesUiState {
  const CartridgesLoading();
}

class CartridgesReady extends CartridgesUiState {
  final List<Cartridge> cartridges;

  const CartridgesReady({required this.cartridges});
}

class CartridgesViewModel extends AsyncNotifier<CartridgesUiState> {
  @override
  Future<CartridgesUiState> build() async {
    final cartridges = await ref.watch(cartridgeLibraryProvider.future);
    return CartridgesReady(cartridges: cartridges);
  }

  Future<void> deleteCartridge(String id) async {
    await ref.read(cartridgeLibraryProvider.notifier).delete(id);

    final current = state.value;
    if (current is CartridgesReady) {
      state = AsyncData(
        CartridgesReady(
          cartridges: current.cartridges.where((c) => c.id != id).toList(),
        ),
      );
    }
  }
}

final cartridgesViewModelProvider =
    AsyncNotifierProvider<CartridgesViewModel, CartridgesUiState>(
      CartridgesViewModel.new,
    );
