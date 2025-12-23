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
      // ===== EXPENSE (System) =====
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
        name: 'Nhà cửa',
        type: CategoryType.expense,
        iconKey: 'home',
        colorValue: 0xFF8BC34A,
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
        name: 'Y tế',
        type: CategoryType.expense,
        iconKey: 'health',
        colorValue: 0xFF4DD0E1,
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
        name: 'Mua sắm',
        type: CategoryType.expense,
        iconKey: 'shopping',
        colorValue: 0xFF9C27B0,
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
        name: 'Làm đẹp',
        type: CategoryType.expense,
        iconKey: 'beauty',
        colorValue: 0xFFFF4081,
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
        name: 'Phí & Lệ phí',
        type: CategoryType.expense,
        iconKey: 'fee',
        colorValue: 0xFF607D8B,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Khác (Khoản chi)',
        type: CategoryType.expense,
        iconKey: 'other',
        colorValue: 0xFF9E9E9E,
        isSystem: true,
        createdAt: DateTime.now(),
      ),

      // ===== INCOME (System) =====
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
        name: 'Khác (Khoản thu)',
        type: CategoryType.income,
        iconKey: 'other_income',
        colorValue: 0xFF9E9E9E,
        isSystem: true,
        createdAt: DateTime.now(),
      ),

      // ===== LOAN / DEBT (System) - added as expense type for compatibility =====
      CategoryGroup(
        id: uuid.v4(),
        name: 'Cho vay',
        type: CategoryType.expense,
        iconKey: 'loan',
        colorValue: 0xFF607D8B,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Đi vay',
        type: CategoryType.expense,
        iconKey: 'debt',
        colorValue: 0xFF795548,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Thu nợ',
        type: CategoryType.expense,
        iconKey: 'collect',
        colorValue: 0xFF4CAF50,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Trả nợ',
        type: CategoryType.expense,
        iconKey: 'repay',
        colorValue: 0xFFF44336,
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
