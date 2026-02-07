import 'package:flutter/material.dart';

class GlobalHelpSheet extends StatelessWidget {
  const GlobalHelpSheet({super.key});

  // Method statis agar mudah dipanggil dari mana saja tanpa new instance manual
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const GlobalHelpSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7, // Tinggi awal 70%
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          controller: controller,
          children: [
            // Garis handle di atas untuk swipe
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // JUDUL
            const Text(
              "Panduan StrokeSense",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Cara menggunakan aplikasi:",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // LANGKAH-LANGKAH
            _buildHelpItem(Icons.camera_alt, "Langkah 1",
                "Pilih modul latihan, lalu arahkan kamera ke kertas tulisan Anda."),
            _buildHelpItem(Icons.grid_on, "Langkah 2",
                "Pastikan kertas rata. Gunakan garis bantu di layar agar foto tidak miring."),
            _buildHelpItem(Icons.analytics, "Langkah 3",
                "Sistem akan menilai ketegakan, jarak, dan kestabilan goresan Anda."),

            const Divider(height: 40),

            // TIPS
            const Text(
              "Tips Goresan yang Baik",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildTipItem("• Gunakan pena tinta hitam di atas kertas putih/bergaris."),
            _buildTipItem("• Jangan ragu saat menarik garis. Goresan cepat lebih stabil."),
            _buildTipItem("• Untuk 'Pagar', jaga sudut tetap 90 derajat."),
            _buildTipItem("• Untuk 'Ombak', jaga ritme dan lebar gelombang."),

            const SizedBox(height: 40),
            
            // TOMBOL TUTUP
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("Saya Paham"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget kecil (Helper) tetap di dalam sini agar file ini mandiri
  Widget _buildHelpItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(child: Icon(icon, size: 20)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(desc, style: const TextStyle(height: 1.3)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4)),
    );
  }
}