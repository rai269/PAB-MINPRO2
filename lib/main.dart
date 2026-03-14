import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/theme_provider.dart';
import 'providers/task_provider.dart';
import 'providers/profile_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'pages/auth/login_page.dart';
import 'pages/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await NotificationService.init();

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    // Tentukan ThemeData aktif berdasarkan mode
    final brightness =
        MediaQuery.platformBrightnessOf(context);
    final ThemeData activeTheme;
    switch (themeProvider.themeMode) {
      case ThemeMode.dark:
        activeTheme = AppTheme.darkTheme;
        break;
      case ThemeMode.light:
        activeTheme = AppTheme.lightTheme;
        break;
      case ThemeMode.system:
      default:
        activeTheme = brightness == Brightness.dark
            ? AppTheme.darkTheme
            : AppTheme.lightTheme;
        break;
    }

    return AnimatedTheme(
      data: activeTheme,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ToDo Pro',
        // Nonaktifkan themeMode bawaan MaterialApp supaya AnimatedTheme yang kerja
        theme: activeTheme,
        darkTheme: activeTheme,
        themeMode: ThemeMode.light,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        if (session != null) {
          return const MainNavigation();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.read<TaskProvider>().clearTasks();
            context.read<ProfileProvider>().clearProfile();
            NotificationService.cancelAll();
          }
        });

        return const LoginPage();
      },
    );
  }
}
