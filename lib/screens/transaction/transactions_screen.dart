import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/transaction_service.dart';
import '../../services/transaction_grouping_service.dart';
import '../../services/auth_service.dart';
import '../../models/transaction.dart' as model;
import '../../widgets/transaction/transaction_list.dart';
import '../../widgets/transaction/month_tabs.dart';
import '../../widgets/transaction/compact_summary.dart';
import '../../widgets/transaction/transaction_grid_view.dart';
import '../../widgets/transaction/transaction_calendar_view.dart';
import '../../widgets/transaction/transaction_category_view.dart';
import 'transaction_day_detail_screen.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionService _transactionService = TransactionService();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');

  ViewMode _viewMode = ViewMode.list;

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;
  
  Map<String, List<model.Transaction>> _groupedTransactions = {};
  Map<String, List<model.Transaction>> _groupedByCategory = {};
  bool _isLoadingTransactions = false;
  String _selectedWallet = 'Tổng cộng';
  final List<String> _wallets = [
    'Tổng cộng',
    'Tiền mặt',
    'Ngân hàng',
    'Ví điện tử',
  ];
  
  // Time period filter - Month is default
  final ScrollController _monthScrollController = ScrollController();

  // Time range type
  String _timeRangeType = 'Tháng'; // Ngày, Tháng, Quý, Năm
  late List<DateTime> _availableTimePeriods;
  DateTime _selectedTimePeriod = DateTime.now();

  @override
  void initState() {
    super.initState();
    _generateTimePeriodsList();
    _loadSummary();
  }

  void _generateTimePeriodsList() {
    _availableTimePeriods = [];
    final now = DateTime.now();

    switch (_timeRangeType) {
      case 'Ngày':
        for (int i = -30; i <= 30; i++) {
          final day = now.add(Duration(days: i));
          _availableTimePeriods.add(DateTime(day.year, day.month, day.day));
        }
        _availableTimePeriods.sort();
        _selectedTimePeriod = DateTime(now.year, now.month, now.day);
        break;
      case 'Quý':
        for (int i = -4; i <= 1; i++) {
          final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1 + i * 3;
          _availableTimePeriods.add(DateTime(now.year, quarterMonth, 1));
        }
        _selectedTimePeriod = _availableTimePeriods[_availableTimePeriods.length ~/ 2];
        break;
      case 'Năm':
        for (int i = -3; i <= 1; i++) {
          _availableTimePeriods.add(DateTime(now.year + i, 1, 1));
        }
        _selectedTimePeriod = DateTime(now.year, 1, 1);
        break;
      case 'Tháng':
      default:
        for (int i = -12; i <= 3; i++) {
          _availableTimePeriods.add(DateTime(now.year, now.month + i, 1));
        }
        _selectedTimePeriod = DateTime(now.year, now.month, 1);
        break;
    }
  }

  Future<void> _loadSummary() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;

    setState(() => _isLoadingTransactions = true);

    final dateRange = _getDateRangeForPeriod(_selectedTimePeriod);
    var transactions = await _transactionService.getTransactionsByDateRange(
      dateRange['start'] as DateTime,
      dateRange['end'] as DateTime,
      userId: userId,
    );

    // Wallet filter
    if (_selectedWallet != 'Tổng cộng') {
      transactions = transactions
          .where((t) => (t.paymentMethod ?? '') == _selectedWallet)
          .toList();
    }

    if (_timeRangeType == 'Ngày') {
      final selectedDay = DateTime(
        _selectedTimePeriod.year,
        _selectedTimePeriod.month,
        _selectedTimePeriod.day,
      );
      transactions = transactions.where((t) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        return d == selectedDay;
      }).toList();
    }

    final income = transactions
        .where((t) => t.type == model.TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final expense = transactions
        .where((t) => t.type == model.TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final grouped = _timeRangeType == 'Quý' || _timeRangeType == 'Năm'
        ? TransactionGroupingService.groupTransactionsByMonth(transactions)
        : TransactionGroupingService.groupTransactionsByDate(transactions);

    final groupedByCategory =
        TransactionGroupingService.groupTransactionsByCategory(transactions);

    setState(() {
      _totalIncome = income;
      _totalExpense = expense;
      _balance = income - expense;
      _groupedTransactions = grouped;
      _groupedByCategory = groupedByCategory;
      _isLoadingTransactions = false;
    });
  }

  Map<String, DateTime> _getDateRangeForPeriod(DateTime period) {
    switch (_timeRangeType) {
      case 'Ngày':
        return {
          'start': DateTime(period.year, period.month, period.day),
          'end': DateTime(period.year, period.month, period.day),
        };
      case 'Quý':
        final quarterStart = ((period.month - 1) ~/ 3) * 3 + 1;
        return {
          'start': DateTime(period.year, quarterStart, 1),
          'end': DateTime(period.year, quarterStart + 3, 0),
        };
      case 'Năm':
        return {
          'start': DateTime(period.year, 1, 1),
          'end': DateTime(period.year, 12, 31),
        };
      case 'Tháng':
      default:
        return {
          'start': DateTime(period.year, period.month, 1),
          'end': DateTime(period.year, period.month + 1, 0),
        };
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360 || screenHeight < 700;
    final padding = isSmallScreen ? 12.0 : 20.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: _buildLeadingAvatar(),
        ),
        title: const Text(
          'Sổ giao dịch',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: _handleMenuSelection,
            color: AppTheme.cardColor,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'timerange',
                child: Row(
                  children: [
                    Icon(Icons.date_range, size: 20),
                    SizedBox(width: 12),
                    Text('Khoảng thời gian'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _viewMode == ViewMode.categoryGroup
                    ? 'view-transactions'
                    : 'view-category',
                child: Row(
                  children: [
                    Icon(
                      _viewMode == ViewMode.categoryGroup
                          ? Icons.receipt_long
                          : Icons.category,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(_viewMode == ViewMode.categoryGroup
                        ? 'Xem theo giao dịch'
                        : 'Xem theo nhóm'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Wallet selector
            Container(
              color: AppTheme.backgroundColor,
              padding: EdgeInsets.fromLTRB(padding, padding, padding, 8),
              child: _buildWalletSelector(isSmallScreen),
            ),

            // Compact summary section
            Container(
              color: AppTheme.backgroundColor,
              padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
              child: CompactSummaryWidget(
                totalBalance: _balance,
                totalIncome: _totalIncome,
                totalExpense: _totalExpense,
                currencyFormat: _currencyFormat,
              ),
            ),

            // Month tabs (or other time period tabs)
            Container(
              color: AppTheme.backgroundColor,
              padding: EdgeInsets.symmetric(vertical: 8),
              child: MonthTabsWidget(
                availableMonths: _availableTimePeriods,
                selectedMonth: _selectedTimePeriod,
                onMonthSelected: (period) {
                  setState(() => _selectedTimePeriod = period);
                  _loadSummary();
                },
                scrollController: _monthScrollController,
                timeRangeType: _timeRangeType,
              ),
            ),

            const SizedBox(height: 8),

            // Scrollable transactions content only
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadSummary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildTransactionsContent(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingAvatar() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userName = authService.currentUser?.fullName ?? 'User';
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white.withOpacity(0.3),
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildTransactionsContent() {
    switch (_viewMode) {
      case ViewMode.list:
        return TransactionListWidget(
          groupedTransactions: _groupedTransactions,
          currencyFormat: _currencyFormat,
          isLoading: _isLoadingTransactions,
          onDateTapped: (date, transactions) async {
            final deleted = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionDayDetailScreen(
                  selectedDate: date,
                  transactions: transactions,
                  currencyFormat: _currencyFormat,
                ),
              ),
            );
            if (deleted == true) {
              _loadSummary();
            }
          },
          onTransactionTapped: (transaction) async {
            final deleted = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionDetailScreen(
                  transaction: transaction,
                  currencyFormat: _currencyFormat,
                ),
              ),
            );
            if (deleted == true) {
              _loadSummary();
            }
          },
        );
      case ViewMode.grid:
        return TransactionGridView(
          transactions: _flattenTransactions(),
          currencyFormat: _currencyFormat,
          isLoading: _isLoadingTransactions,
        );
      case ViewMode.calendar:
        return TransactionCalendarView(
          groupedTransactions: _groupedTransactions,
          currencyFormat: _currencyFormat,
          isLoading: _isLoadingTransactions,
        );
      case ViewMode.categoryGroup:
        return TransactionCategoryView(
          groupedByCategory: _groupedByCategory,
          currencyFormat: _currencyFormat,
          isLoading: _isLoadingTransactions,
        );
    }
  }

  List<model.Transaction> _flattenTransactions() {
    final List<model.Transaction> flattened = [];
    _groupedTransactions.values.forEach(flattened.addAll);
    flattened.sort((a, b) => b.date.compareTo(a.date));
    return flattened;
  }

  Widget _buildWalletSelector(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: AppTheme.primaryTeal,
            size: isSmallScreen ? 18 : 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedWallet,
                isExpanded: true,
                dropdownColor: AppTheme.cardColor,
                icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryTeal),
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: isSmallScreen ? 14 : 15,
                  fontWeight: FontWeight.w500,
                ),
                items: _wallets.map((wallet) {
                  return DropdownMenuItem(
                    value: wallet,
                    child: Text(wallet),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedWallet = value);
                    _loadSummary(); // Reload with filter
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text('Tìm kiếm giao dịch'),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Nhập tên giao dịch hoặc số tiền...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            // TODO: Implement search logic
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'timerange':
        _showTimeRangeDialog();
        break;
      case 'view-category':
        setState(() => _viewMode = ViewMode.categoryGroup);
        break;
      case 'view-transactions':
        setState(() => _viewMode = ViewMode.list);
        break;
      case 'view':
        _showViewModeDialog();
        break;
      case 'export':
        _showExportDialog();
        break;
    }
  }

  void _showTimeRangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text('Khoảng thời gian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Ngày'),
              value: 'Ngày',
              groupValue: _timeRangeType,
              onChanged: (value) {
                setState(() {
                  _timeRangeType = value!;
                  _generateTimePeriodsList();
                  // Set selected period to today
                  final now = DateTime.now();
                  _selectedTimePeriod = DateTime(now.year, now.month, now.day);
                });
                Navigator.pop(context);
                _loadSummary();
              },
            ),
            RadioListTile<String>(
              title: Text('Tháng'),
              value: 'Tháng',
              groupValue: _timeRangeType,
              onChanged: (value) {
                setState(() {
                  _timeRangeType = value!;
                  _generateTimePeriodsList();
                  // Set selected period to first day of this month
                  _selectedTimePeriod = DateTime(DateTime.now().year, DateTime.now().month, 1);
                });
                Navigator.pop(context);
                _loadSummary();
              },
            ),
            RadioListTile<String>(
              title: Text('Quý'),
              value: 'Quý',
              groupValue: _timeRangeType,
              onChanged: (value) {
                setState(() {
                  _timeRangeType = value!;
                  _generateTimePeriodsList();
                  // Set selected period to first month of this quarter
                  final now = DateTime.now();
                  final quarterStart = ((now.month - 1) ~/ 3) * 3 + 1;
                  _selectedTimePeriod = DateTime(now.year, quarterStart, 1);
                });
                Navigator.pop(context);
                _loadSummary();
              },
            ),
            RadioListTile<String>(
              title: Text('Năm'),
              value: 'Năm',
              groupValue: _timeRangeType,
              onChanged: (value) {
                setState(() {
                  _timeRangeType = value!;
                  _generateTimePeriodsList();
                  // Set selected period to first day of this year
                  _selectedTimePeriod = DateTime(DateTime.now().year, 1, 1);
                });
                Navigator.pop(context);
                _loadSummary();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showViewModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text('Chế độ xem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.list),
              title: Text('Danh sách'),
              onTap: () {
                setState(() => _viewMode = ViewMode.list);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.grid_view),
              title: Text('Lưới'),
              onTap: () {
                setState(() => _viewMode = ViewMode.grid);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Lịch'),
              onTap: () {
                setState(() => _viewMode = ViewMode.calendar);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text('Xuất báo cáo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.picture_as_pdf),
              title: Text('PDF'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Export to PDF
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart),
              title: Text('Excel'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Export to Excel
              },
            ),
            ListTile(
              leading: Icon(Icons.text_snippet),
              title: Text('CSV'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Export to CSV
              },
            ),
          ],
        ),
      ),
    );
  }



}

enum ViewMode {
  list,
  grid,
  calendar,
  categoryGroup,
}
