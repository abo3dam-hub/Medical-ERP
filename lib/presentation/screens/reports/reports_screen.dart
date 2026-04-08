// lib/presentation/screens/reports/reports_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../../data/services/export_service.dart';
import '../../../data/services/services.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقارير'),
          bottom: TabBar(
            controller: _tabCtrl,
            tabs: const [
              Tab(text: 'يومي'),
              Tab(text: 'شهري'),
              Tab(text: 'الأطباء'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabCtrl,
          children: const [
            _DailyReportTab(),
            _MonthlyReportTab(),
            _DoctorReportTab(),
          ],
        ),
      ),
    );
  }
}

// ─── تقرير يومي ───
class _DailyReportTab extends ConsumerStatefulWidget {
  const _DailyReportTab();

  @override
  ConsumerState<_DailyReportTab> createState() => _DailyReportTabState();
}

class _DailyReportTabState extends ConsumerState<_DailyReportTab> {
  DateTime _date = DateTime.now();
  DailyReport? _report;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final report = await ref.read(reportProvider).getDailyReport(_date);
    setState(() {
      _report = report;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // اختيار التاريخ
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      locale: const Locale('ar'),
                    );
                    if (d != null) {
                      setState(() => _date = d);
                      _load();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'التاريخ',
                        prefixIcon: Icon(Icons.calendar_today)),
                    child: Text(DateFormat('yyyy/MM/dd').format(_date)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_loading)
            const Expanded(
                child: Center(child: CircularProgressIndicator()))
          else if (_report != null)
            Expanded(
              child: Column(
                children: [
                  _ReportCard(
                      label: 'إجمالي الإيرادات',
                      value: _report!.totalIncome,
                      color: Colors.green,
                      icon: Icons.trending_up),
                  _ReportCard(
                      label: 'إجمالي المصاريف',
                      value: _report!.totalExpenses,
                      color: Colors.red,
                      icon: Icons.trending_down),
                  _ReportCard(
                      label: 'صافي الربح',
                      value: _report!.netProfit,
                      color: _report!.netProfit >= 0
                          ? Colors.blue
                          : Colors.red,
                      icon: Icons.account_balance),
                  if (_report!.cashBox != null) ...[
                    const Divider(),
                    _CashBoxCard(cashBox: _report!.cashBox!),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _exportPdf(),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('تصدير PDF'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_report == null) return;
    // تحويل التقرير اليومي لـ PeriodReport للتصدير
    final period = PeriodReport(
      from: _date,
      to: _date,
      type: 'يومي',
      totalIncome: _report!.totalIncome,
      totalExpenses: _report!.totalExpenses,
      netProfit: _report!.netProfit,
      doctorRevenues: [],
    );
    await ExportService.exportReportToPdf(period);
  }
}

// ─── تقرير شهري ───
class _MonthlyReportTab extends ConsumerStatefulWidget {
  const _MonthlyReportTab();

  @override
  ConsumerState<_MonthlyReportTab> createState() =>
      _MonthlyReportTabState();
}

class _MonthlyReportTabState extends ConsumerState<_MonthlyReportTab> {
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  PeriodReport? _report;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final report =
        await ref.read(reportProvider).getMonthlyReport(_year, _month);
    setState(() {
      _report = report;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'الشهر'),
                  value: _month,
                  items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(DateFormat('MMMM', 'ar')
                              .format(DateTime(2024, i + 1))))),
                  onChanged: (v) => setState(() => _month = v!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'السنة'),
                  value: _year,
                  items: List.generate(
                      5,
                      (i) => DropdownMenuItem(
                          value: DateTime.now().year - i,
                          child: Text('${DateTime.now().year - i}'))),
                  onChanged: (v) => setState(() => _year = v!),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                  onPressed: _load, child: const Text('عرض')),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Expanded(
                child: Center(child: CircularProgressIndicator()))
          else if (_report != null)
            Expanded(
              child: Column(
                children: [
                  _ReportCard(
                      label: 'إجمالي الإيرادات',
                      value: _report!.totalIncome,
                      color: Colors.green,
                      icon: Icons.trending_up),
                  _ReportCard(
                      label: 'إجمالي المصاريف',
                      value: _report!.totalExpenses,
                      color: Colors.red,
                      icon: Icons.trending_down),
                  _ReportCard(
                      label: 'صافي الربح',
                      value: _report!.netProfit,
                      color: Colors.blue,
                      icon: Icons.account_balance),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              ExportService.exportReportToPdf(_report!),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('PDF'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── تقرير الأطباء ───
class _DoctorReportTab extends ConsumerStatefulWidget {
  const _DoctorReportTab();

  @override
  ConsumerState<_DoctorReportTab> createState() => _DoctorReportTabState();
}

class _DoctorReportTabState extends ConsumerState<_DoctorReportTab> {
  List<DoctorRevenue>? _revenues;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ref.read(reportProvider).getDoctorPerformance();
    setState(() {
      _revenues = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_revenues == null || _revenues!.isEmpty) {
      return const Center(child: Text('لا توجد بيانات'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _revenues!.length,
      itemBuilder: (ctx, i) {
        final r = _revenues![i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(child: Text(r.doctor.name[0])),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('د. ${r.doctor.name}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(r.doctor.specialty ?? '',
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text('${r.doctor.commission}%',
                        style: const TextStyle(color: Colors.orange)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DoctorStat('إجمالي الإيرادات',
                        _fmt(r.totalRevenue), Colors.blue),
                    _DoctorStat(
                        'صافي بعد العمولة',
                        _fmt(r.netRevenue),
                        Colors.green),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmt(double n) => NumberFormat('#,##0', 'ar').format(n);
}

class _DoctorStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _DoctorStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ],
    );
  }
}

// ─── بطاقات مشتركة ───
class _ReportCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _ReportCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          NumberFormat('#,##0.00', 'ar').format(value),
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}

class _CashBoxCard extends StatelessWidget {
  final dynamic cashBox;
  const _CashBoxCard({required this.cashBox});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('صندوق النقدية',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CashItem('رصيد الافتتاح',
                    cashBox.openingBalance, Colors.grey),
                _CashItem(
                    'إجمالي الدخل', cashBox.totalIncome, Colors.green),
                _CashItem('إجمالي المصاريف', cashBox.totalExpense,
                    Colors.red),
                _CashItem('رصيد الإغلاق', cashBox.closingBalance,
                    Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CashItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _CashItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(NumberFormat('#,##0', 'ar').format(value),
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }
}
