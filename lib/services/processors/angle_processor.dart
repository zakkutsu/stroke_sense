import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:stroke_sense/models/analysis_result.dart';
import 'base_processor.dart';

class AngleProcessor implements ShapeProcessor {
  final String subType; // 'rintik' atau 'gergaji'
  
  AngleProcessor(this.subType);

  @override
  AnalysisResult analyze(img.Image image) {
    if (subType == 'rintik') {
      return _analyzeDots(image);
    } else {
      return _analyzeZigzag(image);
    }
  }

  // ==========================================
  // LOGIKA 1: RINTIK / TITIK-TITIK
  // ==========================================
  AnalysisResult _analyzeDots(img.Image image) {
    // Kita scan baris tengah (50%)
    int yMid = image.height ~/ 2;
    List<int> inkX = [];
    
    // Scan baris tengah
    for (int x = 0; x < image.width; x++) {
      if (ProcessorUtils.isInk(image, x, yMid)) {
        inkX.add(x);
      }
    }

    if (inkX.isEmpty) return _error("Tidak ada titik terdeteksi.");

    // Kelompokkan pixel yang berdekatan menjadi 1 "Titik" (Blob Detection)
    List<Point<int>> dots = [];
    List<int> currentBlob = [];
    
    for (int x in inkX) {
      if (currentBlob.isEmpty) {
        currentBlob.add(x);
      } else {
        if (x - currentBlob.last < 10) { // Jika jarak < 10px, masih 1 titik yang sama
          currentBlob.add(x);
        } else {
          // Titik selesai, hitung tengahnya
          int centerX = (currentBlob.first + currentBlob.last) ~/ 2;
          dots.add(Point(centerX, yMid));
          currentBlob = [x]; // Mulai titik baru
        }
      }
    }
    // Masukkan blob terakhir
    if (currentBlob.isNotEmpty) {
      int centerX = (currentBlob.first + currentBlob.last) ~/ 2;
      dots.add(Point(centerX, yMid));
    }

    // --- SCORING RINTIK ---
    int dotCount = dots.length;
    double countScore = 0;
    
    // Target: Minimal 3 titik, Maksimal 10 titik (biar gak semrawut)
    if (dotCount >= 3 && dotCount <= 8) countScore = 100;
    else if (dotCount < 3) countScore = 30; // Terlalu sedikit
    else countScore = 60; // Kebanyakan

    // Cek Jarak Antar Titik (Spacing Consistency)
    double spacingScore = 100;
    if (dotCount > 1) {
      List<int> gaps = [];
      for (int i = 0; i < dotCount - 1; i++) {
        gaps.add(dots[i+1].x - dots[i].x);
      }
      double avgGap = gaps.reduce((a, b) => a + b) / gaps.length;
      double variance = 0;
      for (var g in gaps) variance += pow(g - avgGap, 2);
      double stdDev = sqrt(variance / gaps.length);
      
      spacingScore = (100 - (stdDev * 5.0)).clamp(0, 100);
    }

    double finalScore = (countScore * 0.4) + (spacingScore * 0.6);
    String feedback = "";
    
    if (countScore < 50) feedback = "Kurang banyak. Buat minimal 3 titik.";
    else if (spacingScore < 60) feedback = "Jarak antar titik tidak rata.";
    else feedback = "Presisi titik yang bagus!";

    return AnalysisResult(
      overallScore: finalScore,
      verticalityScore: 0,
      spacingScore: spacingScore,
      consistencyScore: countScore,
      stabilityScore: 100, // Titik pasti stabil
      feedback: feedback,
      linesToDraw: [dots], // Kirim koordinat titik untuk digambar
    );
  }

  // ==========================================
  // LOGIKA 2: GERGAJI / ZIGZAG (Tajam)
  // ==========================================
  AnalysisResult _analyzeZigzag(img.Image image) {
    // 1. Ambil Sinyal Garis (Sama kayak Ombak)
    List<Point<int>> signal = [];
    for (int x = 0; x < image.width; x += 2) {
      List<int> inkY = [];
      for (int y = 0; y < image.height; y++) {
        if (ProcessorUtils.isInk(image, x, y)) inkY.add(y);
      }
      if (inkY.isNotEmpty) {
        int avgY = inkY.reduce((a, b) => a + b) ~/ inkY.length;
        signal.add(Point(x, avgY));
      }
    }

    if (signal.length < 50) return _error("Garis terlalu pendek.");

    // 2. Deteksi Puncak (Peaks)
    List<Point<int>> peaks = [];
    for (int i = 5; i < signal.length - 5; i++) {
      int prev = signal[i-3].y;
      int curr = signal[i].y;
      int next = signal[i+3].y;
      
      // Puncak Atas (Lembah visual) atau Puncak Bawah (Gunung visual)
      // Kita cari titik balik ekstrim
      bool isTurn = (curr < prev && curr < next) || (curr > prev && curr > next);
      
      if (isTurn) {
        // Filter jarak biar gak mendeteksi noise
        if (peaks.isEmpty || (signal[i].x - peaks.last.x).abs() > 20) {
          peaks.add(signal[i]);
        }
      }
    }

    if (peaks.length < 3) return _error("Buat minimal 3 lipatan tajam.");

    // 3. Analisis Sudut (Sharpness)
    // Kita cek kemiringan (slope) sebelum dan sesudah puncak.
    // Jika gergaji tajam, perubahan slope harus DRASTIS.
    double totalSharpness = 0;
    
    for (int i = 1; i < signal.length - 1; i++) {
       // Hitung turunan (perubahan Y per X)
       double slope1 = (signal[i].y - signal[i-1].y).toDouble();
       double slope2 = (signal[i+1].y - signal[i].y).toDouble();
       
       // Perubahan kemiringan mendadak = Tajam
       totalSharpness += (slope1 - slope2).abs();
    }
    
    double avgSharpness = totalSharpness / signal.length;
    // Gergaji butuh sharpness tinggi (> 0.5 rata-rata). Ombak biasanya < 0.2.
    double sharpnessScore = (avgSharpness * 150).clamp(0, 100);

    // Konsistensi Tinggi Puncak
    List<int> ys = peaks.map((p) => p.y).toList();
    double avgY = ys.reduce((a, b) => a + b) / ys.length;
    double varY = 0;
    for (var y in ys) varY += pow(y - avgY, 2);
    double stdDevY = sqrt(varY / ys.length);
    double heightScore = (100 - (stdDevY * 3.0)).clamp(0, 100);

    double finalScore = (sharpnessScore * 0.6) + (heightScore * 0.4);
    String feedback = "";

    if (sharpnessScore < 50) feedback = "Sudut terlalu tumpul/membulat. Buat lebih tajam!";
    else if (heightScore < 60) feedback = "Tinggi gergaji tidak rata.";
    else feedback = "Tajam dan konsisten! Bagus.";

    return AnalysisResult(
      overallScore: finalScore,
      verticalityScore: heightScore,
      spacingScore: 80,
      consistencyScore: finalScore,
      stabilityScore: sharpnessScore,
      feedback: feedback,
      linesToDraw: [signal],
    );
  }

  AnalysisResult _error(String msg) {
    return ProcessorUtils.createErrorResult(msg);
  }
}
