// lib/data/database/daos/doctors_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';

part 'doctors_dao.g.dart';

@DriftAccessor(tables: [Doctors])
class DoctorsDao extends DatabaseAccessor<AppDatabase>
    with _$DoctorsDaoMixin {
  DoctorsDao(super.db);

  Stream<List<Doctor>> watchAll() => select(doctors).watch();
  Future<List<Doctor>> getAll() => select(doctors).get();

  Future<Doctor?> getById(int id) =>
      (select(doctors)..where((d) => d.id.equals(id))).getSingleOrNull();

  Future<int> insertDoctor(DoctorsCompanion doc) =>
      into(doctors).insert(doc);

  Future<bool> updateDoctor(DoctorsCompanion doc) =>
      update(doctors).replace(doc);

  Future<int> deleteDoctor(int id) =>
      (delete(doctors)..where((d) => d.id.equals(id))).go();
}
