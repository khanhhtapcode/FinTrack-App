import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/theme.dart';
import 'screens/splash/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/app_settings_provider.dart';

import 'models/user.dart';
import 'models/transaction.dart';
import 'models/category_group.dart';
import 'utils/category_seed.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('vi_VN', null);

  // ================== HIVE (LUÔN KHỞI TẠO) ==================
  await Hive.initFlutter();

  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());
  Hive.registerAdapter(CategoryGroupAdapter());
  Hive.registerAdapter(CategoryTypeAdapter());

  await Hive.openBox<User>('users');
  await Hive.openBox<CategoryGroup>('category_groups');
  await Hive.openBox('session');
  await Hive.openBox('preferences');

  // Seed system categories (idempotent)
  try {
    await CategorySeed.seedIfNeeded();
  } catch (e) {
    debugPrint('Category seeding failed: $e');
  }

  // ================== MOBILE ONLY ==================
  if (!kIsWeb) {
    await dotenv.load(fileName: '.env');

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase init skipped: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'FinTracker',
            locale: Locale(settings.language),
            theme: AppTheme.lightTheme,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
