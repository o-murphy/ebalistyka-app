import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Mixin for wizard form screens. Provides shared [nameController] / [vendorController]
/// lifecycle, validation helpers, and navigation shortcuts.
///
/// Override [initialName] and [initialVendor] to pre-fill the controllers from
/// the screen's widget (called during [initState]).
mixin WizardFormMixin<W extends ConsumerStatefulWidget> on ConsumerState<W> {
  late final TextEditingController nameController;
  late final TextEditingController vendorController;

  String get initialName => '';
  String get initialVendor => '';

  @override
  void initState() {
    nameController = TextEditingController(text: initialName);
    vendorController = TextEditingController(text: initialVendor);
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    vendorController.dispose();
    super.dispose();
  }

  bool get isNameValid => nameController.text.trim().isNotEmpty;

  /// Returns the trimmed name, or [fallback] when the field is empty.
  String wizardTitle(String fallback) {
    final n = nameController.text.trim();
    return n.isEmpty ? fallback : n;
  }

  /// Called from [WizardNameField.onChanged] to trigger a rebuild.
  void onNameChanged() => setState(() {});

  void onDiscard() => context.pop(null);

  void commitSave(Object? Function() builder) => context.pop(builder());
}
