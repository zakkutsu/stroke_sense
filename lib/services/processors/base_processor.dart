import 'package:image/image.dart' as img;
import 'package:stroke_sense/models/analysis_result.dart';
import 'dart:math';

/// Interface: Kontrak bahwa semua processor WAJIB punya fungsi analyze
abstract class ShapeProcessor {
  AnalysisResult analyze(img.Image image);
}

/// Utilities: Fungsi bantuan yang bisa dipakai oleh semua processor
class ProcessorUtils {
  /// Deteksi apakah pixel ini tinta (gelap)
  /// Threshold: luminance < 150 = tinta hitam
  /// NAIK dari 100 ke 150 untuk support kertas abu-abu/tidak putih sempurna
  static bool isInk(img.Image image, int x, int y) {
    return image.getPixel(x, y).luminance < 150;
  }

  /// Cari posisi X tengah dari garis tinta di baris Y tertentu
  /// Return: List posisi X di mana ditemukan garis vertikal
  static List<int> findInkX(img.Image image, int y) {
    List<int> positions = [];
    bool insideLine = false;
    int startX = 0;
    
    for (int x = 0; x < image.width; x++) {
      if (isInk(image, x, y)) {
        if (!insideLine) {
          insideLine = true;
          startX = x;
        }
      } else {
        if (insideLine) {
          // Simpan titik tengah garis (rata-rata start dan end)
          positions.add((startX + x) ~/ 2);
          insideLine = false;
        }
      }
    }
    return positions;
  }

  /// Hitung rata-rata dari list angka
  static double average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Hitung standar deviasi (ukuran variasi data)
  static double standardDeviation(List<double> values) {
    if (values.isEmpty) return 0;
    double avg = average(values);
    double variance = values.map((v) => pow(v - avg, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  /// Generate result error default
  static AnalysisResult errorResult() {
    return AnalysisResult(
      overallScore: 0,
      verticalityScore: 0,
      spacingScore: 0,
      consistencyScore: 0,
      stabilityScore: 0,
      feedback: "Gagal mendeteksi goresan. Gunakan tinta gelap di kertas terang.",
    );
  }

  /// Generate result error dengan custom message
  static AnalysisResult createErrorResult(String message) {
    return AnalysisResult(
      overallScore: 0,
      verticalityScore: 0,
      spacingScore: 0,
      consistencyScore: 0,
      stabilityScore: 0,
      feedback: message,
    );
  }
}
