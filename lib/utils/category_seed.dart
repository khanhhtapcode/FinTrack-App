import 'package:uuid/uuid.dart';
import '../models/category_group.dart';
import '../services/category_group_service.dart';

class CategorySeed {
  /// Seeds system category groups if they are missing.
  ///
  /// Returns the list of names that were actually added. Useful for admin
  /// feedback UI to show what was newly created.
  static Future<List<String>> seedIfNeeded([
    CategoryGroupService? service,
  ]) async {
    final serviceToUse = service ?? CategoryGroupService();
    const uuid = Uuid();

    // Existing groups
    final existing = await serviceToUse.getAll();
    final existingSet = existing
        .map((e) => '${e.type.index}::${e.name.trim().toLowerCase()}')
        .toSet();

    final added = <String>[];

    // Define system defaults per request
    final defaults = <CategoryGroup>[
      // ===== EXPENSE (System) - Sắp xếp alphabetically, "Khác" ở cuối =====
      CategoryGroup(
        id: uuid.v4(),
        name: 'Ăn uống',
        type: CategoryType.expense,
        iconKey: 'food',
        colorValue: 0xFF4CAF50,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Đi lại',
        type: CategoryType.expense,
        iconKey: 'car',
        colorValue: 0xFFFF9800,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Du lịch',
        type: CategoryType.expense,
        iconKey: 'travel',
        colorValue: 0xFF03A9F4,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Gia đình',
        type: CategoryType.expense,
        iconKey: 'family',
        colorValue: 0xFF795548,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Giáo dục',
        type: CategoryType.expense,
        iconKey: 'education',
        colorValue: 0xFF3F51B5,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Giải trí',
        type: CategoryType.expense,
        iconKey: 'entertainment',
        colorValue: 0xFFFFC107,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Hóa đơn',
        type: CategoryType.expense,
        iconKey: 'bill',
        colorValue: 0xFFFF5722,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Làm đẹp',
        type: CategoryType.expense,
        iconKey: 'beauty',
        colorValue: 0xFFFF4081,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Mua sắm',
        type: CategoryType.expense,
        iconKey: 'shopping',
        colorValue: 0xFF9C27B0,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Nhà cửa',
        type: CategoryType.expense,
        iconKey: 'home',
        colorValue: 0xFF8BC34A,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Phí & Lệ phí',
        type: CategoryType.expense,
        iconKey: 'fee',
        colorValue: 0xFF607D8B,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Quần áo',
        type: CategoryType.expense,
        iconKey: 'clothing',
        colorValue: 0xFFE91E63,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Thể thao',
        type: CategoryType.expense,
        iconKey: 'fitness',
        colorValue: 0xFF00BCD4,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Y tế',
        type: CategoryType.expense,
        iconKey: 'health',
        colorValue: 0xFF4DD0E1,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      // "Khác" ở dưới cùng
      CategoryGroup(
        id: uuid.v4(),
        name: 'Khác (Khoản chi)',
        type: CategoryType.expense,
        iconKey: 'other',
        colorValue: 0xFF9E9E9E,
        isSystem: true,
        createdAt: DateTime.now(),
      ),

      // ===== INCOME (System) - Sắp xếp alphabetically, "Khác" ở cuối =====
      CategoryGroup(
        id: uuid.v4(),
        name: 'Đầu tư',
        type: CategoryType.income,
        iconKey: 'investment',
        colorValue: 0xFF673AB7,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Lương',
        type: CategoryType.income,
        iconKey: 'salary',
        colorValue: 0xFF2196F3,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Thưởng',
        type: CategoryType.income,
        iconKey: 'bonus',
        colorValue: 0xFF00BCD4,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      // "Khác" ở dưới cùng
      CategoryGroup(
        id: uuid.v4(),
        name: 'Khác (Khoản thu)',
        type: CategoryType.income,
        iconKey: 'other_income',
        colorValue: 0xFF9E9E9E,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
    ];

    for (final c in defaults) {
      final key = '${c.type.index}::${c.name.trim().toLowerCase()}';
      if (!existingSet.contains(key)) {
        // add only missing defaults
        try {
          await serviceToUse.add(c);
          added.add(c.name);
        } catch (_) {
          // ignore if already exists due to race/edge case
        }
      }
    }

    return added;
  }

  /// Remove duplicate categories per type (keeps first occurrence).
  /// Deduplication based on (type, normalized_name).
  static Future<void> deduplicateCategories([
    CategoryGroupService? service,
  ]) async {
    final svc = service ?? CategoryGroupService();
    final all = await svc.getAll();

    // Group by type
    final byType = <int, List<CategoryGroup>>{};
    for (final cat in all) {
      byType.putIfAbsent(cat.type.index, () => []).add(cat);
    }

    // Within each type, keep only first of each normalized name
    final seen = <int, Set<String>>{}; // type.index -> set of normalized names
    final toDelete = <String>[]; // IDs to delete

    for (final type in byType.keys) {
      seen[type] = {};
      final cats = byType[type]!;
      for (final cat in cats) {
        final normalized = cat.name.trim().toLowerCase();
        if (seen[type]!.contains(normalized)) {
          toDelete.add(cat.id);
        } else {
          seen[type]!.add(normalized);
        }
      }
    }

    // Delete duplicates
    for (final id in toDelete) {
      try {
        await svc.delete(id);
      } catch (_) {
        // ignore
      }
    }
  }

  /// Clean up invalid income categories (expense categories mistakenly typed as income).
  /// Removes: Du lịch & Nghỉ dưỡng, Gia đình & Trẻ em, Hóa đơn & Tiện ích, Nhà ở, 
  ///          Quần áo & Phụ kiện, Thể thao & Fitness, Y tế & Sức khỏe
  static Future<int> cleanupInvalidIncomeCategories([
    CategoryGroupService? service,
  ]) async {
    final svc = service ?? CategoryGroupService();
    final all = await svc.getAll();

    // List of expense category names that shouldn't exist in income type
    final invalidIncomeNames = {
      'du lịch & nghỉ dưỡng',
      'du lịch',
      'gia đình & trẻ em',
      'gia đình',
      'hóa đơn & tiện ích',
      'hóa đơn',
      'nhà ở',
      'quần áo & phụ kiện',
      'quần áo',
      'thể thao & fitness',
      'thể thao',
      'y tế & sức khỏe',
      'y tế',
    };

    var deletedCount = 0;
    final incomeCategories = all.where((c) => c.type == CategoryType.income).toList();

    for (final cat in incomeCategories) {
      final normalized = cat.name.trim().toLowerCase();
      if (invalidIncomeNames.contains(normalized)) {
        try {
          await svc.delete(cat.id);
          deletedCount++;
        } catch (_) {
          // ignore
        }
      }
    }

    return deletedCount;
  }

  /// Clean up invalid expense categories (outdated/renamed categories).
  /// Removes: Du lịch & Nghỉ dưỡng, Gia đình & Trẻ em, Hóa đơn & Tiện ích, Nhà ở,
  ///          Quần áo & Phụ kiện, Thể thao & Fitness, Y tế & Sức khỏe
  static Future<int> cleanupInvalidExpenseCategories([
    CategoryGroupService? service,
  ]) async {
    final svc = service ?? CategoryGroupService();
    final all = await svc.getAll();

    // List of outdated/combined expense category names to remove
    final invalidExpenseNames = {
      'du lịch & nghỉ dưỡng',
      'gia đình & trẻ em',
      'hóa đơn & tiện ích',
      'nhà ở',
      'quần áo & phụ kiện',
      'thể thao & fitness',
      'y tế & sức khỏe',
    };

    var deletedCount = 0;
    final expenseCategories = all.where((c) => c.type == CategoryType.expense).toList();

    for (final cat in expenseCategories) {
      final normalized = cat.name.trim().toLowerCase();
      if (invalidExpenseNames.contains(normalized)) {
        try {
          await svc.delete(cat.id);
          deletedCount++;
        } catch (_) {
          // ignore
        }
      }
    }

    return deletedCount;
  }

  /// Reset system categories (DEV only): delete and reseed.
  /// Returns list of names that were removed and re-added.
  static Future<List<String>> resetSystemCategoriesForDev([
    CategoryGroupService? service,
  ]) async {
    final svc = service ?? CategoryGroupService();
    final existing = await svc.getAll();
    final removed = existing
        .where((e) => e.isSystem)
        .map((e) => e.name)
        .toList();

    // Delete system categories
    await svc.deleteSystemCategories();

    // Reseed
    final added = await seedIfNeeded(svc);

    return removed..addAll(added);
  }
}
