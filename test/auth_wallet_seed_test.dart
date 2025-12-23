import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';

import 'package:expense_tracker_app/models/user.dart';
import 'package:expense_tracker_app/models/wallet.dart';
import 'package:expense_tracker_app/services/auth_service.dart';
import 'package:expense_tracker_app/services/wallet_service.dart';

void main() {
  late Directory tmpDir;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('fintrack_test');
    Hive.init(tmpDir.path);

    // Register adapters (guarded in case adapters already registered in test runner)
    if (!Hive.isAdapterRegistered(UserAdapter().typeId)) {
      Hive.registerAdapter(UserAdapter());
    }
    if (!Hive.isAdapterRegistered(WalletAdapter().typeId)) {
      Hive.registerAdapter(WalletAdapter());
    }
    if (!Hive.isAdapterRegistered(WalletTypeAdapter().typeId)) {
      Hive.registerAdapter(WalletTypeAdapter());
    }

    // Open boxes used in tests
    await Hive.openBox<User>('users');
    await Hive.openBox('session');
    await Hive.openBox<Wallet>('wallets');
  });

  tearDown(() async {
    await Hive.close();
    try {
      await tmpDir.delete(recursive: true);
    } catch (_) {}
  });

  test('login seeds default wallets for user', () async {
    final users = Hive.box<User>('users');

    // Prepare a verified user with known password
    final email = 'jane@example.com';
    final password = 'password123';
    final hashed = sha256.convert(utf8.encode(password)).toString();

    final user = User(
      id: 'user_jane',
      email: email,
      firstName: 'Jane',
      lastName: 'Doe',
      passwordHash: hashed,
      createdAt: DateTime.now(),
      isVerified: true,
    );

    await users.put(email, user);

    final auth = AuthService();
    final res = await auth.login(email: email, password: password);
    expect(res['success'], true, reason: 'Login should succeed');

    // Check wallets seeded
    final ws = WalletService();
    final wallets = await ws.getAll(userId: user.id);
    expect(
      wallets.length,
      greaterThanOrEqualTo(3),
      reason: 'Should have at least 3 seeded wallets',
    );

    final cash = wallets.firstWhere(
      (w) => w.id == 'wallet_cash_${user.id}',
      orElse: () => throw Exception('cash wallet missing'),
    );
    expect(cash.isDefault, true, reason: 'Cash wallet should be default');
  });

  test('session restore schedules wallet seeding', () async {
    final users = Hive.box<User>('users');
    final session = Hive.box('session');

    final email = 'sam@example.com';
    final user = User(
      id: 'user_sam',
      email: email,
      firstName: 'Sam',
      lastName: 'Green',
      passwordHash: sha256.convert(utf8.encode('pw')).toString(),
      createdAt: DateTime.now(),
      isVerified: true,
    );

    await users.put(email, user);
    await session.put('current_user_email', email);

    final auth = AuthService();
    await auth.checkSession();

    // Allow background seeding to run
    await Future.delayed(Duration(milliseconds: 600));

    final ws = WalletService();
    final wallets = await ws.getAll(userId: user.id);
    expect(wallets.length, greaterThanOrEqualTo(3));
  });

  test('admin login does not seed wallets', () async {
    final session = Hive.box('session');
    final auth = AuthService();

    final res = await auth.login(
      email: AuthService.ADMIN_EMAIL,
      password: AuthService.ADMIN_PASSWORD,
    );
    expect(res['success'], true);

    final ws = WalletService();
    final all = await ws.getAll();
    // Ensure no wallet belongs to admin id
    expect(all.where((w) => w.userId == 'admin').isEmpty, true);
  });
}
