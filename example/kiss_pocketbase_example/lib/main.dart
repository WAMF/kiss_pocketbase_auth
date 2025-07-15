import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kiss_pocketbase_example/screens/home_screen.dart';
import 'package:kiss_pocketbase_example/screens/login_screen.dart';
import 'package:kiss_pocketbase_example/services/auth_service.dart';
import 'package:kiss_pocketbase_example/setup_functions.dart';

void main() async {
  // Check if PocketBase is running
  final isRunning = await _isPocketBaseRunning();
  if (!isRunning) {
    print('PocketBase is not running at http://localhost:8090.');
    print('Please start it with:');
    print('  docker-compose -f ../../docker-compose.test.yml up');
    print('Then restart this example app.');
    // Optionally, you could show a dialog in the UI instead of exiting.
    // For now, just exit early.
    return;
  }

  // Setup default providers before running the app
  setupPocketBaseProviders();
  runApp(const MyApp());
}

Future<bool> _isPocketBaseRunning() async {
  try {
    final response = await http.get(
      Uri.parse('http://localhost:8090/api/health'),
    );
    return response.statusCode == 200;
  } on Exception {
    return false;
  }
}

/// Main application widget
class MyApp extends StatelessWidget {
  /// Constructor for MyApp
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PocketBase Auth Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

/// Splash screen widget that handles initial authentication check
class SplashScreen extends StatefulWidget {
  /// Constructor for SplashScreen
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Ensure providers are set up
      setupPocketBaseProviders();

      // Add timeout to prevent hanging
      await _authService.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Timeout occurred, proceed to login screen
        },
      );

      if (!mounted) return;

      if (_authService.isAuthenticated && _authService.currentUser != null) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) =>
                HomeScreen(authData: _authService.currentUser!),
          ),
        );
      } else {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } on Exception {
      // If initialization fails, go to login screen
      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 24),
            Text(
              'PocketBase Auth',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
