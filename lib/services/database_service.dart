import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';

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

    return await openDatabase(path, version: 1, onCreate: _createDB);
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
      if (type == 'income') {
        income += amount;
      } else {
        expense += amount; // Assuming expense is stored as positive number in DB but treated logically
      }
    }

    return {
      'balance': income - expense,
      'income': income,
      'expense': expense,
    };
  }
}
