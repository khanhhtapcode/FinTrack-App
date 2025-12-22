import 'package:expense_tracker_app/services/app_localization.dart';
import 'package:flutter/material.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('vi_VN', null);
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();

  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());

  if (Hive.isBoxOpen('users')) {
    await Hive.box('users').close();
  }

  await Hive.openBox<User>('users');
  await Hive.openBox('session');
  await Hive.openBox('preferences');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppSettingsProvider>(
      future: AppSettingsProvider.create(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return MultiProvider(
          providers: [
            
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
      ,

            ChangeNotifierProvider<AppSettingsProvider>.value(
              value: snapshot.data!,
            ),
          ],
          child: Consumer<AppSettingsProvider>(
            builder: (context, settings, _) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'FinTracker',

                // 🔥 CHỈ CẦN THẾ NÀY
                locale: Locale(settings.language),

                theme: AppTheme.lightTheme,
                home: const SplashScreen(),
              );
            },
          ),
        );
      },
    );
  }
}
