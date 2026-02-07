import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:stroke_sense/models/analysis_result.dart';

class ImageProcessor {
  
  // --- FUNGSI UTAMA ---
  static Future<AnalysisResult> analyze(String imagePath, String moduleId) async {
    // 1. Load & Preprocessing
    final cmd = img.Command()
      ..decodeImageFile(imagePath)
      ..grayscale() // Hitam Putih
      ..adjustColor(contrast: 1.5); // Pertajam beda tinta vs kertas (1.0 = normal, >1 = lebih kontras)
      
    await cmd.executeThread();
    img.Image? processedImage = cmd.outputImage;

    if (processedImage == null) throw Exception("Gagal memproses gambar");

    // Resize biar cepat (lebar 500px cukup)
    processedImage = img.copyResize(processedImage, width: 500);

    // 2. Routing Algoritma
    if (moduleId == 'pagar' || moduleId == 'cakrawala' || moduleId == 'hujan') {
      return _analyzeLinear(processedImage, moduleId);
    } else if (moduleId == 'roda' || moduleId == 'telur') {
      return _analyzeCircle(processedImage); // Algoritma Lingkaran
    } else if (moduleId == 'ombak' || moduleId == 'kawat') {
      return _analyzeWave(processedImage);   // Algoritma Ombak
    } else {
      // Default fallback
      return _analyzeLinear(processedImage, 'pagar');
    }
  }

  // ==========================================================
  // 1. ALGORITMA LINIER (GARIS LURUS / PAGAR)
  // ==========================================================
  static AnalysisResult _analyzeLinear(img.Image image, String type) {
    int height = image.height;
    int yTop = (height * 0.2).toInt();
    int yMid = (height * 0.5).toInt();
    int yBot = (height * 0.8).toInt();

    List<int> pointsTop = _findInkX(image, yTop);
    List<int> pointsBot = _findInkX(image, yBot);

    // Hitung Kemiringan (Tilt)
    double totalDeviasi = 0;
    int count = min(pointsTop.length, pointsBot.length);
    
    for (int i = 0; i < count; i++) {
      totalDeviasi += (pointsTop[i] - pointsBot[i]).abs();
    }
    
    double avgTilt = count > 0 ? totalDeviasi / count : 0;
    // Pagar harus tegak (deviasi 0). Hujan harus miring (deviasi besar).
    
    double score = 0;
    String feedback = "";

    if (type == 'pagar') {
      // Semakin kecil deviasi, semakin bagus
      score = (100 - (avgTilt * 1.5)).clamp(0, 100);
      feedback = score > 80 ? "Garis tegak sempurna!" : "Garis masih miring.";
    } else if (type == 'hujan') {
      // Hujan HARUS miring. Kalau tegak (deviasi 0), malah jelek.
      // Target miring misal 20px - 50px
      if (avgTilt > 10) {
        score = 90; 
        feedback = "Kemiringan garis bagus.";
      } else {
        score = 40; 
        feedback = "Garis terlalu tegak, buatlah miring.";
      }
    } else {
      score = 80; feedback = "Latihan selesai.";
    }

    return AnalysisResult(
      overallScore: score,
      verticalityScore: score,
      spacingScore: 80, // Sederhana dulu
      consistencyScore: 80,
      stabilityScore: 85,
      feedback: feedback,
    );
  }

