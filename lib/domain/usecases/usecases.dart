// lib/domain/repositories/i_patient_repository.dart
import 'package:drift/drift.dart';
import '../../data/database/app_database.dart';

abstract class IPatientRepository {
  Stream<List<Patient>> watchAll();
  Future<List<Patient>> getAll();
  Future<List<Patient>> search(String query);
  Future<Patient?> getById(int id);
  Future<int> create(PatientsCompanion patient);
  Future<bool> update(PatientsCompanion patient);
  Future<int> delete(int id);
}

// ─────────────────────────────────────────────
// lib/domain/usecases/patient_usecases.dart

class CreatePatientUseCase {
  final IPatientRepository _repo;
  CreatePatientUseCase(this._repo);

  Future<int> call({
    required String name,
    String? phone,
    DateTime? birthDate,
    String? notes,
  }) {
    if (name.trim().length < 2) throw Exception('الاسم يجب أن يكون حرفين على الأقل');

    return _repo.create(PatientsCompanion(
      name: Value(name.trim()),
      phone: Value(phone?.trim()),
      birthDate: Value(birthDate),
      notes: Value(notes),
    ));
  }
}

class UpdatePatientUseCase {
  final IPatientRepository _repo;
  UpdatePatientUseCase(this._repo);

  Future<bool> call({
    required int id,
    required String name,
    String? phone,
    DateTime? birthDate,
    String? notes,
  }) {
    if (name.trim().length < 2) throw Exception('الاسم يجب أن يكون حرفين على الأقل');

    return _repo.update(PatientsCompanion(
      id: Value(id),
      name: Value(name.trim()),
      phone: Value(phone?.trim()),
      birthDate: Value(birthDate),
      notes: Value(notes),
    ));
  }
}

class DeletePatientUseCase {
  final IPatientRepository _repo;
  DeletePatientUseCase(this._repo);

  Future<void> call(int id) async {
    // التحقق من عدم وجود زيارات مرتبطة
    await _repo.delete(id);
  }
}

// ─────────────────────────────────────────────
// lib/domain/usecases/visit_usecases.dart

class CreateVisitUseCase {
  final AppDatabase _db;
  CreateVisitUseCase(this._db);

  Future<int> call({
    required int patientId,
    required int doctorId,
    int? appointmentId,
    String? notes,
  }) async {
    final visitId = await _db.visitsDao.insertVisit(VisitsCompanion(
      patientId: Value(patientId),
      doctorId: Value(doctorId),
      appointmentId: Value(appointmentId),
      notes: Value(notes),
    ));

    // تحديث حالة الموعد إن وجد
    if (appointmentId != null) {
      await _db.appointmentsDao.updateStatus(appointmentId, 'done');
    }

    return visitId;
  }
}

class AddProcedureToVisitUseCase {
  final AppDatabase _db;
  AddProcedureToVisitUseCase(this._db);

  Future<void> call({
    required int visitId,
    required int procedureId,
    required double price,
    required int quantity,
  }) async {
    final visit = await _db.visitsDao.getById(visitId);
    if (visit == null) throw Exception('الزيارة غير موجودة');
    if (visit.isLocked) throw Exception('الزيارة مقفلة ولا يمكن تعديلها');

    final total = price * quantity;
    await _db.visitsDao.addProcedureToVisit(VisitProceduresCompanion(
      visitId: Value(visitId),
      procedureId: Value(procedureId),
      price: Value(price),
      quantity: Value(quantity),
      total: Value(total),
    ));

    // تحديث الفاتورة تلقائياً
    await InvoiceRepository(_db).createOrUpdateFromVisit(visitId);
  }
}
