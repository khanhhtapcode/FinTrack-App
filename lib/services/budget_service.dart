import 'package:hive/hive.dart';
import '../models/budget.dart';
import '../services/transaction_service.dart';
import '../models/transaction.dart' as model;

class BudgetService {
  BudgetService._();
  static final BudgetService _instance = BudgetService._();
  factory BudgetService() => _instance;

  late Box<Map> _budgetsBox;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _budgetsBox = await Hive.openBox<Map>('budgets');
    _initialized = true;
  }

  List<Budget> getAllBudgets() {
    if (!_initialized) return [];
    return _budgetsBox.values.map((map) => _budgetFromMap(map.cast<String, dynamic>())).toList();
  }

  List<Budget> getBudgetsOverlapping(DateTime start, DateTime end) {
    return getAllBudgets().where((b) => b.overlaps(start, end)).toList();
  }

  Future<double> computeTotalSpentForBudget({
    required Budget budget,
    required TransactionService transactionService,
    required String? userId,
  }) async {
    final txs = await transactionService.getTransactionsByDateRange(
      budget.startDate,
      budget.endDate,
      userId: userId,
    );
    final spent = txs
        .where((t) => t.type == model.TransactionType.expense)
        .where((t) => (t.category) == budget.category)
        .fold<double>(0, (sum, t) => sum + t.amount);
    return spent;
  }

  bool existsOverlappingBudget({
    required String category,
    required DateTime start,
    required DateTime end,
  }) {
    return getAllBudgets().any((b) =>
        b.category == category && !b.endDate.isBefore(start) && !b.startDate.isAfter(end));
  }

  Future<void> addBudget(Budget budget) async {
    // Reject budgets that end in the past (date-only comparison)
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final endDateOnly = DateTime(budget.endDate.year, budget.endDate.month, budget.endDate.day);
    if (endDateOnly.isBefore(todayDate)) {
      throw ArgumentError('Ngày kết thúc ngân sách không được trong quá khứ');
    }

    // Basic uniqueness: no duplicate category+overlap
    if (existsOverlappingBudget(
      category: budget.category,
      start: budget.startDate,
      end: budget.endDate,
    )) {
      throw ArgumentError('Đã có ngân sách cho danh mục này trong khoảng thời gian trùng lặp');
    }
    if (!_initialized) await init();
    await _budgetsBox.put(budget.id, _budgetToMap(budget));
  }

  Future<void> deleteBudget(String budgetId) async {
    if (!_initialized) await init();
    await _budgetsBox.delete(budgetId);
  }

  Future<void> updateBudget(Budget budget) async {
    // Reject budgets that end in the past (date-only comparison)
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final endDateOnly = DateTime(budget.endDate.year, budget.endDate.month, budget.endDate.day);
    if (endDateOnly.isBefore(todayDate)) {
      throw ArgumentError('Ngày kết thúc ngân sách không được trong quá khứ');
    }

    // Check for overlapping budgets (excluding the current budget being updated)
    final overlapping = getAllBudgets().where((b) =>
        b.id != budget.id && // Exclude current budget
        b.category == budget.category &&
        !b.endDate.isBefore(budget.startDate) &&
        !b.startDate.isAfter(budget.endDate));
    
    if (overlapping.isNotEmpty) {
      throw ArgumentError('Đã có ngân sách cho danh mục này trong khoảng thời gian trùng lặp');
    }
    
    if (!_initialized) await init();
    await _budgetsBox.put(budget.id, _budgetToMap(budget));
  }

  Map<String, dynamic> _budgetToMap(Budget b) {
    return {
      'id': b.id,
      'category': b.category,
      'limit': b.limit,
      'startDate': b.startDate.toIso8601String(),
      'endDate': b.endDate.toIso8601String(),
      'periodType': b.periodType.toString(),
      'note': b.note,
    };
  }

  Budget _budgetFromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      category: map['category'] as String,
      limit: (map['limit'] as num).toDouble(),
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      periodType: _parsePeriodType(map['periodType'] as String),
      note: map['note'] as String?,
    );
  }

  BudgetPeriodType _parsePeriodType(String str) {
    if (str.contains('month')) return BudgetPeriodType.month;
    if (str.contains('quarter')) return BudgetPeriodType.quarter;
    if (str.contains('year')) return BudgetPeriodType.year;
    return BudgetPeriodType.custom;
  }


  static BudgetPeriodType detectPeriodType(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    // Month
    if (s.day == 1 && e.day == 0 && e.month == s.month + 1 && e.year == s.year) {
      return BudgetPeriodType.month;
    }
    // Quarter
    final qStartMonths = {1, 4, 7, 10};
    if (qStartMonths.contains(s.month) && e.day == 0 && e.month == s.month + 3 && e.year == s.year) {
      return BudgetPeriodType.quarter;
    }
    // Year
    if (s.month == 1 && s.day == 1 && e.month == 12 && e.day == 31 && e.year == s.year) {
      return BudgetPeriodType.year;
    }
    return BudgetPeriodType.custom;
  }
}
