import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:stroke_sense/models/analysis_result.dart';
import 'package:stroke_sense/models/exercise_module.dart';

class ResultScreen extends StatelessWidget {
  final String imagePath;
  final ExerciseModule module;
  final AnalysisResult result;

  const ResultScreen({
    super.key,
    required this.imagePath,
    required this.module,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    // Tentukan warna skor (Hijau=Bagus, Merah=Jelek)
    Color scoreColor = result.overallScore >= 80 ? Colors.green : 
                       (result.overallScore >= 50 ? Colors.orange : Colors.red);

    return Scaffold(
      appBar: AppBar(title: const Text("Hasil Analisis")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. TAMPILKAN FOTO USER
            Container(
              height: 250,
              color: Colors.black,
              child: kIsWeb
                  ? const Center(
                      child: Icon(Icons.image, size: 80, color: Colors.white54),
                    )
                  : Image.file(
                      File(imagePath),
                      fit: BoxFit.contain, // Agar seluruh foto terlihat
                    ),
            ),

            // 2. SKOR UTAMA (LINGKARAN BESAR)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100, height: 100,
                        child: CircularProgressIndicator(
                          value: result.overallScore / 100,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey[200],
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        "${result.overallScore.toInt()}",
                        style: TextStyle(
                          fontSize: 32, 
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Kualitas Goresan: ${result.overallScore >= 80 ? 'Sangat Bagus!' : 'Perlu Latihan'}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Modul: ${module.title}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const Divider(),

            // 3. RINCIAN SKOR (PROGRESS BARS)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Rincian Penilaian:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  
                  _buildScoreBar("Ketegakan (Verticality)", result.verticalityScore),
                  _buildScoreBar("Jarak Spasi (Spacing)", result.spacingScore),
                  _buildScoreBar("Konsistensi Tinggi", result.consistencyScore),
                  _buildScoreBar("Kestabilan Tangan", result.stabilityScore),
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            // 4. FEEDBACK / SARAN
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.blue),
                  const SizedBox(width: 15),
                  Expanded(child: Text(result.feedback)),
                ],
              ),
            ),

            // TOMBOL COBA LAGI
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context), // Kembali ke kamera
                icon: const Icon(Icons.refresh),
                label: const Text("Coba Lagi"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBar(String label, double score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text("${score.toInt()}/100", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey[200],
            color: score >= 80 ? Colors.green : Colors.orange,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
