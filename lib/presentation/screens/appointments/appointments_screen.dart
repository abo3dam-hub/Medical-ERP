// lib/presentation/screens/appointments/appointments_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import '../../providers/providers.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() =>
      _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المواعيد'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddAppointmentDialog(context),
              tooltip: 'موعد جديد',
            ),
          ],
        ),
        body: Column(
          children: [
            // شريط اختيار التاريخ
            _DateSelector(
              selectedDate: _selectedDate,
              onDateChanged: (d) => setState(() => _selectedDate = d),
            ),
            const Divider(height: 1),
            Expanded(child: _AppointmentList(date: _selectedDate)),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddAppointmentDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => _AddAppointmentDialog(defaultDate: _selectedDate),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _DateSelector(
      {required this.selectedDate, required this.onDateChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onDateChanged(
                selectedDate.subtract(const Duration(days: 1))),
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  locale: const Locale('ar'),
                );
                if (picked != null) onDateChanged(picked);
              },
              child: Column(
                children: [
                  Text(
                    DateFormat('EEEE', 'ar').format(selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('yyyy/MM/dd').format(selectedDate),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () =>
                onDateChanged(selectedDate.add(const Duration(days: 1))),
          ),
          TextButton(
            onPressed: () => onDateChanged(DateTime.now()),
            child: const Text('اليوم'),
          ),
        ],
      ),
    );
  }
}

class _AppointmentList extends ConsumerWidget {
  final DateTime date;
  const _AppointmentList({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final from = DateTime(date.year, date.month, date.day);
    final to = from.add(const Duration(days: 1));

    return FutureBuilder(
      future:
          db.appointmentsDao.getAppointmentsWithDetails(from: from, to: to),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final appts = snap.data!;
        if (appts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy, size: 60, color: Colors.grey),
                SizedBox(height: 8),
                Text('لا توجد مواعيد في هذا اليوم',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: appts.length,
          itemBuilder: (ctx, i) {
            final a = appts[i];
            return Card(
              child: ListTile(
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(a.appointment.datetime),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                title: Text(a.patient.name),
                subtitle: Text('د. ${a.doctor.name}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusChip(a.appointment.status),
                    PopupMenuButton<String>(
                      onSelected: (s) => _changeStatus(context, ref,
                          a.appointment.id, s),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'confirmed', child: Text('✅ تأكيد')),
                        PopupMenuItem(value: 'done', child: Text('✔ منجز')),
                        PopupMenuItem(value: 'cancelled', child: Text('❌ إلغاء')),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    final Map<String, (String, Color)> map = {
      'pending': ('معلق', Colors.orange),
      'confirmed': ('مؤكد', Colors.blue),
      'done': ('منجز', Colors.green),
      'cancelled': ('ملغي', Colors.red),
    };
    final (label, color) = map[status] ?? (status, Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _changeStatus(BuildContext context, WidgetRef ref, int id,
      String status) async {
    await ref.read(databaseProvider).appointmentsDao.updateStatus(id, status);
    // refresh
    (context as Element).markNeedsBuild();
  }
}

// ─── حوار إضافة موعد ───
class _AddAppointmentDialog extends ConsumerStatefulWidget {
  final DateTime defaultDate;
  const _AddAppointmentDialog({required this.defaultDate});

  @override
  ConsumerState<_AddAppointmentDialog> createState() =>
      _AddAppointmentDialogState();
}

class _AddAppointmentDialogState
    extends ConsumerState<_AddAppointmentDialog> {
  int? _patientId;
  int? _doctorId;
  DateTime _datetime = DateTime.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _datetime = widget.defaultDate.copyWith(
        hour: TimeOfDay.now().hour, minute: TimeOfDay.now().minute);
  }

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(patientsStreamProvider);
    final doctors = ref.watch(doctorsStreamProvider);

    return AlertDialog(
      title: const Text('موعد جديد'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // اختيار المريض
            patients.when(
              data: (list) => DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'المريض'),
                value: _patientId,
                items: list
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: (v) => setState(() => _patientId = v),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 12),
            // اختيار الطبيب
            doctors.when(
              data: (list) => DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'الطبيب'),
                value: _doctorId,
                items: list
                    .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                    .toList(),
                onChanged: (v) => setState(() => _doctorId = v),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 12),
            // التاريخ والوقت
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(DateFormat('yyyy/MM/dd – HH:mm').format(_datetime)),
              leading: const Icon(Icons.access_time),
              onTap: _pickDateTime,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('حفظ'),
        ),
      ],
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _datetime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
    );
    if (date == null) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_datetime));
    if (time == null) return;
    setState(() => _datetime =
        date.copyWith(hour: time.hour, minute: time.minute));
  }

  Future<void> _save() async {
    if (_patientId == null || _doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى اختيار المريض والطبيب'),
            backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(databaseProvider).appointmentsDao.insertAppointment(
            AppointmentsCompanion(
              patientId: Value(_patientId!),
              doctorId: Value(_doctorId!),
              datetime: Value(_datetime),
            ),
          );
      if (mounted) Navigator.pop(context);
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
