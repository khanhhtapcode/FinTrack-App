import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Flow',
      theme: AppTheme.lightTheme,
      home: SplashScreen(), // Bắt đầu từ splash
      debugShowCheckedModeBanner: false,
    );
  }
}
