import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/notification_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transactions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
CREATE TABLE notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL,
  isRead INTEGER NOT NULL,
  createdAt TEXT NOT NULL
)
''');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE transactions (
  id $idType,
  title $textType,
  amount $doubleType,
  date $textType,
  type $textType,
  category $textType
)
''');

    await db.execute('''
CREATE TABLE notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL,
  isRead INTEGER NOT NULL,
  createdAt TEXT NOT NULL
)
''');
  }

  Future<TransactionModel> create(TransactionModel transaction) async {
    final db = await instance.database;
    final id = await db.insert('transactions', transaction.toMap());
    return TransactionModel(
      id: id,
      title: transaction.title,
      amount: transaction.amount,
      date: transaction.date,
      type: transaction.type,
      category: transaction.category,
    );
  }

  Future<List<TransactionModel>> readAllTransactions() async {
    final db = await instance.database;
    final orderBy = 'date DESC';
    final result = await db.query('transactions', orderBy: orderBy);

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Get Summary (Total Balance, Income, Expense)
  Future<Map<String, double>> getSummary() async {
    final db = await instance.database;
    final result = await db.query('transactions');
    
    double income = 0;
    double expense = 0;

    for (var row in result) {
      final amount = row['amount'] as double;
      final type = row['type'] as String;
      if (type == 'income' || type == 'loan_taken') {
        income += amount;
      } else {
        expense += amount;
      }
    }

    return {
      'balance': income - expense,
      'income': income,
      'expense': expense,
    };
  }
  // Get Transactions for a specific month
  Future<List<TransactionModel>> getTransactionsForMonth(int year, int month) async {
    final db = await instance.database;
    final start = DateTime(year, month, 1).toIso8601String();
    // Calculate end date: 1st of next month
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final end = DateTime(nextYear, nextMonth, 1).toIso8601String();

    final orderBy = 'date DESC';
    // Query dates >= start AND date < end
    final result = await db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [start, end],
      orderBy: orderBy,
    );

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  // Get Summary (Total Balance, Income, Expense) for a specific month
  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final db = await instance.database;
    
    final start = DateTime(year, month, 1).toIso8601String();
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final end = DateTime(nextYear, nextMonth, 1).toIso8601String();

    final result = await db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [start, end],
    );
    
    double income = 0;
    double expense = 0;

    for (var row in result) {
      final amount = row['amount'] as double;
      final type = row['type'] as String;
      if (type == 'income' || type == 'loan_taken') {
        income += amount;
      } else {
        expense += amount;
      }
    }

    return {
      'balance': income - expense,
      'income': income,
      'expense': expense,
    };
  }

  // ========== NOTIFICATION METHODS ==========
  
  Future<NotificationModel> createNotification(NotificationModel notification) async {
    final db = await instance.database;
    final id = await db.insert('notifications', notification.toMap());
    return NotificationModel(
      id: id,
      title: notification.title,
      message: notification.message,
      type: notification.type,
      isRead: notification.isRead,
      createdAt: notification.createdAt,
    );
  }

  Future<List<NotificationModel>> readAllNotifications() async {
    final db = await instance.database;
    final result = await db.query('notifications', orderBy: 'createdAt DESC');
    return result.map((json) => NotificationModel.fromMap(json)).toList();
  }

  Future<int> getUnreadNotificationCount() async {
    final db = await instance.database;
    final result = await db.query(
      'notifications',
      where: 'isRead = ?',
      whereArgs: [0],
    );
    return result.length;
  }

  Future<int> markNotificationAsRead(int id) async {
    final db = await instance.database;
    return await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteNotification(int id) async {
    final db = await instance.database;
    return await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
