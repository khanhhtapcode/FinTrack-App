import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/transaction.dart' as model;
import '../../utils/category_helper.dart';

/// Widget hiển thị một transaction item
class TransactionItemWidget extends StatelessWidget {
  final model.Transaction transaction;
  final NumberFormat currencyFormat;

  const TransactionItemWidget({
    Key? key,
    required this.transaction,
    required this.currencyFormat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryHelper.getCategoryColor(transaction.category);
    final categoryIcon = CategoryHelper.getCategoryIcon(transaction.category);
    
    final amountText = transaction.type == model.TransactionType.income
        ? '+${currencyFormat.format(transaction.amount)}'
        : '-${currencyFormat.format(transaction.amount)}';
    
    final amountColor = transaction.type == model.TransactionType.income
        ? Colors.green
        : Colors.red;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Category icon container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(categoryIcon, color: categoryColor, size: 24),
            ),
          ),
          SizedBox(width: 12),
          
          // Category name and payment method
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  transaction.paymentMethod ?? 'Không có phương thức',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '₫',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
