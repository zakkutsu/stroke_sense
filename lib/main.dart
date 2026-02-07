import 'package:flutter/material.dart';
import 'package:stroke_sense/screens/home_screen.dart';
import 'package:stroke_sense/core/theme.dart'; // Import Tema tadi
import 'package:stroke_sense/core/theme_provider.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';

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

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const StrokeSenseApp(),
    ),
  );
}

class StrokeSenseApp extends StatelessWidget {
  const StrokeSenseApp({super.key});

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
          home: const HomeScreen(),
        );
      },
    );
  }
}