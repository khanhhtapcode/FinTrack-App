import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../models/user.dart';
import 'email_service.dart';

class AuthService extends ChangeNotifier {
  static const String _userBoxName = 'users';
  static const String _sessionBoxName = 'session';

  User? _currentUser;
  String? _currentOTP;
  String? _pendingEmail; // Email waiting for OTP verification

  // Admin credentials (hardcoded)
  static const String ADMIN_EMAIL = 'admin@fintracker.com';
  static const String ADMIN_PASSWORD = 'Admin@123'; // Mật khẩu admin

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.email == ADMIN_EMAIL;

  // Hash password using SHA256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate random user ID
  String _generateUserId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(10000).toString();
  }

  // Generate 4-digit OTP
  String _generateOTP() {
    return (1000 + Random().nextInt(9000)).toString();
  }

  // Register User (Step 1: Create account, send OTP)
  Future<Map<String, dynamic>> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    try {
      final box = await Hive.openBox<User>(_userBoxName);

      // Check if email already exists
      if (box.values.any((user) => user.email == email)) {
        return {'success': false, 'message': 'Email đã tồn tại'};
      }

      // Generate OTP
      _currentOTP = _generateOTP();
      _pendingEmail = email;

      // Send OTP via email
      bool emailSent = await EmailService.sendOTP(email, _currentOTP!);

      if (!emailSent) {
        return {
          'success': false,
          'message': 'Không thể gửi email. Vui lòng thử lại.',
        };
      }

      // Store user data temporarily (not saved until OTP verified)
      final tempUser = User(
        id: _generateUserId(),
        email: email,
        firstName: firstName,
        lastName: lastName,
        passwordHash: _hashPassword(password),
        createdAt: DateTime.now(),
        isVerified: false,
      );

      // Save temporarily (will be saved permanently after OTP verification)
      await box.put(email, tempUser);

      notifyListeners();

      return {'success': true, 'message': 'OTP đã được gửi đến $email'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String otp) async {
    try {
      if (_currentOTP == null || _pendingEmail == null) {
        return {
          'success': false,
          'message': 'Không tìm thấy OTP. Vui lòng đăng ký lại.',
        };
      }

      if (otp != _currentOTP) {
        return {'success': false, 'message': 'OTP không đúng'};
      }

      // OTP correct - mark user as verified
      final box = await Hive.openBox<User>(_userBoxName);
      final user = box.get(_pendingEmail);

      if (user != null) {
        user.isVerified = true;
        await user.save();
        _currentUser = user;
        await _saveSession(user);
      }

      // Clear OTP
      _currentOTP = null;
      _pendingEmail = null;

      notifyListeners();

      return {'success': true, 'message': 'Xác thực thành công!'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Save User Preferences (from Favorites screen)
  Future<void> savePreferences(List<String> preferences) async {
    if (_currentUser != null) {
      _currentUser!.preferences = preferences;
      await _currentUser!.save();
      notifyListeners();
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Check if admin login
      if (email == ADMIN_EMAIL) {
        if (password == ADMIN_PASSWORD) {
          // Create admin user object
          _currentUser = User(
            id: 'admin',
            email: ADMIN_EMAIL,
            firstName: 'Admin',
            lastName: 'System',
            passwordHash: _hashPassword(ADMIN_PASSWORD),
            createdAt: DateTime.now(),
            isVerified: true,
          );

          await _saveSession(_currentUser!);
          notifyListeners();

          return {
            'success': true,
            'message': 'Đăng nhập Admin thành công!',
            'user': _currentUser,
            'isAdmin': true,
          };
        } else {
          return {'success': false, 'message': 'Mật khẩu Admin không đúng'};
        }
      }

      // Normal user login
      final box = await Hive.openBox<User>(_userBoxName);
      final user = box.get(email);

      if (user == null) {
        return {'success': false, 'message': 'Email không tồn tại'};
      }

      if (!user.isVerified) {
        return {'success': false, 'message': 'Tài khoản chưa được xác thực'};
      }

      String hashedPassword = _hashPassword(password);
      if (user.passwordHash != hashedPassword) {
        return {'success': false, 'message': 'Mật khẩu không đúng'};
      }

      // Login successful
      user.lastLoginAt = DateTime.now();
      await user.save();
      _currentUser = user;
      await _saveSession(user);
      notifyListeners();

      return {
        'success': true,
        'message': 'Đăng nhập thành công!',
        'user': user,
        'isAdmin': false,
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Save session
  Future<void> _saveSession(User user) async {
    final sessionBox = await Hive.openBox(_sessionBoxName);
    await sessionBox.put('current_user_email', user.email);
    await sessionBox.put('login_time', DateTime.now().toIso8601String());
  }

  // Check and restore session
  Future<void> checkSession() async {
    final sessionBox = await Hive.openBox(_sessionBoxName);
    final userEmail = sessionBox.get('current_user_email');

    if (userEmail != null) {
      final userBox = await Hive.openBox<User>(_userBoxName);
      _currentUser = userBox.get(userEmail);
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    final sessionBox = await Hive.openBox(_sessionBoxName);
    await sessionBox.clear();
    _currentUser = null;
    notifyListeners();
  }

  // Resend OTP
  Future<Map<String, dynamic>> resendOTP() async {
    if (_pendingEmail == null) {
      return {'success': false, 'message': 'Không tìm thấy email'};
    }

    _currentOTP = _generateOTP();
    bool emailSent = await EmailService.sendOTP(_pendingEmail!, _currentOTP!);

    if (!emailSent) {
      return {'success': false, 'message': 'Không thể gửi email'};
    }

    return {'success': true, 'message': 'OTP mới đã được gửi'};
  }
}
