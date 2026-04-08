// lib/presentation/providers/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/usecases/usecases.dart';

// ─── قاعدة البيانات ───
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ─── Repositories ───
final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(ref.watch(databaseProvider));
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository(ref.watch(databaseProvider));
});

// ─── Use Cases ───
final createPatientProvider = Provider<CreatePatientUseCase>((ref) {
  return CreatePatientUseCase(ref.watch(patientRepositoryProvider));
});

final updatePatientProvider = Provider<UpdatePatientUseCase>((ref) {
  return UpdatePatientUseCase(ref.watch(patientRepositoryProvider));
});

final createVisitProvider = Provider<CreateVisitUseCase>((ref) {
  return CreateVisitUseCase(ref.watch(databaseProvider));
});

final addProcedureToVisitProvider = Provider<AddProcedureToVisitUseCase>((ref) {
  return AddProcedureToVisitUseCase(ref.watch(databaseProvider));
});

// ─── Stream Providers ───
final patientsStreamProvider = StreamProvider<List<Patient>>((ref) {
  return ref.watch(patientRepositoryProvider).watchAll();
});

final doctorsStreamProvider = StreamProvider<List<Doctor>>((ref) {
  return ref.watch(databaseProvider).doctorsDao.watchAll();
});

final proceduresStreamProvider = StreamProvider<List<Procedure>>((ref) {
  return ref.watch(databaseProvider).proceduresDao.watchAll();
});

final itemsStreamProvider = StreamProvider<List<Item>>((ref) {
  return ref.watch(databaseProvider).inventoryDao.watchItems();
});

final todayAppointmentsProvider = StreamProvider<List<AppointmentWithDetails>>((ref) {
  return ref.watch(databaseProvider).appointmentsDao.watchTodayAppointments();
});

// ─── Patient Search ───
final patientSearchProvider =
    StateNotifierProvider<PatientSearchNotifier, AsyncValue<List<Patient>>>(
  (ref) => PatientSearchNotifier(ref.watch(patientRepositoryProvider)),
);

class PatientSearchNotifier extends StateNotifier<AsyncValue<List<Patient>>> {
  final PatientRepository _repo;
  PatientSearchNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = const AsyncValue.loading();
    try {
      final patients = await _repo.getAll();
      state = AsyncValue.data(patients);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      loadAll();
      return;
    }
    state = const AsyncValue.loading();
    try {
      final results = await _repo.search(query);
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ─── Report Provider ───
final reportProvider = Provider<ReportService>((ref) {
  return ReportService(ref.watch(databaseProvider));
});

// ─── Backup Provider ───
final backupProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseProvider));
});
