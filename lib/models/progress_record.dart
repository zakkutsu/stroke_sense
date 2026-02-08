class ProgressRecord {
  final int? id; // Auto-increment ID dari database
  final String moduleId;
  final String moduleTitle;
  final double overallScore;
  final double verticalityScore;
  final double spacingScore;
  final double consistencyScore;
  final double stabilityScore;
  final String feedback;
  final DateTime timestamp;
  final String? imagePath; // Opsional: path ke foto hasil

  ProgressRecord({
    this.id,
    required this.moduleId,
    required this.moduleTitle,
    required this.overallScore,
    required this.verticalityScore,
    required this.spacingScore,
    required this.consistencyScore,
    required this.stabilityScore,
    required this.feedback,
    required this.timestamp,
    this.imagePath,
  });

  // Convert ke Map untuk simpan ke database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'moduleId': moduleId,
      'moduleTitle': moduleTitle,
      'overallScore': overallScore,
      'verticalityScore': verticalityScore,
      'spacingScore': spacingScore,
      'consistencyScore': consistencyScore,
      'stabilityScore': stabilityScore,
      'feedback': feedback,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'imagePath': imagePath,
    };
  }

  // Convert dari Map database
  factory ProgressRecord.fromMap(Map<String, dynamic> map) {
    return ProgressRecord(
      id: map['id'] as int?,
      moduleId: map['moduleId'] as String,
      moduleTitle: map['moduleTitle'] as String,
      overallScore: map['overallScore'] as double,
      verticalityScore: map['verticalityScore'] as double,
      spacingScore: map['spacingScore'] as double,
      consistencyScore: map['consistencyScore'] as double,
      stabilityScore: map['stabilityScore'] as double,
      feedback: map['feedback'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      imagePath: map['imagePath'] as String?,
    );
  }

  // Helper: Dapatkan warna berdasarkan skor
  String get scoreCategory {
    if (overallScore >= 80) return 'Excellent';
    if (overallScore >= 60) return 'Good';
    if (overallScore >= 40) return 'Fair';
    return 'Needs Practice';
  }
}
