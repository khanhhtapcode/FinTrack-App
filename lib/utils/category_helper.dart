import 'package:flutter/material.dart';

/// Helper class untuk mapping category ke icon, color, dan format
class CategoryHelper {
  /// Map category name ke Material Icon
  static IconData getCategoryIcon(String category) {
    const iconMap = {
      'Ăn uống': Icons.restaurant,
      'Mua sắm': Icons.shopping_bag,
      'Giải trí': Icons.movie,
      'Di chuyển': Icons.directions_car,
      'Sức khỏe': Icons.local_hospital,
      'Giáo dục': Icons.school,
      'Lương': Icons.attach_money,
      'Thưởng': Icons.card_giftcard,
      'Đầu tư': Icons.trending_up,
    };
    return iconMap[category] ?? Icons.category;
  }

  /// Map category name ke Color
  static Color getCategoryColor(String category) {
    const colorMap = {
      'Ăn uống': Colors.orange,
      'Mua sắm': Colors.pink,
      'Giải trí': Colors.purple,
      'Di chuyển': Colors.blue,
      'Sức khỏe': Colors.red,
      'Giáo dục': Colors.green,
      'Lương': Colors.teal,
      'Thưởng': Colors.amber,
      'Đầu tư': Colors.indigo,
    };
    return colorMap[category] ?? Colors.grey;
  }

  /// Get category display name (capitalize first letter)
  static String getDisplayName(String category) {
    if (category.isEmpty) return category;
    return category[0].toUpperCase() + category.substring(1);
  }

  /// Get all available categories
  static List<String> getAllCategories() {
    return [
      'Ăn uống',
      'Mua sắm',
      'Giải trí',
      'Di chuyển',
      'Sức khỏe',
      'Giáo dục',
      'Lương',
      'Thưởng',
      'Đầu tư',
    ];
  }
}
