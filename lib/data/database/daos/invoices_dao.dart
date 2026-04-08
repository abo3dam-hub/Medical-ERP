// lib/data/database/daos/invoices_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/medical_tables.dart';

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
      (select(invoiceItems)..where((i) => i.invoiceId.equals(invoiceId)))
          .get();

  Future<int> insertInvoice(InvoicesCompanion inv) =>
      into(invoices).insert(inv);

  Future<int> insertInvoiceItem(InvoiceItemsCompanion item) =>
      into(invoiceItems).insert(item);

  Future<void> updateInvoiceTotals(
      int invoiceId, double total, double paid) async {
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

  Future<double> getTotalIncome({DateTime? from, DateTime? to}) async {
    final query = select(invoices);
    if (from != null || to != null) {
      query.where((i) {
        Expression<bool> expr = const Constant(true);
        if (from != null)
          expr = expr & i.createdAt.isBiggerOrEqualValue(from);
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
