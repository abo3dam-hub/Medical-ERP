// lib/presentation/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../patients/patients_list_screen.dart';
import '../appointments/appointments_screen.dart';
import '../visits/visits_screen.dart';
import '../invoices/invoice_screen.dart';
import '../reports/reports_screen.dart';
import '../inventory/inventory_screen.dart';
import '../settings/settings_screen.dart';
import '../../providers/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard, label: 'الرئيسية', screen: const _DashboardTab()),
    _NavItem(icon: Icons.people, label: 'المرضى', screen: const PatientsListScreen()),
    _NavItem(icon: Icons.calendar_today, label: 'المواعيد', screen: const AppointmentsScreen()),
    _NavItem(icon: Icons.medical_services, label: 'الزيارات', screen: const VisitsScreen()),
    _NavItem(icon: Icons.receipt, label: 'الفواتير', screen: const InvoiceScreen()),
    _NavItem(icon: Icons.bar_chart, label: 'التقارير', screen: const ReportsScreen()),
    _NavItem(icon: Icons.inventory, label: 'المخزون', screen: const InventoryScreen()),
    _NavItem(icon: Icons.settings, label: 'الإعدادات', screen: const SettingsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Row(
          children: [
            // شريط التنقل الجانبي
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              extended: true,
              minExtendedWidth: 200,
              backgroundColor: const Color(0xFF0D2137),
              selectedIconTheme: const IconThemeData(color: Color(0xFF64B5F6)),
              unselectedIconTheme: const IconThemeData(color: Colors.white54),
              selectedLabelTextStyle: const TextStyle(
                  color: Color(0xFF64B5F6), fontWeight: FontWeight.bold),
              unselectedLabelTextStyle: const TextStyle(color: Colors.white54),
              leading: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.local_hospital, color: Colors.white, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'عيادة الصحة',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              destinations: _navItems
                  .map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // المحتوى الرئيسي
            Expanded(child: _navItems[_selectedIndex].screen),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget screen;
  _NavItem({required this.icon, required this.label, required this.screen});
}

// ─── لوحة الإحصاءات ───
class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAppts = ref.watch(todayAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة التحكم')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مواعيد اليوم',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Expanded(
              child: todayAppts.when(
                data: (appts) => appts.isEmpty
                    ? const Center(child: Text('لا توجد مواعيد اليوم'))
                    : ListView.builder(
                        itemCount: appts.length,
                        itemBuilder: (ctx, i) {
                          final a = appts[i];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                  child: Icon(Icons.person)),
                              title: Text(a.patient.name),
                              subtitle: Text('د. ${a.doctor.name}'),
                              trailing: _StatusChip(a.appointment.status),
                            ),
                          );
                        }),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('خطأ: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final Map<String, (String, Color)> map = {
      'pending': ('معلق', Colors.orange),
      'confirmed': ('مؤكد', Colors.blue),
      'done': ('منجز', Colors.green),
      'cancelled': ('ملغي', Colors.red),
    };
    final (label, color) = map[status] ?? (status, Colors.grey);
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }
}
