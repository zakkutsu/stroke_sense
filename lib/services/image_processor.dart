import 'package:image/image.dart' as img;
import 'package:stroke_sense/models/analysis_result.dart';
// Import semua processor spesialis
import 'processors/base_processor.dart';
import 'processors/linear_processor.dart';
import 'processors/curve_processor.dart';
import 'processors/shape_processor.dart';
import 'processors/angle_processor.dart';

/// ImageProcessor: Router/Manager utama untuk analisis gambar
/// Tugasnya: Load gambar → Pilih processor yang tepat → Jalankan analisis
class ImageProcessor {
  
  /// Fungsi utama untuk menganalisis gambar tulisan tangan
  static Future<AnalysisResult> analyze(String imagePath, String moduleId) async {
    // === STEP 1: Load & Preprocessing ===
    final cmd = img.Command()
      ..decodeImageFile(imagePath)
      ..grayscale() // Convert ke hitam-putih
      ..adjustColor(contrast: 1.5); // Pertajam kontras tinta vs kertas
      
    await cmd.executeThread();
    img.Image? processedImage = cmd.outputImage;

    if (processedImage == null) {
      throw Exception("Gagal memproses gambar");
    }

    // Resize untuk performa (lebar 500px cukup untuk analisis)
    processedImage = img.copyResize(processedImage, width: 500);

    // === STEP 2: PILIH PROCESSOR (Strategy Pattern) ===
    ShapeProcessor processor;

    switch (moduleId) {
      // LEVEL 1: GARIS LURUS
      case 'pagar':
      case 'cakrawala':
      case 'hujan':
        processor = LinearProcessor(moduleId);
        break;
        
      // LEVEL 2: LENGKUNGAN
      case 'ombak':
      case 'kawat':
        processor = CurveProcessor();
        break;
        
      // LEVEL 3: BENTUK TERTUTUP
      case 'roda':
      case 'telur':
        processor = GeometricShapeProcessor();
        break;
        
      // LEVEL 4: SUDUT & PRESISI
      case 'gergaji':
      case 'rintik':
        processor = AngleProcessor(moduleId);
        break;
        
      default:
        // Fallback: gunakan linear processor
        processor = LinearProcessor('pagar');
    }

    // === STEP 3: JALANKAN ANALISIS ===
    return processor.analyze(processedImage);
  }
}
