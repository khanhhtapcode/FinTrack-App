import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/transaction.dart' as model;
import '../../services/transaction_service.dart';
import '../../services/ocr_service.dart';
import '../../models/receipt_data.dart';
import '../../services/auth_service.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  int _selectedTab = 0; // 0: Khoản chi, 1: Khoản thu, 2: Vay/Nợ
  String _selectedCategory = 'Ăn uống';
  String _selectedPaymentMethod = 'Tiền mặt';
  String _amount = '0';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  final TransactionService _transactionService = TransactionService();
  final OcrService _ocrService = OcrService();
  final ImagePicker _imagePicker = ImagePicker();

  // Payment methods
  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'Tiền mặt', 'icon': Icons.money},
    {'name': 'Thẻ tín dụng', 'icon': Icons.credit_card},
    {'name': 'Thẻ ghi nợ', 'icon': Icons.payment},
    {'name': 'Chuyển khoản', 'icon': Icons.account_balance},
    {'name': 'Ví điện tử', 'icon': Icons.wallet},
    {'name': 'Khác', 'icon': Icons.more_horiz},
  ];

  // Categories for each tab
  final Map<int, List<Map<String, dynamic>>> _categories = {
    0: [
      // Khoản chi
      {'name': 'Ăn uống', 'icon': Icons.restaurant},
      {'name': 'Xăng xe', 'icon': Icons.local_gas_station},
      {'name': 'Shopping', 'icon': Icons.shopping_bag},
      {'name': 'Giải trí', 'icon': Icons.movie},
      {'name': 'Y tế', 'icon': Icons.medical_services},
      {'name': 'Giáo dục', 'icon': Icons.school},
      {'name': 'Hóa đơn', 'icon': Icons.receipt},
      {'name': 'Điện nước', 'icon': Icons.bolt},
      {'name': 'Nhà cửa', 'icon': Icons.home},
      {'name': 'Quần áo', 'icon': Icons.checkroom},
      {'name': 'Làm đẹp', 'icon': Icons.face},
      {'name': 'Thể thao', 'icon': Icons.fitness_center},
      {'name': 'Du lịch', 'icon': Icons.flight},
      {'name': 'Điện thoại', 'icon': Icons.phone_android},
      {'name': 'Internet', 'icon': Icons.wifi},
      {'name': 'Khác', 'icon': Icons.more_horiz},
    ],
    1: [
      // Khoản thu
      {'name': 'Lương', 'icon': Icons.account_balance_wallet},
      {'name': 'Thưởng', 'icon': Icons.card_giftcard},
      {'name': 'Đầu tư', 'icon': Icons.trending_up},
      {'name': 'Bán hàng', 'icon': Icons.point_of_sale},
      {'name': 'Làm thêm', 'icon': Icons.work},
      {'name': 'Khác', 'icon': Icons.more_horiz},
    ],
    2: [
      // Vay/Nợ
      {'name': 'Cho vay', 'icon': Icons.arrow_upward},
      {'name': 'Đi vay', 'icon': Icons.arrow_downward},
      {'name': 'Trả nợ', 'icon': Icons.payment},
      {'name': 'Thu nợ', 'icon': Icons.attach_money},
    ],
  };

  // Quick amount buttons
  final List<String> _quickAmounts = [
    '100,000',
    '200,000',
    '500,000',
    '1,000,000',
    '2,000,000',
  ];

  @override
  void initState() {
    super.initState();
    _initializeOCR();
  }

  Future<void> _initializeOCR() async {
    try {
      await _ocrService.initialize();
      print('✅ OCR service initialized successfully');
    } catch (e) {
      print('⚠️ Failed to initialize OCR service: $e');
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    // Responsive spacing
    final verticalSpacing = isSmallScreen ? 8.0 : 16.0;
    final sectionSpacing = isSmallScreen ? 12.0 : 20.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thêm giao dịch',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: AppTheme.textPrimary),
            onPressed: () {
              _showScanOptions();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tab selector (Khoản chi / Khoản thu / Vay/Nợ)
            _buildTabSelector(),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05, // 5% of screen width
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category selector with dropdown
                    Center(child: _buildCategorySelector()),

                    SizedBox(height: sectionSpacing),

                    // Amount display
                    _buildAmountDisplay(),

                    SizedBox(height: verticalSpacing),

                    // Payment Method Selector
                    _buildPaymentMethodSelector(),

                    SizedBox(height: verticalSpacing),

                    // Note field
                    _buildNoteField(),

                    SizedBox(height: verticalSpacing),

                    // Date picker
                    _buildDatePicker(),

                    SizedBox(height: verticalSpacing),

                    // Add details button
                    if (!isSmallScreen) _buildAddDetailsButton(),
                    if (!isSmallScreen) SizedBox(height: verticalSpacing),

                    // Save button (Lưu)
                    _buildSaveButton(),

                    SizedBox(height: sectionSpacing),

                    // Quick amount buttons
                    _buildQuickAmountButtons(),

                    SizedBox(height: sectionSpacing),

                    // Custom numpad
                    _buildCustomNumpad(),

                    SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildTab('Khoản chi', 0),
          _buildTab('Khoản thu', 1),
          _buildTab('Vay/Nợ', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
            // Reset category to first category of new tab
            final categories = _categories[index] ?? [];
            if (categories.isNotEmpty) {
              _selectedCategory = categories[0]['name'] as String;
            }
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    // Get icon for selected category
    IconData categoryIcon = Icons.category;
    final currentCategories = _categories[_selectedTab] ?? [];
    final selectedCat = currentCategories.firstWhere(
      (cat) => cat['name'] == _selectedCategory,
      orElse: () => {'name': _selectedCategory, 'icon': Icons.category},
    );
    categoryIcon = selectedCat['icon'] as IconData;

    return InkWell(
      onTap: _showCategoryPicker,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryTeal,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(categoryIcon, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              _selectedCategory,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    // Get icon for selected payment method
    IconData methodIcon = Icons.payment;
    final selectedMethod = _paymentMethods.firstWhere(
      (method) => method['name'] == _selectedPaymentMethod,
      orElse: () => {'name': _selectedPaymentMethod, 'icon': Icons.payment},
    );
    methodIcon = selectedMethod['icon'] as IconData;

    return GestureDetector(
      onTap: _showPaymentMethodPicker,
      child: Row(
        children: [
          Icon(methodIcon, color: Colors.grey[400]),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedPaymentMethod,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }

  void _showPaymentMethodPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Chọn phương thức thanh toán',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = _paymentMethods[index];
                  final isSelected = method['name'] == _selectedPaymentMethod;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPaymentMethod = method['name'] as String;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryTeal.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryTeal
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            method['icon'] as IconData,
                            size: 32,
                            color: isSelected
                                ? AppTheme.primaryTeal
                                : Colors.grey[600],
                          ),
                          SizedBox(height: 8),
                          Text(
                            method['name'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppTheme.primaryTeal
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountDisplay() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'VND',
            style: TextStyle(
              color: AppTheme.primaryTeal,
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _amount,
              style: TextStyle(
                fontSize: isSmallScreen ? 28 : 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryTeal,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Show category picker dialog
  void _showCategoryPicker() {
    final categories = _categories[_selectedTab] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Chọn danh mục',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category['name'] == _selectedCategory;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category['name'] as String;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryTeal.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryTeal
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category['icon'] as IconData,
                            size: 32,
                            color: isSelected
                                ? AppTheme.primaryTeal
                                : Colors.grey[600],
                          ),
                          SizedBox(height: 8),
                          Text(
                            category['name'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? AppTheme.primaryTeal
                                  : AppTheme.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return Row(
      children: [
        Icon(Icons.note_outlined, color: Colors.grey[400]),
        SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Thêm ghi chú',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // Format date text
    final dateText = isSmallScreen
        ? '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'
        : 'Thứ ${_selectedDate.weekday}, ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';

    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: AppTheme.primaryTeal),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, color: Colors.grey[400]),
          SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_left, color: AppTheme.primaryTeal, size: 20),
                SizedBox(width: 4),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dateText,
                      style: TextStyle(
                        color: AppTheme.primaryTeal,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.primaryTeal,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDetailsButton() {
    return Center(
      child: TextButton(
        onPressed: () {
          // TODO: Show more details
        },
        child: Text(
          'THÊM CHI TIẾT',
          style: TextStyle(
            color: AppTheme.primaryTeal,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    // Check if amount is valid
    bool isValid = _amount != '0' && _amount.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: ElevatedButton(
        onPressed: isValid ? _saveTransaction : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid ? AppTheme.primaryTeal : Colors.grey[200],
          foregroundColor: isValid ? Colors.white : Colors.grey[400],
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Lưu',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    try {
      // Parse amount (remove commas)
      final amountValue = double.parse(_amount.replaceAll(',', ''));

      // Determine transaction type
      model.TransactionType type;
      if (_selectedTab == 0) {
        type = model.TransactionType.expense;
      } else if (_selectedTab == 1) {
        type = model.TransactionType.income;
      } else {
        type = model.TransactionType.loan;
      }

      // Get current user ID
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id ?? '';

      if (userId.isEmpty) {
        throw Exception('User not logged in');
      }

      // Create transaction
      final transaction = model.Transaction(
        id: Uuid().v4(),
        amount: amountValue,
        category: _selectedCategory,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        date: _selectedDate,
        type: type,
        paymentMethod: _selectedPaymentMethod,
        createdAt: DateTime.now(),
        userId: userId,
      );

      // Save to Hive
      await _transactionService.addTransaction(transaction);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lưu giao dịch thành công!'),
            backgroundColor: AppTheme.primaryTeal,
            duration: Duration(seconds: 2),
          ),
        );

        // Go back
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildQuickAmountButtons() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Wrap(
      spacing: isSmallScreen ? 6 : 8,
      runSpacing: isSmallScreen ? 6 : 8,
      alignment: WrapAlignment.center,
      children: _quickAmounts.map((amount) {
        return InkWell(
          onTap: () {
            setState(() {
              _amount = amount;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              amount,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomNumpad() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    // Responsive button height
    final buttonHeight = isSmallScreen ? 48.0 : 56.0;
    final spacing = isSmallScreen ? 6.0 : 8.0;

    return Column(
      children: [
        _buildNumpadRow(
          ['C', '/', '*', '⌫'],
          buttonHeight: buttonHeight,
          spacing: spacing,
        ),
        SizedBox(height: spacing),
        _buildNumpadRow(
          ['7', '8', '9', '-'],
          buttonHeight: buttonHeight,
          spacing: spacing,
        ),
        SizedBox(height: spacing),
        _buildNumpadRow(
          ['4', '5', '6', '+'],
          buttonHeight: buttonHeight,
          spacing: spacing,
        ),
        SizedBox(height: spacing),
        _buildNumpadRow(
          ['1', '2', '3', '→'],
          isLastRow: true,
          buttonHeight: buttonHeight,
          spacing: spacing,
        ),
        SizedBox(height: spacing),
        Row(
          children: [
            Expanded(
              child: _buildNumpadButton('0', buttonHeight: buttonHeight),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _buildNumpadButton('000', buttonHeight: buttonHeight),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _buildNumpadButton('.', buttonHeight: buttonHeight),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: Container(
                height: buttonHeight,
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumpadRow(
    List<String> buttons, {
    bool isLastRow = false,
    double? buttonHeight,
    double? spacing,
  }) {
    final height = buttonHeight ?? 56.0;
    final gap = spacing ?? 8.0;

    return Row(
      children: buttons.map((button) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: button == buttons.last ? 0 : gap),
            child: _buildNumpadButton(
              button,
              isSpecial: isLastRow && button == '→',
              buttonHeight: height,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumpadButton(
    String text, {
    bool isSpecial = false,
    double? buttonHeight,
  }) {
    final height = buttonHeight ?? 56.0;
    Color bgColor;
    Color textColor;

    if (isSpecial) {
      bgColor = AppTheme.primaryTeal;
      textColor = Colors.white;
    } else if (text == 'C' || text == '⌫') {
      bgColor = Colors.grey[200]!;
      textColor = Colors.grey[600]!;
    } else if (text == '/' || text == '*' || text == '-' || text == '+') {
      bgColor = Colors.grey[200]!;
      textColor = Colors.grey[600]!;
    } else {
      bgColor = Colors.grey[100]!;
      textColor = AppTheme.textPrimary;
    }

    return InkWell(
      onTap: () {
        _handleNumpadInput(text);
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: text == '⌫'
              ? Icon(Icons.backspace_outlined, color: textColor, size: 20)
              : text == '→'
              ? Icon(Icons.arrow_forward, color: textColor, size: 20)
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
        ),
      ),
    );
  }

  void _handleNumpadInput(String input) {
    setState(() {
      if (input == 'C') {
        _amount = '0';
      } else if (input == '⌫') {
        if (_amount.length > 1) {
          // Remove last character and reformat
          String temp = _amount.replaceAll(',', '');
          temp = temp.substring(0, temp.length - 1);
          _amount = _formatNumber(temp);
        } else {
          _amount = '0';
        }
      } else if (input == '→') {
        // Submit/Continue action
        _saveTransaction();
      } else if (input == '+' || input == '-' || input == '*' || input == '/') {
        // Calculator functions (optional - can implement later)
      } else {
        // Number input
        String temp = _amount.replaceAll(',', '');
        if (temp == '0') {
          temp = input;
        } else {
          temp += input;
        }
        _amount = _formatNumber(temp);
      }
    });
  }

  String _formatNumber(String number) {
    if (number.isEmpty) return '0';

    // Remove all commas first
    number = number.replaceAll(',', '');

    // Parse to int and format with commas
    try {
      final value = int.parse(number);
      return value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    } catch (e) {
      return number;
    }
  }

  /// Show options to scan from camera or gallery
  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quét hóa đơn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt, color: AppTheme.primaryTeal),
              ),
              title: Text('Chụp ảnh'),
              subtitle: Text(
                'Quét hóa đơn với camera',
                style: TextStyle(fontSize: 11),
              ),
              onTap: _scanFromCamera,
            ),
            SizedBox(height: 10),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library, color: AppTheme.primaryTeal),
              ),
              title: Text('Chọn từ thư viện'),
              subtitle: Text(
                'Chọn ảnh hóa đơn từ thư viện',
                style: TextStyle(fontSize: 11),
              ),
              onTap: _pickFromGallery,
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ========== OCR METHODS ==========

  Future<void> _scanFromCamera() async {
    try {
      Navigator.pop(context); // Close the scan options dialog

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        _showLoadingDialog('Đang xử lý hóa đơn...');

        final result = await _ocrService.scanReceipt(File(image.path));

        Navigator.pop(context); // Close loading dialog

        if (result != null) {
          _processReceiptData(result);
        } else {
          _showErrorDialog('Không thể nhận diện hóa đơn');
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if open
      _showErrorDialog('Lỗi khi chụp ảnh: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      Navigator.pop(context); // Close the scan options dialog

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        _showLoadingDialog('Đang xử lý hóa đơn...');

        final result = await _ocrService.scanReceipt(File(image.path));

        Navigator.pop(context); // Close loading dialog

        if (result != null) {
          _processReceiptData(result);
        } else {
          _showErrorDialog('Không thể nhận diện hóa đơn');
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if open
      _showErrorDialog('Lỗi khi chọn ảnh: $e');
    }
  }

  void _processReceiptData(ReceiptData data) {
    setState(() {
      // Update amount
      if (data.amount > 0) {
        _amount = data.amount.toStringAsFixed(0);
      }

      // Update date
      _selectedDate = data.date;

      // Update category - map from standard to Vietnamese
      final categoryMapping = {
        'Food & Drink': 'Ăn uống',
        'Transport': 'Xăng xe',
        'Shopping': 'Shopping',
        'Entertainment': 'Giải trí',
        'Healthcare': 'Y tế',
        'Education': 'Giáo dục',
        'Bills': 'Hóa đơn',
        'Other': 'Khác',
      };

      final vietnameseCategory =
          categoryMapping[data.category] ?? data.category;
      final currentCategories = _categories[_selectedTab] ?? [];
      if (currentCategories.any((cat) => cat['name'] == vietnameseCategory)) {
        _selectedCategory = vietnameseCategory;
      }

      // Build note from merchant and items
      String noteText = '';
      if (data.merchant != 'Unknown' && data.merchant.isNotEmpty) {
        noteText += 'Cửa hàng: ${data.merchant}\n';
      }
      if (data.items.isNotEmpty) {
        noteText += 'Món: ${data.items.join(", ")}\n';
      }
      if (data.notes != null && data.notes!.isNotEmpty) {
        noteText += data.notes!;
      }

      if (noteText.isNotEmpty) {
        _noteController.text = noteText.trim();
      }
    });

    // Show success message with confidence
    final confidencePercent = (data.confidence * 100).toStringAsFixed(0);
    final confidenceEmoji = data.confidence >= 0.7 ? '✅' : '⚠️';
    final confidenceText = data.confidence >= 0.7
        ? 'Độ tin cậy: $confidencePercent%'
        : 'Độ tin cậy thấp: $confidencePercent% - Vui lòng kiểm tra lại';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$confidenceEmoji Đã quét hóa đơn thành công'),
            SizedBox(height: 4),
            Text(confidenceText, style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: data.confidence >= 0.7
            ? AppTheme.accentGreen
            : Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
