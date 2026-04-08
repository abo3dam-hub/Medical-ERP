// lib/data/database/daos/procedures_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';

part 'procedures_dao.g.dart';

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
