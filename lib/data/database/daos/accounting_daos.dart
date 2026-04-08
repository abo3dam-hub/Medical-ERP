// lib/data/database/daos/invoices_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';

part 'invoices_dao.g.dart';

@DriftAccessor(tables: [Invoices, InvoiceItems, Visits, Patients])
class InvoicesDao extends DatabaseAccessor<AppDatabase>
    with _$InvoicesDaoMixin {
  InvoicesDao(super.db);

  Future<Invoice?> getByVisitId(int visitId) =>
      (select(invoices)..where((i) => i.visitId.equals(visitId)))
          .getSingleOrNull();

  Future<Invoice?> getById(int id) =>
      (select(invoices)..where((i) => i.id.equals(id))).getSingleOrNull();

  Future<List<InvoiceWithPatient>> getAllWithPatient() {
    return select(invoices).join([
      innerJoin(visits, visits.id.equalsExp(invoices.visitId)),
      innerJoin(patients, patients.id.equalsExp(visits.patientId)),
    ]).map((row) => InvoiceWithPatient(
          invoice: row.readTable(invoices),
          patient: row.readTable(patients),
        )).get();
  }

  Future<List<InvoiceItem>> getItemsByInvoiceId(int invoiceId) =>
      (select(invoiceItems)..where((i) => i.invoiceId.equals(invoiceId))).get();

  Future<int> insertInvoice(InvoicesCompanion inv) =>
      into(invoices).insert(inv);

  Future<int> insertInvoiceItem(InvoiceItemsCompanion item) =>
      into(invoiceItems).insert(item);

  Future<void> updateInvoiceTotals(int invoiceId, double total, double paid) async {
    String status = 'unpaid';
    if (paid >= total) status = 'paid';
    else if (paid > 0) status = 'partial';

    await (update(invoices)..where((i) => i.id.equals(invoiceId))).write(
      InvoicesCompanion(
        totalAmount: Value(total),
        paidAmount: Value(paid),
        status: Value(status),
      ),
    );
  }

  Future<void> lockInvoice(int id) =>
      (update(invoices)..where((i) => i.id.equals(id)))
          .write(const InvoicesCompanion(isLocked: Value(true)));

  // تقارير: إجمالي الإيرادات
  Future<double> getTotalIncome({DateTime? from, DateTime? to}) async {
    final query = select(invoices);
    if (from != null || to != null) {
      query.where((i) {
        Expression<bool> expr = const Constant(true);
        if (from != null) expr = expr & i.createdAt.isBiggerOrEqualValue(from);
        if (to != null) expr = expr & i.createdAt.isSmallerOrEqualValue(to);
        return expr;
      });
    }
    final rows = await query.get();
    return rows.fold(0.0, (sum, r) => sum + r.paidAmount);
  }
}

class InvoiceWithPatient {
  final Invoice invoice;
  final Patient patient;
  InvoiceWithPatient({required this.invoice, required this.patient});
}

// ─────────────────────────────────────────────
// lib/data/database/daos/payments_dao.dart

part 'payments_dao.g.dart';

@DriftAccessor(tables: [Payments, Invoices])
class PaymentsDao extends DatabaseAccessor<AppDatabase>
    with _$PaymentsDaoMixin {
  PaymentsDao(super.db);

  Future<List<Payment>> getByInvoiceId(int invoiceId) =>
      (select(payments)..where((p) => p.invoiceId.equals(invoiceId))).get();

  Future<double> getTotalPaid(int invoiceId) async {
    final rows = await getByInvoiceId(invoiceId);
    return rows.fold(0.0, (sum, p) => sum + p.amount);
  }

  Future<int> addPayment(PaymentsCompanion payment) =>
      into(payments).insert(payment);

  Future<int> deletePayment(int id) =>
      (delete(payments)..where((p) => p.id.equals(id))).go();
}

// ─────────────────────────────────────────────
// lib/data/database/daos/expenses_dao.dart

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

// ─────────────────────────────────────────────
// lib/data/database/daos/cashbox_dao.dart

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

  // تحذير المواد الناقصة
  Future<List<Item>> getLowStockItems() =>
      (select(items)..where((i) => i.quantity.isSmallerOrEqualValue(i.minQuantity))).get();
}

// ─────────────────────────────────────────────
// lib/data/database/daos/audit_dao.dart

part 'audit_dao.g.dart';

@DriftAccessor(tables: [AuditLog])
class AuditDao extends DatabaseAccessor<AppDatabase> with _$AuditDaoMixin {
  AuditDao(super.db);

  Future<int> log({
    required String tableName,
    required int recordId,
    required String actionType,
    String? oldValues,
    String? newValues,
  }) =>
      into(auditLog).insert(AuditLogCompanion(
        tableName: Value(tableName),
        recordId: Value(recordId),
        actionType: Value(actionType),
        oldValues: Value(oldValues),
        newValues: Value(newValues),
      ));

  Future<List<AuditLogData>> getRecentLogs({int limit = 100}) =>
      (select(auditLog)
            ..orderBy([(a) => OrderingTerm.desc(a.timestamp)])
            ..limit(limit))
          .get();
}
