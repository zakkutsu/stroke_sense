import 'package:image/image.dart' as img;
import 'package:stroke_sense/models/analysis_result.dart';
import 'base_processor.dart';
import 'dart:math';

/// Processor khusus untuk analisis pola lengkungan/kurva
/// Digunakan untuk: Ombak (~~~~), Kawat (eeeee)
class CurveProcessor implements ShapeProcessor {
  @override
  AnalysisResult analyze(img.Image image) {
    // === STEP 1: Extract Wave Signal ===
    // Scan kolom per kolom, cari titik tengah Y tinta di setiap X
    List<double> signalY = [];
    
    for (int x = 0; x < image.width; x += 2) { // Skip 2px untuk performa
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

    if (signalY.length < 50) return ProcessorUtils.errorResult();

    // === STEP 2: Analisis Smoothness (Kehalusan) ===
    // Cek perubahan mendadak antar titik (Jitter Detection)
    double totalJitter = 0;
    for (int i = 0; i < signalY.length - 1; i++) {
      totalJitter += (signalY[i] - signalY[i + 1]).abs();
    }
    double avgJitter = totalJitter / signalY.length;
    
    // Smooth wave memiliki jitter kecil, gemetar = jitter besar
    double smoothnessScore = (100 - (avgJitter * 2)).clamp(0, 100);

    // === STEP 3: Peak Detection (Deteksi Puncak & Lembah) ===
    List<int> peakIndices = [];
    List<int> valleyIndices = [];
    
    for (int i = 1; i < signalY.length - 1; i++) {
      // Peak: Titik lebih tinggi dari kiri & kanan (Y kecil = atas)
      if (signalY[i] < signalY[i - 1] && signalY[i] < signalY[i + 1]) {
        peakIndices.add(i);
      }
      // Valley: Titik lebih rendah dari kiri & kanan (Y besar = bawah)
      if (signalY[i] > signalY[i - 1] && signalY[i] > signalY[i + 1]) {
        valleyIndices.add(i);
      }
    }

    int totalWaves = min(peakIndices.length, valleyIndices.length);

    // === STEP 4: Analisis Konsistensi Amplitudo (Tinggi Ombak) ===
    double amplitudeScore = 80; // Default
    if (peakIndices.length >= 2 && valleyIndices.length >= 2) {
      List<double> amplitudes = [];
      
      for (int i = 0; i < min(peakIndices.length, valleyIndices.length); i++) {
        double amp = (signalY[valleyIndices[i]] - signalY[peakIndices[i]]).abs();
        amplitudes.add(amp);
      }
      
      double stdDev = ProcessorUtils.standardDeviation(amplitudes);
      amplitudeScore = (100 - (stdDev * 0.5)).clamp(0, 100);
    }

    // === STEP 5: Analisis Konsistensi Frekuensi (Jarak Antar Ombak) ===
    double frequencyScore = 80; // Default
    if (peakIndices.length >= 3) {
      List<double> wavelengths = [];
      
      for (int i = 0; i < peakIndices.length - 1; i++) {
        double distance = (peakIndices[i + 1] - peakIndices[i]).toDouble();
        wavelengths.add(distance);
      }
      
      double stdDev = ProcessorUtils.standardDeviation(wavelengths);
      frequencyScore = (100 - (stdDev * 0.3)).clamp(0, 100);
    }

    // === SKOR FINAL ===
    double finalScore = 0;
    String feedback = "";

    if (totalWaves < 2) {
      finalScore = 30;
      feedback = "Tidak terdeteksi pola ombak. Pastikan ada minimal 2-3 gelombang.";
    } else {
      // Bobot: Smoothness 40%, Amplitude 30%, Frequency 30%
      finalScore = (smoothnessScore * 0.4) + (amplitudeScore * 0.3) + (frequencyScore * 0.3);
      finalScore = finalScore.clamp(0, 100);

      if (finalScore > 85) {
        feedback = "Sempurna! Ombak halus dan ritme terjaga dengan baik.";
      } else if (smoothnessScore < 60) {
        feedback = "Goresan terlihat gemetar. Relaks tangan dan gunakan gerakan dari pergelangan.";
      } else if (amplitudeScore < 60) {
        feedback = "Tinggi ombak tidak konsisten. Jaga amplitudo tetap sama.";
      } else if (frequencyScore < 60) {
        feedback = "Jarak antar ombak tidak konsisten. Pertahankan ritme yang stabil.";
      } else {
        feedback = "Ombak bagus, tingkatkan kehalusan gerakan.";
      }
    }

    return AnalysisResult(
      overallScore: finalScore,
      verticalityScore: 0, // Tidak relevan
      spacingScore: frequencyScore,
      consistencyScore: amplitudeScore,
      stabilityScore: smoothnessScore,
      feedback: feedback,
    );
  }
}
