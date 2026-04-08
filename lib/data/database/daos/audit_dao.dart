// lib/data/database/daos/audit_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';

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
