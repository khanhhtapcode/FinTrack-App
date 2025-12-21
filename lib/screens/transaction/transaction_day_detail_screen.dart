import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/transaction.dart' as model;
import '../../widgets/transaction/transaction_item.dart';

/// Màn hình chi tiết giao dịch theo ngày
class TransactionDayDetailScreen extends StatelessWidget {
  final DateTime selectedDate;
  final List<model.Transaction> transactions;
  final NumberFormat currencyFormat;

  const TransactionDayDetailScreen({
    Key? key,
    required this.selectedDate,
    required this.transactions,
    required this.currencyFormat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate day balance (income - expense)
    final totalIncome = transactions
        .where((t) => t.type == model.TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final totalExpense = transactions
        .where((t) => t.type == model.TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final dayBalance = totalIncome - totalExpense;

    // Format date
    final dateStr = DateFormat('dd/MM/yyyy').format(selectedDate);
    final dayOfWeekStr = _getDayOfWeek(selectedDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        elevation: 0,
        title: Text(
          'Chi tiết giao dịch',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Date header with balance
            Container(
              color: AppTheme.primaryTeal,
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Date
                  Text(
                    '$dayOfWeekStr - $dateStr',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12),

                  // Day balance
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Tổng số dư ngày',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${currencyFormat.format(dayBalance)} ₫',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Income and Expense summary
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          'Thu nhập',
                          totalIncome,
                          Colors.green,
                          currencyFormat,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryItem(
                          'Chi tiêu',
                          totalExpense,
                          Colors.red,
                          currencyFormat,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Transactions list
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giao dịch (${transactions.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  Column(
                    children: transactions
                        .map((transaction) => Column(
                              children: [
                                TransactionItemWidget(
                                  transaction: transaction,
                                  currencyFormat: currencyFormat,
                                ),
                                SizedBox(height: 8),
                              ],
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double amount,
    Color color,
    NumberFormat format,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '${format.format(amount)} ₫',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getDayOfWeek(DateTime date) {
    const days = [
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật',
    ];
    final dayIndex = date.weekday - 1;
    return dayIndex >= 0 && dayIndex < 7 ? days[dayIndex] : 'Unknown';
  }
}
