import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'auth/signin_page.dart';
import 'screens/root_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  void toggleTheme() {
    setState(() => isDarkMode = !isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    final baseLight = ThemeData.light();
    final baseDark = ThemeData.dark();

    TextTheme makeBold(TextTheme textTheme) {
      return textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        displaySmall: textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),

        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),

        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),

        bodyLarge: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        bodyMedium: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        bodySmall: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),

        labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        labelMedium: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        labelSmall: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
      );
    }

    final lightTextTheme = makeBold(
      baseLight.textTheme.apply(fontFamily: "Quicksand"),
    );
    final darkTextTheme = makeBold(
      baseDark.textTheme.apply(fontFamily: "Quicksand"),
    );

    final lightTheme = baseLight.copyWith(
      textTheme: lightTextTheme,
      appBarTheme: baseLight.appBarTheme.copyWith(
        titleTextStyle: lightTextTheme.titleLarge,
      ),
    );

    final darkTheme = baseDark.copyWith(
      textTheme: darkTextTheme,
      appBarTheme: baseDark.appBarTheme.copyWith(
        titleTextStyle: darkTextTheme.titleLarge,
      ),
    );

    // then return MaterialApp
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Journal App",

      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      home: const SplashScreen(),
      routes: {
        '/auth': (_) =>
            AuthWrapper(isDarkMode: isDarkMode, onToggleTheme: toggleTheme),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const AuthWrapper({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        //.logged in → go to RootScreen (not JournalHomePage)
        if (snapshot.hasData) {
          return RootScreen(
            isDarkMode: isDarkMode,
            onToggleTheme: onToggleTheme,
          );
        }

        // not logged in → Sign-in page
        return const SignInPage();
      },
    );
  }
}
