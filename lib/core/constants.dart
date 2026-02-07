class AppConstants {
  static const String appName = "StrokeSense";
  static const String errorNoCamera = "Kamera tidak ditemukan";
  static const String errorAnalysis = "Gagal menganalisis gambar";
  
  // Nilai batas toleransi (bisa diubah-ubah di sini buat tuning akurasi)
  static const double thresholdInkDarkness = 100.0;
  static const double minLineScore = 60.0;
}
