// lib/presentation/screens/patients/add_patient_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';

class AddPatientScreen extends ConsumerStatefulWidget {
  final int? editId;
  const AddPatientScreen({super.key, this.editId});

  @override
  ConsumerState<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends ConsumerState<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _birthDate;
  bool _loading = false;

  bool get _isEdit => widget.editId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadPatient();
  }

  Future<void> _loadPatient() async {
    final patient =
        await ref.read(patientRepositoryProvider).getById(widget.editId!);
    if (patient != null) {
      _nameCtrl.text = patient.name;
      _phoneCtrl.text = patient.phone ?? '';
      _notesCtrl.text = patient.notes ?? '';
      setState(() => _birthDate = patient.birthDate);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'تعديل بيانات المريض' : 'إضافة مريض جديد'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // اسم المريض
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم المريض *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 2) {
                      return 'يجب إدخال اسم المريض (حرفان على الأقل)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // الهاتف
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),

                // تاريخ الميلاد
                InkWell(
                  onTap: _pickBirthDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الميلاد',
                      prefixIcon: Icon(Icons.cake),
                    ),
                    child: Text(
                      _birthDate != null
                          ? DateFormat('yyyy/MM/dd').format(_birthDate!)
                          : 'اختر التاريخ',
                      style: TextStyle(
                        color: _birthDate != null ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ملاحظات
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // زر الحفظ
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save),
                    label: Text(_isEdit ? 'حفظ التعديلات' : 'إضافة المريض'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      if (_isEdit) {
        await ref.read(updatePatientProvider).call(
              id: widget.editId!,
              name: _nameCtrl.text,
              phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
              birthDate: _birthDate,
              notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
            );
      } else {
        await ref.read(createPatientProvider).call(
              name: _nameCtrl.text,
              phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
              birthDate: _birthDate,
              notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'تم تحديث بيانات المريض' : 'تمت إضافة المريض'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
