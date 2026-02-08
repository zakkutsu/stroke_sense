import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:stroke_sense/models/analysis_result.dart';
import 'base_processor.dart';

/// Processor khusus untuk analisis bentuk tertutup (lingkaran/oval)
/// Digunakan untuk: Roda (OOOO), Telur (0000)
/// Menggunakan Algoritma "Radar 360°"
class GeometricShapeProcessor implements ShapeProcessor {
  final String subType; // 'roda' atau 'telur'
  
  GeometricShapeProcessor({this.subType = 'roda'});

  @override
  AnalysisResult analyze(img.Image image) {
    // 1. CARI SEMUA PIXEL TINTA & TITIK PUSAT (CENTROID)
    int sumX = 0, sumY = 0;
    List<Point<int>> inkPixels = [];

    // Kita scan seluruh gambar (skip 2px biar cepat tapi tetap akurat)
    for (int y = 0; y < image.height; y += 2) {
      for (int x = 0; x < image.width; x += 2) {
        if (ProcessorUtils.isInk(image, x, y)) {
          sumX += x;
          sumY += y;
          inkPixels.add(Point(x, y));
        }
      }
    }

    // Validasi: Kalau tinta terlalu sedikit, anggap kosong
    if (inkPixels.length < 100) {
      return ProcessorUtils.createErrorResult("Bentuk tidak terlihat jelas.");
    }

    // Koordinat Pusat Gravitasi (Centroid)
    double centerX = sumX / inkPixels.length;
    double centerY = sumY / inkPixels.length;

    // 2. HITUNG JARI-JARI (RADIUS) & SUDUT (ANGLE) UNTUK SETIAP TITIK
    List<double> radii = [];
    double totalRadius = 0;
    
    // Kita butuh data pixel yang 'diurutkan' berdasarkan sudut agar visualisasinya nyambung
    // Map<Sudut, Point>
    List<_PolarPoint> polarPoints = [];

    for (var p in inkPixels) {
      double dx = p.x - centerX;
      double dy = p.y - centerY;
      
      // Jarak ke pusat (Pythagoras)
      double r = sqrt((dx * dx) + (dy * dy));
      
      // Sudut (Atan2 returns -PI to +PI)
      double angle = atan2(dy, dx); 

      radii.add(r);
      totalRadius += r;
      polarPoints.add(_PolarPoint(p, angle, r));
    }

    double avgRadius = totalRadius / radii.length;

    // 3. HITUNG TINGKAT "KEBULATAN" (ROUNDNESS)
    // Menggunakan Standar Deviasi Jari-jari.
    // Lingkaran sempurna: Deviasi 0 (semua jari-jari sama).
    double sumVariance = 0;
    for (var r in radii) {
      sumVariance += pow(r - avgRadius, 2);
    }
    double stdDev = sqrt(sumVariance / radii.length);

    // Rasio Deviasi terhadap Radius (Coefficient of Variation)
    // Biar lingkaran besar dan kecil dinilai adil.
    double cv = (stdDev / avgRadius) * 100; 

    // 4. CEK KELENGKAPAN (CLOSURE)
    // Apakah lingkarannya putus (seperti huruf C)?
    // Kita cek apakah ada "bucket" sudut yang kosong.
    // Kita bagi 360 derajat jadi 36 sektor (per 10 derajat).
    Set<int> filledSectors = {};
    for (var pp in polarPoints) {
      // Normalisasi sudut -PI..PI ke 0..360
      double deg = (pp.angle * 180 / pi);
      if (deg < 0) deg += 360;
      int sector = (deg / 10).floor(); // 0 sampai 35
      filledSectors.add(sector);
    }
    int gapCount = 36 - filledSectors.length; // Berapa sektor yang bolong?

    // 5. SCORING FORMULA
    
    // Skor Kebulatan (Roundness)
    // CV < 5% = Bagus (Skor 100). CV > 20% = Jelek (Skor 40).
    double roundnessScore = (100 - ((cv - 5) * 4.0)).clamp(0, 100);
    if (cv <= 5) roundnessScore = 100;

    // Skor Penutupan (Closure)
    // Tiap sektor bolong (10 derajat) mengurangi nilai drastis
    double closureScore = (100 - (gapCount * 15.0)).clamp(0, 100);

    // Skor Akhir
    double finalScore = 0;
    String feedback = "";

    if (subType == 'roda') {
      // Roda harus BULAT dan TERTUTUP
      finalScore = (roundnessScore * 0.7) + (closureScore * 0.3);
      
      if (closureScore < 80) {
        feedback = "Lingkaran terputus/tidak nyambung.";
      } else if (roundnessScore < 60) {
        feedback = "Bentuk lonjong/penyok. Jaga jarak ke pusat tetap sama.";
      } else if (roundnessScore < 85) {
        feedback = "Cukup bulat, tapi masih sedikit tidak rata.";
      } else {
        feedback = "Luar biasa! Lingkaran sempurna.";
      }
    } else if (subType == 'telur') {
      // Telur MEMANG harus lonjong. Jadi kalau bulat sempurna malah salah.
      // Kita targetkan CV sekitar 10-15% (oval).
      double ovalDiff = (cv - 12).abs(); // Seberapa jauh dari "kelonjongan ideal"
      finalScore = (100 - (ovalDiff * 5)).clamp(0, 100);
      
      if (cv < 8) {
        feedback = "Terlalu bulat. Telur harus lonjong.";
      } else if (cv > 20) {
        feedback = "Bentuk terlalu pipih/rusak.";
      } else {
        feedback = "Bentuk oval yang bagus.";
      }
    } else {
      // Default for other shapes
      finalScore = (roundnessScore * 0.7) + (closureScore * 0.3);
      feedback = "Bentuk terdeteksi.";
    }

    // 6. PERSIAPAN VISUALISASI (AGAR GARIS MERAH/HIJAU NYAMBUNG)
    // Urutkan titik berdasarkan sudutnya (-180 sampai +180)
    polarPoints.sort((a, b) => a.angle.compareTo(b.angle));

    // Convert balik ke List<Point> untuk dikirim ke UI
    List<Point<int>> visualLine = polarPoints.map((e) => e.point).toList();

    // Tutup loop visualisasi (sambungkan titik akhir ke awal)
    if (visualLine.isNotEmpty && closureScore > 80) {
      visualLine.add(visualLine.first);
    }

    return AnalysisResult(
      overallScore: finalScore,
      verticalityScore: 0, // Tidak relevan buat lingkaran
      spacingScore: closureScore, // Kita pinjam field ini buat Closure
      consistencyScore: roundnessScore, 
      stabilityScore: roundnessScore,
      feedback: feedback,
      linesToDraw: [visualLine], // Kirim sebagai 1 garis panjang melingkar
    );
  }
}

// Class bantuan kecil untuk sorting
class _PolarPoint {
  final Point<int> point;
  final double angle;
  final double dist;
  _PolarPoint(this.point, this.angle, this.dist);
}
