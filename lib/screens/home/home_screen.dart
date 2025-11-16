import 'package:expense_tracker_app/widgets/balance_card_widget.dart';
import 'package:expense_tracker_app/widgets/chart_widget.dart';
import 'package:expense_tracker_app/widgets/recent_transactions_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../transaction/add_transaction_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedYear = DateTime.now().year; // ✅ Thêm state cho year

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
                });
                Navigator.pop(context); // Đóng dialog sau khi chọn
              },
            ),
          ),
        );
      },
    );
  }

  // Sample data
  final double totalBalance = 36636000;
  final List<Map<String, dynamic>> recentTransactions = [
    {
      'title': 'Ăn uống',
      'subtitle': 'Vị tiền mặt',
      'amount': -30000,
      'date': '07/11/2025',
      'iconPath': ('assets/icons/food.png'),
      'color': Colors.orange,
    },
    {
      'title': 'Mua sắm',
      'subtitle': 'Tài khoản ngân hàng',
      'amount': -1000000,
      'date': '07/11/2025',
      'iconPath': ('assets/icons/shopping.png'),
      'color': Colors.pink,
    },
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigation logic - implement later
    // switch (index) {
    //   case 0: // Home
    //     break;
    //   case 1: // Transactions
    //     break;
    //   case 2: // Add (middle button)
    //     break;
    //   case 3: // Reports
    //     break;
    //   case 4: // Account
    //     break;
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with avatar, name, notification
                _buildHeader(),

                SizedBox(height: AppConstants.paddingLarge),

                // Balance Card
                BalanceCardWidget(balance: totalBalance),

                SizedBox(height: AppConstants.paddingLarge),

                // Chart Section
                _buildChartSection(),

                SizedBox(height: AppConstants.paddingLarge),

                // Recent Transactions
                RecentTransactionsWidget(transactions: recentTransactions),
              ],
            ),
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavBar(),

      // Floating Action Button (Add button)
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTransactionScreen()),
          );

          // Refresh screen if transaction was saved
          if (result == true && mounted) {
            setState(() {
              // This will rebuild the widget and show updated data
            });
          }
        },
        backgroundColor: AppTheme.primaryTeal,
        child: Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Avatar
        CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryTeal.withOpacity(0.2),
          child: const Icon(Icons.person, color: AppTheme.primaryTeal),
        ),

        // Name
        Text(
          'Trang Chủ',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryTeal,
            fontWeight: FontWeight.w600,
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

        // Chart Widget
        const ChartWidget(),
      ],
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
}
