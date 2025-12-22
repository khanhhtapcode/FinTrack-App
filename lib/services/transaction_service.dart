import 'package:hive/hive.dart';
import '../models/transaction.dart';

class TransactionService {
  static const String _boxName = 'transactions';
  Box<Transaction>? _box;

  // ================= SINGLETON =================
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  // ================= INIT =================
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<Transaction>(_boxName);
    }
  }

  // ================= ADD =================
  Future<void> addTransaction(Transaction transaction) async {
    await init();
    await _box!.put(transaction.id, transaction);
  }

  // ================= GET ALL (OPTIMIZED) =================
  Future<List<Transaction>> getAllTransactions({String? userId}) async {
    await init();
    if (userId == null || userId.isEmpty) {
      return [];
    }

    // 🔥 SNAPSHOT DATA → TRÁNH LIVE ITERABLE (FIX ANR)
    final List<Transaction> all = List<Transaction>.from(_box!.values);

    return all.where((t) => t.userId == userId).toList();
  }

  // ================= GET BY TYPE =================
  Future<List<Transaction>> getTransactionsByType(
    TransactionType type, {
    String? userId,
  }) async {
    await init();
    if (userId == null || userId.isEmpty) {
      return [];
    }

    final List<Transaction> all = List<Transaction>.from(_box!.values);

    return all.where((t) => t.type == type && t.userId == userId).toList();
  }

  // ================= GET BY DATE RANGE =================
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end, {
    String? userId,
  }) async {
    await init();
    if (userId == null || userId.isEmpty) {
      return [];
    }

    final List<Transaction> all = List<Transaction>.from(_box!.values);

    return all.where((t) {
      return t.userId == userId &&
          t.date.isAfter(start.subtract(const Duration(days: 1))) &&
          t.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // ================= CURRENT MONTH =================
  Future<List<Transaction>> getCurrentMonthTransactions({
    String? userId,
  }) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return getTransactionsByDateRange(startOfMonth, endOfMonth, userId: userId);
  }

  // ================= UPDATE =================
  Future<void> updateTransaction(Transaction transaction) async {
    await init();
    await _box!.put(transaction.id, transaction);
  }

  // ================= DELETE =================
  Future<void> deleteTransaction(String id) async {
    await init();
    await _box!.delete(id);
  }

  // ================= TOTAL EXPENSE =================
  Future<double> getCurrentMonthExpense({String? userId}) async {
    final transactions = await getCurrentMonthTransactions(userId: userId);

    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  // ================= TOTAL INCOME =================
  Future<double> getCurrentMonthIncome({String? userId}) async {
    final transactions = await getCurrentMonthTransactions(userId: userId);

    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  // ================= ADMIN =================
  Future<List<Transaction>> getAllTransactionsAdmin() async {
    await init();

    // snapshot để an toàn
    return List<Transaction>.from(_box!.values);
  }

  Future<List<Transaction>> getTransactionsByUserId(String userId) async {
    await init();

    final List<Transaction> all = List<Transaction>.from(_box!.values);

    return all.where((t) => t.userId == userId).toList();
  }

  // ================= CLEAR =================
  Future<void> clearAll() async {
    await init();
    await _box!.clear();
  }

  // ================= CLOSE =================
  Future<void> close() async {
    await _box?.close();
  }
}
