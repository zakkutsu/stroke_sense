import 'package:image/image.dart' as img;
import 'package:stroke_sense/models/analysis_result.dart';
import 'base_processor.dart';
import 'dart:math';

/// Processor khusus untuk analisis sudut tajam dan presisi titik
/// Digunakan untuk: Gergaji (/\/\/\), Rintik (• • • •)
class AngleProcessor implements ShapeProcessor {
  final String moduleId;
  
  AngleProcessor(this.moduleId);

  @override
  AnalysisResult analyze(img.Image image) {
    if (moduleId == 'rintik') {
      return _analyzeRintik(image);
    } else {
      return _analyzeGergaji(image);
    }
  }

  /// Analisis untuk modul Gergaji (Zigzag)
  /// Fokus: Ketajaman sudut & konsistensi perubahan arah
  AnalysisResult _analyzeGergaji(img.Image image) {
    // === STEP 1: Extract Zigzag Signal ===
    List<double> signalY = [];
    
    for (int x = 0; x < image.width; x += 2) {
      int inkYSum = 0;
      int inkCount = 0;
      
      for (int y = 0; y < image.height; y++) {
        if (ProcessorUtils.isInk(image, x, y)) {
          inkYSum += y;
          inkCount++;
        }
      }
      
      if (inkCount > 0) {
        signalY.add(inkYSum / inkCount);
      }
    }

    if (signalY.length < 30) return ProcessorUtils.errorResult();

    // === STEP 2: Deteksi Titik Balik (Direction Changes) ===
    List<int> peakIndices = []; // Puncak (sudut atas)
    List<int> valleyIndices = []; // Lembah (sudut bawah)
    
    for (int i = 1; i < signalY.length - 1; i++) {
      // Peak: Y kecil (atas)
      if (signalY[i] < signalY[i - 1] && signalY[i] < signalY[i + 1]) {
        peakIndices.add(i);
      }
      // Valley: Y besar (bawah)
      if (signalY[i] > signalY[i - 1] && signalY[i] > signalY[i + 1]) {
        valleyIndices.add(i);
      }
    }

    int totalAngles = peakIndices.length + valleyIndices.length;
    if (totalAngles < 3) {
      return AnalysisResult(
        overallScore: 20,
        verticalityScore: 0,
        spacingScore: 0,
        consistencyScore: 0,
        stabilityScore: 0,
        feedback: "Pola zigzag tidak terdeteksi. Buat sudut lebih tajam.",
      );
    }

    // === STEP 3: Analisis Ketajaman Sudut ===
    // Sudut tajam = perubahan Y yang drastis dalam jarak X pendek
    List<double> sharpnessList = [];
    
    for (int i = 1; i < signalY.length - 1; i++) {
      double angle = (signalY[i - 1] - signalY[i]).abs() + (signalY[i + 1] - signalY[i]).abs();
      sharpnessList.add(angle);
    }
    
    double avgSharpness = ProcessorUtils.average(sharpnessList);
    // Sharpness tinggi = sudut tajam (bagus untuk zigzag)
    double sharpnessScore = (avgSharpness * 2).clamp(0, 100);

    // === STEP 4: Konsistensi Amplitudo ===
    List<double> amplitudes = [];
    int minLength = min(peakIndices.length, valleyIndices.length);
    
    for (int i = 0; i < minLength; i++) {
      double amp = (signalY[valleyIndices[i]] - signalY[peakIndices[i]]).abs();
      amplitudes.add(amp);
    }
    
    double amplitudeScore = 80;
    if (amplitudes.length >= 2) {
      double stdDev = ProcessorUtils.standardDeviation(amplitudes);
      amplitudeScore = (100 - (stdDev * 0.5)).clamp(0, 100);
    }

    // === STEP 5: Konsistensi Frekuensi (Jarak antar sudut) ===
    List<double> wavelengths = [];
    for (int i = 0; i < peakIndices.length - 1; i++) {
      wavelengths.add((peakIndices[i + 1] - peakIndices[i]).toDouble());
    }
    
    double frequencyScore = 80;
    if (wavelengths.length >= 2) {
      double stdDev = ProcessorUtils.standardDeviation(wavelengths);
      frequencyScore = (100 - (stdDev * 0.3)).clamp(0, 100);
    }

    // === SKOR FINAL ===
    double finalScore = (sharpnessScore * 0.4) + (amplitudeScore * 0.3) + (frequencyScore * 0.3);
    finalScore = finalScore.clamp(0, 100);

    String feedback = "";
    if (finalScore > 85) {
      feedback = "Sempurna! Sudut zigzag tajam dan konsisten.";
    } else if (sharpnessScore < 60) {
      feedback = "Sudut kurang tajam. Buat perubahan arah lebih drastis.";
    } else if (amplitudeScore < 60) {
      feedback = "Tinggi zigzag tidak konsisten. Jaga amplitudo tetap sama.";
    } else {
      feedback = "Bagus, tingkatkan ketajaman sudut.";
    }

    return AnalysisResult(
      overallScore: finalScore,
      verticalityScore: 0,
      spacingScore: frequencyScore,
      consistencyScore: amplitudeScore,
      stabilityScore: sharpnessScore,
      feedback: feedback,
    );
  }

