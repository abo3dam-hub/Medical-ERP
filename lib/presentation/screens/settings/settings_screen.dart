// lib/presentation/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإعدادات')),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // ─── النسخ الاحتياطي ───
            _SectionHeader('النسخ الاحتياطي'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.backup, color: Colors.blue),
                    title: const Text('إنشاء نسخة احتياطية'),
                    subtitle: const Text('حفظ قاعدة البيانات في مجلد'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => _createBackup(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restore, color: Colors.orange),
                    title: const Text('استعادة نسخة احتياطية'),
                    subtitle: const Text('استبدال قاعدة البيانات الحالية'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => _restoreBackup(context, ref),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── إدارة الأطباء ───
            _SectionHeader('إدارة الأطباء'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_add, color: Colors.green),
                title: const Text('إضافة طبيب جديد'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => _showAddDoctorDialog(context, ref),
              ),
            ),
            _DoctorsList(),

            const SizedBox(height: 16),

            // ─── إدارة الإجراءات ───
            _SectionHeader('إدارة الإجراءات / الخدمات'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.medical_services, color: Colors.purple),
                title: const Text('إضافة إجراء جديد'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => _showAddProcedureDialog(context, ref),
              ),
            ),
            _ProceduresList(),

            const SizedBox(height: 16),

            // ─── إدارة المصاريف ───
            _SectionHeader('إضافة مصروف'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.money_off, color: Colors.red),
                title: const Text('تسجيل مصروف جديد'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => _showAddExpenseDialog(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    try {
      final path = await ref.read(backupProvider).createBackup();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(path != null
              ? 'تم الحفظ: $path'
              : 'تم إلغاء العملية'),
          backgroundColor: path != null ? Colors.green : Colors.grey,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ تحذير'),
        content: const Text(
            'ستؤدي هذه العملية إلى استبدال جميع بيانات النظام الحالية بالنسخة الاحتياطية المختارة.\n\nهل تريد المتابعة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await ref.read(backupProvider).restoreBackup();
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('تمت الاستعادة'),
            content: const Text(
                'تمت استعادة البيانات بنجاح. يرجى إعادة تشغيل التطبيق.'),
            actions: [
              ElevatedButton(
                  onPressed: () {},
                  child: const Text('إعادة التشغيل')),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showAddDoctorDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final commCtrl = TextEditingController(text: '0');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة طبيب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'اسم الطبيب *'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: specCtrl,
              decoration: const InputDecoration(labelText: 'التخصص'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: commCtrl,
              decoration: const InputDecoration(labelText: 'نسبة العمولة %'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await ref.read(databaseProvider).doctorsDao.insertDoctor(
                    DoctorsCompanion(
                      name: Value(nameCtrl.text.trim()),
                      specialty: Value(specCtrl.text.isEmpty
                          ? null
                          : specCtrl.text.trim()),
                      commission: Value(double.tryParse(commCtrl.text) ?? 0),
                    ),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddProcedureDialog(
      BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة إجراء / خدمة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'اسم الإجراء *'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              decoration:
                  const InputDecoration(labelText: 'السعر الافتراضي'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await ref
                  .read(databaseProvider)
                  .proceduresDao
                  .insertProcedure(ProceduresCompanion(
                    name: Value(nameCtrl.text.trim()),
                    defaultPrice:
                        Value(double.tryParse(priceCtrl.text) ?? 0),
                  ));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddExpenseDialog(
      BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'عام');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل مصروف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'وصف المصروف *'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'المبلغ *'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: categoryCtrl,
              decoration: const InputDecoration(labelText: 'الفئة'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (titleCtrl.text.trim().isEmpty || amount <= 0) return;
              await ref.read(databaseProvider).expensesDao.insertExpense(
                    ExpensesCompanion(
                      title: Value(titleCtrl.text.trim()),
                      amount: Value(amount),
                      category: Value(categoryCtrl.text.trim()),
                    ),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: Text(title,
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13)),
    );
  }
}

class _DoctorsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctors = ref.watch(doctorsStreamProvider);
    return doctors.when(
      data: (list) => Column(
        children: list
            .map((d) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.blue),
                    title: Text('د. ${d.name}'),
                    subtitle: Text(
                        '${d.specialty ?? 'غير محدد'} – عمولة: ${d.commission}%'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await ref
                            .read(databaseProvider)
                            .doctorsDao
                            .deleteDoctor(d.id);
                      },
                    ),
                  ),
                ))
            .toList(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}

class _ProceduresList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final procs = ref.watch(proceduresStreamProvider);
    return procs.when(
      data: (list) => Column(
        children: list
            .map((p) => Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.medical_services, color: Colors.purple),
                    title: Text(p.name),
                    subtitle: Text('السعر: ${p.defaultPrice} د.ع'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await ref
                            .read(databaseProvider)
                            .proceduresDao
                            .deleteProcedure(p.id);
                      },
                    ),
                  ),
                ))
            .toList(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}
