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

  Future<void> delete(String id) async {
    final group = _box.get(id);
    if (group == null) return;
    if (group.isSystem) {
      throw ArgumentError('Không thể xóa danh mục hệ thống');
    }

    await _box.delete(id);
  }

  bool get isEmpty => _box.isEmpty;
}
