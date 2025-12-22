import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../config/theme.dart';
import '../../../models/user.dart';
import '../../../services/app_localization.dart';
import '../../../services/app_settings_provider.dart';
import '../../auth/login_screen.dart';

// ============================================================================
// ACCOUNT MANAGEMENT SCREEN - Change password, delete account
// ============================================================================

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  User? currentUser;

  // ========================================================================
  // LIFECYCLE
  // ========================================================================

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userBox = await Hive.openBox<User>('users');
    final users = userBox.values.toList();

    if (users.isNotEmpty) {
      setState(() {
        currentUser = users.first;
      });
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ========================================================================
  // BUILD
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settings, _) {
        t(String key) => AppStrings.t(key, language: settings.language);

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: Text(t('account_management')),
            backgroundColor: AppTheme.cardColor,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildUserHeader(t),
                const SizedBox(height: 32),
                Container(
                  color: AppTheme.cardColor,
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.lock_outline,
                        title: t('change_password'),
                        onTap: () => _showChangePasswordDialog(t),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.delete_outline,
                        title: t('delete_account'),
                        onTap: () => _showDeleteAccountDialog(t),
                        textColor: Colors.red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _showLogoutDialog(t),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        t('logout'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========================================================================
  // UI COMPONENTS
  // ========================================================================

  Widget _buildUserHeader(Function(String) t) {
    final userName = currentUser?.fullName ?? 'User';
    final userEmail = currentUser?.email ?? 'email@example.com';

    return Column(
      children: [
        // Avatar
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              currentUser?.firstName.isNotEmpty == true
                  ? currentUser!.firstName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Username
        Text(
          userName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 4),

        // Email
        Text(
          userEmail,
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),

        const SizedBox(height: 8),

        // Verified Badge
        if (currentUser?.isVerified == true)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 16, color: Colors.green[700]),
                const SizedBox(width: 4),
                Text(
                  t('verified'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: textColor ?? AppTheme.textPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor ?? AppTheme.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      color: Colors.grey[200],
    );
  }

  // ========================================================================
  // CHANGE PASSWORD
  // ========================================================================

  void _showChangePasswordDialog(Function(String) t) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t('change_password')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Old Password
                TextField(
                  controller: oldPasswordController,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: t('current_password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureOld ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() => obscureOld = !obscureOld);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // New Password
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: t('new_password'),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() => obscureNew = !obscureNew);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: t('confirm_new_password'),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() => obscureConfirm = !obscureConfirm);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t('password_mismatch'))),
                  );
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t('password_too_short'))),
                  );
                  return;
                }

                final success = await _changePassword(
                  oldPasswordController.text,
                  newPasswordController.text,
                  t,
                );

                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t('password_changed_success')),
                      backgroundColor: AppTheme.primaryTeal,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
              ),
              child: Text(t('confirm')),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _changePassword(
    String oldPassword,
    String newPassword,
    Function(String) t,
  ) async {
    try {
      if (currentUser == null) return false;

      // Verify old password
      final oldPasswordHash = _hashPassword(oldPassword);
      if (currentUser!.passwordHash != oldPasswordHash) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('current_password_incorrect'))),
          );
        }
        return false;
      }

      // Update password
      final newPasswordHash = _hashPassword(newPassword);
      currentUser!.passwordHash = newPasswordHash;
      await currentUser!.save();
      setState(() {});

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${t('error')}: $e')));
      }
      return false;
    }
  }

  // ========================================================================
  // DELETE ACCOUNT
  // ========================================================================

  void _showDeleteAccountDialog(Function(String) t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete_account')),
        content: Text(t('confirm_delete_account')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              await _deleteAccount(t);
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t('delete_account')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(Function(String) t) async {
    try {
      final userBox = await Hive.openBox<User>('users');

      if (currentUser != null) {
        // Delete user from Hive
        await userBox.delete(currentUser!.id);

        // Delete all user transactions
        try {
          final transactionBox = await Hive.openBox('transactions');
          final userTransactions = transactionBox.values
              .where((t) => t.userId == currentUser!.id)
              .toList();

          for (var transaction in userTransactions) {
            await transactionBox.delete(transaction.key);
          }
        } catch (e) {
          print('Error deleting transactions: $e');
        }

        // Clear session
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        final sessionBox = await Hive.openBox('session');
        await sessionBox.clear();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('account_deleted_success')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('delete_account_error')}: $e')),
        );
      }
    }
  }

  // ========================================================================
  // LOGOUT
  // ========================================================================

  void _showLogoutDialog(Function(String) t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('logout')),
        content: Text(t('confirm_logout')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(t('logout'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
