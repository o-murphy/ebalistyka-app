import 'package:ebalistyka/shared/widgets/screen_top_bar.dart';
import 'package:flutter/material.dart';

class BaseScreen extends StatelessWidget {
  const BaseScreen({
    required this.title,
    required this.body,
    this.actions,
    this.isSubscreen = false,
    this.showBack = true,
    this.floatingActionButton,
    this.withTabs,
    this.bottomBar,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool isSubscreen;
  final bool showBack;
  final Widget? floatingActionButton;
  final List<Tab>? withTabs;

  /// Pinned bottom bar (e.g. action buttons in wizards).
  /// Placed in Scaffold.bottomNavigationBar so the body never scrolls behind it.
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScreenTopBar(
        title: title,
        actions: actions,
        isSubscreen: isSubscreen,
        showBack: showBack,
        withTabs: withTabs,
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: bottomBar != null
          ? SafeArea(child: bottomBar!)
          : null,
      floatingActionButton: floatingActionButton,
    );
  }
}
