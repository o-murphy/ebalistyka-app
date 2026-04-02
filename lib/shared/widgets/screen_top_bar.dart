import 'package:go_router/go_router.dart';
import 'package:eballistica/router.dart';
import 'package:flutter/material.dart';

class ScreenTopBar extends StatelessWidget implements PreferredSizeWidget {
  const ScreenTopBar({
    required this.title,
    this.actions,
    this.isSubscreen = false,
    this.showBack = true,
    this.withTabs,
    super.key,
  });

  final String title;
  final List<Widget>? actions;
  final bool isSubscreen;
  final bool showBack;
  final List<Tab>? withTabs;

  @override
  Size get preferredSize {
    final tabHeight = (withTabs != null && withTabs!.isNotEmpty)
        ? kTextTabBarHeight
        : 0.0;
    return Size.fromHeight(kToolbarHeight + tabHeight);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  isSubscreen ? context.pop() : context.go(Routes.home),
              tooltip: 'Back',
            )
          : null,
      actions: actions,
      bottom: (withTabs != null && withTabs!.isNotEmpty)
          ? TabBar(tabs: withTabs!)
          : null,
    );
  }
}
