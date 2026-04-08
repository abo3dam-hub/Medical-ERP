// lib/data/database/daos/inventory_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';

part 'inventory_dao.g.dart';

@DriftAccessor(tables: [Items, StockMovements])
class InventoryDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryDaoMixin {
  InventoryDao(super.db);

  Stream<List<Item>> watchItems() => select(items).watch();
  Future<List<Item>> getItems() => select(items).get();

  Future<Item?> getItemById(int id) =>
      (select(items)..where((i) => i.id.equals(id))).getSingleOrNull();

  Future<int> insertItem(ItemsCompanion item) => into(items).insert(item);
  Future<bool> updateItem(ItemsCompanion item) => update(items).replace(item);
  Future<int> deleteItem(int id) =>
      (delete(items)..where((i) => i.id.equals(id))).go();

  Future<void> adjustStock(int itemId, int delta) async {
    final item = await getItemById(itemId);
    if (item == null) return;
    final newQty = item.quantity + delta;
    if (newQty < 0) throw Exception('المخزون لا يمكن أن يكون سالباً');
    await (update(items)..where((i) => i.id.equals(itemId)))
        .write(ItemsCompanion(quantity: Value(newQty)));
  }

  Future<int> addMovement(StockMovementsCompanion mov) =>
      into(stockMovements).insert(mov);

  Future<List<StockMovement>> getMovementsForItem(int itemId) =>
      (select(stockMovements)
            ..where((m) => m.itemId.equals(itemId))
            ..orderBy([(m) => OrderingTerm.desc(m.date)]))
          .get();

  Future<List<Item>> getLowStockItems() => (select(items)
        ..where((i) => i.quantity.isSmallerOrEqualValue(i.minQuantity)))
      .get();
}
