import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ebalistyka/shared/widgets/base_screen.dart';

class ReticleViewScreen extends ConsumerWidget {
  const ReticleViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BaseScreen(
      title: 'Reticle View',
      isSubscreen: true,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.remove_red_eye_outlined, size: 72),
              SizedBox(height: 20),
              Text(
                'Reticle View Screen placeholder',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text(
                'This route is reserved for the fullscreen reticle view screen.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
