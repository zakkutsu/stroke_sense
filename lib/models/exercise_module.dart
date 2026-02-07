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
  // LEVEL 1: DASAR LINIER
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

  // LEVEL 2: DASAR GEOMETRI
  ExerciseModule(
    id: 'roda',
    title: 'Roda',
    symbol: 'OOOO',
    description: 'Lingkaran penuh. Melatih keluwesan.',
    icon: Icons.circle_outlined,
    difficulty: Difficulty.medium,
    category: 'Geometri',
  ),
  ExerciseModule(
    id: 'telur',
    title: 'Telur',
    symbol: '0000',
    description: 'Bentuk lonjong dasar huruf a, d, g.',
    icon: Icons.egg_outlined,
    difficulty: Difficulty.medium,
    category: 'Geometri',
  ),

  // LEVEL 3: ALIRAN BERSAMBUNG
  ExerciseModule(
    id: 'ombak',
    title: 'Ombak',
    symbol: '~~~~',
    description: 'Pola lengkung bersambung.',
    icon: Icons.waves,
    difficulty: Difficulty.hard,
    category: 'Flow',
  ),
  ExerciseModule(
    id: 'kawat',
    title: 'Kawat',
    symbol: 'eeeee',
    description: 'Pola putaran seperti kabel telepon.',
    icon: Icons.all_inclusive,
    difficulty: Difficulty.hard,
    category: 'Flow',
  ),
];