import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/theme.dart';
import 'screens/splash/splash_screen.dart';
import 'services/auth_service.dart';
import 'models/user.dart';
import 'models/transaction.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());

  // Clean up old boxes (only for development)
  if (Hive.isBoxOpen('users')) {
    await Hive.box('users').close();
  }

  // Open boxes with correct types
  await Hive.openBox<User>('users'); // Typed box for User
  await Hive.openBox('session'); // Simple key-value
  await Hive.openBox('preferences'); // Simple key-value

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthService())],
      child: MaterialApp(
        title: 'FinTracker',
        theme: AppTheme.lightTheme,
        home: SplashScreen(), // hoặc HomeScreen(), tùy ý bạn
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
