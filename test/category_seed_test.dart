import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:expense_tracker_app/models/category_group.dart';
import 'package:expense_tracker_app/services/category_group_service.dart';
import 'package:expense_tracker_app/utils/category_seed.dart';

void main() {
  late Directory tmpDir;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('fintrack_cat_test');
    Hive.init(tmpDir.path);

    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(CategoryGroupAdapter().typeId)) {
      Hive.registerAdapter(CategoryGroupAdapter());
    }
    if (!Hive.isAdapterRegistered(CategoryTypeAdapter().typeId)) {
      Hive.registerAdapter(CategoryTypeAdapter());
    }

    await Hive.openBox<CategoryGroup>('category_groups');
  });

  tearDown(() async {
    await Hive.close();
    try {
      await tmpDir.delete(recursive: true);
    } catch (_) {}
  });

  test('seedIfNeeded adds categories and is idempotent', () async {
    final service = CategoryGroupService();

    final added = await CategorySeed.seedIfNeeded(service);
    expect(added.isNotEmpty, true);

    // calling again should add nothing
    final added2 = await CategorySeed.seedIfNeeded(service);
    expect(added2.isEmpty, true);

    final all = await service.getAll();
    expect(all.where((g) => g.isSystem).isNotEmpty, true);
  });

  test(
    'resetSystemCategoriesForDev deletes and reseeds system categories',
    () async {
      final service = CategoryGroupService();

      // ensure seeded
      await CategorySeed.seedIfNeeded(service);

      // add a user category that should survive
      final userCat = CategoryGroup(
        id: 'user_cat_1',
        name: 'My Special',
        type: CategoryType.expense,
        iconKey: 'star',
        colorValue: 0xFF000000,
        isSystem: false,
        createdAt: DateTime.now(),
      );

      await service.add(userCat);

      final removedAndAdded = await CategorySeed.resetSystemCategoriesForDev(
        service,
      );

      expect(removedAndAdded.isNotEmpty, true);

      final all = await service.getAll();
      // user category should still exist
      expect(all.any((g) => g.id == 'user_cat_1'), true);
      // system category should be present again (check by name)
      expect(all.any((g) => g.isSystem && g.name == 'Ăn uống'), true);
    },
  );

  test('system category cannot be renamed without allowSystemEdit', () async {
    final service = CategoryGroupService();
    await CategorySeed.seedIfNeeded(service);

    final all = await service.getAll();
    final sys = all.firstWhere(
      (g) => g.isSystem,
      orElse: () => throw Exception('No system category'),
    );

    final modified = CategoryGroup(
      id: sys.id,
      name: sys.name + ' Renamed',
      type: sys.type,
      iconKey: sys.iconKey,
      colorValue: sys.colorValue,
      isSystem: sys.isSystem,
      createdAt: sys.createdAt,
    );

    expect(() async => await service.update(modified), throwsArgumentError);

    // allowSystemEdit should permit the change
    await service.update(modified, allowSystemEdit: true);

    final reloaded = (await service.getAll()).firstWhere((g) => g.id == sys.id);
    expect(reloaded.name, modified.name);
  });
}
