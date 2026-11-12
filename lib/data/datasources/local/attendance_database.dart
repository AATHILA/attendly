import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/attendance_model.dart';

class AttendanceDatabase {
  static final AttendanceDatabase instance = AttendanceDatabase._init();
  static Database? _database;

  AttendanceDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableAttendance} (
        id TEXT PRIMARY KEY,
        employeeId TEXT NOT NULL,
        employeeName TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        isSynced INTEGER NOT NULL,
        sessionId TEXT
      )
    ''');
  }

  /// Insert an attendance record
  Future<void> insertRecord(AttendanceModel record) async {
    final db = await database;
    await db.insert(
      AppConstants.tableAttendance,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve attendance history for an individual employee (Sorted latest first)
  Future<List<AttendanceModel>> getEmployeeRecords(String employeeId) async {
    final db = await database;
    final result = await db.query(
      AppConstants.tableAttendance,
      where: 'employeeId = ?',
      whereArgs: [employeeId],
      orderBy: 'timestamp DESC',
    );

    return result.map((map) => AttendanceModel.fromMap(map)).toList();
  }

  /// Retrieve all attendance records (For Admin Dashboard)
  Future<List<AttendanceModel>> getAllRecords() async {
    final db = await database;
    final result = await db.query(
      AppConstants.tableAttendance,
      orderBy: 'timestamp DESC',
    );

    return result.map((map) => AttendanceModel.fromMap(map)).toList();
  }

  /// Check if employee has already checked in today (Prevents duplicate check-ins)
  Future<bool> hasCheckedInToday(String employeeId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10); // 'YYYY-MM-DD'

    final result = await db.query(
      AppConstants.tableAttendance,
      where: 'employeeId = ? AND type = ? AND timestamp LIKE ?',
      whereArgs: [employeeId, 'CHECK_IN', '$today%'],
    );

    return result.isNotEmpty;
  }

  /// Check if employee has already checked out today (Prevents duplicate check-outs)
  Future<bool> hasCheckedOutToday(String employeeId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10); // 'YYYY-MM-DD'

    final result = await db.query(
      AppConstants.tableAttendance,
      where: 'employeeId = ? AND type = ? AND timestamp LIKE ?',
      whereArgs: [employeeId, 'CHECK_OUT', '$today%'],
    );

    return result.isNotEmpty;
  }

  /// Get pending offline records that need to be synced
  Future<List<AttendanceModel>> getUnsyncedRecords() async {
    final db = await database;
    final result = await db.query(
      AppConstants.tableAttendance,
      where: 'isSynced = ?',
      whereArgs: [0],
    );

    return result.map((map) => AttendanceModel.fromMap(map)).toList();
  }

  /// Mark records as synced after successful network sync
  Future<void> markRecordsAsSynced(List<String> recordIds) async {
    if (recordIds.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(recordIds.length, '?').join(',');

    await db.rawUpdate(
      'UPDATE ${AppConstants.tableAttendance} SET isSynced = 1 WHERE id IN ($placeholders)',
      recordIds,
    );
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}