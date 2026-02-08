import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stroke_sense/models/exercise_module.dart';
import 'package:stroke_sense/screens/camera_screen.dart';
import 'package:stroke_sense/screens/history_screen.dart';
import 'package:stroke_sense/widgets/global_help_sheet.dart';
import 'package:stroke_sense/core/theme_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Kelompokkan data berdasarkan kategori baru (4 kategori)
    final linearModules = exerciseList.where((e) => e.category == 'Linear').toList();
    final curveModules = exerciseList.where((e) => e.category == 'Curve').toList();
    final shapeModules = exerciseList.where((e) => e.category == 'Shape').toList();
    final angleModules = exerciseList.where((e) => e.category == 'Angle').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("StrokeSense"),
        // centerTitle & backgroundColor sudah diatur di AppTheme
        actions: [
          // TOMBOL RIWAYAT
          IconButton(
            icon: const Icon(Icons.history, size: 28),
            tooltip: 'Riwayat Latihan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          // TOMBOL TOGGLE DARK/LIGHT MODE
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  size: 28,
                ),
                tooltip: themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
          // TOMBOL BANTUAN (TANDA TANYA)
          IconButton(
            icon: const Icon(Icons.help_outline, size: 28),
            tooltip: 'Panduan & Cara Pakai',
            onPressed: () => GlobalHelpSheet.show(context),
          ),
          const SizedBox(width: 12), // Sedikit jarak dari pinggir
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader("Level 1: Garis Lurus"),
          ...linearModules.map((e) => _buildExerciseCard(context, e)),

          const SizedBox(height: 20),
          _buildSectionHeader("Level 2: Lengkungan"),
          ...curveModules.map((e) => _buildExerciseCard(context, e)),

          const SizedBox(height: 20),
          _buildSectionHeader("Level 3: Bentuk Tertutup"),
          ...shapeModules.map((e) => _buildExerciseCard(context, e)),

          const SizedBox(height: 20),
          _buildSectionHeader("Level 4: Sudut & Presisi"),
          ...angleModules.map((e) => _buildExerciseCard(context, e)),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildExerciseCard(BuildContext context, ExerciseModule module) {
    Color difficultyColor;
    switch (module.difficulty) {
      case Difficulty.easy: difficultyColor = Colors.green; break;
      case Difficulty.medium: difficultyColor = Colors.orange; break;
      case Difficulty.hard: difficultyColor = Colors.red; break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(module.icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              module.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            // Simbol dalam container terpisah dengan background
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                module.symbol,
                style: TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            module.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: difficultyColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: difficultyColor.withOpacity(0.5)),
          ),
          child: Text(
            module.difficulty.name.toUpperCase(),
            style: TextStyle(fontSize: 10, color: difficultyColor, fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () {
          HapticFeedback.mediumImpact(); // Efek getaran saat tap
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CameraScreen(module: module),
            ),
          );
        },
      ),
    );
  }
}