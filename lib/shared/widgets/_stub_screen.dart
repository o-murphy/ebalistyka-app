import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart';

/// Reusable stub for screens that are not yet implemented.
/// All screens except Home have a back button + centered title header.
class StubScreen extends StatelessWidget {
  const StubScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return BaseScreen(
      title: title,
      isSubscreen: true,
      body: Center(
        child: Text(
          title,
          style: tt.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
          ),
        ),
      ),
    );
  }
}
