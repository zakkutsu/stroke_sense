import 'package:flutter/material.dart';

enum Difficulty { easy, medium, hard }

class ExerciseModule {
  final String id;
  final String title;
  final String symbol; // <-- Properti Baru
  final String description;
  final IconData icon;
  final Difficulty difficulty;
  final String category;

  ExerciseModule({
    required this.id,
    required this.title,
    required this.symbol, // <-- Wajib diisi
    required this.description,
    required this.icon,
    required this.difficulty,
    required this.category,
  });
}

final List<ExerciseModule> exerciseList = [
  // LEVEL 1: DASAR LINIER (Garis Lurus)
  ExerciseModule(
    id: 'pagar',
    title: 'Pagar',
    symbol: '|||||', // Simbol Visual
    description: 'Garis tegak lurus. Fokus kestabilan vertikal.',
    icon: Icons.vertical_align_center,
    difficulty: Difficulty.easy,
    category: 'Linear',
  ),
  ExerciseModule(
    id: 'cakrawala',
    title: 'Cakrawala',
    symbol: '-----',
    description: 'Garis mendatar. Melatih geseran tangan.',
    icon: Icons.remove,
    difficulty: Difficulty.easy,
    category: 'Linear',
  ),
  ExerciseModule(
    id: 'hujan',
    title: 'Hujan',
    symbol: '/////',
    description: 'Garis miring. Penting untuk kecepatan.',
    icon: Icons.trending_up,
    difficulty: Difficulty.medium,
    category: 'Linear',
  ),

  // LEVEL 2: LENGKUNGAN (Curves)
  ExerciseModule(
    id: 'ombak',
    title: 'Ombak',
    symbol: '~~~~',
    description: 'Lengkung U bersambung. Melatih kehalusan.',
    icon: Icons.waves,
    difficulty: Difficulty.medium,
    category: 'Curve',
  ),
  ExerciseModule(
    id: 'kawat',
    title: 'Kawat',
    symbol: 'eeeee',
    description: 'Loop bersambung seperti kabel telepon.',
    icon: Icons.all_inclusive,
    difficulty: Difficulty.medium,
    category: 'Curve',
  ),

  // LEVEL 3: BENTUK TERTUTUP (Shapes)
  ExerciseModule(
    id: 'roda',
    title: 'Roda',
    symbol: 'OOOO',
    description: 'Lingkaran sempurna. Melatih keluwesan putar.',
    icon: Icons.circle_outlined,
    difficulty: Difficulty.hard,
    category: 'Shape',
  ),
  ExerciseModule(
    id: 'telur',
    title: 'Telur',
    symbol: '0000',
    description: 'Oval lonjong. Dasar huruf a, d, g.',
    icon: Icons.egg_outlined,
    difficulty: Difficulty.hard,
    category: 'Shape',
  ),

  // LEVEL 4: SUDUT TAJAM (Angles)  
  ExerciseModule(
    id: 'gergaji',
    title: 'Gergaji',
    symbol: '/\\/\\/\\',
    description: 'Zigzag tajam. Melatih presisi sudut.',
    icon: Icons.show_chart,
    difficulty: Difficulty.hard,
    category: 'Angle',
  ),
  ExerciseModule(
    id: 'rintik',
    title: 'Rintik',
    symbol: '• • • •',
    description: 'Titik-titik terpisah. Melatih tekanan pena.',
    icon: Icons.more_horiz,
    difficulty: Difficulty.easy,
    category: 'Angle',
  ),
];