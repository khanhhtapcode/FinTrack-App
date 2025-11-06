import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  String _selectedLanguage = 'vi'; // 'vi' for Vietnamese, 'en' for English

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'QUẢN LÝ VÀ GIÁM SÁT\nCHI TIÊU HÀNG NGÀY',
      'subtitle':
          'Theo dõi mọi khoản chi tiêu một cách dễ dàng và chính xác nhất.',
      'icon': Icons.analytics_outlined,
      'color': Color(0xFF4ECDC4),
    },
    {
      'title': 'NHẬP CHI HÓA ĐƠN\nTỰ ĐỘNG, DỄ DÀNG',
      'subtitle': 'Quét mã QR hoặc chụp ảnh hóa đơn để tự động nhập thông tin.',
      'icon': Icons.receipt_long_outlined,
      'color': Color(0xFF3498DB),
    },
    {
      'title': 'THIẾT LẬP NGÂN SÁCH\nHẠN MỨC PHÙ HỢP',
      'subtitle':
          'Đặt ngân sách hàng tháng và nhận thông báo khi sắp vượt mức.',
      'icon': Icons.savings_outlined,
      'color': Color(0xFF27AE60),
    },
    {
      'title': 'BẢO MẬT TỐI ƯU\nAN TOÀN TUYỆT ĐỐI',
      'subtitle':
          'Dữ liệu được mã hóa và bảo vệ với công nghệ bảo mật tiên tiến.',
      'icon': Icons.security_outlined,
      'color': Color(0xFF2C3E50),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) => _buildPage(_pages[index]),
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo Section
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4ECDC4),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FINTRAKCER',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  Text(
                    'Smart spend, Bright future',
                    style: TextStyle(fontSize: 10, color: Color(0xFF7F8C8D)),
                  ),
                ],
              ),
            ],
          ),

          // Language Selector
          PopupMenuButton<String>(
            offset: Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (String value) {
              setState(() {
                _selectedLanguage = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'vi',
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      size: 16,
                      color: _selectedLanguage == 'vi'
                          ? Color(0xFF4ECDC4)
                          : Colors.transparent,
                    ),
                    SizedBox(width: 8),
                    Text('Tiếng Việt'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      size: 16,
                      color: _selectedLanguage == 'en'
                          ? Color(0xFF4ECDC4)
                          : Colors.transparent,
                    ),
                    SizedBox(width: 8),
                    Text('English'),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF4ECDC4), width: 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language, size: 16, color: Color(0xFF4ECDC4)),
                  SizedBox(width: 4),
                  Text(
                    _selectedLanguage == 'vi' ? 'Tiếng Việt' : 'English',
                    style: TextStyle(
                      color: Color(0xFF4ECDC4),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Color(0xFF4ECDC4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> page) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              color: page['color'].withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: page['color'].withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: page['color'].withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: page['color'],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: page['color'].withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(page['icon'], size: 40, color: Colors.white),
                ),
              ],
            ),
          ),

          SizedBox(height: 48),

          Text(
            page['title'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
              height: 1.3,
            ),
          ),

          SizedBox(height: 16),

          Text(
            page['subtitle'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF7F8C8D),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // Page Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: _currentIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? _pages[_currentIndex]['color']
                      : Color(0xFF7F8C8D).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          SizedBox(height: 32),

          // Single Register Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return RegisterScreen();
                    },
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4ECDC4),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'ĐĂNG KÝ MIỄN PHÍ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          SizedBox(height: 4),

          // Login Link
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return LoginScreen();
                  },
                ),
              );
            },
            child: Text(
              'ĐĂNG NHẬP',
              style: TextStyle(
                color: Color(0xFF4ECDC4),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 8),
          // Version Text
          Text(
            'Phiên bản 1.1',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
