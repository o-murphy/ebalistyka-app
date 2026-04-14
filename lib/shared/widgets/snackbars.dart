import 'package:flutter/material.dart';

void showNotAvailableSnackBar(BuildContext context, [String? feature]) {
  final message = feature != null
      ? '$feature not yet available'
      : 'Not yet available';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
