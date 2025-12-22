import 'package:expense_tracker_app/screens/profile/profile_screen.dart';
import 'package:expense_tracker_app/widgets/home/balance_card_widget.dart';
import 'package:expense_tracker_app/widgets/home/chart_widget.dart';
import 'package:expense_tracker_app/widgets/home/recent_transactions_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
import '../../models/transaction.dart' as model;
import '../transaction/add_transaction_screen.dart';
import '../auth/login_screen.dart';
import '../transaction/transactions_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedYear = DateTime.now().year;

  final TransactionService _transactionService = TransactionService();

  // Data from database
  double _totalBalance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  List<model.Transaction> _allTransactions = [];
  List<Map<String, dynamic>> _recentTransactions = [];
  final Map<int, double> _monthlyExpenses = {}; // For chart

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get current user ID
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;

      if (userId == null || userId.isEmpty) {
        // User not logged in
        setState(() => _isLoading = false);
        return;
      }

      // Load all transactions for this user
      _allTransactions = await _transactionService.getAllTransactions(
        userId: userId,
      );

      // Calculate totals
      _totalIncome = _allTransactions
          .where((t) => t.type == model.TransactionType.income)
          .fold<double>(0, (sum, t) => sum + t.amount);

      _totalExpense = _allTransactions
          .where((t) => t.type == model.TransactionType.expense)
          .fold<double>(0, (sum, t) => sum + t.amount);

      // Calculate balance (income - expense)
      _totalBalance = _totalIncome - _totalExpense;

      // Get recent transactions (last 5)
      final recentList = _allTransactions.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      _recentTransactions = recentList.take(5).map((t) {
        return {
          'id': t.id,
          'title': t.category,
          'subtitle': t.paymentMethod ?? 'Không có phương thức',
          'amount': t.type == model.TransactionType.expense
              ? -t.amount
              : t.amount,
          'date': DateFormat('dd/MM/yyyy').format(t.date),
          'iconPath': _getCategoryIcon(t.category),
          'color': _getCategoryColor(t.category),
        };
      }).toList();

      // Calculate monthly expenses for chart (current year)
      _calculateMonthlyExpenses();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateMonthlyExpenses() {
    _monthlyExpenses.clear();

    // Initialize all months with 0
    for (int i = 1; i <= 12; i++) {
      _monthlyExpenses[i] = 0;
    }

    // Calculate expenses for each month in selected year
    for (var transaction in _allTransactions) {
      if (transaction.date.year == _selectedYear &&
          transaction.type == model.TransactionType.expense) {
        final month = transaction.date.month;
        _monthlyExpenses[month] =
            (_monthlyExpenses[month] ?? 0) + transaction.amount;
      }
    }
  }

  String _getCategoryIcon(String category) {
    // Map categories to icons
    const iconMap = {
      'Ăn uống': 'assets/icons/food.png',
      'Mua sắm': 'assets/icons/shopping.png',
      'Giải trí': 'assets/icons/entertainment.png',
      'Di chuyển': 'assets/icons/transport.png',
      'Sức khỏe': 'assets/icons/health.png',
      'Giáo dục': 'assets/icons/education.png',
      'Lương': 'assets/icons/salary.png',
      'Thưởng': 'assets/icons/bonus.png',
      'Đầu tư': 'assets/icons/investment.png',
    };
    return iconMap[category] ?? 'assets/icons/other.png';
  }

  Color _getCategoryColor(String category) {
    // Map categories to colors
    const colorMap = {
      'Ăn uống': Colors.orange,
      'Mua sắm': Colors.pink,
      'Giải trí': Colors.purple,
      'Di chuyển': Colors.blue,
      'Sức khỏe': Colors.red,
      'Giáo dục': Colors.green,
    };
    return colorMap[category] ?? AppTheme.primaryTeal;
  }

  // YearPicker
  Future<void> _showYearPicker(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn năm'),
          contentPadding: const EdgeInsets.all(0),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              selectedDate: DateTime(_selectedYear),
              onChanged: (DateTime dateTime) {
                setState(() {
                  _selectedYear = dateTime.year;
                  _calculateMonthlyExpenses(); // Recalculate for new year
                });
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    // Middle slot reserved for the FAB; open add flow instead of switching
    if (index == 2) {
      _openAddTransaction();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360 || screenHeight < 700;
    final padding = isSmallScreen ? 12.0 : AppConstants.paddingMedium;
    final spacing = isSmallScreen ? 12.0 : AppConstants.paddingLarge;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(padding, spacing),
          const TransactionsScreen(),
          const SizedBox.shrink(), // placeholder for FAB slot
          _buildReportsPlaceholder(),
          const ProfileScreen(),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavBar(),

      // Floating Action Button (Add button)
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: _openAddTransaction,
              backgroundColor: AppTheme.primaryTeal,
              child: const Icon(Icons.add, size: 32),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userName = authService.currentUser?.fullName ?? 'User';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Avatar
        CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryTeal.withOpacity(0.2),
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
            style: TextStyle(
              color: AppTheme.primaryTeal,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),

        // Name
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào,',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  userName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryTeal,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        // Notification Icon
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: AppTheme.primaryTeal,
          onPressed: () {
            // Open notifications
          },
        ),

        // Logout Icon (Temporary)
        IconButton(
          icon: const Icon(Icons.logout),
          color: Colors.red,
          onPressed: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đăng xuất'),
        content: Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final authService = Provider.of<AuthService>(
                context,
                listen: false,
              );
              await authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Thống kê',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            // ✅ Year filter button - Clickable
            InkWell(
              onTap: () => _showYearPicker(context), // Call year picker
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Row(
                  children: [
                    Text(
                      'Year - $_selectedYear', // ✅ Hiển thị năm được chọn
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppTheme.primaryTeal,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: AppConstants.paddingMedium),

        // Chart Widget with real data
        ChartWidget(monthlyData: _monthlyExpenses),
      ],
    );
  }

  // Home tab content wrapped so it can live inside IndexedStack
  Widget _buildHomeTab(double padding, double spacing) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryTeal),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with avatar, name, notification
                _buildHeader(),

                SizedBox(height: spacing),

                // Balance Card with real data
                BalanceCardWidget(balance: _totalBalance),

                SizedBox(height: padding),

                // Income & Expense Summary
                _buildSummaryCards(),

                SizedBox(height: spacing),

                // Chart Section
                _buildChartSection(),

                SizedBox(height: spacing),

                // Recent Transactions
                _recentTransactions.isEmpty
                    ? Center(child: _buildEmptyState())
                    : RecentTransactionsWidget(
                        transactions: _recentTransactions,
                      ),

                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.cardColor,
      selectedItemColor: AppTheme.primaryTeal,
      unselectedItemColor: AppTheme.textSecondary,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Trang chủ',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.sync_alt), label: 'Giao dịch'),
        BottomNavigationBarItem(
          icon: SizedBox.shrink(), // Placeholder for FAB
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pie_chart_outline),
          activeIcon: Icon(Icons.pie_chart),
          label: 'Ngân sách',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Tài khoản',
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        // Income Card
        Expanded(
          child: Container(
            padding: EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.arrow_downward, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Thu nhập',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  NumberFormat('#,##0').format(_totalIncome),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  AppConstants.currencySymbol,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: AppConstants.paddingMedium),
        // Expense Card
        Expanded(
          child: Container(
            padding: EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.arrow_upward, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Chi tiêu',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  NumberFormat('#,##0').format(_totalExpense),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  AppConstants.currencySymbol,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(AppConstants.paddingLarge * 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Chưa có giao dịch',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Nhấn nút + để thêm giao dịch đầu tiên',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _openAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddTransactionScreen()),
    );

    if (result == true && mounted) {
      _loadData();
    }
  }

  Widget _buildReportsPlaceholder() {
    return SafeArea(
      child: Center(
        child: Text(
          'Ngân sách / Báo cáo (đang cập nhật)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
