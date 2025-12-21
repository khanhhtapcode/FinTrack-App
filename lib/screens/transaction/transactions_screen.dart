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
import 'transaction_day_detail_screen.dart';

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
  
  Map<String, List<model.Transaction>> _groupedTransactions = {};
  bool _isLoadingTransactions = false;
  String _selectedWallet = 'Tổng cộng';
  final List<String> _wallets = [
    'Tổng cộng',
    'Tiền mặt',
    'Ngân hàng',
    'Ví điện tử',
  ];
  
  // Sort options state
  String _sortBy = 'Mới nhất';
  final List<String> _sortOptions = [
    'Mới nhất',
    'Cũ nhất',
    'Số tiền cao nhất',
    'Số tiền thấp nhất',
  ];
  
  // Time period filter - Month is default
  DateTime _selectedMonth = DateTime.now();
  late List<DateTime> _availableMonths;
  final ScrollController _monthScrollController = ScrollController();
  
  // Time range type
  String _timeRangeType = 'Tháng'; // Ngày, Tuần, Tháng, Quý, Năm
  late List<DateTime> _availableTimePeriods;
  DateTime _selectedTimePeriod = DateTime.now();
  
  void _generateMonthsList() {
    _availableMonths = [];
    final now = DateTime.now();
    // Tạo danh sách từ 12 tháng trước đến 3 tháng tương lai
    for (int i = -12; i <= 3; i++) {
      final month = DateTime(now.year, now.month + i, 1);
      _availableMonths.add(month);
    }
  }

  void _generateTimePeriodsList() {
    _availableTimePeriods = [];
    final now = DateTime.now();
    
    switch (_timeRangeType) {
      case 'Ngày':
        // Tạo danh sách 60 ngày (30 trước, hôm nay, 30 sau)
        for (int i = -30; i <= 30; i++) {
          final day = now.add(Duration(days: i));
          _availableTimePeriods.add(DateTime(day.year, day.month, day.day));
        }
        _availableTimePeriods.sort();
        break;
      case 'Tháng':
        // Tạo danh sách từ 12 tháng trước đến 3 tháng tương lai
        for (int i = -12; i <= 3; i++) {
          final month = DateTime(now.year, now.month + i, 1);
          _availableTimePeriods.add(month);
        }
        _availableTimePeriods.sort();
        break;
      case 'Quý':
        // Tạo danh sách 8 quý (4 trước, quý này, 3 sau)
        for (int i = -4; i <= 3; i++) {
          final quarter = now.add(Duration(days: i * 90));
          final quarter1 = DateTime(quarter.year, ((quarter.month - 1) ~/ 3) * 3 + 1, 1);
          _availableTimePeriods.add(quarter1);
        }
        _availableTimePeriods = _availableTimePeriods.toSet().toList();
        _availableTimePeriods.sort();
        break;
      case 'Năm':
        // Tạo danh sách 10 năm (5 trước, năm này, 4 sau)
        for (int i = -5; i <= 4; i++) {
          final year = DateTime(now.year + i, 1, 1);
          _availableTimePeriods.add(year);
        }
        _availableTimePeriods.sort();
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _generateMonthsList();
    _generateTimePeriodsList();
    _selectedTimePeriod = _selectedMonth;
    _loadSummary();
    
    // Scroll đến tháng hiện tại sau khi widget được render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentPeriod();
    });
  }
  
  // Scroll tabs to center the current period based on _timeRangeType
  void _scrollToCurrentPeriod() {
    if (!_monthScrollController.hasClients) return;

    final now = DateTime.now();
    int currentIndex = -1;

    switch (_timeRangeType) {
      case 'Ngày':
        currentIndex = _availableTimePeriods.indexWhere(
          (d) => d.year == now.year && d.month == now.month && d.day == now.day,
        );
        break;
      case 'Tháng':
        currentIndex = _availableTimePeriods.indexWhere(
          (d) => d.year == now.year && d.month == now.month,
        );
        break;
      case 'Quý':
        final currentQuarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        currentIndex = _availableTimePeriods.indexWhere(
          (d) => d.year == now.year && d.month == currentQuarterStartMonth && d.day == 1,
        );
        break;
      case 'Năm':
        currentIndex = _availableTimePeriods.indexWhere(
          (d) => d.year == now.year && d.month == 1 && d.day == 1,
        );
        break;
      default:
        currentIndex = _availableTimePeriods.indexWhere(
          (d) => d.year == now.year && d.month == now.month,
        );
    }

    if (currentIndex != -1) {
      final itemWidth = 90.0; // approximate tab width
      final screenWidth = MediaQuery.of(context).size.width;
      final targetOffset = (currentIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

      _monthScrollController.animateTo(
        targetOffset.clamp(0.0, _monthScrollController.position.maxScrollExtent),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToCurrentMonth() {
    if (!_monthScrollController.hasClients) return;
    
    final now = DateTime.now();
    final currentMonthIndex = _availableMonths.indexWhere(
      (month) => month.year == now.year && month.month == now.month,
    );
    
    if (currentMonthIndex != -1) {
      // Tính toán offset: mỗi tab khoảng 90-100px, scroll để current month ở giữa màn hình
      final itemWidth = 90.0;
      final screenWidth = MediaQuery.of(context).size.width;
      final targetOffset = (currentMonthIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      
      _monthScrollController.animateTo(
        targetOffset.clamp(0.0, _monthScrollController.position.maxScrollExtent),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  @override
  void dispose() {
    _monthScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    // Get current user ID
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;

    if (userId == null || userId.isEmpty) {
      return;
    }

    setState(() => _isLoadingTransactions = true);

    // Get date range based on selected time period
    final dateRange = _getDateRangeForPeriod(_selectedTimePeriod);
    var transactions = await _transactionService.getTransactionsByDateRange(
      dateRange['start'] as DateTime,
      dateRange['end'] as DateTime,
      userId: userId,
    );
    
    // For single day mode, filter to only that specific day
    if (_timeRangeType == 'Ngày') {
      final selectedDay = DateTime(_selectedTimePeriod.year, _selectedTimePeriod.month, _selectedTimePeriod.day);
      transactions = transactions.where((t) {
        final transactionDay = DateTime(t.date.year, t.date.month, t.date.day);
        return transactionDay == selectedDay;
      }).toList();
    }
    
    // Calculate income and expense from transactions
    final income = transactions
        .where((t) => t.type == model.TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
    
    final expense = transactions
        .where((t) => t.type == model.TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    
    // Group transactions based on time range type
    final grouped = _timeRangeType == 'Quý' || _timeRangeType == 'Năm'
        ? TransactionGroupingService.groupTransactionsByMonth(transactions)
        : TransactionGroupingService.groupTransactionsByDate(transactions);

    setState(() {
      _totalIncome = income;
      _totalExpense = expense;
      _balance = income - expense;
      _groupedTransactions = grouped;
      _isLoadingTransactions = false;
    });
  }

  Map<String, DateTime> _getDateRangeForPeriod(DateTime period) {
    switch (_timeRangeType) {
      case 'Ngày':
        // For single day, we need to account for the +/- 1 day adjustment in getTransactionsByDateRange
        // So we ask for the exact day, and let the service expand it
        final start = DateTime(period.year, period.month, period.day);
        final end = DateTime(period.year, period.month, period.day);
        return {'start': start, 'end': end};
      case 'Tháng':
        final start = DateTime(period.year, period.month, 1);
        final end = DateTime(period.year, period.month + 1, 0);
        return {'start': start, 'end': end};
      case 'Quý':
        final quarterStart = ((period.month - 1) ~/ 3) * 3 + 1;
        final start = DateTime(period.year, quarterStart, 1);
        final end = DateTime(period.year, quarterStart + 3, 0);
        return {'start': start, 'end': end};
      case 'Năm':
        final start = DateTime(period.year, 1, 1);
        final end = DateTime(period.year, 12, 31);
        return {'start': start, 'end': end};
      default:
        final startOfMonth = DateTime(period.year, period.month, 1);
        final endOfMonth = DateTime(period.year, period.month + 1, 0);
        return {'start': startOfMonth, 'end': endOfMonth};
    }
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
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        title: _buildCustomHeader(),
        centerTitle: false,
        titleSpacing: 16,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSummary,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Wallet selector
                Container(
                  color: AppTheme.primaryTeal,
                  padding: EdgeInsets.fromLTRB(padding, 8, padding, 8),
                  child: _buildWalletSelector(isSmallScreen),
                ),
                
                // Compact summary section
                Container(
                  color: AppTheme.primaryTeal,
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
                  color: Colors.white,
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

                SizedBox(height: 8),

                // Transaction list
                TransactionListWidget(
                  groupedTransactions: _groupedTransactions,
                  currencyFormat: _currencyFormat,
                  isLoading: _isLoadingTransactions,
                  onDateTapped: (date, transactions) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionDayDetailScreen(
                          selectedDate: date,
                          transactions: transactions,
                          currencyFormat: _currencyFormat,
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildCustomHeader() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userName = authService.currentUser?.fullName ?? 'User';

    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white.withOpacity(0.3),
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        
        SizedBox(width: 12),
        
        // Title
        Expanded(
          child: Text(
            'Sổ giao dịch',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Search icon
        IconButton(
          icon: Icon(Icons.search, color: Colors.white),
          onPressed: _showSearchDialog,
        ),
        
        // Menu icon (3 dots)
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.white),
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            PopupMenuItem(
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
              value: 'sort',
              child: Row(
                children: [
                  Icon(Icons.sort, size: 20),
                  SizedBox(width: 12),
                  Text('Sắp xếp'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'filter',
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 20),
                  SizedBox(width: 12),
                  Text('Lọc theo thời gian'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.view_list, size: 20),
                  SizedBox(width: 12),
                  Text('Chế độ xem'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.file_download, size: 20),
                  SizedBox(width: 12),
                  Text('Xuất báo cáo'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWalletSelector(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: isSmallScreen ? 18 : 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedWallet,
                isExpanded: true,
                dropdownColor: AppTheme.primaryTeal,
                icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                style: TextStyle(
                  color: Colors.white,
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
      case 'sort':
        _showSortDialog();
        break;
      case 'filter':
        _showFilterDialog();
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

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sắp xếp theo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _sortOptions.map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
                // TODO: Apply sort
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lọc theo thời gian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Hôm nay'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Filter today
              },
            ),
            ListTile(
              leading: Icon(Icons.date_range),
              title: Text('Tuần này'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Filter this week
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_month),
              title: Text('Tháng này'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Filter this month
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_view_month),
              title: Text('Tùy chỉnh'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show date range picker
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
        title: Text('Chế độ xem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.list),
              title: Text('Danh sách'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Switch to list view
              },
            ),
            ListTile(
              leading: Icon(Icons.grid_view),
              title: Text('Lưới'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Switch to grid view
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Lịch'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Switch to calendar view
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
