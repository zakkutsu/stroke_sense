import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Untuk cek platform
import 'package:stroke_sense/main.dart'; // Untuk ambil variable 'cameras'
import 'package:stroke_sense/models/exercise_module.dart';
import 'package:stroke_sense/widgets/global_help_sheet.dart'; // Reuse help widget
import 'package:stroke_sense/screens/result_screen.dart'; // Import layar hasil
import 'package:stroke_sense/models/analysis_result.dart'; // Import model hasil
import 'package:stroke_sense/services/image_processor.dart'; // Import image processor
import 'dart:math'; // Untuk random skor sementara (demo web)

class CameraScreen extends StatefulWidget {
  final ExerciseModule module;

  const CameraScreen({super.key, required this.module});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    // Hanya inisialisasi kamera jika BUKAN di web
    if (!kIsWeb) {
      _initializeCamera();
    }
  }

  // Fungsi untuk menyalakan kamera
  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) return; // Cegah error jika tidak ada kamera (emulator)

    // Pilih kamera belakang (biasanya index 0)
    final camera = cameras.first;
    
    _controller = CameraController(
      camera,
      ResolutionPreset.high, // Resolusi tinggi untuk deteksi tulisan
      enableAudio: false, // Kita tidak butuh audio
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print("Camera error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose(); // Wajib dimatikan agar tidak boros baterai
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // CEK JIKA RUNNING DI WEB BROWSER
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(widget.module.title),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.smartphone,
                  size: 100,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 30),
                const Text(
                  '📱 Fitur Kamera Hanya untuk Mobile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Aplikasi StrokeSense dirancang untuk digunakan di HP/Tablet fisik agar bisa memfoto tulisan tangan Anda.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Cara Menjalankan di HP:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildWebInstruction('1. Colokkan HP ke PC dengan kabel USB'),
                      _buildWebInstruction('2. Aktifkan USB Debugging di HP'),
                      _buildWebInstruction('3. Di terminal ketik: flutter run'),
                      _buildWebInstruction('4. Pilih device HP Anda'),
                      const SizedBox(height: 20),
                      // TOMBOL DEMO UNTUK WEB
                      ElevatedButton.icon(
                        onPressed: () {
                          // Simulasi hasil untuk demo di web
                          final random = Random();
                          final dummyResult = AnalysisResult(
                            overallScore: 70 + random.nextInt(25).toDouble(),
                            verticalityScore: 60 + random.nextInt(40).toDouble(),
                            spacingScore: 60 + random.nextInt(40).toDouble(),
                            consistencyScore: 60 + random.nextInt(40).toDouble(),
                            stabilityScore: 60 + random.nextInt(40).toDouble(),
                            feedback: "Goresan sudah cukup tegas, namun perhatikan jarak antar garis agar lebih konsisten.",
                          );
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResultScreen(
                                imagePath: '', // Web tidak butuh path
                                module: widget.module,
                                result: dummyResult,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.preview),
                        label: const Text('Demo Result Screen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali ke Home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // KODE CAMERA UNTUK MOBILE (Original)
    // Jika kamera belum siap/rusak, tampilkan loading hitam
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. LAYER KAMERA (Paling Belakang)
          CameraPreview(_controller!),

          // 2. LAYER OVERLAY / GARIS BANTU (Tengah)
          // Ini fitur canggihnya: Garis berubah sesuai modul
          CustomPaint(
            painter: GuideOverlayPainter(module: widget.module),
            child: Container(),
          ),

          // 3. LAYER UI & TOMBOL (Paling Depan)
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header Atas
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tombol Back transparan
                      CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      // Judul Modul
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.module.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Tombol Bantuan Reuse
                      CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.help_outline, color: Colors.white),
                          onPressed: () => GlobalHelpSheet.show(context),
                        ),
                      ),
                    ],
                  ),
                ),

                // Footer Bawah (Tombol Jepret)
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        // 1. Ambil Gambar
                        final image = await _controller!.takePicture();
                        
                        if (!mounted) return;

                        // 2. Tampilkan Loading (Dialog)
                        showDialog(
                          context: context,
                          barrierDismissible: false, // Tidak bisa ditutup user
                          builder: (context) => const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 15),
                                Text("Sedang Menganalisis Goresan...", style: TextStyle(color: Colors.white))
                              ],
                            ),
                          ),
                        );

                        // 3. PROSES ANALISIS REAL (BUKAN DUMMY LAGI)
                        // Jalankan ImageProcessor di background
                        AnalysisResult result = await ImageProcessor.analyze(image.path, widget.module.id);

                        if (!mounted) return;
                        Navigator.pop(context); // Tutup Loading

                        // 4. Pindah ke Layar Hasil
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResultScreen(
                              imagePath: image.path,
                              module: widget.module,
                              result: result,
                            ),
                          ),
                        );

                      } catch (e) {
                        print("Error analyzing: $e");
                        if(mounted) {
                          Navigator.pop(context); // Tutup loading
                          // Tampilkan pesan error ke user
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Gagal menganalisis: ${e.toString()}")),
                          );
                        }
                      }
                    },
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.transparent,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget untuk instruksi web
  Widget _buildWebInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// --- CLASS PELUKIS GARIS BANTU (CUSTOM PAINTER) ---
class GuideOverlayPainter extends CustomPainter {
  final ExerciseModule module;
  GuideOverlayPainter({required this.module});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3) // Garis transparan (Ghost)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Logika Menggambar sesuai Kategori Modul
    if (module.id == 'pagar') {
      // Gambar Garis Vertikal
      double step = size.width / 8; // Bagi layar jadi 8 kolom
      for (double x = step; x < size.width; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    } else if (module.id == 'cakrawala') {
      // Gambar Garis Horizontal
      double step = size.height / 10; // Bagi layar jadi 10 baris
      for (double y = step; y < size.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (module.id == 'roda' || module.id == 'telur') {
      // Gambar Kotak/Lingkaran di tengah
      final center = Offset(size.width / 2, size.height / 2);
      canvas.drawCircle(center, size.width * 0.3, paint);
    } else if (module.id == 'hujan') {
      // Gambar Garis Miring (Diagonal)
       double step = size.width / 5;
       for (double i = -size.width; i < size.width * 2; i += step) {
         canvas.drawLine(Offset(i, 0), Offset(i + size.height * 0.5, size.height), paint);
       }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}