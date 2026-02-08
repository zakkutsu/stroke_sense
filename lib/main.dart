import 'package:flutter/material.dart';
import 'package:stroke_sense/screens/landing_screen.dart';
import 'package:stroke_sense/screens/onboarding_screen.dart';
import 'package:stroke_sense/core/theme.dart'; // Import Tema tadi
import 'package:stroke_sense/core/theme_provider.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Variable Global untuk menyimpan daftar kamera
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Deteksi kamera yang tersedia di HP
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: ${e.code}\nError Message: ${e.description}');
  }

  // Cek apakah ini pertama kali buka aplikasi
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: StrokeSenseApp(isFirstTime: isFirstTime),
    ),
  );
}

class StrokeSenseApp extends StatelessWidget {
  final bool isFirstTime;
  
  const StrokeSenseApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'StrokeSense',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          // Tentukan halaman awal berdasarkan status first time
          home: isFirstTime ? const OnboardingScreen() : const LandingScreen(),
        );
      },
    );
  }
}