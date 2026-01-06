import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';

void main() async {
  // 1. Ensure bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Hive (Offline Storage)
  await Hive.initFlutter();
  // TODO: Register Hive Adapters here in future phases

  // 3. Initialize SharedPreferences (Settings)
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  // 4. Set up Bloc Observer (for debugging logs)
  Bloc.observer = SimpleBlocObserver();

  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;

  const MyApp({super.key, required this.isDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Simple local state for theme toggling (can be moved to Bloc later)
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDarkMode;
  }

  void toggleTheme() async {
    setState(() {
      _isDark = !_isDark;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Todo Clean Arch',
      debugShowCheckedModeBanner: false,

      // Theme Configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,

      home: Scaffold(
        appBar: AppBar(
          title: const Text('Todo App Foundation'),
          actions: [
            IconButton(
              icon: Icon(_isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: toggleTheme,
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Foundation Phase Complete',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text('Folder Structure: Checked ✅'),
              const Text('Theme System: Checked ✅'),
              const Text('Dimensions System: Checked ✅'),
              const Text('Hive Initialized: Checked ✅'),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple Bloc Observer to log state changes in console
class SimpleBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('${bloc.runtimeType} $change');
  }
}
