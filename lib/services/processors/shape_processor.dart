import 'package:image/image.dart' as img;
import 'package:stroke_sense/models/analysis_result.dart';
import 'base_processor.dart';
import 'dart:math';

/// Processor khusus untuk analisis bentuk tertutup (lingkaran/oval)
/// Digunakan untuk: Roda (OOOO), Telur (0000)
class GeometricShapeProcessor implements ShapeProcessor {
  @override
  AnalysisResult analyze(img.Image image) {
    // === STEP 1: Cari Centroid (Titik Pusat Massa) ===
    int sumX = 0, sumY = 0, pixelCount = 0;
    List<Point> inkPixels = [];

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        if (ProcessorUtils.isInk(image, x, y)) {
          sumX += x;
          sumY += y;
          pixelCount++;
          inkPixels.add(Point(x, y));
        }
      }
    }

    if (pixelCount == 0) return ProcessorUtils.errorResult();

    double centerX = sumX / pixelCount;
    double centerY = sumY / pixelCount;

    // === STEP 2: Hitung Jarak Setiap Pixel Tinta ke Pusat (Radius) ===
    List<double> radii = [];
    for (var p in inkPixels) {
      double r = sqrt(pow(p.x - centerX, 2) + pow(p.y - centerY, 2));
      radii.add(r);
    }

    double avgRadius = ProcessorUtils.average(radii);
    double stdDev = ProcessorUtils.standardDeviation(radii);

    // === STEP 3: Analisis Kebulatan (Roundness) ===
    // Standar Deviasi rendah = radius konsisten = bulat sempurna
    // StdDev 0-2 = Perfect Circle
    // StdDev 5-10 = Agak lonjong
    // StdDev >15 = Bentuk tidak beraturan
    
    double roundnessScore = (100 - (stdDev * 5)).clamp(0, 100);

    // === STEP 4: Analisis Kelengkapan (Completeness) ===
    // Cek apakah lingkaran tertutup penuh atau ada gap
    double completenessScore = _analyzeCompleteness(inkPixels, centerX, centerY, avgRadius);

    // === STEP 5: Analisis Ukuran (Size Consistency) ===
    // Cek apakah semua lingkaran (jika ada banyak) ukurannya sama
    double sizeScore = 85; // Placeholder (bisa dikembangkan untuk multi-circle)

    // === SKOR FINAL ===
    double finalScore = (roundnessScore * 0.6) + (completenessScore * 0.3) + (sizeScore * 0.1);
    finalScore = finalScore.clamp(0, 100);

    // === FEEDBACK ===
    String feedback = "";
    if (finalScore > 90) {
      feedback = "Luar biasa! Lingkaran sangat bulat dan sempurna.";
    } else if (roundnessScore < 60) {
      feedback = "Bentuk terlalu lonjong atau tidak beraturan. Coba kunci siku tangan dan putar dari bahu.";
    } else if (completenessScore < 60) {
      feedback = "Lingkaran belum tertutup sempurna. Ada gap di beberapa bagian.";
    } else {
      feedback = "Sedikit lonjong, tetap pertahankan pusat putaran.";
    }

    return AnalysisResult(
      overallScore: finalScore,
      verticalityScore: 0, // Tidak relevan untuk lingkaran
      spacingScore: sizeScore,
      consistencyScore: roundnessScore,
      stabilityScore: completenessScore,
      feedback: feedback,
    );
  }

  /// Analisis kelengkapan lingkaran (apakah tertutup penuh?)
  /// Metode: Sampling 360 derajat dari pusat, cek berapa % ada tinta
  double _analyzeCompleteness(List<Point> inkPixels, double cx, double cy, double radius) {
    if (radius < 5) return 50; // Radius terlalu kecil untuk dianalisis

    int samplesPerDegree = 1; // Sampling tiap 1 derajat
    int totalSamples = 360 * samplesPerDegree;
    int hitCount = 0;

    // Buat set untuk lookup cepat
    Set<String> inkSet = inkPixels.map((p) => '${p.x},${p.y}').toSet();

    for (int i = 0; i < totalSamples; i++) {
      double angle = (i / samplesPerDegree) * (pi / 180); // Convert ke radian
      
      // Hitung posisi di lingkaran ideal
      int x = (cx + radius * cos(angle)).round();
      int y = (cy + radius * sin(angle)).round();
      
      // Cek apakah ada tinta di sekitar posisi ini (toleransi ±2 pixel)
      bool foundInk = false;
      for (int dx = -2; dx <= 2; dx++) {
        for (int dy = -2; dy <= 2; dy++) {
          if (inkSet.contains('${x + dx},${y + dy}')) {
            foundInk = true;
            break;
          }
        }
        if (foundInk) break;
      }
      
      if (foundInk) hitCount++;
    }

    // Persentase kelengkapan
    double completeness = (hitCount / totalSamples) * 100;
    return completeness.clamp(0, 100);
  }
}
