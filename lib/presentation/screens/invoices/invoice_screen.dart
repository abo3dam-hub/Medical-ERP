// lib/presentation/screens/invoices/invoice_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import 'invoice_detail_screen.dart';

class InvoiceScreen extends ConsumerWidget {
  const InvoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الفواتير')),
        body: FutureBuilder(
          future: db.invoicesDao.getAllWithPatient(),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final invoices = snap.data!;
            if (invoices.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('لا توجد فواتير',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: invoices.length,
              itemBuilder: (ctx, i) {
                final inv = invoices[i];
                final remaining =
                    inv.invoice.totalAmount - inv.invoice.paidAmount;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _statusColor(inv.invoice.status)
                          .withOpacity(0.15),
                      child: Icon(Icons.receipt,
                          color: _statusColor(inv.invoice.status)),
                    ),
                    title: Row(
                      children: [
                        Text(inv.patient.name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        _StatusBadge(inv.invoice.status),
                      ],
                    ),
                    subtitle: Text(
                      'الإجمالي: ${_fmt(inv.invoice.totalAmount)}  |  '
                      'المدفوع: ${_fmt(inv.invoice.paidAmount)}  |  '
                      'المتبقي: ${_fmt(remaining)}',
                    ),
                    trailing: Text(
                      DateFormat('yyyy/MM/dd').format(inv.invoice.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => InvoiceDetailScreen(
                              invoiceId: inv.invoice.id)),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _fmt(double n) => NumberFormat('#,##0', 'ar').format(n);
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final Map<String, (String, Color)> map = {
      'unpaid': ('غير مدفوع', Colors.red),
      'partial': ('جزئي', Colors.orange),
      'paid': ('مدفوع', Colors.green),
    };
    final (label, color) = map[status] ?? (status, Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
