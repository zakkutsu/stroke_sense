import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:stroke_sense/models/progress_record.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  // Singleton: hanya ada satu instance database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('stroke_sense.db');
    return _database!;
  }

  // Inisialisasi Database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Buat Tabel
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE progress (
        id $idType,
        moduleId $textType,
        moduleTitle $textType,
        overallScore $realType,
        verticalityScore $realType,
        spacingScore $realType,
        consistencyScore $realType,
        stabilityScore $realType,
        feedback $textType,
        timestamp $intType,
        imagePath TEXT
      )
    ''');
  }

  // ==================== CRUD OPERATIONS ====================

  // CREATE: Simpan Progress Baru
  Future<ProgressRecord> saveProgress(ProgressRecord record) async {
    final db = await instance.database;
    final id = await db.insert('progress', record.toMap());
    return record.copyWith(id: id);
  }

  // READ: Ambil Semua Progress (Terbaru di Atas)
  Future<List<ProgressRecord>> getAllProgress() async {
    final db = await instance.database;
    final result = await db.query(
      'progress',
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => ProgressRecord.fromMap(map)).toList();
  }

  // READ: Ambil Progress per Modul
  Future<List<ProgressRecord>> getProgressByModule(String moduleId) async {
    final db = await instance.database;
    final result = await db.query(
      'progress',
      where: 'moduleId = ?',
      whereArgs: [moduleId],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => ProgressRecord.fromMap(map)).toList();
  }

  // READ: Ambil Latest N Records
  Future<List<ProgressRecord>> getLatestProgress(int limit) async {
    final db = await instance.database;
    final result = await db.query(
      'progress',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return result.map((map) => ProgressRecord.fromMap(map)).toList();
  }

  // STATISTICS: Rata-rata skor per modul
  Future<double> getAverageScore(String moduleId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT AVG(overallScore) as avg FROM progress WHERE moduleId = ?',
      [moduleId],
    );
    if (result.isNotEmpty && result.first['avg'] != null) {
      return result.first['avg'] as double;
    }
    return 0.0;
  }

  // STATISTICS: Jumlah total latihan
  Future<int> getTotalExerciseCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM progress');
    if (result.isNotEmpty) {
      return result.first['count'] as int;
    }
    return 0;
  }

  // STATISTICS: Best score untuk modul tertentu
  Future<double> getBestScore(String moduleId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT MAX(overallScore) as best FROM progress WHERE moduleId = ?',
      [moduleId],
    );
    if (result.isNotEmpty && result.first['best'] != null) {
      return result.first['best'] as double;
    }
    return 0.0;
  }

  // DELETE: Hapus satu record
  Future<int> deleteProgress(int id) async {
    final db = await instance.database;
    return await db.delete(
      'progress',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE: Hapus semua progress
  Future<int> deleteAllProgress() async {
    final db = await instance.database;
    return await db.delete('progress');
  }

  // CLOSE: Tutup database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

// Extension untuk copyWith (helper)
extension ProgressRecordCopyWith on ProgressRecord {
  ProgressRecord copyWith({
    int? id,
    String? moduleId,
    String? moduleTitle,
    double? overallScore,
    double? verticalityScore,
    double? spacingScore,
    double? consistencyScore,
    double? stabilityScore,
    String? feedback,
    DateTime? timestamp,
    String? imagePath,
  }) {
    return ProgressRecord(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      moduleTitle: moduleTitle ?? this.moduleTitle,
      overallScore: overallScore ?? this.overallScore,
      verticalityScore: verticalityScore ?? this.verticalityScore,
      spacingScore: spacingScore ?? this.spacingScore,
      consistencyScore: consistencyScore ?? this.consistencyScore,
      stabilityScore: stabilityScore ?? this.stabilityScore,
      feedback: feedback ?? this.feedback,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
