import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/transaction.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  // Singleton pattern
  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'pocket_ledger.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        isPaid INTEGER NOT NULL
      )
    ''');
  }

  // CRUD operations for transactions

  // Create
  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read
  Future<List<Transaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions');
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  // Read transactions by type
  Future<List<Transaction>> getTransactionsByType(TransactionType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type.index],
    );
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  // Read transactions by month and year
  Future<List<Transaction>> getTransactionsByMonth(int month, int year) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  // Update
  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // Delete
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get total expenses for a month
  Future<double> getTotalExpensesForMonth(int month, int year) async {
    final transactions = await getTransactionsByMonth(month, year);
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Get total debts you owe for a month
  Future<double> getTotalDebtsYouOweForMonth(int month, int year) async {
    final transactions = await getTransactionsByMonth(month, year);
    return transactions
        .where((t) => t.type == TransactionType.debtYouOwe && !t.isPaid)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Get total debts owed to you for a month
  Future<double> getTotalDebtsOwedToYouForMonth(int month, int year) async {
    final transactions = await getTransactionsByMonth(month, year);
    return transactions
        .where((t) => t.type == TransactionType.debtOwedToYou && !t.isPaid)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Get net balance for a month
  Future<double> getNetBalanceForMonth(int month, int year) async {
    final totalExpenses = await getTotalExpensesForMonth(month, year);
    final totalDebtsYouOwe = await getTotalDebtsYouOweForMonth(month, year);
    final totalDebtsOwedToYou = await getTotalDebtsOwedToYouForMonth(month, year);
    return totalDebtsOwedToYou - totalDebtsYouOwe - totalExpenses;
  }
}