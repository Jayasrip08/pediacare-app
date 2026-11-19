# PediaCare / OmniClinic - Modular Multi-Specialty Healthcare Platform (Flutter + Supabase)

Phase 1 MVP extended with a **Dynamic Department Architecture** by **InnoLift Ventures Private Limited**.
One Flutter codebase supporting role-based experiences (Parent / Doctor) with dynamic specialty modules tailored per clinic:

| Department | Clinical Specialty | Tailored Clinical Features & Workspace |
|---|---|---|
| 👶 **Pediatrics** | Child Health | Vaccination tracker & due dates, Growth charts (Weight/Height/Head), Pediatric weight-based dose calculator |
| 💆 **Dermatology** | Skin & Cosmetology | Before / After side-by-side photo comparison gallery, treatment package session logs (laser, peels) |
| 🦷 **Dental** | Oral Health & Dentistry | Interactive Odontogram (Adult #1–#32 teeth map with Caries, Filled, RCT, Crown, Missing), Procedure treatment plans |
| 🤰 **Pregnancy Care** | Obstetrics & Maternity | Naegele EDD & gestational age calculator (week & trimester countdown), ANC checkups (BP, FHR, fundal height), prenatal test protocol |
| 👁️ **Eye Clinics** | Ophthalmology & Optometry | Refraction prescription pad (OD/OS: SPH, CYL, AXIS, ADD, VA 6/6), IOP tonometry with glaucoma alert, slit lamp findings |
| 🧠 **Psychiatry** | Mental Health & Counselling | Interactive PHQ-9 & GAD-7 screeners with automated score & severity bands, SOAP therapy session notes, coping goals |

## What is implemented (Phase 1 scope)

| Area | Parent | Doctor |
|---|---|---|
| Auth | Phone OTP (+ email/password for dev), role onboarding | same, plus clinic creation |
| Child | Multiple child profiles, DPDP consent, auto vaccine schedule | Patient list + search, child timeline |
| Vaccines | Tracker, due/overdue, mark given | Pending-vaccine list, mark given |
| Growth | Weight/height/head chart (fl_chart) | Add/view measurements |
| Appointments | Book slot, token, live queue position | Today's queue, start consult, no-show |
| Prescriptions | View, PDF share/print, WhatsApp share | Weight-based dose calculator, one-tap send, PDF |
| Records | Upload/view reports (private storage) | View patient records |
| Chat | Realtime chat + photo/PDF attach, read receipts | Inbox with unread counts |
| Follow-ups | - | Missed follow-up list (auto-detected) |
| Onboarding | Scan clinic QR / enter code | Clinic QR + code, edit hours |

Not in this MVP (per roadmap): push notifications, WhatsApp Business API, AI symptom guidance,
Tamil voice input, WHO percentile bands, teleconsultation, multi-clinic.

## 1. Supabase setup
1. Create a project at supabase.com.
2. SQL Editor -> run `supabase/migrations/20260101000000_pediacare_schema.sql`, then `supabase/seed.sql`.
3. Authentication -> Providers:
   * **Phone**: enable and connect an SMS provider (Twilio / MessageBird / Vonage). For development use
     *Test phone numbers & OTPs* so no SMS is needed.
   * **Email** (optional dev login): enable; disable "Confirm email" for quick testing.
4. Project Settings -> API: copy the project URL and the `anon` public key.

## 2. Flutter setup (Flutter 3.27+)
```bash
cd pediacare
flutter create . --org com.innolift --project-name pediacare   # generates android/ ios/ folders
cp env.example.json env.json                                    # fill in URL + anon key
flutter pub get
flutter run --dart-define-from-file=env.json
flutter test                                                    # dose-calculator unit tests
```

### Platform configuration
**Android** - `android/app/build.gradle(.kts)`: `minSdk = 23`. In `AndroidManifest.xml` add
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<queries>
  <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
  <intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>
</queries>
```
**iOS** - `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key><string>Scan your clinic's QR code</string>
<key>NSPhotoLibraryUsageDescription</key><string>Upload reports and photos</string>
<key>LSApplicationQueriesSchemes</key><array><string>https</string><string>tel</string></array>
```

## 3. Try it end-to-end
1. Device A: sign in -> **Doctor** -> enter clinic details. Open the **Clinic** tab (QR + code).
2. Device B: sign in -> **Parent** -> add child -> scan the QR (or type the code).
3. Parent books an appointment -> Doctor sees it on the dashboard -> *Start consultation* ->
   *Prescribe* (weight is prefilled from growth records) -> *Send to parent app*.
4. Parent opens **Visits -> Prescriptions**, shares the PDF, chats with the doctor.

## Architecture
```
lib/
  core/        theme (deck palette), router (go_router + auth guard), shared widgets, utils
  models/      plain Dart models (fromJson)
  data/        Supabase repositories (auth, health, clinic, appointment, prescription, chat)
  providers.dart  Riverpod providers (state + caching)
  features/
    auth/ parent/ doctor/ shared/   screens grouped by feature; shared/ is reused by both roles
supabase/      schema + RLS + RPC functions + seed
```
* **Security**: all tables use Row Level Security. Parents see only their children; a doctor sees only
  children linked to their clinic (via `join_clinic()`); prescriptions are insert-only (immutable);
  files live in a private bucket scoped by child id; parents can only cancel appointments.
* **Realtime**: chat uses Supabase Realtime (`messages` table).
* **Brand**: Navy `#0F1E3D`, Orange `#F7861E`, Space Grotesk + Inter (via `google_fonts`).

## IMPORTANT before a real pilot
* **Clinical review**: the vaccine schedule (`seed.sql`) and the drug formulary are *defaults*.
  A pediatrician must verify them against current IAP/UIP guidance. Formulary rows have
  `reviewed=false`, which shows a warning in the app; set to `true` after sign-off.
  The calculator only *suggests* a dose - the doctor must edit/confirm and tick the confirmation box.
* **Doctor verification**: any user can currently choose "Doctor" at onboarding. Add a
  `verified` flag + admin approval before onboarding real clinics.
* **Time zone**: queue/day logic assumes Asia/Kolkata; slots are generated in device time.
* **Compliance**: add a privacy policy, data-retention + account-deletion flow (DPDP Act), and
  review Supabase region (choose Mumbai) and backups.
* **Reminders**: this MVP shows due/overdue in-app. For push reminders add Firebase Cloud Messaging
  + a Supabase Edge Function / pg_cron job.
* **Fonts**: `google_fonts` downloads fonts at runtime; bundle them in `assets/` for offline use.
