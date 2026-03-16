// lib/screens/home_screen.dart
import 'package:flutter/material.dart';

class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Тут ви описуєте інтерфейс саме цього екрана
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.table_view, size: 64, color: Colors.deepPurple),
          const SizedBox(height: 16),
          const Text(
            'Tables',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('There will be shooting tables and charts'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => print("Розрахунок..."),
            child: const Text("Start Calculation"),
          ),
        ],
      ),
    );
  }
}
