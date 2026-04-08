// lib/data/database/daos/cashbox_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';

part 'cashbox_dao.g.dart';

@DriftAccessor(tables: [CashBox])
class CashBoxDao extends DatabaseAccessor<AppDatabase>
    with _$CashBoxDaoMixin {
  CashBoxDao(super.db);

  Future<CashBoxData?> getByDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return (select(cashBox)
          ..where((c) =>
              c.date.isBiggerOrEqualValue(dayStart) &
              c.date.isSmallerValue(dayEnd)))
        .getSingleOrNull();
  }

  Future<int> upsertCashBox(CashBoxCompanion entry) =>
      into(cashBox).insertOnConflictUpdate(entry);

  Future<void> closeDay(int id) =>
      (update(cashBox)..where((c) => c.id.equals(id)))
          .write(const CashBoxCompanion(isClosed: Value(true)));

  Future<List<CashBoxData>> getHistory({int limit = 30}) =>
      (select(cashBox)
            ..orderBy([(c) => OrderingTerm.desc(c.date)])
            ..limit(limit))
          .get();
}

// ─────────────────────────────────────────────
// lib/data/database/daos/inventory_dao.dart
