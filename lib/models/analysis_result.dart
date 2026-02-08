import 'dart:math'; // Import untuk Point

class AnalysisResult {
  final double overallScore; // Nilai Akhir (0-100)
  
  // Detail Nilai
  final double verticalityScore; // Ketegakan
  final double spacingScore;     // Jarak Spasi
  final double consistencyScore; // Konsistensi Tinggi
  final double stabilityScore;   // Kestabilan (Gemetar/Tidak)
  
  // Feedback teks
  final String feedback;

  // [BARU] Data untuk digambar di layar (List of Lines)
  // Setiap Line punya banyak titik (Point)
  final List<List<Point<int>>>? linesToDraw;

  AnalysisResult({
    required this.overallScore,
    required this.verticalityScore,
    required this.spacingScore,
    required this.consistencyScore,
    required this.stabilityScore,
    required this.feedback,
    this.linesToDraw, // Tambahkan di constructor
  });
}
