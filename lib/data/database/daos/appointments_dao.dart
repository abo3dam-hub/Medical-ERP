// lib/data/database/daos/appointments_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';

part 'appointments_dao.g.dart';

@DriftAccessor(tables: [Appointments, Patients, Doctors])
class AppointmentsDao extends DatabaseAccessor<AppDatabase>
    with _$AppointmentsDaoMixin {
  AppointmentsDao(super.db);

  // جلب المواعيد مع بيانات المريض والطبيب
  Future<List<AppointmentWithDetails>> getAppointmentsWithDetails({
    DateTime? from,
    DateTime? to,
  }) {
    final query = select(appointments).join([
      innerJoin(patients, patients.id.equalsExp(appointments.patientId)),
      innerJoin(doctors, doctors.id.equalsExp(appointments.doctorId)),
    ]);

    if (from != null) {
      query.where(appointments.datetime.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where(appointments.datetime.isSmallerOrEqualValue(to));
    }

    query.orderBy([OrderingTerm.asc(appointments.datetime)]);

    return query.map((row) => AppointmentWithDetails(
          appointment: row.readTable(appointments),
          patient: row.readTable(patients),
          doctor: row.readTable(doctors),
        )).get();
  }

  Stream<List<AppointmentWithDetails>> watchTodayAppointments() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = select(appointments).join([
      innerJoin(patients, patients.id.equalsExp(appointments.patientId)),
      innerJoin(doctors, doctors.id.equalsExp(appointments.doctorId)),
    ]);
    query
      ..where(appointments.datetime.isBiggerOrEqualValue(startOfDay))
      ..where(appointments.datetime.isSmallerValue(endOfDay))
      ..orderBy([OrderingTerm.asc(appointments.datetime)]);

    return query.map((row) => AppointmentWithDetails(
          appointment: row.readTable(appointments),
          patient: row.readTable(patients),
          doctor: row.readTable(doctors),
        )).watch();
  }

  Future<int> insertAppointment(AppointmentsCompanion appt) =>
      into(appointments).insert(appt);

  Future<bool> updateAppointment(AppointmentsCompanion appt) =>
      update(appointments).replace(appt);

  Future<int> updateStatus(int id, String status) =>
      (update(appointments)..where((a) => a.id.equals(id)))
          .write(AppointmentsCompanion(status: Value(status)));

  Future<int> deleteAppointment(int id) =>
      (delete(appointments)..where((a) => a.id.equals(id))).go();
}

class AppointmentWithDetails {
  final Appointment appointment;
  final Patient patient;
  final Doctor doctor;

  AppointmentWithDetails({
    required this.appointment,
    required this.patient,
    required this.doctor,
  });
}
