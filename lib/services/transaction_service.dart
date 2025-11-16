import 'package:hive/hive.dart';
import '../models/transaction.dart';

class TransactionService {
  static const String _boxName = 'transactions';
  Box<Transaction>? _box;

  // Singleton pattern
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  // Initialize Hive box
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<Transaction>(_boxName);
    }
  }

  // Add transaction
  Future<void> addTransaction(Transaction transaction) async {
    await init();
    await _box!.put(transaction.id, transaction);
  }

  // Get all transactions
  Future<List<Transaction>> getAllTransactions() async {
    await init();
    return _box!.values.toList();
  }

  // Get transactions by type
  Future<List<Transaction>> getTransactionsByType(TransactionType type) async {
    await init();
    return _box!.values.where((t) => t.type == type).toList();
  }

  // Get transactions by date range
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    await init();
    return _box!.values.where((t) {
      return t.date.isAfter(start.subtract(Duration(days: 1))) &&
          t.date.isBefore(end.add(Duration(days: 1)));
    }).toList();
  }

  // Get transactions for current month
  Future<List<Transaction>> getCurrentMonthTransactions() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return getTransactionsByDateRange(startOfMonth, endOfMonth);
  }

  // Update transaction
  Future<void> updateTransaction(Transaction transaction) async {
    await init();
    await _box!.put(transaction.id, transaction);
  }

  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    await init();
    await _box!.delete(id);
  }

  // Get total expense for current month
  Future<double> getCurrentMonthExpense() async {
    final transactions = await getCurrentMonthTransactions();
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  // Get total income for current month
  Future<double> getCurrentMonthIncome() async {
    final transactions = await getCurrentMonthTransactions();
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  // Clear all transactions (for testing)
  Future<void> clearAll() async {
    await init();
    await _box!.clear();
  }

  // Close box
  Future<void> close() async {
    await _box?.close();
  }
}
