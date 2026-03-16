import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart'; // Додаємо цей імпорт

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Обов'язково ініціалізуємо менеджер вікон
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(375, 812), // Розмір екрана iPhone 13 mini в логічних пікселях
    center: true,
    title: "Мій Мобільний Додаток",
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 1. Індекс поточного вибраного екрана
  int _selectedIndex = 0;

  // 2. Список віджетів (екранів), між якими ми перемикаємось
  // Ви можете винести їх в окремі файли пізніше
  static const List<Widget> _pages = <Widget>[
    Center(child: Text('Головний екран', style: TextStyle(fontSize: 24))),
    Center(child: Text('Екран налаштувань', style: TextStyle(fontSize: 24))),
    Center(child: Text('Ваша C++ Логіка', style: TextStyle(fontSize: 24))),
  ];

  // 3. Функція, що змінює індекс при натисканні
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мій Flutter Додаток'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      // 4. Тіло екрана змінюється динамічно залежно від індексу
      body: _pages[_selectedIndex],

      // 5. Сам BottomNavigationBar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home), label: 'Головна'),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Налаштування',
          ),
          NavigationDestination(
            icon: Icon(Icons.terminal),
            label: 'C++ Engine',
          ),
        ],
      ),
    );
  }
}
