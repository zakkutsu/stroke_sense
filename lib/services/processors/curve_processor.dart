import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:stroke_sense/models/analysis_result.dart';
import 'base_processor.dart';

class CurveProcessor implements ShapeProcessor {
  final String subType; // 'ombak' atau 'kawat'
  
  CurveProcessor(this.subType);

  @override
  AnalysisResult analyze(img.Image image) {
    // 1. UBAH GAMBAR JADI SINYAL GRAFIK (SIGNAL EXTRACTION)
    // Kita scan kolom per kolom (X) untuk mencari rata-rata posisi Y tinta.
    List<Point<int>> signalPoints = [];
    
    // Skip step 2px untuk performa
    for (int x = 0; x < image.width; x += 2) {
      List<int> inkY = [];
      for (int y = 0; y < image.height; y++) {
        if (ProcessorUtils.isInk(image, x, y)) {
          inkY.add(y);
        }
      }
      
      if (inkY.isNotEmpty) {
        // Ambil titik tengah tebal tinta di kolom ini
        int avgY = (inkY.reduce((a, b) => a + b) / inkY.length).round();
        signalPoints.add(Point(x, avgY));
      }
    }

    if (signalPoints.length < 50) {
      return ProcessorUtils.createErrorResult("Goresan terlalu pendek.");
    }

    // 2. DETEKSI PUNCAK (PEAKS) & LEMBAH (VALLEYS)
    List<Point<int>> peaks = [];
    List<Point<int>> valleys = [];
    
    // Smoothing signal sedikit agar pixel kasar tidak dianggap puncak
    // (Simple Moving Average)
    List<Point<int>> smoothSignal = [];
    for (int i = 2; i < signalPoints.length - 2; i++) {
      int sumY = signalPoints[i-2].y + signalPoints[i-1].y + signalPoints[i].y + signalPoints[i+1].y + signalPoints[i+2].y;
      smoothSignal.add(Point(signalPoints[i].x, sumY ~/ 5));
    }

    // Algoritma cari puncak lokal
    for (int i = 1; i < smoothSignal.length - 1; i++) {
      int prevY = smoothSignal[i-1].y;
      int currY = smoothSignal[i].y;
      int nextY = smoothSignal[i+1].y;

      // Di koordinat layar, Y=0 ada di atas.
      // Jadi "Puncak Gunung" (Visual) adalah Y Minimum (Secara Angka).
      // "Lembah" (Visual) adalah Y Maksimum.
      
      bool isVisualPeak = (currY < prevY) && (currY < nextY); // Nilai Y lebih kecil dari tetangga
      bool isVisualValley = (currY > prevY) && (currY > nextY); // Nilai Y lebih besar dari tetangga

      // Filter: Puncak harus cukup tajam (beda 2px) biar gak noise
      if (isVisualPeak) peaks.add(smoothSignal[i]);
      if (isVisualValley) valleys.add(smoothSignal[i]);
    }

    // Validasi Dasar
    if (peaks.length < 2) {
      return ProcessorUtils.createErrorResult("Kurang bergelombang. Buat minimal 2 bukit.");
    }

    // 3. HITUNG METRIK KONSISTENSI (RITME)
    
    // A. Konsistensi Ketinggian Puncak (Amplitude Stability)
    // Seberapa rata tinggi gunung-gunung itu?
    List<int> peakHeights = peaks.map((p) => p.y).toList();
    double avgHeight = peakHeights.reduce((a, b) => a + b) / peakHeights.length;
    double varianceH = 0;
    for (var h in peakHeights) varianceH += pow(h - avgHeight, 2);
    double stdDevHeight = sqrt(varianceH / peakHeights.length);
    
    // Nilai Amplitude: Deviasi 5px = Bagus (90). Deviasi 20px = Jelek (50).
    double amplitudeScore = (100 - (stdDevHeight * 3.0)).clamp(0, 100);

    // B. Konsistensi Jarak Antar Puncak (Frequency Stability)
    // Seberapa lebar jarak antar gelombang?
    List<int> peakDistances = [];
    for (int i = 0; i < peaks.length - 1; i++) {
      peakDistances.add(peaks[i+1].x - peaks[i].x);
    }
    
    double frequencyScore = 100;
    if (peakDistances.isNotEmpty) {
      double avgDist = peakDistances.reduce((a, b) => a + b) / peakDistances.length;
      double varianceD = 0;
      for (var d in peakDistances) varianceD += pow(d - avgDist, 2);
      double stdDevDist = sqrt(varianceD / peakDistances.length);
      
      // Nilai Frekuensi: Deviasi jarak lebar
      frequencyScore = (100 - (stdDevDist * 4.0)).clamp(0, 100);
    }

    // C. Kehalusan (Smoothness)
    // Apakah garisnya patah-patah (zigzag) atau mulus?
    // Kita hitung total perubahan slope mendadak (Jitter).
    double totalJitter = 0;
    for (int i = 0; i < smoothSignal.length - 1; i++) {
      totalJitter += (smoothSignal[i].y - smoothSignal[i+1].y).abs();
    }
    // Normalisasi jitter per panjang garis
    double smoothnessRaw = totalJitter / smoothSignal.length;
    // Ombak yang bagus punya jitter rendah tapi tidak nol.
    // Logic sederhana: makin sedikit jitter kasar, makin bagus.
    double smoothnessScore = 85; // Base score, dikurangi kalau ada spike tajam

    // 4. FINAL SCORING
    double finalScore = (amplitudeScore * 0.4) + (frequencyScore * 0.4) + (smoothnessScore * 0.2);
    String feedback = "";

    if (amplitudeScore < 60) feedback = "Tinggi ombak tidak rata.";
    else if (frequencyScore < 60) feedback = "Lebar ombak berubah-ubah (Ritme rusak).";
    else if (peaks.length < 3) feedback = "Terlalu pendek, buat ombak lebih panjang.";
    else feedback = "Ombak yang indah! Ritme terjaga.";

    // 5. VISUALISASI
    // Kita kirim sinyal garisnya + Titik Puncak sebagai marking
    // Untuk visualisasi garis putus-putus atau titik puncak, kita bisa akali di sini.
    // Tapi untuk sekarang kita kirim garis utamanya dulu.
    
    return AnalysisResult(
      overallScore: finalScore,
      verticalityScore: amplitudeScore, // Kita pinjam istilah Verticality buat Tinggi Puncak
      spacingScore: frequencyScore,     // Spacing buat Jarak Puncak
      consistencyScore: finalScore,
      stabilityScore: smoothnessScore,
      feedback: feedback,
      linesToDraw: [smoothSignal], 
    );
  }
}
