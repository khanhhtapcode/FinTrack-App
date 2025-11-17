import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/transaction.dart' as model;
import '../../services/transaction_service.dart';
import '../../services/ocr_service.dart';
import 'package:uuid/uuid.dart';

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
  final OCRService _ocrService = OCRService();

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
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          // Tab selector (Khoản chi / Khoản thu / Vay/Nợ)
          _buildTabSelector(),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category selector with dropdown
                  Center(child: _buildCategorySelector()),

                  SizedBox(height: 20),

                  // Amount display
                  _buildAmountDisplay(),

                  SizedBox(height: 16),

                  // Payment Method Selector
                  _buildPaymentMethodSelector(),

                  SizedBox(height: 16),

                  // Note field
                  _buildNoteField(),

                  SizedBox(height: 16),

                  // Date picker
                  _buildDatePicker(),

                  SizedBox(height: 24),

                  // Add details button
                  _buildAddDetailsButton(),

                  SizedBox(height: 16),

                  // Save button (Lưu)
                  _buildSaveButton(),

                  SizedBox(height: 20),

                  // Quick amount buttons
                  _buildQuickAmountButtons(),

                  SizedBox(height: 20),

                  // Custom numpad
                  _buildCustomNumpad(),
                ],
              ),
            ),
          ),
        ],
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
              fontSize: 14,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            _amount,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryTeal,
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
          Row(
            children: [
              Icon(Icons.chevron_left, color: AppTheme.primaryTeal, size: 20),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Thứ năm, ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: TextStyle(color: AppTheme.primaryTeal, fontSize: 14),
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.chevron_right, color: AppTheme.primaryTeal, size: 20),
            ],
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _quickAmounts.map((amount) {
        return InkWell(
          onTap: () {
            setState(() {
              _amount = amount;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              amount,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomNumpad() {
    return Column(
      children: [
        _buildNumpadRow(['C', '/', '*', '⌫']),
        SizedBox(height: 8),
        _buildNumpadRow(['7', '8', '9', '-']),
        SizedBox(height: 8),
        _buildNumpadRow(['4', '5', '6', '+']),
        SizedBox(height: 8),
        _buildNumpadRow(['1', '2', '3', '→'], isLastRow: true),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildNumpadButton('0')),
            SizedBox(width: 8),
            Expanded(child: _buildNumpadButton('000')),
            SizedBox(width: 8),
            Expanded(child: _buildNumpadButton('.')),
            SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 56,
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

  Widget _buildNumpadRow(List<String> buttons, {bool isLastRow = false}) {
    return Row(
      children: buttons.map((button) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: button == buttons.last ? 0 : 8),
            child: _buildNumpadButton(
              button,
              isSpecial: isLastRow && button == '→',
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumpadButton(String text, {bool isSpecial = false}) {
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
        height: 56,
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
              subtitle: Text('Sử dụng camera để quét hóa đơn'),
              onTap: () {
                Navigator.pop(context);
                _scanFromCamera();
              },
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
              subtitle: Text('Chọn ảnh hóa đơn có sẵn'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Scan receipt from camera
  Future<void> _scanFromCamera() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryTeal),
              SizedBox(height: 16),
              Text('Đang xử lý hóa đơn...'),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await _ocrService.scanFromCamera();

      if (mounted) Navigator.pop(context); // Close loading

      if (result != null) {
        _processOCRResult(result);
      } else {
        _showErrorDialog(
          'Không thể mở camera.\n\n'
          'Vui lòng kiểm tra:\n'
          '• Quyền truy cập camera\n'
          '• Camera có hoạt động không',
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      print('Camera scan error: $e');
      _showErrorDialog(
        'Lỗi khi quét hóa đơn\n\n'
        'Chi tiết: ${e.toString()}\n\n'
        'Thử:\n'
        '• Cấp quyền camera trong Settings\n'
        '• Khởi động lại ứng dụng',
      );
    }
  }

  /// Pick receipt from gallery
  Future<void> _pickFromGallery() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryTeal),
              SizedBox(height: 16),
              Text('Đang xử lý hóa đơn...'),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await _ocrService.pickFromGallery();

      if (mounted) Navigator.pop(context); // Close loading

      if (result != null) {
        _processOCRResult(result);
      } else {
        _showErrorDialog(
          'Không thể chọn ảnh.\n\n'
          'Vui lòng kiểm tra:\n'
          '• Quyền truy cập thư viện ảnh\n'
          '• Có ảnh trong thư viện không',
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      print('Gallery pick error: $e');
      _showErrorDialog(
        'Lỗi khi xử lý ảnh\n\n'
        'Chi tiết: ${e.toString()}\n\n'
        'Thử:\n'
        '• Cấp quyền thư viện ảnh trong Settings\n'
        '• Chọn ảnh khác\n'
        '• Khởi động lại ứng dụng',
      );
    }
  }

  /// Process OCR result and fill in the form
  void _processOCRResult(OCRResult result) {
    setState(() {
      // Fill in amount if detected
      if (result.amount != null && result.amount! > 0) {
        _amount = _formatNumber(result.amount!.toInt().toString());
      }

      // Fill in suggested category if detected
      if (result.suggestedCategories.isNotEmpty) {
        _selectedCategory = result.suggestedCategories.first;
      }

      // Add full text to notes
      if (result.fullText.isNotEmpty) {
        _noteController.text = 'Quét từ hóa đơn';
      }
    });

    // Show success dialog with details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Quét thành công'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.amount != null)
              Text(
                '✓ Số tiền: ${_formatNumber(result.amount!.toInt().toString())} ₫',
              ),
            if (result.suggestedCategories.isNotEmpty)
              Text(
                '✓ Danh mục gợi ý: ${result.suggestedCategories.join(", ")}',
              ),
            SizedBox(height: 10),
            Text(
              'Vui lòng kiểm tra và chỉnh sửa nếu cần.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppTheme.primaryTeal)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text('Lỗi'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppTheme.primaryTeal)),
          ),
        ],
      ),
    );
  }
}
