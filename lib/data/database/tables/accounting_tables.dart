// lib/data/database/tables/accounting_tables.dart

import 'package:drift/drift.dart';
import 'medical_tables.dart';

// ─── جدول الفواتير ───
class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get visitId =>
      integer().references(Visits, #id, onDelete: KeyAction.restrict)();
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  TextColumn get status => text().withDefault(const Constant('unpaid'))();
  // unpaid / partial / paid
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
}

// ─── بنود الفاتورة ───
class InvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId =>
      integer().references(Invoices, #id, onDelete: KeyAction.cascade)();
  TextColumn get procedureName => text()();
  RealColumn get price => real()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  RealColumn get total => real()();
}

// ─── جدول المدفوعات ───
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId =>
      integer().references(Invoices, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
}

// ─── جدول المصاريف ───
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get category => text().withDefault(const Constant('عام'))();
}

// ─── صندوق النقدية اليومي ───
class CashBox extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get openingBalance => real().withDefault(const Constant(0.0))();
  RealColumn get totalIncome => real().withDefault(const Constant(0.0))();
  RealColumn get totalExpense => real().withDefault(const Constant(0.0))();
  RealColumn get closingBalance => real().withDefault(const Constant(0.0))();
  BoolColumn get isClosed => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {date}
      ];
}

// ─── المخزون ───
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 2, max: 100)();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  IntColumn get minQuantity => integer().withDefault(const Constant(0))();
}

// ─── حركات المخزون ───
class StockMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId =>
      integer().references(Items, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()(); // in / out
  IntColumn get quantity => integer()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
}

// ─── سجل التدقيق ───
class AuditLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tableName => text()();
  IntColumn get recordId => integer()();
  TextColumn get actionType => text()(); // INSERT / UPDATE / DELETE
  TextColumn get oldValues => text().nullable()();
  TextColumn get newValues => text().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}
