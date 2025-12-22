
enum BudgetPeriodType { month, quarter, year, custom }

class Budget {
  final String id;
  final String category; // Expense category name
  final double limit;
  final DateTime startDate;
  final DateTime endDate;
  final BudgetPeriodType periodType;
  final String? note;

  const Budget({
    required this.id,
    required this.category,
    required this.limit,
    required this.startDate,
    required this.endDate,
    required this.periodType,
    this.note,
  });

  bool overlaps(DateTime rangeStart, DateTime rangeEnd) {
    // Overlap if start <= rangeEnd and end >= rangeStart
    return !startDate.isAfter(rangeEnd) && !endDate.isBefore(rangeStart);
  }
}
