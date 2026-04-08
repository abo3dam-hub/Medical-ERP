// lib/presentation/screens/visits/add_visit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../providers/providers.dart';
import 'visit_detail_screen.dart';

class AddVisitScreen extends ConsumerStatefulWidget {
  final int patientId;
  final int? appointmentId;
  const AddVisitScreen({super.key, required this.patientId, this.appointmentId});

  @override
  ConsumerState<AddVisitScreen> createState() => _AddVisitScreenState();
}

class _AddVisitScreenState extends ConsumerState<AddVisitScreen> {
  int? _doctorId;
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctors = ref.watch(doctorsStreamProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('زيارة جديدة')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              doctors.when(
                data: (list) => DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'الطبيب المعالج *',
                    prefixIcon: Icon(Icons.person_pin),
                  ),
                  value: _doctorId,
                  items: list
                      .map((d) => DropdownMenuItem(
                          value: d.id,
                          child: Text('د. ${d.name} – ${d.specialty ?? ''}')
                      ))
                      .toList(),
                  onChanged: (v) => setState(() => _doctorId = v),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات الزيارة',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading || _doctorId == null ? null : _createVisit,
                  icon: _loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add_circle),
                  label: const Text('إنشاء الزيارة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createVisit() async {
    if (_doctorId == null) return;
    setState(() => _loading = true);
    try {
      final visitId = await ref.read(createVisitProvider).call(
        patientId: widget.patientId,
        doctorId: _doctorId!,
        appointmentId: widget.appointmentId,
        notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => VisitDetailScreen(visitId: visitId)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
