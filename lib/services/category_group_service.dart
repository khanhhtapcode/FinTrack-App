import 'package:hive/hive.dart';
import '../models/category_group.dart';

class CategoryGroupService {
  static const _boxName = 'category_groups';

  Box<CategoryGroup> get _box => Hive.box<CategoryGroup>(_boxName);

  Future<List<CategoryGroup>> getAll({CategoryType? type}) async {
    final list = _box.values.toList();

    if (type == null) return list;
    return list.where((e) => e.type == type).toList();
  }

  Future<void> add(CategoryGroup group) async {
    final nameNorm = group.name.trim().toLowerCase();

    // Disallow adding a user category that duplicates an existing system category (same type)
    final existing = _box.values.toList();
    final duplicateSystem = existing.any(
      (e) =>
          e.isSystem &&
          e.name.trim().toLowerCase() == nameNorm &&
          e.type == group.type,
    );
    if (duplicateSystem && !group.isSystem) {
      throw ArgumentError('Tên nhóm trùng với danh mục hệ thống');
    }

    // Disallow any duplicate name within same type
    final duplicateAny = existing.any(
      (e) => e.name.trim().toLowerCase() == nameNorm && e.type == group.type,
    );
    if (duplicateAny) {
      throw ArgumentError('Nhóm danh mục đã tồn tại');
    }

    await _box.put(group.id, group);
  }

  /// Update an existing CategoryGroup.
  ///
  /// By default, system categories (isSystem==true) cannot have their name
  /// or type changed by normal calls. Pass [allowSystemEdit=true] only when
  /// the caller is an admin performing a controlled change (or tests).
  Future<void> update(
    CategoryGroup group, {
    bool allowSystemEdit = false,
  }) async {
    final existing = _box.get(group.id);
    if (existing == null) {
      throw ArgumentError('Nhóm danh mục không tồn tại');
    }

    if (existing.isSystem && !allowSystemEdit) {
      // Disallow renaming or type change for system categories
      if (existing.name.trim().toLowerCase() !=
              group.name.trim().toLowerCase() ||
          existing.type != group.type) {
        throw ArgumentError(
          'Không thể chỉnh sửa tên hoặc loại của danh mục hệ thống',
        );
      }
    }

    // Also prevent creating a non-system group with the same name as an existing system group
    final nameNorm = group.name.trim().toLowerCase();
    final duplicateSystem = _box.values.any(
      (e) =>
          e.isSystem &&
          e.name.trim().toLowerCase() == nameNorm &&
          e.type == group.type &&
          e.id != group.id,
    );
    if (duplicateSystem && !group.isSystem) {
      throw ArgumentError('Tên nhóm trùng với danh mục hệ thống');
    }

    await _box.put(group.id, group);
  }

  Future<void> delete(String id) async {
    final group = _box.get(id);
    if (group == null) return;
    if (group.isSystem) {
      throw ArgumentError('Không thể xóa danh mục hệ thống');
    }

    await _box.delete(id);
  }

  /// Delete all system categories (DEV only). Use with caution.
  Future<void> deleteSystemCategories() async {
    final toDelete = _box.values.where((g) => g.isSystem).toList();
    for (final g in toDelete) {
      await _box.delete(g.id);
    }
  }

  bool get isEmpty => _box.isEmpty;
}
