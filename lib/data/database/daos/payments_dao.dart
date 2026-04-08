// lib/data/database/daos/payments_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';

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
