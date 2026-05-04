import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ToggleBorder extends StatefulWidget {
  final Widget child;

  const ToggleBorder({super.key, required this.child});

  @override
  State<ToggleBorder> createState() => _ToggleBorderState();
}

class _ToggleBorderState extends State<ToggleBorder> {
  bool isEnabled = false;

  void _toggleBorder() {
    setState(() {
      isEnabled = !isEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (_) => _toggleBorder(),
      behavior: HitTestBehavior.translucent,
      child: Container(
        decoration: BoxDecoration(
          border: isEnabled ? Border.all(color: Colors.red, width: 3) : null,
        ),
        child: widget.child,
      ),
    );
  }
}

Widget ht(Widget child) {
  if (kDebugMode) {
    return ToggleBorder(child: child);
  }
  return child;
}