  // ==========================================================
  // 2. ALGORITMA GEOMETRI (LINGKARAN / RODA)
  // ==========================================================
  static AnalysisResult _analyzeCircle(img.Image image) {
    // A. Cari Titik Pusat (Centroid) dari tinta hitam
    int sumX = 0, sumY = 0, pixelCount = 0;
    List<Point> inkPixels = [];

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        if (_isInk(image, x, y)) {
          sumX += x;
          sumY += y;
          pixelCount++;
          inkPixels.add(Point(x, y));
        }
      }
    }

    if (pixelCount == 0) return _errorResult();

    double centerX = sumX / pixelCount;
    double centerY = sumY / pixelCount;

    // B. Hitung Jarak setiap pixel tinta ke Titik Pusat (Jari-jari)
    List<double> radii = [];
    double totalRadius = 0;

    for (var p in inkPixels) {
      double r = sqrt(pow(p.x - centerX, 2) + pow(p.y - centerY, 2));
      radii.add(r);
      totalRadius += r;
    }

    double avgRadius = totalRadius / radii.length;

    // C. Hitung Standar Deviasi (Seberapa "Peyang" lingkarannya)
    double varianceSum = 0;
    for (var r in radii) {
      varianceSum += pow(r - avgRadius, 2);
    }
    double stdDev = sqrt(varianceSum / radii.length);

    // Skor: Semakin kecil StdDev, semakin bulat sempurna.
    // Toleransi: StdDev 2.0 = Perfect. StdDev 10.0 = Jelek.
    double roundnessScore = (100 - (stdDev * 5)).clamp(0, 100);

    String feedback = "";
    if (roundnessScore > 85) feedback = "Luar biasa! Lingkaran sangat bulat.";
    else if (roundnessScore > 60) feedback = "Sedikit lonjong, pertahankan pusat putaran.";
    else feedback = "Bentuk tidak beraturan. Coba kunci siku tangan.";

    return AnalysisResult(
      overallScore: roundnessScore,
      verticalityScore: 0, // Tidak relevan
      spacingScore: 0,
      consistencyScore: roundnessScore, // Konsistensi jari-jari
      stabilityScore: 80, 
      feedback: feedback,
    );
  }

  // ==========================================================
  // 3. ALGORITMA OMBAK (WAVE / KAWAT)
  // ==========================================================
  static AnalysisResult _analyzeWave(img.Image image) {
    // Kita scan kolom per kolom, cari titik tengah tinta di setiap X
    List<double> signalY = [];
    
    for (int x = 0; x < image.width; x+=2) { // Skip 2px biar cepat
      int inkYSum = 0;
      int inkCount = 0;
      for (int y = 0; y < image.height; y++) {
        if (_isInk(image, x, y)) {
          inkYSum += y;
          inkCount++;
        }
      }
      if (inkCount > 0) {
        signalY.add(inkYSum / inkCount); // Rata-rata Y tinta di kolom X ini
      }
    }

    if (signalY.length < 50) return _errorResult();

    // A. Analisis Kestabilan (Smoothness)
    // Cek perubahan mendadak antar titik (Jitter)
    double totalJitter = 0;
    for (int i = 0; i < signalY.length - 1; i++) {
      totalJitter += (signalY[i] - signalY[i+1]).abs();
    }
    // Jika ombak halus, jitter harusnya kecil & ritmis. 
    // Jika tangan gemetar, jitter besar.
    
    // B. Deteksi Puncak & Lembah (Peak Detection)
    int peaks = 0;
    for (int i = 1; i < signalY.length - 1; i++) {
      // Titik lebih tinggi dari kiri & kanannya (Ingat: di gambar Y=0 itu atas)
      if (signalY[i] < signalY[i-1] && signalY[i] < signalY[i+1]) {
        peaks++;
      }
    }

    double flowScore = 80; // Placeholder logika kompleks
    if (peaks < 2) flowScore = 40; // Kurang banyak ombaknya
    
    String feedback = "Ombak bagus, ritme terjaga.";
    if (peaks == 0) feedback = "Tidak terlihat pola ombak.";

    return AnalysisResult(
      overallScore: flowScore,
      verticalityScore: 0,
      spacingScore: 0,
      consistencyScore: flowScore,
      stabilityScore: (100 - (totalJitter/signalY.length)).clamp(0, 100),
      feedback: feedback,
    );
  }

  // --- HELPER FUNCTIONS ---

  static bool _isInk(img.Image image, int x, int y) {
    // Deteksi warna gelap (luminance < 100)
    return image.getPixel(x, y).luminance < 100;
  }

  static List<int> _findInkX(img.Image image, int y) {
    List<int> positions = [];
    bool insideLine = false;
    int startX = 0;
    
    for (int x = 0; x < image.width; x++) {
      if (_isInk(image, x, y)) {
        if (!insideLine) { insideLine = true; startX = x; }
      } else {
        if (insideLine) {
          positions.add((startX + x) ~/ 2);
          insideLine = false;
        }
      }
    }
    return positions;
  }

  static AnalysisResult _errorResult() {
    return AnalysisResult(
      overallScore: 0, verticalityScore: 0, spacingScore: 0, 
      consistencyScore: 0, stabilityScore: 0, 
      feedback: "Gagal mendeteksi goresan. Gunakan tinta gelap di kertas terang."
    );
  }
}

