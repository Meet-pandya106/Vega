# Dhan F&O Trading Ledger & Accounting Mobile App

A privacy-focused, zero-threat, multi-tab Android application designed specifically for **Indian Index and Stock Futures & Options (F&O)** trading with **Dhan Brokerage Rules**, **ICAI Tax Turnover Accounting**, and **Supabase Backend**.

---

## 📱 Features & Highlights

* **5 Multi-Tab Interface:**
  1. **Dashboard:** Today's Net P&L hero card with breathing emerald/crimson aura, active derivative lot pills, real-time capital balance, and privacy blur toggle.
  2. **Quick Punch & Calculator:** Instant F&O trade logger with lot size auto-completion (Nifty, BankNifty, Sensex, and 180+ F&O stocks like Reliance, Tata Motors). Computes exact real-time Dhan brokerage, STT, and taxes.
  3. **Tradebook:** Filterable history of closed and open executions with complete Dhan contract note fee breakdowns.
  4. **Calendar & Journal:** Monthly P&L heatmap with green/red day indicators and trading discipline/mistake tagging.
  5. **Taxes & Accounting:** Automatic calculation of running **ICAI F&O Turnover**, allowable business expense tracking, and **Dhan CSV Tradebook import**.

* **🛡️ Zero-Threat Security Architecture:**
  * **Biometric Lock:** Unlocks via Android Keystore fingerprint / PIN.
  * **Auto-Lock:** Blurs screen and locks immediately when minimized or switched in Android recent apps (`FLAG_SECURE`).
  * **Minimal Permissions:** Only uses `INTERNET` (for your private Supabase instance) and `USE_BIOMETRIC`. Zero invasive device access.

---

## 🧮 Dhan F&O Expense Math Engine

Every trade execution automatically calculates:
* **Brokerage:** Flat ₹20 per executed order for Options; ₹20 or 0.03% for Futures.
* **STT (Securities Transaction Tax):** 0.1% on Option sell turnover (Union Budget revised rule); 0.02% on Futures.
* **Exchange Turnover Charges:** 0.03503% (NSE Options) / 0.00173% (NSE Futures).
* **GST:** 18% on (Brokerage + Exchange Charges + SEBI).
* **Stamp Duty:** 0.003% (Buy side Options) / 0.002% (Futures).
* **SEBI & IPFT:** ₹10 per crore (0.0001%).

---

## 📂 Project Structure

```
Personal Application/
├── lib/
│   ├── main.dart                          # Application entry point & theme
│   ├── core/
│   │   ├── constants/fo_master.dart        # Nifty, BankNifty, Sensex & 180+ F&O stock lot sizes
│   │   ├── models/dhan_charges.dart        # Dhan fee breakdown models
│   │   ├── services/
│   │   │   ├── dhan_calculator_service.dart# Pure Dart Dhan expense engine
│   │   │   ├── tax_accounting_service.dart # ICAI turnover & business tax deductions
│   │   │   ├── csv_import_service.dart     # Dhan Tradebook CSV parser
│   │   │   ├── biometric_service.dart      # Android Keystore biometric protection
│   │   │   └── supabase_service.dart       # Riverpod state & Supabase data store
│   │   └── theme/app_theme.dart            # High-contrast OLED dark theme
│   └── features/
│       ├── navigation/main_screen.dart     # 5-tab Bottom Navigation & lock screen
│       ├── dashboard/dashboard_screen.dart # Realized P&L & index master
│       ├── quick_punch/quick_punch_screen.dart # Fast order logger & live calc
│       ├── tradebook/tradebook_screen.dart # Executed trades & contract note modal
│       ├── calendar/calendar_screen.dart   # Monthly heatmap & discipline notes
│       └── accounting/accounting_screen.dart # ICAI turnover & CSV import
├── supabase/
│   └── schema.sql                          # Complete PostgreSQL schema with RLS
├── web_preview/
│   └── index.html                          # Instant interactive browser simulator
└── pubspec.yaml                            # Dependencies & Flutter config
```

---

## 🚀 How to Run & Build the Android APK

### 1. Instant Interactive Browser Preview
Open [index.html](file:///c:/Personal%20Application/web_preview/index.html) in Chrome or Edge to immediately interact with the multi-tab interface and live Dhan calculation engine.

### 2. Connect Supabase Database
1. Go to your [Supabase Dashboard](https://supabase.com).
2. Open the **SQL Editor** and paste the contents of `supabase/schema.sql`.
3. Click **Run**. All tables, indexes, and Row-Level Security (RLS) policies will be configured instantly.

### 3. Build Android APK
When Flutter is installed:
```powershell
flutter pub get
flutter run
```

To create the production release APK installable on your Android phone:
```powershell
flutter build apk --release
```
The installable `.apk` file will be generated in `build/app/outputs/flutter-apk/app-release.apk`.
