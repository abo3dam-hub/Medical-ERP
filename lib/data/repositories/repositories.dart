// lib/data/repositories/patient_repository.dart
import 'dart:convert';
import '../../domain/repositories/i_patient_repository.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart';

class PatientRepository implements IPatientRepository {
  final AppDatabase _db;

  PatientRepository(this._db);

  @override
  Stream<List<Patient>> watchAll() => _db.patientsDao.watchAll();

  @override
  Future<List<Patient>> getAll() => _db.patientsDao.getAll();

  @override
  Future<List<Patient>> search(String query) =>
      _db.patientsDao.search(query);

  @override
  Future<Patient?> getById(int id) => _db.patientsDao.getById(id);

  @override
  Future<int> create(PatientsCompanion patient) async {
    final id = await _db.patientsDao.insertPatient(patient);
    await _db.auditDao.log(
      tableName: 'patients',
      recordId: id,
      actionType: 'INSERT',
      newValues: jsonEncode(patient.toJson()),
    );
    return id;
  }

  @override
  Future<bool> update(PatientsCompanion patient) async {
    final old = await getById(patient.id.value);
    final result = await _db.patientsDao.updatePatient(patient);
    await _db.auditDao.log(
      tableName: 'patients',
      recordId: patient.id.value,
      actionType: 'UPDATE',
      oldValues: jsonEncode(old?.toJson()),
      newValues: jsonEncode(patient.toJson()),
    );
    return result;
  }

  @override
  Future<int> delete(int id) async {
    final old = await getById(id);
    final result = await _db.patientsDao.deletePatient(id);
    await _db.auditDao.log(
      tableName: 'patients',
      recordId: id,
      actionType: 'DELETE',
      oldValues: jsonEncode(old?.toJson()),
    );
    return result;
  }
}

// ─────────────────────────────────────────────
// lib/data/repositories/invoice_repository.dart

class InvoiceRepository {
  final AppDatabase _db;

  InvoiceRepository(this._db);

  Future<Invoice?> getByVisitId(int visitId) =>
      _db.invoicesDao.getByVisitId(visitId);

  Future<List<InvoiceItem>> getItems(int invoiceId) =>
      _db.invoicesDao.getItemsByInvoiceId(invoiceId);

  Future<List<Payment>> getPayments(int invoiceId) =>
      _db.paymentsDao.getByInvoiceId(invoiceId);

  // إنشاء فاتورة من الإجراءات
  Future<Invoice> createOrUpdateFromVisit(int visitId) async {
    final procs = await _db.visitsDao.getProceduresForVisit(visitId);
    final total = procs.fold(0.0, (sum, p) => sum + p.total);

    final existing = await _db.invoicesDao.getByVisitId(visitId);

    if (existing != null) {
      // تحديث الفاتورة الموجودة
      await _db.invoicesDao.updateInvoiceTotals(
        existing.id,
        total,
        existing.paidAmount,
      );
      return (await _db.invoicesDao.getById(existing.id))!;
    } else {
      // إنشاء فاتورة جديدة
      final invoiceId = await _db.invoicesDao.insertInvoice(
        InvoicesCompanion(
          visitId: Value(visitId),
          totalAmount: Value(total),
        ),
      );

      // إضافة بنود الفاتورة
      for (final proc in procs) {
        await _db.invoicesDao.insertInvoiceItem(
          InvoiceItemsCompanion(
            invoiceId: Value(invoiceId),
            procedureName: Value(proc.procedureId.toString()),
            price: Value(proc.price),
            quantity: Value(proc.quantity),
            total: Value(proc.total),
          ),
        );
      }

      return (await _db.invoicesDao.getById(invoiceId))!;
    }
  }

  // إضافة دفعة مع التحقق من عدم الإفراط في الدفع
  Future<void> addPayment({
    required int invoiceId,
    required double amount,
  }) async {
    final invoice = await _db.invoicesDao.getById(invoiceId);
    if (invoice == null) throw Exception('الفاتورة غير موجودة');
    if (invoice.isLocked) throw Exception('الفاتورة مقفلة ولا يمكن تعديلها');

    final remaining = invoice.totalAmount - invoice.paidAmount;
    if (amount > remaining) {
      throw Exception('المبلغ المدفوع أكبر من المتبقي (${remaining.toStringAsFixed(2)})');
    }

    await _db.paymentsDao.addPayment(
      PaymentsCompanion(
        invoiceId: Value(invoiceId),
        amount: Value(amount),
      ),
    );

    final newPaid = invoice.paidAmount + amount;
    await _db.invoicesDao.updateInvoiceTotals(
      invoiceId,
      invoice.totalAmount,
      newPaid,
    );

    // تحديث صندوق النقدية
    await _updateCashBoxIncome(amount);
  }

  Future<void> _updateCashBoxIncome(double amount) async {
    final today = DateTime.now();
    final existing = await _db.cashBoxDao.getByDate(today);
    if (existing != null) {
      final newIncome = existing.totalIncome + amount;
      final newClosing = existing.openingBalance + newIncome - existing.totalExpense;
      await _db.cashBoxDao.upsertCashBox(CashBoxCompanion(
        id: Value(existing.id),
        date: Value(existing.date),
        openingBalance: Value(existing.openingBalance),
        totalIncome: Value(newIncome),
        totalExpense: Value(existing.totalExpense),
        closingBalance: Value(newClosing),
      ));
    }
  }
}
