import 'package:flutter/material.dart';
import 'package:stroke_sense/screens/home_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          // Gradient Biru Modern (Atas ke Bawah)
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2196F3), // Biru Terang (Material Blue)
              Color(0xFF0D47A1), // Biru Gelap
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. LOGO / ICON APLIKASI
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // Lingkaran transparan
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_note_rounded, // Ikon Pena/Kertas
                size: 100,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 30),

            // 2. JUDUL APLIKASI
            const Text(
              "StrokeSense",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
                fontFamily: 'Serif', // Opsional: Ganti font jika mau
              ),
            ),
            
            // 3. TAGLINE / SLOGAN
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Text(
                "Latih kestabilan tangan dan pikiran melalui terapi grafologi digital.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 60),

            // 4. TOMBOL UTAMA (MULAI)
            ElevatedButton(
              onPressed: () {
                // Pindah ke Menu Grid (HomeScreen)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0D47A1), // Warna Teks Biru
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5, // Efek bayangan
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Mulai Latihan",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward_rounded),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 5. TOMBOL SEKUNDER (RIWAYAT / INFO - Opsional)
            TextButton(
              onPressed: () {
                // Nanti bisa diarahkan ke halaman About atau History
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Fitur Riwayat segera hadir!")),
                );
              },
              child: const Text(
                "Riwayat Saya",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            
            const Spacer(), // Dorong version ke paling bawah

            // 6. VERSION FOOTER
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                "v1.0.0 Alpha",
                style: TextStyle(color: Colors.white30, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
