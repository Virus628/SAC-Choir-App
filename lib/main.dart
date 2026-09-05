import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Leave the cache size at Firestore's default so local storage stays bounded.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(const ChoirApp());
}

class ChoirApp extends StatefulWidget {
  const ChoirApp({super.key});

  @override
  State<ChoirApp> createState() => _ChoirAppState();
}

class _ChoirAppState extends State<ChoirApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDarkMode = prefs.getBool('isDarkMode') ?? false;
    if (mounted && savedDarkMode != _isDarkMode) {
      setState(() => _isDarkMode = savedDarkMode);
    }
  }

  Future<void> _toggleTheme() async {
    setState(() => _isDarkMode = !_isDarkMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAC Choir App',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Light Theme Configuration
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1F1F1),
        cardTheme: const CardThemeData(color: Colors.white),
        appBarTheme: const AppBarThemeData(
          backgroundColor: Color(0xFFF1F1F1),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        useMaterial3: true,
      ),

      // Dark Theme Configuration
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: const CardThemeData(color: Color(0xFF1E1E1E)),
        appBarTheme: const AppBarThemeData(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),

      home: SACAppHomeScreen(
        isDarkMode: _isDarkMode,
        onThemeToggle: _toggleTheme,
      ),
    );
  }
}