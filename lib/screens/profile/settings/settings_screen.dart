import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../services/app_localization.dart';
import '../../../services/app_settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _languages = ['Tiếng Việt', 'English'];
  final List<String> _languageCodes = ['vi', 'en'];
  final List<String> _currencies = ['VND', 'USD', 'EUR', 'JPY'];
  final List<String> _dateFormats = ['dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'];
  final List<String> _weekDays = ['Monday', 'Sunday'];
  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settings, _) {
        t(String key) =>
            AppStrings.t(key, language: settings.language);

        if (settings.isLoading) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              title: Text(t('settings')),
              backgroundColor: AppTheme.cardColor,
            ),
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: Text(t('settings')),
            backgroundColor: AppTheme.cardColor,
            elevation: 0,
            centerTitle: false,
          ),
          body: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // ===================== DISPLAY SECTION =====================
              _buildSectionHeader(t('display')),

              _buildSettingItem(
                context: context,
                title: t('language'),
                subtitle: _getLanguageName(settings.language),
                icon: Icons.language,
                onTap: () => _showLanguagePicker(context, settings),
              ),
              _buildDivider(),

              _buildSettingItem(
                context: context,
                title: t('currency'),
                subtitle: settings.currency,
                icon: Icons.attach_money,
                onTap: () => _showCurrencyPicker(context, settings),
              ),
              _buildDivider(),

              _buildSettingItem(
                context: context,
                title: t('date_format'),
                subtitle: settings.dateFormat,
                icon: Icons.calendar_today_outlined,
                onTap: () => _showDateFormatPicker(context, settings),
              ),
              _buildDivider(),

              _buildSettingItem(
                context: context,
                title: t('first_day_week'),
                subtitle: settings.firstDayOfWeek,
                icon: Icons.event_outlined,
                onTap: () => _showWeekDayPicker(context, settings),
              ),
              _buildDivider(),

              _buildSettingItem(
                context: context,
                title: t('first_day_month'),
                subtitle: settings.firstDayOfMonth,
                icon: Icons.date_range_outlined,
                onTap: () => _showDayOfMonthPicker(context, settings),
              ),
              _buildDivider(),

              _buildSettingItem(
                context: context,
                title: t('first_month_year'),
                subtitle: settings.firstMonthOfYear,
                icon: Icons.calendar_month_outlined,
                onTap: () => _showMonthOfYearPicker(context, settings),
              ),

              const SizedBox(height: 24),

              // ===================== NOTIFICATION SECTION =====================
              _buildSectionHeader(t('notifications')),

              _buildSwitchItem(
                context: context,
                title: t('show_notifications'),
                subtitle: t('allow_notifications'),
                icon: Icons.notifications_outlined,
                value: settings.showNotifications,
                onChanged: (value) async {
                  await settings.setShowNotifications(value);
                },
              ),
              _buildDivider(),

              _buildSwitchItem(
                context: context,
                title: t('notification_sound'),
                subtitle: t('enable_sound'),
                icon: Icons.volume_up_outlined,
                value: settings.soundEnabled,
                onChanged: settings.showNotifications
                    ? (value) async => await settings.setSoundEnabled(value)
                    : null,
              ),
              _buildDivider(),

              _buildSwitchItem(
                context: context,
                title: t('vibration'),
                subtitle: t('enable_vibration'),
                icon: Icons.vibration,
                value: settings.vibrationEnabled,
                onChanged: settings.showNotifications
                    ? (value) async => await settings.setVibrationEnabled(value)
                    : null,
              ),

              const SizedBox(height: 24),

              // ===================== ABOUT SECTION =====================
              _buildSectionHeader(t('about')),

              _buildInfoItem(
                context: context,
                title: t('version'),
                subtitle: '1.0.0',
                icon: Icons.info_outlined,
              ),
              _buildDivider(),

              _buildSettingItem(
                context: context,
                title: t('privacy'),
                icon: Icons.privacy_tip_outlined,
                onTap: () => _showComingSoon(context, t('privacy')),
              ),
              _buildDivider(),

              _buildSettingItem(
                context: context,
                title: t('terms'),
                icon: Icons.description_outlined,
                onTap: () => _showComingSoon(context, t('terms')),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // ========================================================================
  // WIDGET BUILDERS
  // ========================================================================

  Widget _buildSectionHeader(String title) {
    return Container(
      color: AppTheme.cardColor,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.primaryTeal,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Container(
      color: AppTheme.cardColor,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryTeal, size: 24),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          color: AppTheme.textSecondary,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      color: AppTheme.cardColor,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryTeal, size: 24),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool)? onChanged,
  }) {
    final isEnabled = onChanged != null;

    return Container(
      color: AppTheme.cardColor,
      child: ListTile(
        enabled: isEnabled,
        leading: Icon(
          icon,
          color: isEnabled ? AppTheme.primaryTeal : Colors.grey,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isEnabled ? AppTheme.textPrimary : Colors.grey,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isEnabled ? AppTheme.textSecondary : Colors.grey,
          ),
        ),
        trailing: Switch(
          value: isEnabled ? value : false,
          onChanged: onChanged,
          activeColor: AppTheme.primaryTeal,
          inactiveTrackColor: Colors.grey[300],
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
  // PICKER DIALOGS
  // ========================================================================

  void _showLanguagePicker(BuildContext context, AppSettingsProvider settings) {
    t(String key) => AppStrings.t(key, language: settings.language);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _languages.length,
            (index) => ListTile(
              leading: Radio<String>(
                value: _languageCodes[index],
                groupValue: settings.language,
                onChanged: (value) {
                  Navigator.pop(context);
                  if (value != null) {
                    settings.setLanguage(value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppStrings.t('language_changed', language: value),
                        ),
                        backgroundColor: AppTheme.primaryTeal,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                activeColor: AppTheme.primaryTeal,
              ),
              title: Text(_languages[index]),
              onTap: () {
                Navigator.pop(context);
                settings.setLanguage(_languageCodes[index]);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppStrings.t(
                        'language_changed',
                        language: _languageCodes[index],
                      ),
                    ),
                    backgroundColor: AppTheme.primaryTeal,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, AppSettingsProvider settings) {
    t(String key) => AppStrings.t(key, language: settings.language);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('currency')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _currencies.length,
            (index) => ListTile(
              leading: Radio<String>(
                value: _currencies[index],
                groupValue: settings.currency,
                onChanged: (value) {
                  Navigator.pop(context);
                  if (value != null) {
                    settings.setCurrency(value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(t('currency_changed')),
                        backgroundColor: AppTheme.primaryTeal,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                activeColor: AppTheme.primaryTeal,
              ),
              title: Text(_currencies[index]),
              onTap: () {
                Navigator.pop(context);
                settings.setCurrency(_currencies[index]);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t('currency_changed')),
                    backgroundColor: AppTheme.primaryTeal,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showDateFormatPicker(
    BuildContext context,
    AppSettingsProvider settings,
  ) {
    t(String key) => AppStrings.t(key, language: settings.language);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('date_format')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _dateFormats.length,
            (index) => ListTile(
              leading: Radio<String>(
                value: _dateFormats[index],
                groupValue: settings.dateFormat,
                onChanged: (value) {
                  Navigator.pop(context);
                  if (value != null) {
                    settings.setDateFormat(value);
                  }
                },
                activeColor: AppTheme.primaryTeal,
              ),
              title: Text(_dateFormats[index]),
              onTap: () {
                Navigator.pop(context);
                settings.setDateFormat(_dateFormats[index]);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showWeekDayPicker(BuildContext context, AppSettingsProvider settings) {
    t(String key) => AppStrings.t(key, language: settings.language);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('first_day_week')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _weekDays.length,
            (index) => ListTile(
              leading: Radio<String>(
                value: _weekDays[index],
                groupValue: settings.firstDayOfWeek,
                onChanged: (value) {
                  Navigator.pop(context);
                  if (value != null) {
                    settings.setFirstDayOfWeek(value);
                  }
                },
                activeColor: AppTheme.primaryTeal,
              ),
              title: Text(_weekDays[index]),
              onTap: () {
                Navigator.pop(context);
                settings.setFirstDayOfWeek(_weekDays[index]);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showDayOfMonthPicker(
    BuildContext context,
    AppSettingsProvider settings,
  ) {
    t(String key) => AppStrings.t(key, language: settings.language);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('first_day_month')),
        content: SizedBox(
          width: 300,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 31,
            itemBuilder: (context, index) {
              final day = (index + 1).toString();
              final isSelected = settings.firstDayOfMonth == day;

              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  settings.setFirstDayOfMonth(day);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryTeal : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryTeal : Colors.grey,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showMonthOfYearPicker(
    BuildContext context,
    AppSettingsProvider settings,
  ) {
    t(String key) => AppStrings.t(key, language: settings.language);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('first_month_year')),
        content: SizedBox(
          width: 300,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = _months[index];
              final isSelected = settings.firstMonthOfYear == month;

              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  settings.setFirstMonthOfYear(month);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryTeal : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryTeal : Colors.grey,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      month.substring(0, 3),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature sẽ sớm được cập nhật'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.primaryTeal,
      ),
    );
  }

  String _getLanguageName(String code) {
    final index = _languageCodes.indexOf(code);
    return index >= 0 ? _languages[index] : _languages[0];
  }
}
