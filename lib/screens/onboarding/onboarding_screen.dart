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
            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                            'MONEY FLOW',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          Text(
                            'Smart spend, Bright future',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text(
                      'ĐĂNG NHẬP',
                      style: TextStyle(
                        color: Color(0xFF4ECDC4),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
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
                                child: Icon(
                                  page['icon'],
                                  size: 40,
                                  color: Colors.white,
                                ),
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
                },
              ),
            ),

            // Bottom Section
            Container(
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

                  // Navigation Buttons
                  Row(
                    children: [
                      if (_currentIndex > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _pages[_currentIndex]['color'],
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'QUAY LẠI',
                              style: TextStyle(
                                color: _pages[_currentIndex]['color'],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      if (_currentIndex > 0) SizedBox(width: 16),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentIndex == _pages.length - 1) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterScreen(),
                                ),
                              );
                            } else {
                              _pageController.nextPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pages[_currentIndex]['color'],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _currentIndex == _pages.length - 1
                                ? 'ĐĂNG KÝ MIỄN PHÍ'
                                : 'TIẾP THEO',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  if (_currentIndex == 0)
                    TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          _pages.length - 1,
                          duration: Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        'Bỏ qua',
                        style: TextStyle(
                          color: Color(0xFF7F8C8D),
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
