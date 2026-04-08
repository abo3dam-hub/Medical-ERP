// lib/presentation/screens/patients/patients_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import 'add_patient_screen.dart';
import 'patient_detail_screen.dart';

class PatientsListScreen extends ConsumerWidget {
  const PatientsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المرضى'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openAddPatient(context, ref),
            tooltip: 'إضافة مريض',
          ),
        ],
      ),
      body: Column(
        children: [
          // حقل البحث
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'بحث باسم المريض أو الهاتف...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (q) =>
                  ref.read(patientSearchProvider.notifier).search(q),
            ),
          ),
          Expanded(
            child: patientsAsync.when(
              data: (patients) {
                if (patients.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('لا يوجد مرضى مسجلون', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: patients.length,
                  itemBuilder: (ctx, i) {
                    final p = patients[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            p.name.substring(0, 1),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(p.name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(p.phone ?? 'لا يوجد هاتف'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _openEditPatient(context, ref, p.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _confirmDelete(context, ref, p.id, p.name),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PatientDetailScreen(patientId: p.id)),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('حدث خطأ: $e', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddPatient(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPatientScreen()),
    ).then((_) => ref.read(patientSearchProvider.notifier).loadAll());
  }

  void _openEditPatient(BuildContext context, WidgetRef ref, int id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddPatientScreen(editId: id)),
    ).then((_) => ref.read(patientSearchProvider.notifier).loadAll());
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف المريض "$name"؟\nسيتم حذف جميع بياناته.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(patientRepositoryProvider).delete(id);
        ref.read(patientSearchProvider.notifier).loadAll();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
