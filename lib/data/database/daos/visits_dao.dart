// lib/data/database/daos/visits_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';

part 'visits_dao.g.dart';

@DriftAccessor(tables: [Visits, VisitProcedures, Patients, Doctors, Procedures])
class VisitsDao extends DatabaseAccessor<AppDatabase> with _$VisitsDaoMixin {
  VisitsDao(super.db);

  Future<List<VisitWithDetails>> getVisitsForPatient(int patientId) {
    final query = select(visits).join([
      innerJoin(patients, patients.id.equalsExp(visits.patientId)),
      innerJoin(doctors, doctors.id.equalsExp(visits.doctorId)),
    ])
      ..where(visits.patientId.equals(patientId))
      ..orderBy([OrderingTerm.desc(visits.date)]);

    return query.map((row) => VisitWithDetails(
          visit: row.readTable(visits),
          patient: row.readTable(patients),
          doctor: row.readTable(doctors),
        )).get();
  }

  Future<Visit?> getById(int id) =>
      (select(visits)..where((v) => v.id.equals(id))).getSingleOrNull();

  Future<int> insertVisit(VisitsCompanion visit) =>
      into(visits).insert(visit);

  Future<bool> updateVisit(VisitsCompanion visit) =>
      update(visits).replace(visit);

  Future<void> lockVisit(int id) =>
      (update(visits)..where((v) => v.id.equals(id)))
          .write(const VisitsCompanion(isLocked: Value(true)));

  Future<List<VisitProcedure>> getProceduresForVisit(int visitId) =>
      (select(visitProcedures)..where((vp) => vp.visitId.equals(visitId))).get();

  Future<int> addProcedureToVisit(VisitProceduresCompanion proc) =>
      into(visitProcedures).insert(proc);

  Future<int> removeProcedureFromVisit(int id) =>
      (delete(visitProcedures)..where((vp) => vp.id.equals(id))).go();

  // إجمالي الإيرادات لكل طبيب
  Future<List<DoctorRevenue>> getDoctorRevenue({
    DateTime? from,
    DateTime? to,
  }) async {
    final query = select(visitProcedures).join([
      innerJoin(visits, visits.id.equalsExp(visitProcedures.visitId)),
      innerJoin(doctors, doctors.id.equalsExp(visits.doctorId)),
    ]);

    if (from != null) query.where(visits.date.isBiggerOrEqualValue(from));
    if (to != null) query.where(visits.date.isSmallerOrEqualValue(to));

    final rows = await query
        .map((row) => (
              doctor: row.readTable(doctors),
              total: row.readTable(visitProcedures).total,
            ))
        .get();

    final Map<int, DoctorRevenue> revenueMap = {};
    for (final r in rows) {
      final d = r.doctor;
      if (!revenueMap.containsKey(d.id)) {
        revenueMap[d.id] = DoctorRevenue(doctor: d, totalRevenue: 0);
      }
      revenueMap[d.id] = DoctorRevenue(
        doctor: d,
        totalRevenue: revenueMap[d.id]!.totalRevenue + r.total,
      );
    }
    return revenueMap.values.toList();
  }
}

class VisitWithDetails {
  final Visit visit;
  final Patient patient;
  final Doctor doctor;

  VisitWithDetails({
    required this.visit,
    required this.patient,
    required this.doctor,
  });
}

class DoctorRevenue {
  final Doctor doctor;
  final double totalRevenue;

  DoctorRevenue({required this.doctor, required this.totalRevenue});

  double get netRevenue => totalRevenue - (totalRevenue * doctor.commission / 100);
}

// ─────────────────────────────────────────────
// lib/data/database/daos/procedures_dao.dart

part 'procedures_dao.g.dart'; // تضاف في ملف منفصل فعلياً

@DriftAccessor(tables: [Procedures])
class ProceduresDao extends DatabaseAccessor<AppDatabase>
    with _$ProceduresDaoMixin {
  ProceduresDao(super.db);

  Stream<List<Procedure>> watchAll() => select(procedures).watch();
  Future<List<Procedure>> getAll() => select(procedures).get();

  Future<int> insertProcedure(ProceduresCompanion proc) =>
      into(procedures).insert(proc);

  Future<bool> updateProcedure(ProceduresCompanion proc) =>
      update(procedures).replace(proc);

  Future<int> deleteProcedure(int id) =>
      (delete(procedures)..where((p) => p.id.equals(id))).go();
}
