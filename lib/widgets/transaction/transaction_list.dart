import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/transaction.dart' as model;
import 'transaction_item.dart';

/// Widget hiển thị danh sách giao dịch được nhóm theo ngày
class TransactionListWidget extends StatelessWidget {
  final Map<String, List<model.Transaction>> groupedTransactions;
  final NumberFormat currencyFormat;
  final bool isLoading;
  final Function(DateTime, List<model.Transaction>)? onDateTapped;

  const TransactionListWidget({
    Key? key,
    required this.groupedTransactions,
    required this.currencyFormat,
    this.isLoading = false,
    this.onDateTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryTeal,
        ),
      );
    }

    if (groupedTransactions.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: groupedTransactions.entries.map((entry) {
          final dateLabel = entry.key;
          final transactions = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: GestureDetector(
                  onTap: () {
                    // Call callback when date is tapped
                    if (onDateTapped != null) {
                      onDateTapped!(transactions[0].date, transactions);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: Row(
                      children: [
                        // Day/Month indicator
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              _getDayOrMonthLabel(dateLabel, transactions[0]),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        // Date label
                        Expanded(
                          child: Text(
                            dateLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        // Arrow icon
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Transactions for this date
              Column(
                children: transactions
                    .map((transaction) => TransactionItemWidget(
                          transaction: transaction,
                          currencyFormat: currencyFormat,
                        ))
                    .toList(),
              ),
              
              SizedBox(height: 8),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Không có giao dịch',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Chưa có giao dịch trong khoảng thời gian này',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Extract day or month label from date label
  String _getDayOrMonthLabel(String dateLabel, model.Transaction firstTransaction) {
    // Check if it's a month-based label (contains "Tháng")
    if (dateLabel.contains('Tháng')) {
      // Return month and year abbreviation
      return '${firstTransaction.date.month}/${firstTransaction.date.year % 100}';
    }
    // Otherwise return day number
    return '${firstTransaction.date.day}';
  }
}
