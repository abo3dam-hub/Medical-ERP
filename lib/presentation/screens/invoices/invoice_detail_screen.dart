// lib/presentation/screens/invoices/invoice_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final int invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState
    extends ConsumerState<InvoiceDetailScreen> {
  bool _refresh = false;

  void _reload() => setState(() => _refresh = !_refresh);

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final invoiceRepo = ref.watch(invoiceRepositoryProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder(
        future: Future.wait([
          db.invoicesDao.getById(widget.invoiceId),
          db.invoicesDao.getItemsByInvoiceId(widget.invoiceId),
          db.paymentsDao.getByInvoiceId(widget.invoiceId),
        ]),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          final invoice = snap.data![0] as dynamic;
          final items = snap.data![1] as List;
          final payments = snap.data![2] as List;

          if (invoice == null) {
            return const Scaffold(
                body: Center(child: Text('الفاتورة غير موجودة')));
          }

          final remaining = invoice.totalAmount - invoice.paidAmount;

          return Scaffold(
            appBar: AppBar(
              title: Text('فاتورة #${invoice.id}'),
              actions: [
                if (!invoice.isLocked && invoice.status == 'paid')
                  IconButton(
                    icon: const Icon(Icons.lock),
                    tooltip: 'قفل الفاتورة',
                    onPressed: () async {
                      await db.invoicesDao.lockInvoice(invoice.id);
                      _reload();
                    },
                  ),
              ],
            ),
            body: Column(
              children: [
                // ملخص الفاتورة
                _InvoiceSummaryCard(invoice: invoice),

                // بنود الفاتورة
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    children: [
                      const Text('بنود الفاتورة',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 6),
                      ...items.map((item) => Card(
                            child: ListTile(
                              title: Text(item.procedureName),
                              subtitle: Text(
                                  '${item.quantity} × ${_fmt(item.price)}'),
                              trailing: Text(_fmt(item.total),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                          )),
                      const Divider(height: 24),

                      // سجل المدفوعات
                      const Text('سجل الدفعات',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 6),
                      if (payments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('لم يتم تسجيل أي دفعة',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ...payments.map((p) => Card(
                            color: Colors.green.shade50,
                            child: ListTile(
                              leading: const Icon(Icons.payments,
                                  color: Colors.green),
                              title: Text(_fmt(p.amount),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                              subtitle: Text(DateFormat('yyyy/MM/dd – HH:mm')
                                  .format(p.date)),
                              trailing: invoice.isLocked
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red, size: 18),
                                      onPressed: () =>
                                          _deletePayment(context, db, p),
                                    ),
                            ),
                          )),
                    ],
                  ),
                ),

                // شريط الإجراءات السفلي
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, -2))
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('الإجمالي: ${_fmt(invoice.totalAmount)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text('المدفوع: ${_fmt(invoice.paidAmount)}',
                                style:
                                    const TextStyle(color: Colors.green)),
                            Text('المتبقي: ${_fmt(remaining)}',
                                style: TextStyle(
                                    color: remaining > 0
                                        ? Colors.red
                                        : Colors.grey)),
                          ],
                        ),
                      ),
                      if (!invoice.isLocked && remaining > 0)
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showAddPaymentDialog(context, invoiceRepo,
                                  remaining, invoice.id),
                          icon: const Icon(Icons.add_card),
                          label: const Text('تسجيل دفعة'),
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

  String _fmt(double n) => '${NumberFormat('#,##0.00', 'ar').format(n)} د.ع';

  Future<void> _deletePayment(BuildContext context, db, dynamic payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الدفعة'),
        content: const Text('هل تريد حذف هذه الدفعة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final invoice = await db.invoicesDao.getById(widget.invoiceId);
      await db.paymentsDao.deletePayment(payment.id);
      if (invoice != null) {
        final newPaid = invoice.paidAmount - payment.amount;
        await db.invoicesDao.updateInvoiceTotals(
            widget.invoiceId, invoice.totalAmount, newPaid.clamp(0.0, double.infinity));
      }
      _reload();
    }
  }

  Future<void> _showAddPaymentDialog(BuildContext context,
      invoiceRepo, double remaining, int invoiceId) async {
    final ctrl = TextEditingController(
        text: remaining.toStringAsFixed(2));
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل دفعة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المبلغ المتبقي: ${_fmt(remaining)}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                  labelText: 'المبلغ المدفوع', prefixIcon: Icon(Icons.payments)),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(ctrl.text) ?? 0;
              if (amount <= 0) return;
              try {
                await invoiceRepo.addPayment(
                    invoiceId: invoiceId, amount: amount);
                if (context.mounted) Navigator.pop(context);
                _reload();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('خطأ: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('تأكيد الدفع'),
          ),
        ],
      ),
    );
  }
}

class _InvoiceSummaryCard extends StatelessWidget {
  final dynamic invoice;
  const _InvoiceSummaryCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final remaining = invoice.totalAmount - invoice.paidAmount;
    final color = invoice.status == 'paid'
        ? Colors.green
        : invoice.status == 'partial'
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem('الإجمالي',
              NumberFormat('#,##0', 'ar').format(invoice.totalAmount),
              Colors.black87),
          _SummaryItem('المدفوع',
              NumberFormat('#,##0', 'ar').format(invoice.paidAmount),
              Colors.green),
          _SummaryItem('المتبقي',
              NumberFormat('#,##0', 'ar').format(remaining),
              remaining > 0 ? Colors.red : Colors.grey),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }
}
