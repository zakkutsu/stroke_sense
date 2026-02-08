import 'package:image/image.dart' as img;
import 'package:stroke_sense/models/analysis_result.dart';
import 'base_processor.dart';
import 'dart:math';

/// Processor khusus untuk analisis garis lurus (Linear)
/// Digunakan untuk: Pagar (|||||), Cakrawala (-----), Hujan (/////)
class LinearProcessor implements ShapeProcessor {
  final String moduleId;
  
  LinearProcessor(this.moduleId);

  @override
  AnalysisResult analyze(img.Image image) {
    int height = image.height;
    
    // Sampling 3 titik: Atas (15%), Tengah (50%), Bawah (85%)
    int yTop = (height * 0.15).toInt();
    int yMid = (height * 0.5).toInt();
    int yBot = (height * 0.85).toInt();

    List<int> pointsTop = ProcessorUtils.findInkX(image, yTop);
    List<int> pointsMid = ProcessorUtils.findInkX(image, yMid);
    List<int> pointsBot = ProcessorUtils.findInkX(image, yBot);

    // Validasi: minimal ada garis
    int lineCount = pointsMid.length;
    if (lineCount == 0) return ProcessorUtils.errorResult();
    
    // Penalty jika jumlah garis tidak konsisten
    double consistencyPenalty = 0;
    if (pointsTop.length != lineCount || pointsBot.length != lineCount) {
      consistencyPenalty = 30;
      lineCount = min(lineCount, min(pointsTop.length, pointsBot.length));
    }

    // === ANALISIS KETEGAKAN & KELURUSAN ===
    double totalVerticalityError = 0;
    double totalStraightnessError = 0;

    for (int i = 0; i < lineCount; i++) {
      int xTop = pointsTop[i];
      int xMid = pointsMid[i];
      int xBot = pointsBot[i];

      // 1. Ketegakan: Seberapa jauh geser dari atas ke bawah
      totalVerticalityError += (xTop - xBot).abs();

      // 2. Kelurusan: Apakah garis bengkok di tengah?
      double idealMid = (xTop + xBot) / 2;
      double bendError = (xMid - idealMid).abs();
      totalStraightnessError += bendError;
    }

    // === KALKULASI SKOR ===
    double avgVerticalError = lineCount > 0 ? totalVerticalityError / lineCount : 0;
    double avgStraightError = lineCount > 0 ? totalStraightnessError / lineCount : 0;

    // Penalty: Tiap pixel miring = -2.5 poin, tiap pixel bengkok = -4 poin
    double verticalityScore = (100 - (avgVerticalError * 2.5)).clamp(0, 100);
    double straightnessScore = (100 - (avgStraightError * 4.0)).clamp(0, 100);

    // Analisis Spasi (jarak antar garis)
    double spacingScore = _analyzeSpacing(pointsMid);

    // === SKOR FINAL ===
    double finalScore = 0;
    String feedback = "";

    switch (moduleId) {
      case 'pagar':
        // Pagar: Fokus ketegakan & kelurusan
        finalScore = (verticalityScore * 0.5) + (straightnessScore * 0.5) - consistencyPenalty;
        finalScore = finalScore.clamp(0, 100);

        if (finalScore > 90) {
          feedback = "Sempurna! Garis tegak dan lurus.";
        } else if (straightnessScore < 60) {
          feedback = "Garis terlihat bengkok/melengkung. Tahan nafas saat menarik garis.";
        } else if (verticalityScore < 60) {
          feedback = "Garis lurus tapi miring. Perbaiki sudut tangan.";
        } else {
          feedback = "Terus berlatih kestabilan tangan.";
        }
        break;

      case 'cakrawala':
        // Cakrawala: Horizontal lines (lebih toleran terhadap vertical error)
        finalScore = (straightnessScore * 0.7) + (spacingScore * 0.3) - consistencyPenalty;
        finalScore = finalScore.clamp(0, 100);
        feedback = finalScore > 80 
            ? "Garis horizontal sangat rapi!"
            : "Jaga agar garis tetap lurus horizontal.";
        break;

      case 'hujan':
        // Hujan: Diagonal lines
        finalScore = (verticalityScore * 0.4) + (straightnessScore * 0.4) + (spacingScore * 0.2) - consistencyPenalty;
        finalScore = finalScore.clamp(0, 100);
        feedback = finalScore > 80
            ? "Garis miring konsisten!"
            : "Perhatikan sudut kemiringan dan jarak antar garis.";
        break;

      default:
        finalScore = (verticalityScore + straightnessScore) / 2 - consistencyPenalty;
        finalScore = finalScore.clamp(0, 100);
        feedback = "Terus berlatih untuk hasil lebih baik.";
    }

    return AnalysisResult(
      overallScore: finalScore,
      verticalityScore: verticalityScore,
      spacingScore: spacingScore,
      consistencyScore: (100 - consistencyPenalty).clamp(0, 100),
      stabilityScore: straightnessScore,
      feedback: feedback,
    );
  }

  /// Analisis jarak antar garis (Spacing)
  double _analyzeSpacing(List<int> positions) {
    if (positions.length < 2) return 80; // Default jika cuma 1 garis

    List<double> gaps = [];
    for (int i = 0; i < positions.length - 1; i++) {
      gaps.add((positions[i + 1] - positions[i]).toDouble());
    }

    // Hitung standar deviasi (variasi jarak)
    double stdDev = ProcessorUtils.standardDeviation(gaps);
    
    // Semakin kecil stdDev, semakin konsisten jaraknya
    // StdDev 0 = perfect, StdDev 20+ = buruk
    double spacingScore = (100 - (stdDev * 3)).clamp(0, 100);
    return spacingScore;
  }
}
