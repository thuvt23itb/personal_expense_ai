import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/receipt.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final documents = await getApplicationDocumentsDirectory();
    final dbPath = p.join(documents.path, 'expense_tracker.db');
    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE receipts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            merchant TEXT NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            category TEXT NOT NULL,
            imagePath TEXT,
            rawText TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_receipts_date ON receipts(date)');
      },
    );
    return _database!;
  }

  Future<List<Receipt>> getAllReceipts() async {
    final db = await database;
    final rows = await db.query('receipts', orderBy: 'date DESC, id DESC');
    return rows.map(Receipt.fromMap).toList();
  }

  Future<int> insertReceipt(Receipt receipt) async {
    final db = await database;
    final map = receipt.toMap()..remove('id');
    return db.insert('receipts', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateReceipt(Receipt receipt) async {
    if (receipt.id == null) throw ArgumentError('Receipt id is required for update');
    final db = await database;
    final map = receipt.toMap()..remove('id');
    return db.update('receipts', map, where: 'id = ?', whereArgs: [receipt.id]);
  }

  Future<int> deleteReceipt(int id) async {
    final db = await database;
    return db.delete('receipts', where: 'id = ?', whereArgs: [id]);
  }
}
