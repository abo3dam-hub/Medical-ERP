// lib/data/database/daos/patients_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';

part 'patients_dao.g.dart';

@DriftAccessor(tables: [Patients])
class PatientsDao extends DatabaseAccessor<AppDatabase>
    with _$PatientsDaoMixin {
  PatientsDao(super.db);

  Stream<List<Patient>> watchAll() => select(patients).watch();

  Future<List<Patient>> getAll() => select(patients).get();

  Future<List<Patient>> search(String query) {
    return (select(patients)
          ..where((p) =>
              p.name.contains(query) | p.phone.contains(query)))
        .get();
  }

  Future<Patient?> getById(int id) =>
      (select(patients)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<int> insertPatient(PatientsCompanion patient) =>
      into(patients).insert(patient);

  Future<bool> updatePatient(PatientsCompanion patient) =>
      update(patients).replace(patient);

  Future<int> deletePatient(int id) =>
      (delete(patients)..where((p) => p.id.equals(id))).go();
}
