import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:stroke_sense/models/analysis_result.dart';
import 'package:stroke_sense/models/exercise_module.dart';
import 'package:stroke_sense/models/progress_record.dart';
import 'package:stroke_sense/services/database_service.dart';

class ResultScreen extends StatefulWidget {
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
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    // Auto-save saat screen dibuka
    _saveProgress();
  }

  Future<void> _saveProgress() async {
    if (_isSaved) return; // Prevent double save

    try {
      final record = ProgressRecord(
        moduleId: widget.module.id,
        moduleTitle: widget.module.title,
        overallScore: widget.result.overallScore,
        verticalityScore: widget.result.verticalityScore,
        spacingScore: widget.result.spacingScore,
        consistencyScore: widget.result.consistencyScore,
        stabilityScore: widget.result.stabilityScore,
        feedback: widget.result.feedback,
        timestamp: DateTime.now(),
        imagePath: widget.imagePath.isNotEmpty ? widget.imagePath : null,
      );

      await DatabaseService.instance.saveProgress(record);
      
      if (mounted) {
        setState(() => _isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Progress tersimpan!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan warna skor (Hijau=Bagus, Merah=Jelek)
    Color scoreColor = widget.result.overallScore >= 80 ? Colors.green : 
                       (widget.result.overallScore >= 50 ? Colors.orange : Colors.red);

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
                      File(widget.imagePath),
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
                          value: widget.result.overallScore / 100,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey[200],
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        "${widget.result.overallScore.toInt()}",
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
                    "Kualitas Goresan: ${widget.result.overallScore >= 80 ? 'Sangat Bagus!' : 'Perlu Latihan'}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Modul: ${widget.module.title}",
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
                  
                  _buildScoreBar("Ketegakan (Verticality)", widget.result.verticalityScore),
                  _buildScoreBar("Jarak Spasi (Spacing)", widget.result.spacingScore),
                  _buildScoreBar("Konsistensi Tinggi", widget.result.consistencyScore),
                  _buildScoreBar("Kestabilan Tangan", widget.result.stabilityScore),
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
                  Expanded(child: Text(widget.result.feedback)),
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
