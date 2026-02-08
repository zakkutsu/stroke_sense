import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:stroke_sense/models/analysis_result.dart';
import 'base_processor.dart';

class LinearProcessor implements ShapeProcessor {
  final String subType; // 'pagar', 'cakrawala', 'hujan'
  
  LinearProcessor(this.subType);

  @override
  AnalysisResult analyze(img.Image image) {
    // ROUTING OTOMATIS BERDASARKAN TIPE
    if (subType == 'cakrawala') {
      return _analyzeHorizontal(image); // Scan Kiri-Kanan
    } else {
      return _analyzeVertical(image);   // Scan Atas-Bawah (Pagar/Hujan)
    }
  }

  // ==========================================
  // 1. LOGIKA VERTIKAL (PAGAR / HUJAN)
  // ==========================================
  AnalysisResult _analyzeVertical(img.Image image) {
    int totalSlices = 20; 
    int height = image.height;
    int startY = (height * 0.10).toInt();
    int endY = (height * 0.90).toInt();
    int stepY = (endY - startY) ~/ totalSlices;

    Map<int, List<int>> linesData = {}; 
    
    // --- SCANNING ---
    for (int i = 0; i <= totalSlices; i++) {
      int currentY = startY + (i * stepY);
      List<int> inkBlobsX = ProcessorUtils.findInkX(image, currentY); // Cari X di baris Y
      
      if (inkBlobsX.isEmpty) continue;
      _clusterPoints(linesData, inkBlobsX); // Kelompokkan titik
    }

    // --- SCORING & VISUALIZATION ---
    return _calculateScore(linesData, totalSlices, isVertical: true, rangeStart: startY, rangeEnd: endY);
  }

  // ==========================================
  // 2. LOGIKA HORIZONTAL (CAKRAWALA) - BARU!
  // ==========================================
  AnalysisResult _analyzeHorizontal(img.Image image) {
    int totalSlices = 20; 
    int width = image.width;
    
    // Kita scan dari Kiri (10%) ke Kanan (90%)
    int startX = (width * 0.10).toInt();
    int endX = (width * 0.90).toInt();
    int stepX = (endX - startX) ~/ totalSlices;

    Map<int, List<int>> linesData = {}; 

    // --- SCANNING (KIRI KE KANAN) ---
    for (int i = 0; i <= totalSlices; i++) {
      int currentX = startX + (i * stepX);
      
      // LOGIKA TERBALIK: Cari posisi Y tinta pada kolom X tertentu
      List<int> inkBlobsY = _findInkY(image, currentX); 
      
      if (inkBlobsY.isEmpty) continue;
      _clusterPoints(linesData, inkBlobsY);
    }

    // --- SCORING ---
    return _calculateScore(linesData, totalSlices, isVertical: false, rangeStart: startX, rangeEnd: endX);
  }

  // ==========================================
  // 3. HELPER FUNCTIONS (OTAK HITUNGAN)
  // ==========================================

  // Fungsi khusus cari Y (untuk Cakrawala) - Kebalikan dari findInkX
  List<int> _findInkY(img.Image image, int x) {
    List<int> positions = [];
    bool insideLine = false;
    int startY = 0;
    
    for (int y = 0; y < image.height; y++) {
      if (ProcessorUtils.isInk(image, x, y)) {
        if (!insideLine) { insideLine = true; startY = y; }
      } else {
        if (insideLine) {
          positions.add((startY + y) ~/ 2);
          insideLine = false;
        }
      }
    }
    return positions;
  }

  void _clusterPoints(Map<int, List<int>> linesData, List<int> newPoints) {
    if (linesData.isEmpty) {
      for (int k = 0; k < newPoints.length; k++) {
        linesData[k] = [newPoints[k]];
      }
    } else {
      for (int newVal in newPoints) {
        int bestLineIdx = -1;
        int minDistance = 1000;
        linesData.forEach((idx, valList) {
          if (valList.isNotEmpty) {
            int dist = (newVal - valList.last).abs();
            if (dist < 40 && dist < minDistance) { // Toleransi jarak
              minDistance = dist;
              bestLineIdx = idx;
            }
          }
        });
        if (bestLineIdx != -1) linesData[bestLineIdx]!.add(newVal);
      }
    }
  }

