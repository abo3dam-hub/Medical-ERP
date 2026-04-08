// lib/presentation/screens/patients/patient_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../visits/add_visit_screen.dart';

class PatientDetailScreen extends ConsumerWidget {
  final int patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder(
        future: db.patientsDao.getById(patientId),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          final patient = snap.data!;
          return Scaffold(
            appBar: AppBar(
              title: Text(patient.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'إضافة زيارة',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AddVisitScreen(patientId: patientId)),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                // بطاقة معلومات المريض
                _PatientInfoCard(patient: patient),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('سجل الزيارات',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                // قائمة الزيارات
                Expanded(
                  child: FutureBuilder(
                    future:
                        db.visitsDao.getVisitsForPatient(patientId),
                    builder: (ctx, snap) {
                      if (!snap.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final visits = snap.data!;
                      if (visits.isEmpty) {
                        return const Center(
                            child: Text('لا توجد زيارات سابقة',
                                style: TextStyle(color: Colors.grey)));
                      }
                      return ListView.builder(
                        itemCount: visits.length,
                        itemBuilder: (ctx, i) {
                          final v = visits[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: const Icon(Icons.medical_services,
                                    color: Colors.blue),
                              ),
                              title: Text(
                                  DateFormat('yyyy/MM/dd – HH:mm')
                                      .format(v.visit.date)),
                              subtitle: Text('د. ${v.doctor.name}'),
                              trailing: v.visit.isLocked
                                  ? const Icon(Icons.lock,
                                      color: Colors.orange, size: 18)
                                  : const Icon(Icons.chevron_left),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => VisitDetailScreen(
                                        visitId: v.visit.id)),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PatientInfoCard extends StatelessWidget {
  final dynamic patient;
  const _PatientInfoCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              patient.name.substring(0, 1),
              style: TextStyle(
                  fontSize: 28,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                if (patient.phone != null)
                  Row(children: [
                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(patient.phone!,
                        style: const TextStyle(color: Colors.grey)),
                  ]),
                if (patient.birthDate != null)
                  Row(children: [
                    const Icon(Icons.cake, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                        DateFormat('yyyy/MM/dd').format(patient.birthDate!),
                        style: const TextStyle(color: Colors.grey)),
                  ]),
                if (patient.notes != null && patient.notes!.isNotEmpty)
                  Text(patient.notes!,
                      style: const TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