  /// Analisis untuk modul Rintik (Titik-titik)
  /// Fokus: Jarak antar titik, keseragaman ukuran, dan presisi penempatan
  AnalysisResult _analyzeRintik(img.Image image) {
    // === STEP 1: Deteksi Titik-titik (Connected Components) ===
    List<Point> dotCenters = _findDotCenters(image);

    if (dotCenters.length < 2) {
      return AnalysisResult(
        overallScore: 10,
        verticalityScore: 0,
        spacingScore: 0,
        consistencyScore: 0,
        stabilityScore: 0,
        feedback: "Titik tidak terdeteksi. Pastikan ada minimal 3-4 titik terpisah.",
      );
    }

    // === STEP 2: Analisis Jarak Antar Titik ===
    List<double> distances = [];
    for (int i = 0; i < dotCenters.length - 1; i++) {
      double dist = sqrt(
        pow(dotCenters[i + 1].x - dotCenters[i].x, 2) +
        pow(dotCenters[i + 1].y - dotCenters[i].y, 2)
      );
      distances.add(dist);
    }

    // Calculate spacing consistency
    double distanceStdDev = ProcessorUtils.standardDeviation(distances);
    
    // Jarak konsisten = stdDev kecil
    double spacingScore = (100 - (distanceStdDev * 0.5)).clamp(0, 100);

    // === STEP 3: Analisis Kelurusan Horizontal ===
    // Titik-titik idealnya sejajar horizontal (Y sama)
    List<double> yPositions = dotCenters.map((p) => p.y.toDouble()).toList();
    double yStdDev = ProcessorUtils.standardDeviation(yPositions);
    
    double alignmentScore = (100 - (yStdDev * 2)).clamp(0, 100);

    // === STEP 4: Skor Akhir ===
    double finalScore = (spacingScore * 0.6) + (alignmentScore * 0.4);
    finalScore = finalScore.clamp(0, 100);

    String feedback = "";
    if (finalScore > 90) {
      feedback = "Sempurna! Titik-titik sejajar dan jarak konsisten.";
    } else if (spacingScore < 60) {
      feedback = "Jarak antar titik tidak konsisten. Gunakan penggaris sebagai panduan.";
    } else if (alignmentScore < 60) {
      feedback = "Titik tidak sejajar horizontal. Jaga agar tetap lurus.";
    } else {
      feedback = "Bagus, tingkatkan presisi penempatan titik.";
    }

    return AnalysisResult(
      overallScore: finalScore,
      verticalityScore: 0,
      spacingScore: spacingScore,
      consistencyScore: alignmentScore,
      stabilityScore: finalScore,
      feedback: feedback,
    );
  }

  /// Helper: Cari pusat setiap titik menggunakan connected component analysis
  List<Point> _findDotCenters(img.Image image) {
    List<Point> centers = [];
    List<List<bool>> visited = List.generate(
      image.height,
      (_) => List.filled(image.width, false),
    );

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        if (!visited[y][x] && ProcessorUtils.isInk(image, x, y)) {
          // Flood fill untuk cari satu blob
          List<Point> blob = [];
          _floodFill(image, x, y, visited, blob);
          
          // Hitung centroid blob ini
          if (blob.length > 5) { // Minimal 5 pixel baru dianggap titik
            int sumX = 0, sumY = 0;
            for (var p in blob) {
              sumX += p.x.toInt();
              sumY += p.y.toInt();
            }
            centers.add(Point(sumX ~/ blob.length, sumY ~/ blob.length));
          }
        }
      }
    }

    // Sort dari kiri ke kanan
    centers.sort((a, b) => a.x.compareTo(b.x));
    return centers;
  }

  /// Flood fill rekursif untuk cari connected component
  void _floodFill(img.Image image, int x, int y, List<List<bool>> visited, List<Point> blob) {
    if (x < 0 || x >= image.width || y < 0 || y >= image.height) return;
    if (visited[y][x] || !ProcessorUtils.isInk(image, x, y)) return;

    visited[y][x] = true;
    blob.add(Point(x, y));

    // 4-connectivity (atas, bawah, kiri, kanan)
    _floodFill(image, x + 1, y, visited, blob);
    _floodFill(image, x - 1, y, visited, blob);
    _floodFill(image, x, y + 1, visited, blob);
    _floodFill(image, x, y - 1, visited, blob);
  }
}
