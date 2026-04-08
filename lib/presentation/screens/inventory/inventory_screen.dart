// lib/presentation/screens/inventory/inventory_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import '../../providers/providers.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsStreamProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المخزون'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddItemDialog(context, ref),
              tooltip: 'إضافة صنف',
            ),
          ],
        ),
        body: items.when(
          data: (list) {
            // تنبيه المواد الناقصة
            final lowStock = list.where((i) => i.quantity <= i.minQuantity).toList();

            return Column(
              children: [
                if (lowStock.isNotEmpty)
                  MaterialBanner(
                    backgroundColor: Colors.orange.shade50,
                    leading: const Icon(Icons.warning, color: Colors.orange),
                    content: Text(
                        '${lowStock.length} صنف تحت الحد الأدنى للمخزون'),
                    actions: [
                      TextButton(
                        onPressed: () {},
                        child: const Text('عرض'),
                      ),
                    ],
                  ),
                Expanded(
                  child: list.isEmpty
                      ? const Center(
                          child: Text('لا توجد أصناف مسجلة',
                              style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: list.length,
                          itemBuilder: (ctx, i) {
                            final item = list[i];
                            final isLow = item.quantity <= item.minQuantity;
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isLow
                                      ? Colors.orange.shade50
                                      : Colors.green.shade50,
                                  child: Icon(
                                    Icons.inventory_2,
                                    color: isLow
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(item.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    if (isLow) ...[
                                      const SizedBox(width: 8),
                                      const Chip(
                                        label: Text('ناقص',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10)),
                                        backgroundColor: Colors.orange,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                    'الكمية: ${item.quantity}  |  الحد الأدنى: ${item.minQuantity}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.add_circle,
                                          color: Colors.green),
                                      tooltip: 'وارد',
                                      onPressed: () => _showMovementDialog(
                                          context, ref, item, 'in'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle,
                                          color: Colors.red),
                                      tooltip: 'صادر',
                                      onPressed: () => _showMovementDialog(
                                          context, ref, item, 'out'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.history,
                                          color: Colors.blue),
                                      tooltip: 'الحركات',
                                      onPressed: () =>
                                          _showMovementsHistory(
                                              context, ref, item),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Center(child: Text('خطأ: $e')),
        ),
      ),
    );
  }

  Future<void> _showAddItemDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final minQtyCtrl = TextEditingController(text: '5');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة صنف جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'اسم الصنف *'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minQtyCtrl,
              decoration:
                  const InputDecoration(labelText: 'الحد الأدنى للمخزون'),
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
              await ref.read(databaseProvider).inventoryDao.insertItem(
                    ItemsCompanion(
                      name: Value(nameCtrl.text.trim()),
                      minQuantity: Value(int.tryParse(minQtyCtrl.text) ?? 5),
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

  Future<void> _showMovementDialog(
      BuildContext context, WidgetRef ref, dynamic item, String type) async {
    final qtyCtrl = TextEditingController(text: '1');
    final reasonCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(type == 'in' ? 'إضافة للمخزون (وارد)' : 'سحب من المخزون (صادر)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الصنف: ${item.name}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('الكمية الحالية: ${item.quantity}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(labelText: 'الكمية *'),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'السبب'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: type == 'in'
                ? ElevatedButton.styleFrom(backgroundColor: Colors.green)
                : ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final qty = int.tryParse(qtyCtrl.text) ?? 0;
              if (qty <= 0) return;
              try {
                final db = ref.read(databaseProvider);
                final delta = type == 'in' ? qty : -qty;
                await db.inventoryDao.adjustStock(item.id, delta);
                await db.inventoryDao.addMovement(StockMovementsCompanion(
                  itemId: Value(item.id),
                  type: Value(type),
                  quantity: Value(qty),
                  reason: Value(reasonCtrl.text.isEmpty ? null : reasonCtrl.text),
                ));
                if (context.mounted) Navigator.pop(context);
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
            child: Text(type == 'in' ? 'إضافة' : 'سحب'),
          ),
        ],
      ),
    );
  }

  Future<void> _showMovementsHistory(
      BuildContext context, WidgetRef ref, dynamic item) async {
    final movements =
        await ref.read(databaseProvider).inventoryDao.getMovementsForItem(item.id);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('حركات: ${item.name}'),
        content: SizedBox(
          width: 400,
          height: 350,
          child: movements.isEmpty
              ? const Center(child: Text('لا توجد حركات'))
              : ListView.builder(
                  itemCount: movements.length,
                  itemBuilder: (ctx, i) {
                    final m = movements[i];
                    return ListTile(
                      leading: Icon(
                        m.type == 'in' ? Icons.add_circle : Icons.remove_circle,
                        color: m.type == 'in' ? Colors.green : Colors.red,
                      ),
                      title: Text(
                          '${m.type == 'in' ? '+' : '-'}${m.quantity}',
                          style: TextStyle(
                              color: m.type == 'in'
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(m.reason ?? ''),
                      trailing: Text(
                          DateFormat('yyyy/MM/dd').format(m.date),
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'))
        ],
      ),
    );
  }
}
