import 'package:expense_tracker_app/screens/profile/account/account_management_screen.dart';
import 'package:expense_tracker_app/screens/wallet/wallets_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/app_localization.dart';
import '../../services/app_settings_provider.dart';
import '../auth/login_screen.dart';
import 'settings/settings_screen.dart';
import '../about/about_screen.dart';

// ============================================================================
// PROFILE SCREEN - User profile with settings and menu options
// ============================================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    return Consumer<AppSettingsProvider>(
      builder: (context, settings, _) {
        t(String key) => AppStrings.t(key, language: settings.language);

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: Text(t('account')),
            backgroundColor: AppTheme.cardColor,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () => _showHelpDialog(context, t),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(currentUser, t),
                const SizedBox(height: 16),
                _buildMenuSection(context, t),
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

  Widget _buildProfileHeader(dynamic user, Function(String) t) {
    final userName = user?.fullName ?? 'User';
    final userEmail = user?.email ?? 'email@example.com';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AccountManagementScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        color: AppTheme.cardColor,
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      t('free_account'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Name
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Email
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, Function(String) t) {
    return Column(
      children: [
        // Account Section
        Container(
          color: AppTheme.cardColor,
          child: Column(
            children: [
              _buildMenuItem(
                icon: Icons.person_outline,
                title: t('account_management'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountManagementScreen(),
                    ),
                  );
                },
              ),
              _buildDivider(),

              _buildMenuItem(
                icon: Icons.account_balance_wallet_outlined,
                title: t('my_wallets'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyWalletScreen(),
                    ),
                  );
                },
              ),
              _buildDivider(),

              _buildMenuItem(
                icon: Icons.settings_outlined,
                title: t('settings'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Features Section
        Container(
          color: AppTheme.cardColor,
          child: Column(
            children: [
              _buildMenuItem(
                icon: Icons.category_outlined,
                title: t('category_groups'),
                onTap: () => _showComingSoonDialog(context, t),
              ),
              _buildDivider(),

              _buildMenuItem(
                icon: Icons.repeat,
                title: t('recurring_transactions'),
                onTap: () => _showComingSoonDialog(context, t),
              ),
              _buildDivider(),

              _buildMenuItem(
                icon: Icons.build_outlined,
                title: t('tools'),
                onTap: () => _showComingSoonDialog(context, t),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Info & Support Section
        Container(
          color: AppTheme.cardColor,
          child: Column(
            children: [
              _buildMenuItem(
                icon: Icons.explore_outlined,
                title: t('explore_fintracker'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
              _buildDivider(),

              _buildMenuItem(
                icon: Icons.help_outline,
                title: t('help'),
                onTap: () => _showHelpDialog(context, t),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Logout Section
        Container(
          color: AppTheme.cardColor,
          child: _buildMenuItem(
            icon: Icons.logout,
            title: t('logout'),
            onTap: () => _showLogoutDialog(context, t),
            textColor: Colors.red,
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
  // DIALOGS
  // ========================================================================

  void _showLogoutDialog(BuildContext context, Function(String) t) {
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
            onPressed: () async {
              final authService = Provider.of<AuthService>(
                context,
                listen: false,
              );
              await authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(t('logout'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, Function(String) t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('coming_soon')),
        content: Text(t('feature_under_development')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('ok')),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context, Function(String) t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('help')),
        content: Text('${t('need_support')}\n\n${t('support_info')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('close')),
          ),
        ],
      ),
    );
  }
}