  AnalysisResult _calculateScore(Map<int, List<int>> linesData, int totalSlices, {required bool isVertical, required int rangeStart, required int rangeEnd}) {
    // Hapus noise - turunkan threshold dari 50% ke 30% agar lebih permisif
    linesData.removeWhere((key, points) => points.length < (totalSlices * 0.3));
    if (linesData.isEmpty) return ProcessorUtils.createErrorResult("Garis tidak terdeteksi. Gunakan tinta lebih gelap atau kertas lebih terang.");

    double totalStraightnessError = 0;
    double totalSlantError = 0;
    List<double> lineCentroids = [];

    // DATA UNTUK VISUALISASI (GARIS MERAH/HIJAU)
    List<List<Point<int>>> visualLines = [];

    linesData.forEach((idx, points) {
      // 1. Hitung Garis Ideal (Regresi)
      double startP = points.first.toDouble();
      double endP = points.last.toDouble();
      double sumDev = 0;
      
      for (int i = 0; i < points.length; i++) {
        double ideal = startP + ((endP - startP) * (i / points.length));
        sumDev += (points[i] - ideal).abs();
      }
      totalStraightnessError += (sumDev / points.length);
      totalSlantError += (startP - endP).abs();
      lineCentroids.add(points.reduce((a, b) => a + b) / points.length);

      // 2. Susun Garis Visual
      List<Point<int>> singleLine = [];
      double stepPerPoint = (rangeEnd - rangeStart) / (points.length + 1);
      
      for (int i = 0; i < points.length; i++) {
        int val = points[i]; // Ini bisa X atau Y tergantung mode
        int axisPos = (rangeStart + (i * stepPerPoint)).toInt();
        
        if (isVertical) {
          singleLine.add(Point(val, axisPos)); // Pagar: val=X, axis=Y
        } else {
          singleLine.add(Point(axisPos, val)); // Cakrawala: axis=X, val=Y
        }
      }
      visualLines.add(singleLine);
    });

    int count = linesData.length;
    double avgStraight = count > 0 ? totalStraightnessError / count : 0;
    double avgSlant = count > 0 ? totalSlantError / count : 0;

    // --- SCORING FORMULA ---
    double stabilityScore = (100 - (avgStraight * 15.0)).clamp(0, 100);
    // Untuk Cakrawala, Slant berarti miring ke atas/bawah
    double verticalityScore = (100 - (avgSlant * 2.5)).clamp(0, 100); 

    // SPACING SCORE
    double spacingScore = 100;
    if (lineCentroids.length > 1) {
      lineCentroids.sort();
      List<double> gaps = [];
      for (int i = 0; i < lineCentroids.length - 1; i++) {
        gaps.add(lineCentroids[i+1] - lineCentroids[i]);
      }
      double avgGap = gaps.reduce((a, b) => a + b) / gaps.length;
      double variance = 0;
      for (var g in gaps) {
        variance += pow(g - avgGap, 2);
      }
      double stdDev = sqrt(variance / gaps.length);
      spacingScore = (100 - (stdDev * 6.0)).clamp(0, 100);
    }

    // FINAL FEEDBACK
    double finalScore = (stabilityScore * 0.5) + (verticalityScore * 0.3) + (spacingScore * 0.2);
    String feedback = "";

    if (stabilityScore < 50) {
      feedback = "Garis Bengkok/Melengkung. Tarik lebih cepat.";
    } else if (verticalityScore < 60) {
      feedback = isVertical ? "Garis Miring." : "Garis tidak rata air (menanjak/menurun).";
    } else if (spacingScore < 60) {
      feedback = "Jarak spasi tidak konsisten.";
    } else {
      feedback = "Sempurna! Sangat stabil.";
    }

    return AnalysisResult(
      overallScore: finalScore,
      verticalityScore: verticalityScore,
      spacingScore: spacingScore,
      consistencyScore: stabilityScore,
      stabilityScore: stabilityScore,
      feedback: feedback,
      linesToDraw: visualLines,
    );
  }
}
