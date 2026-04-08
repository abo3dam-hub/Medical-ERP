// lib/presentation/screens/visits/visit_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import '../../providers/providers.dart';
import '../invoices/invoice_detail_screen.dart';

class VisitDetailScreen extends ConsumerStatefulWidget {
  final int visitId;
  const VisitDetailScreen({super.key, required this.visitId});

  @override
  ConsumerState<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends ConsumerState<VisitDetailScreen> {
  bool _refreshFlag = false;

  void _refresh() => setState(() => _refreshFlag = !_refreshFlag);

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder(
        future: Future.wait([
          db.visitsDao.getById(widget.visitId),
          db.visitsDao.getProceduresForVisit(widget.visitId),
          db.invoicesDao.getByVisitId(widget.visitId),
        ]),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          final visit = snap.data![0] as dynamic;
          final procedures = snap.data![1] as List;
          final invoice = snap.data![2] as dynamic;

          if (visit == null) {
            return const Scaffold(body: Center(child: Text('الزيارة غير موجودة')));
          }

          final isLocked = visit.isLocked as bool;
          final total = procedures.fold<double>(0.0, (s, p) => s + (p.total as double));

          return Scaffold(
            appBar: AppBar(
              title: Text('زيارة – ${DateFormat('yyyy/MM/dd').format(visit.date)}'),
              actions: [
                if (!isLocked)
                  IconButton(
                    icon: const Icon(Icons.lock_open),
                    tooltip: 'قفل الزيارة',
                    onPressed: () => _lockVisit(context, db),
                  ),
                if (invoice != null)
                  IconButton(
                    icon: const Icon(Icons.receipt_long),
                    tooltip: 'عرض الفاتورة',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              InvoiceDetailScreen(invoiceId: invoice.id)),
                    ),
                  ),
              ],
            ),
            body: Column(
              children: [
                // رأس الزيارة
                _VisitHeader(visit: visit, isLocked: isLocked),
                const Divider(),

                // قائمة الإجراءات
                Expanded(
                  child: procedures.isEmpty
                      ? const Center(
                          child: Text('لم يتم إضافة إجراءات بعد',
                              style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: procedures.length,
                          itemBuilder: (ctx, i) {
                            final p = procedures[i];
                            return Card(
                              child: ListTile(
                                title: Text('إجراء #${p.procedureId}'),
                                subtitle: Text(
                                    '${p.quantity} × ${_fmt(p.price)} = ${_fmt(p.total)}'),
                                trailing: isLocked
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _removeProcedure(context, db, p.id),
                                      ),
                              ),
                            );
                          },
                        ),
                ),

                // شريط الإجمالي
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, -2))
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'الإجمالي: ${_fmt(total)}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (!isLocked)
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showAddProcedureDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة إجراء'),
                        ),
                      if (!isLocked && invoice == null && procedures.isNotEmpty)
                        const SizedBox(width: 8),
                      if (!isLocked && procedures.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () =>
                              _createInvoice(context, db),
                          icon: const Icon(Icons.receipt),
                          label: const Text('إنشاء فاتورة'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmt(double n) => NumberFormat('#,##0.00', 'ar').format(n);

  Future<void> _removeProcedure(BuildContext context, db, int id) async {
    await db.visitsDao.removeProcedureFromVisit(id);
    await ref.read(invoiceRepositoryProvider).createOrUpdateFromVisit(widget.visitId);
    _refresh();
  }

  Future<void> _lockVisit(BuildContext context, db) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('قفل الزيارة'),
        content: const Text('بعد القفل لن يمكن تعديل الزيارة أو إجراءاتها. هل تريد المتابعة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('قفل')),
        ],
      ),
    );
    if (confirm == true) {
      await db.visitsDao.lockVisit(widget.visitId);
      _refresh();
    }
  }

  Future<void> _createInvoice(BuildContext context, db) async {
    try {
      final invoice = await ref
          .read(invoiceRepositoryProvider)
          .createOrUpdateFromVisit(widget.visitId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  InvoiceDetailScreen(invoiceId: invoice.id)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showAddProcedureDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) =>
          _AddProcedureDialog(visitId: widget.visitId, onAdded: _refresh),
    );
  }
}

class _VisitHeader extends StatelessWidget {
  final dynamic visit;
  final bool isLocked;
  const _VisitHeader({required this.visit, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('yyyy/MM/dd – HH:mm').format(visit.date),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (visit.notes != null && visit.notes!.isNotEmpty)
                  Text(visit.notes!,
                      style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          if (isLocked)
            const Chip(
              label: Text('مقفلة', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.orange,
            ),
        ],
      ),
    );
  }
}

// ─── حوار إضافة إجراء ───
class _AddProcedureDialog extends ConsumerStatefulWidget {
  final int visitId;
  final VoidCallback onAdded;
  const _AddProcedureDialog(
      {required this.visitId, required this.onAdded});

  @override
  ConsumerState<_AddProcedureDialog> createState() =>
      _AddProcedureDialogState();
}

class _AddProcedureDialogState
    extends ConsumerState<_AddProcedureDialog> {
  int? _procedureId;
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  bool _loading = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final procs = ref.watch(proceduresStreamProvider);

    return AlertDialog(
      title: const Text('إضافة إجراء'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            procs.when(
              data: (list) => DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'الإجراء'),
                value: _procedureId,
                items: list
                    .map((p) => DropdownMenuItem(
                        value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: (v) {
                  setState(() => _procedureId = v);
                  if (v != null) {
                    final proc = list.firstWhere((p) => p.id == v);
                    _priceCtrl.text = proc.defaultPrice.toStringAsFixed(2);
                  }
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(labelText: 'السعر'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    decoration: const InputDecoration(labelText: 'الكمية'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
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
          child: const Text('إضافة'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_procedureId == null) return;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final qty = int.tryParse(_qtyCtrl.text) ?? 1;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى إدخال سعر صحيح'),
            backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(addProcedureToVisitProvider).call(
            visitId: widget.visitId,
            procedureId: _procedureId!,
            price: price,
            quantity: qty,
          );
      widget.onAdded();
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

// ─── شاشة الزيارات العامة ───
class VisitsScreen extends ConsumerWidget {
  const VisitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patients = ref.watch(patientsStreamProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الزيارات')),
        body: patients.when(
          data: (list) => list.isEmpty
              ? const Center(child: Text('لا يوجد مرضى مسجلون'))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final p = list[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(p.name[0])),
                        title: Text(p.name),
                        subtitle: Text(p.phone ?? ''),
                        trailing: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    AddVisitScreen(patientId: p.id)),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('زيارة جديدة'),
                        ),
                      ),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ),
      ),
    );
  }
}
