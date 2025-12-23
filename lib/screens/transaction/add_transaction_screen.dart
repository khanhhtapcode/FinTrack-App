import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';

import '../../config/theme.dart';
import '../../models/transaction.dart' as model;
import '../../services/transaction_service.dart';
import '../../services/ocr_service.dart';
import '../../models/receipt_data.dart';
import '../../services/auth_service.dart';
import '../../models/category_group.dart';
import '../../utils/category_icon_mapper.dart';

import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/wallet.dart';
import '../../services/wallet_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  int _selectedTab = 0; // 0: Khoản chi, 1: Khoản thu, 2: Vay/Nợ
  String _selectedCategory = '';
  String _amount = '0';
  DateTime _selectedDate = DateTime.now();

  // Wallets
  List<Wallet> _wallets = [];
  String? _selectedWalletId;

  final TextEditingController _noteController = TextEditingController();
  final TransactionService _transactionService = TransactionService();
  final OcrService _ocrService = OcrService();
  final ImagePicker _imagePicker = ImagePicker();

  /// 🔹 DANH MỤC TỪ HIVE
  List<CategoryGroup> _categories = [];

  // Payment method removed – wallet now represents the source of funds.

  /// Quick amount buttons
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
    _loadCategoriesFromHive();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final service = WalletService();
    await service.init();
    final ws = await service.getAll();
    if (ws.isNotEmpty) {
      setState(() {
        _wallets = ws;
        _selectedWalletId = _wallets.first.id;
      });
    }
  }

  void _loadCategoriesFromHive() {
    final box = Hive.box<CategoryGroup>('category_groups');

    final type = _selectedTab == 0
        ? CategoryType.expense
        : _selectedTab == 1
        ? CategoryType.income
        : null;

    final items = box.values
        .where((c) => type == null || c.type == type)
        .toList();

    setState(() {
      _categories = items;
      if (_categories.isNotEmpty) {
        _selectedCategory = _categories.first.name;
      }
    });
  }

  Future<void> _initializeOCR() async {
    try {
      await _ocrService.initialize();
    } catch (_) {}
  }

  @override
  void dispose() {
    _noteController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  // ================= UI =================

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
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: AppTheme.textPrimary),
            onPressed: _showScanOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabSelector(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCategorySelector(),
                  const SizedBox(height: 20),
                  _buildAmountDisplay(),
                  const SizedBox(height: 16),
                  _buildWalletSelector(),
                  const SizedBox(height: 12),
                  // Payment method removed to avoid duplication with wallet
                  const SizedBox(height: 16),
                  _buildNoteField(),
                  const SizedBox(height: 16),
                  _buildDatePicker(),
                  const SizedBox(height: 20),
                  _buildSaveButton(),
                  const SizedBox(height: 20),
                  _buildQuickAmountButtons(),
                  const SizedBox(height: 20),
                  _buildCustomNumpad(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB =================

  Widget _buildTabSelector() {
    return Row(
      children: [
        _buildTab('Khoản chi', 0),
        _buildTab('Khoản thu', 1),
        _buildTab('Vay/Nợ', 2),
      ],
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedTab = index;
              _loadCategoriesFromHive();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryTeal : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryTeal : Colors.grey.shade300,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryTeal.withAlpha(
                          (0.08 * 255).round(),
                        ),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= CATEGORY =================

  Widget _buildCategorySelector() {
    if (_categories.isEmpty) {
      return const Text('Chưa có danh mục');
    }

    final category = _categories.firstWhere(
      (e) => e.name == _selectedCategory,
      orElse: () => _categories.first,
    );

    return GestureDetector(
      onTap: _showCategoryPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryTeal,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white.withAlpha((0.15 * 255).round()),
              child: Builder(
                builder: (context) {
                  final asset = CategoryIconMapper.assetForKey(
                    category.iconKey,
                  );
                  if (asset != null) {
                    return ClipOval(
                      child: Image.asset(
                        asset,
                        width: 18,
                        height: 18,
                        fit: BoxFit.cover,
                      ),
                    );
                  }
                  return Icon(
                    CategoryIconMapper.fromKey(category.iconKey),
                    color: Colors.white,
                    size: 18,
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Text(
              category.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemCount: _categories.length,
        itemBuilder: (_, index) {
          final c = _categories[index];
          return InkWell(
            onTap: () {
              setState(() => _selectedCategory = c.name);
              Navigator.pop(sheetContext);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Color(c.colorValue),
                  child: Builder(
                    builder: (_) {
                      final asset = CategoryIconMapper.assetForKey(c.iconKey);
                      if (asset != null) {
                        return ClipOval(
                          child: Image.asset(
                            asset,
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                      return Icon(
                        CategoryIconMapper.fromKey(c.iconKey),
                        color: Colors.white,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(c.name, textAlign: TextAlign.center),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= HELPERS =================

  Widget _buildAmountDisplay() {
    final displayAmount = _amount.isEmpty ? '0' : _amount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Số tiền',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  displayAmount,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₫',
                style: TextStyle(fontSize: 20, color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Payment method selector removed

  Widget _buildWalletSelector() {
    final selected = _wallets.firstWhere(
      (w) => w.id == _selectedWalletId,
      orElse: () => _wallets.isNotEmpty
          ? _wallets.first
          : Wallet(
              id: '',
              userId: '',
              name: 'Không có ví',
              type: WalletType.cash,
              balance: 0,
              isDefault: false,
              createdAt: DateTime.now(),
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Chọn ví',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () async {
            FocusScope.of(context).unfocus();
            final chosen = await showModalBottomSheet<Wallet>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (sheetContext) {
                return SafeArea(
                  child: FractionallySizedBox(
                    heightFactor: 0.6,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const Text(
                            'Chọn ví',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _wallets.length,
                              itemBuilder: (context, index) {
                                final w = _wallets[index];
                                return ListTile(
                                  title: Text(w.name),
                                  subtitle: Text('${w.balance} VND'),
                                  trailing: w.id == _selectedWalletId
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.green,
                                        )
                                      : null,
                                  onTap: () {
                                    Navigator.pop(sheetContext, w);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );

            if (chosen != null) setState(() => _selectedWalletId = chosen.id);
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppTheme.primaryTeal,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    selected.name,
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return TextField(
      controller: _noteController,
      maxLines: 3,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.note, size: 20),
        hintText: 'Ghi chú',
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildDatePicker() {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(Duration(days: 365)),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      icon: Icon(Icons.calendar_today, color: AppTheme.primaryTeal),
      label: Text(
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
        style: TextStyle(color: AppTheme.primaryTeal),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ================= SAVE =================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryTeal,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _saveTransaction,
        child: const Text(
          'Lưu',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    final amountValue = double.parse(_amount.replaceAll(',', ''));

    final type = _selectedTab == 0
        ? model.TransactionType.expense
        : _selectedTab == 1
        ? model.TransactionType.income
        : model.TransactionType.loan;

    final auth = context.read<AuthService>();
    final userId = auth.currentUser?.id ?? '';

    final tx = model.Transaction(
      id: const Uuid().v4(),
      amount: amountValue,
      category: _selectedCategory,
      note: _noteController.text,
      date: _selectedDate,
      type: type,
      createdAt: DateTime.now(),
      userId: userId,
      walletId: _selectedWalletId,
    );

    await _transactionService.addTransaction(tx);

    if (mounted) Navigator.pop(context, true);
  }

  Widget _buildQuickAmountButtons() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Wrap(
      spacing: isSmallScreen ? 6 : 8,
      runSpacing: isSmallScreen ? 6 : 8,
      alignment: WrapAlignment.center,
      children: _quickAmounts.map((amount) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            foregroundColor: AppTheme.textPrimary,
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 8 : 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          onPressed: () {
            setState(() {
              _amount = _formatNumber(amount.replaceAll(',', ''));
            });
          },
          child: Text(
            amount,
            style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
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
        // Just close keyboard/focus, don't save
        FocusScope.of(context).unfocus();
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
                  color: AppTheme.primaryTeal.withAlpha((0.1 * 255).round()),
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
                  color: AppTheme.primaryTeal.withAlpha((0.1 * 255).round()),
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
        // Round and format with separators
        _amount = _formatNumber(data.amount.round().toString());
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
      // _categories is a flat list of CategoryGroup; check by name
      if (_categories.any((cat) => cat.name == vietnameseCategory)) {
        _selectedCategory = vietnameseCategory;
      } else if (_categories.isNotEmpty && _selectedCategory.isEmpty) {
        _selectedCategory = _categories.first.name;
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
