# 🏥 نظام إدارة العيادة الطبية
## Flutter Desktop – Windows | Drift ORM | Riverpod | Clean Architecture

---

## 📁 هيكل المشروع

```
lib/
├── main.dart                          # نقطة الدخول + إعداد Theme عربي RTL
│
├── data/
│   ├── database/
│   │   ├── app_database.dart          # AppDatabase الرئيسي (Drift)
│   │   ├── tables/
│   │   │   ├── medical_tables.dart    # Patients, Doctors, Appointments, Visits, Procedures, VisitProcedures
│   │   │   └── accounting_tables.dart # Invoices, Payments, Expenses, CashBox, Items, StockMovements, AuditLog
│   │   └── daos/
│   │       ├── patients_dao.dart
│   │       ├── doctors_dao.dart
│   │       ├── appointments_dao.dart
│   │       ├── visits_dao.dart
│   │       ├── procedures_dao.dart
│   │       ├── invoices_dao.dart
│   │       ├── payments_dao.dart
│   │       ├── expenses_dao.dart
│   │       ├── cashbox_dao.dart
│   │       ├── inventory_dao.dart
│   │       └── audit_dao.dart
│   │
│   ├── repositories/
│   │   └── repositories.dart          # PatientRepository, InvoiceRepository
│   │
│   └── services/
│       ├── services.dart              # ReportService, BackupService
│       └── export_service.dart        # PDF + Excel export
│
├── domain/
│   ├── repositories/
│   │   └── i_patient_repository.dart  # Interface
│   └── usecases/
│       └── usecases.dart              # CreatePatient, UpdatePatient, CreateVisit, AddProcedureToVisit
│
└── presentation/
    ├── providers/
    │   └── providers.dart             # كل Riverpod Providers
    └── screens/
        ├── home/
        │   └── home_screen.dart       # NavigationRail + Dashboard
        ├── patients/
        │   ├── patients_list_screen.dart
        │   ├── add_patient_screen.dart
        │   └── patient_detail_screen.dart
        ├── appointments/
        │   └── appointments_screen.dart
        ├── visits/
        │   ├── add_visit_screen.dart
        │   └── visit_detail_screen.dart
        ├── invoices/
        │   ├── invoice_screen.dart
        │   └── invoice_detail_screen.dart
        ├── reports/
        │   └── reports_screen.dart
        ├── inventory/
        │   └── inventory_screen.dart
        └── settings/
            └── settings_screen.dart
```

---

## 🚀 خطوات تشغيل المشروع

### 1. تثبيت الحزم
```bash
flutter pub get
```

### 2. تحميل خطوط Cairo
أضف ملفات الخطوط إلى `assets/fonts/`:
- `Cairo-Regular.ttf`
- `Cairo-Bold.ttf`
- `Cairo-SemiBold.ttf`

يمكن تحميلها من Google Fonts:
```bash
# أو استخدم google_fonts مباشرة (لا حاجة لتحميل يدوي)
```

### 3. توليد كود Drift
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. تشغيل على Windows
```bash
flutter run -d windows
```

---

## 🔧 ملاحظات مهمة

### إعداد Windows
في `windows/runner/main.cpp` تأكد من إضافة:
```cpp
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
```

### Foreign Keys
يتم تفعيل `PRAGMA foreign_keys = ON` تلقائياً عند فتح قاعدة البيانات.

### WAL Mode
تم تفعيل `PRAGMA journal_mode = WAL` لتحسين الأداء.

---

## 📊 تدفق العمل الرئيسي

```
موعد → زيارة → إضافة إجراءات → فاتورة تلقائية → دفعات → تحديث الصندوق
```

### حالات الفاتورة التلقائية:
- `unpaid`  → عند الإنشاء
- `partial` → عند تسجيل دفعة جزئية
- `paid`    → عند اكتمال الدفع

---

## 🔒 قواعد القفل

| العنصر | شرط القفل | ما يمنعه |
|--------|-----------|---------|
| الزيارة | يدوي | تعديل الإجراءات |
| الفاتورة | عند الدفع الكامل | تعديل البنود |
| يوم الصندوق | يدوي | تعديل الأرصدة |

---

## 📦 النسخ الاحتياطي

- **يدوي**: من إعدادات → نسخ احتياطي
- **تلقائي**: عند كل بدء للتطبيق (يحتفظ بآخر 7 نسخ)
- **الاستعادة**: تستبدل قاعدة البيانات الحالية + إعادة تشغيل

---

## 📤 التصدير

- **PDF**: بتخطيط عربي RTL مع اسم العيادة والتواريخ
- **Excel**: جدول منظم بأعمدة: التاريخ، النوع، المبلغ، الملاحظات
