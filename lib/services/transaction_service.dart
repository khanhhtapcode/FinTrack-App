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

  // Get all transactions for a specific user
  Future<List<Transaction>> getAllTransactions({String? userId}) async {
    await init();
    if (userId == null || userId.isEmpty) {
      return []; // Không có user ID = không có transactions
    }
    return _box!.values.where((t) => t.userId == userId).toList();
  }

  // Get transactions by type for a specific user
  Future<List<Transaction>> getTransactionsByType(
    TransactionType type, {
    String? userId,
  }) async {
    await init();
    if (userId == null || userId.isEmpty) {
      return [];
    }
    return _box!.values
        .where((t) => t.type == type && t.userId == userId)
        .toList();
  }

  // Get transactions by date range for a specific user
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end, {
    String? userId,
  }) async {
    await init();
    if (userId == null || userId.isEmpty) {
      return [];
    }
    return _box!.values.where((t) {
      return t.userId == userId &&
          t.date.isAfter(start.subtract(Duration(days: 1))) &&
          t.date.isBefore(end.add(Duration(days: 1)));
    }).toList();
  }

  // Get transactions for current month for a specific user
  Future<List<Transaction>> getCurrentMonthTransactions({
    String? userId,
  }) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return getTransactionsByDateRange(startOfMonth, endOfMonth, userId: userId);
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

  // Get total expense for current month for a specific user
  Future<double> getCurrentMonthExpense({String? userId}) async {
    final transactions = await getCurrentMonthTransactions(userId: userId);
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  // Get total income for current month for a specific user
  Future<double> getCurrentMonthIncome({String? userId}) async {
    final transactions = await getCurrentMonthTransactions(userId: userId);
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  // Admin: Get ALL transactions (for admin panel)
  Future<List<Transaction>> getAllTransactionsAdmin() async {
    await init();
    return _box!.values.toList();
  }

  // Admin: Get transactions by user ID
  Future<List<Transaction>> getTransactionsByUserId(String userId) async {
    await init();
    return _box!.values.where((t) => t.userId == userId).toList();
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
