// lib/data/database/tables/medical_tables.dart

import 'package:drift/drift.dart';

// ─── جدول المرضى ───
class Patients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 2, max: 100)();
  TextColumn get phone => text().withLength(max: 20).nullable()();
  DateTimeColumn get birthDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─── جدول الأطباء ───
class Doctors extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 2, max: 100)();
  TextColumn get specialty => text().nullable()();
  RealColumn get commission => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─── جدول المواعيد ───
class Appointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId =>
      integer().references(Patients, #id, onDelete: KeyAction.cascade)();
  IntColumn get doctorId =>
      integer().references(Doctors, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get datetime => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  // pending / confirmed / cancelled / done
}

// ─── جدول الزيارات ───
class Visits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId =>
      integer().references(Patients, #id, onDelete: KeyAction.cascade)();
  IntColumn get doctorId =>
      integer().references(Doctors, #id, onDelete: KeyAction.restrict)();
  IntColumn get appointmentId =>
      integer().references(Appointments, #id, onDelete: KeyAction.setNull).nullable()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
}

// ─── جدول الإجراءات/الخدمات ───
class Procedures extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 2, max: 100)();
  RealColumn get defaultPrice => real().withDefault(const Constant(0.0))();
}

// ─── جدول إجراءات الزيارة ───
class VisitProcedures extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get visitId =>
      integer().references(Visits, #id, onDelete: KeyAction.cascade)();
  IntColumn get procedureId =>
      integer().references(Procedures, #id, onDelete: KeyAction.restrict)();
  RealColumn get price => real()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  RealColumn get total => real()();
}
