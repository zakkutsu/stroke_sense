class AnalysisResult {
  final double overallScore; // Nilai Akhir (0-100)
  
  // Detail Nilai
  final double verticalityScore; // Ketegakan
  final double spacingScore;     // Jarak Spasi
  final double consistencyScore; // Konsistensi Tinggi
  final double stabilityScore;   // Kestabilan (Gemetar/Tidak)
  
  // Feedback teks
  final String feedback;

  AnalysisResult({
    required this.overallScore,
    required this.verticalityScore,
    required this.spacingScore,
    required this.consistencyScore,
    required this.stabilityScore,
    required this.feedback,
  });
}
