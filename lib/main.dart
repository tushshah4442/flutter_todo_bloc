import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_state_event.dart';
import 'core/theme/app_theme.dart';
import 'data/models/task_model.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'presentation/screens/login_screen.dart';

void main() async {
  // 1. Ensure bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TaskModelAdapter());
  await Hive.openBox('tasks_box'); // Open box immediately to be ready

  // 3. Initialize SharedPreferences (Settings)
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  // 4. Set up Bloc Observer (for debugging logs)
  Bloc.observer = SimpleBlocObserver();

  runApp(MyApp(isDarkMode: isDarkMode, prefs: prefs));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  final SharedPreferences prefs; // Inject prefs

  const MyApp({super.key, required this.isDarkMode, required this.prefs});

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
    await widget.prefs.setBool('isDarkMode', _isDark);
  }

  @override
  Widget build(BuildContext context) {
    // 5. Dependency Injection (Root)
    final authRepository = AuthRepositoryImpl(sharedPreferences: widget.prefs);

    return RepositoryProvider(
      create: (context) => authRepository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthBloc(authRepository: authRepository)
                  ..add(CheckAuthStatus()),
          ),
          // TaskBloc will be added here in Phase 5
        ],
        child: MaterialApp(
          title: 'Flutter Todo Clean Arch',
          debugShowCheckedModeBanner: false,

          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,

          // 6. Navigation Logic based on Auth State
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is Authenticated) {
                return const HomeScreenPlaceholder();
              } else if (state is Unauthenticated) {
                return const LoginScreen();
              }
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
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
