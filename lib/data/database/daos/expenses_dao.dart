// lib/data/database/daos/expenses_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';

part 'expenses_dao.g.dart';

@DriftAccessor(tables: [Expenses])
class ExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$ExpensesDaoMixin {
  ExpensesDao(super.db);

  Future<List<Expense>> getAll() => select(expenses).get();

  Future<List<Expense>> getByDateRange(DateTime from, DateTime to) =>
      (select(expenses)
            ..where((e) =>
                e.date.isBiggerOrEqualValue(from) &
                e.date.isSmallerOrEqualValue(to)))
          .get();

  Future<double> getTotalExpenses({DateTime? from, DateTime? to}) async {
    final rows = from != null && to != null
        ? await getByDateRange(from, to)
        : await getAll();
    return rows.fold(0.0, (sum, e) => sum + e.amount);
  }

  Future<int> insertExpense(ExpensesCompanion expense) =>
      into(expenses).insert(expense);

  Future<int> deleteExpense(int id) =>
      (delete(expenses)..where((e) => e.id.equals(id))).go();
}
