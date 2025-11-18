import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/transaction_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/transaction_list_widget.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionService _transactionService = TransactionService();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    // Get current user ID
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;

    if (userId == null || userId.isEmpty) {
      return;
    }

    final income = await _transactionService.getCurrentMonthIncome(
      userId: userId,
    );
    final expense = await _transactionService.getCurrentMonthExpense(
      userId: userId,
    );

    setState(() {
      _totalIncome = income;
      _totalExpense = expense;
      _balance = income - expense;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360 || screenHeight < 700;
    final padding = isSmallScreen ? 12.0 : 20.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        elevation: 0,
        title: Text(
          'Giao dịch tháng ${DateTime.now().month}',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSummary,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Summary cards
                Container(
                  color: AppTheme.primaryTeal,
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    children: [
                      _buildSummaryCard(
                        'Thu nhập',
                        _totalIncome,
                        Colors.green,
                        Icons.arrow_upward,
                        isSmallScreen,
                      ),
                      SizedBox(height: isSmallScreen ? 10 : 12),
                      _buildSummaryCard(
                        'Chi tiêu',
                        _totalExpense,
                        Colors.red,
                        Icons.arrow_downward,
                        isSmallScreen,
                      ),
                      SizedBox(height: isSmallScreen ? 10 : 12),
                      _buildSummaryCard(
                        'Số dư',
                        _balance,
                        _balance >= 0 ? Colors.green : Colors.red,
                        Icons.account_balance_wallet,
                        isSmallScreen,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 16 : 20),

                // Transaction list
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Giao dịch gần đây',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                TransactionListWidget(),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
    bool isSmallScreen,
  ) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 40 : 48,
            height: isSmallScreen ? 40 : 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: isSmallScreen ? 20 : 24),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                ),
                SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_currencyFormat.format(amount)} ₫',
                    style: TextStyle(
                      color: color,
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
