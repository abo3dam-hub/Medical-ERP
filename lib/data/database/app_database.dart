// lib/data/database/app_database.dart

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/medical_tables.dart';
import 'tables/accounting_tables.dart';
import 'daos/patients_dao.dart';
import 'daos/doctors_dao.dart';
import 'daos/appointments_dao.dart';
import 'daos/visits_dao.dart';
import 'daos/procedures_dao.dart';
import 'daos/invoices_dao.dart';
import 'daos/payments_dao.dart';
import 'daos/expenses_dao.dart';
import 'daos/cashbox_dao.dart';
import 'daos/inventory_dao.dart';
import 'daos/audit_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Patients,
    Doctors,
    Appointments,
    Visits,
    Procedures,
    VisitProcedures,
    Invoices,
    InvoiceItems,
    Payments,
    Expenses,
    CashBox,
    Items,
    StockMovements,
    AuditLog,
  ],
  daos: [
    PatientsDao,
    DoctorsDao,
    AppointmentsDao,
    VisitsDao,
    ProceduresDao,
    InvoicesDao,
    PaymentsDao,
    ExpensesDao,
    CashBoxDao,
    InventoryDao,
    AuditDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Migrations go here in future versions
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'clinic_database');
  }
}
