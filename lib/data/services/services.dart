// lib/data/services/report_service.dart

import '../database/app_database.dart';

class ReportService {
  final AppDatabase _db;
  ReportService(this._db);

  Future<DailyReport> getDailyReport(DateTime date) async {
    final from = DateTime(date.year, date.month, date.day);
    final to = from.add(const Duration(days: 1));

    final income = await _db.invoicesDao.getTotalIncome(from: from, to: to);
    final expenses = await _db.expensesDao.getTotalExpenses(from: from, to: to);
    final cashBox = await _db.cashBoxDao.getByDate(date);

    return DailyReport(
      date: date,
      totalIncome: income,
      totalExpenses: expenses,
      netProfit: income - expenses,
      cashBox: cashBox,
    );
  }

  Future<PeriodReport> getMonthlyReport(int year, int month) async {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 1);
    return _getPeriodReport(from, to, 'شهري');
  }

  Future<PeriodReport> getYearlyReport(int year) async {
    final from = DateTime(year, 1, 1);
    final to = DateTime(year + 1, 1, 1);
    return _getPeriodReport(from, to, 'سنوي');
  }

  Future<PeriodReport> _getPeriodReport(
      DateTime from, DateTime to, String type) async {
    final income = await _db.invoicesDao.getTotalIncome(from: from, to: to);
    final expenses = await _db.expensesDao.getTotalExpenses(from: from, to: to);
    final doctorRevenues = await _db.visitsDao.getDoctorRevenue(from: from, to: to);

    return PeriodReport(
      from: from,
      to: to,
      type: type,
      totalIncome: income,
      totalExpenses: expenses,
      netProfit: income - expenses,
      doctorRevenues: doctorRevenues,
    );
  }

  Future<List<DoctorRevenue>> getDoctorPerformance({
    DateTime? from,
    DateTime? to,
  }) =>
      _db.visitsDao.getDoctorRevenue(from: from, to: to);
}

class DailyReport {
  final DateTime date;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final CashBoxData? cashBox;

  DailyReport({
    required this.date,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    this.cashBox,
  });
}

class PeriodReport {
  final DateTime from;
  final DateTime to;
  final String type;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final List<DoctorRevenue> doctorRevenues;

  PeriodReport({
    required this.from,
    required this.to,
    required this.type,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.doctorRevenues,
  });
}

// ─────────────────────────────────────────────
// lib/data/services/backup_service.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupService {
  final AppDatabase _db;
  BackupService(this._db);

  String get _dbName => 'clinic_database.db';

  Future<String?> _getDbPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDir.path, _dbName);
    return dbPath;
  }

  // نسخ احتياطي إلى مجلد يختاره المستخدم
  Future<String?> createBackup() async {
    final dbPath = await _getDbPath();
    if (dbPath == null) return null;

    final dateStr = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final backupName = 'clinic_backup_$dateStr.db';

    final saveDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'اختر مجلد حفظ النسخة الاحتياطية',
    );

    if (saveDir == null) return null;

    final savePath = p.join(saveDir, backupName);
    await File(dbPath).copy(savePath);
    return savePath;
  }

  // استعادة من نسخة احتياطية
  Future<bool> restoreBackup() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'اختر ملف النسخة الاحتياطية',
      type: FileType.any,
      allowedExtensions: ['db'],
    );

    if (result == null || result.files.single.path == null) return false;

    final backupPath = result.files.single.path!;
    final dbPath = await _getDbPath();
    if (dbPath == null) return false;

    // إغلاق قاعدة البيانات أولاً
    await _db.close();

    // استبدال الملف
    await File(backupPath).copy(dbPath);

    return true; // يجب إعادة تشغيل التطبيق بعد هذا
  }

  // نسخ احتياطي تلقائي عند بدء التطبيق
  Future<void> autoBackup() async {
    final dbPath = await _getDbPath();
    if (dbPath == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final autoBackupDir = Directory(p.join(appDir.path, 'auto_backups'));
    if (!autoBackupDir.existsSync()) await autoBackupDir.create();

    // الاحتفاظ بـ 7 نسخ فقط
    final files = autoBackupDir
        .listSync()
        .whereType<File>()
        .toList()
      ..sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

    if (files.length >= 7) {
      await files.first.delete();
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final backupPath = p.join(autoBackupDir.path, 'auto_$dateStr.db');
    await File(dbPath).copy(backupPath);
  }
}
