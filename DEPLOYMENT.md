# Roz Hisab — Setup, Deployment & Technical Docs

For the project description (what it is, why it was built), see [README.md](README.md).

## 🚀 Zero Se Live Tak — Poora Command Sequence (Ek Jagah)

```bash
# STEP 1 — Project ko chalane layak banao
cd roz_hisab
flutter create --org com.rozhisab --project-name roz_hisab .
flutter pub get
dart run flutter_launcher_icons
flutter run

# STEP 2 — GitHub par source code live karo
git init
git add .
git commit -m "Initial commit: Roz Hisab v1.0"
git remote add origin https://github.com/<your-username>/roz-hisab.git
git branch -M main
git push -u origin main

# STEP 3A — Android app live karo (Play Store)
keytool -genkey -v -keystore ~/roz-hisab-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias roz_hisab
flutter build appbundle --release

# STEP 3B — Website live karo
npm install -g firebase-tools
firebase login
firebase init hosting
flutter build web --release
firebase deploy
```

---

## Chalane Ke Liye (Local Setup)
```bash
flutter create --org com.rozhisab --project-name roz_hisab .
flutter pub get
dart run flutter_launcher_icons
flutter run
```
`--org` flag zaroori hai — bina iske package `com.example.roz_hisab` banega jo Play Store allow nahi karta.

---

## 1️⃣ GitHub Par Live Karna

```bash
git init
git add .
git commit -m "Initial commit: Roz Hisab v1.0"
git remote add origin https://github.com/<your-username>/roz-hisab.git
git branch -M main
git push -u origin main
```

`.github/workflows/build_apk.yml` already hai — push hote hi GitHub khud `flutter create .` chala kar (android/ios folders generate karega), phir `flutter analyze` aur APK build kar dega, sab automatically. Koi local setup CI ke liye zaroori nahi.

**Future changes:**
```bash
git add .
git commit -m "kya badla, ek line mein"
git push
```

---

## 2️⃣ Google Play Store Par Live Karna

**Step 1 — Signing key:**
```bash
keytool -genkey -v -keystore ~/roz-hisab-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias roz_hisab
```

**Step 2 — `android/key.properties`** (already `.gitignore` mein hai):
```properties
storePassword=<jo password rakha>
keyPassword=<jo password rakha>
keyAlias=roz_hisab
storeFile=/full/path/to/roz-hisab-key.jks
```

**Step 3 — Release bundle:**
```bash
flutter build appbundle --release
```

**Step 4 — Privacy policy host karo (Play Store ke liye mandatory):**

[`PRIVACY_POLICY.md`](PRIVACY_POLICY.md) already likha hua hai — usay kisi public URL par host karo, jaise:
```bash
# GitHub Pages ke through (free, sabse aasan):
# Settings → Pages → Deploy from branch → main → root
# URL ban jayega: https://<username>.github.io/roz-hisab/PRIVACY_POLICY.md
```
Ya phir GitHub par file ka raw link (`https://raw.githubusercontent.com/...`) bhi kaam karta hai — Play Console isse accept karta hai.

**Step 5 — Version bump har release par:**

`pubspec.yaml` mein `version: 0.1.0+1` — pehla number (`0.1.0`) user-facing version hai, `+1` wala build number Play Store ke liye har naye upload par **barhana zaroori hai** (e.g. `0.1.1+2`), warna Play Console upload reject kar dega.

**Step 6 — Play Console:**
1. [play.google.com/console](https://play.google.com/console) — developer account ($25 one-time)
2. "Create app" → details fill karo
3. `.aab` upload karo
4. Step 4 wala privacy policy URL paste karo
5. Review submit (1-3 din)

---

## 3️⃣ Website (PWA) Par Live Karna

```bash
flutter build web --release
```

### Firebase Hosting (recommended)
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
flutter build web --release
firebase deploy
```

### GitHub Pages
```bash
flutter build web --release --base-href "/roz-hisab/"
cd build/web
git init && git add . && git commit -m "Deploy web build"
git branch -M gh-pages
git remote add origin https://github.com/<your-username>/roz-hisab.git
git push -f origin gh-pages
```

### Netlify
```bash
npm install -g netlify-cli
flutter build web --release
netlify deploy --prod --dir=build/web
```

---

## 🔒 Security

| Layer | Implementation |
|---|---|
| App access control | PIN + biometric — Settings → App Lock |
| PIN storage | SHA-256 hash in `flutter_secure_storage` |
| App data storage | SharedPreferences, AES-256 encrypted |
| PIN recovery | "Forgot PIN?" — resets lock, data stays safe |
| Backup file | JSON, your control |
| Release build | Obfuscated |
| Signing key | `.gitignore`'d |

**Web note:** No biometrics in browser (falls back to PIN only). `flutter_secure_storage` on web uses IndexedDB (less secure than mobile Keystore/Keychain, but fine for normal use).

**Not yet built:** push notifications (from a server — local bill-reminder notifications ARE built), encrypted backup export file, cloud sync.

See [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for the full data-handling policy — required to be hosted at a public URL before Play Store submission (see step 4 above).

---

## What's New

Beyond the original three modules (Shopping, Udhar Khata, Bills), the following have since been added — all using the existing design system and dependencies, no new packages required:

| Feature | Where | What it solves |
|---|---|---|
| **Settle Up** | Udhar → contact detail | Records a full or partial repayment against a balance without the user having to work out loan direction ("+ I Gave" vs "+ I Took") themselves. |
| **Remind via WhatsApp** | Udhar → contact detail | One tap opens WhatsApp with a ready-drafted balance reminder to that contact, using a number typed into the app (no contacts-list access). |
| **Auto-renewing recurring bills** | Bills | Marking a recurring bill paid silently creates next month's bill, so reminders don't quietly stop when someone forgets to re-add it. |
| **"Buy Again" quick-add + quantity stepper** | Shopping → New Trip | Frequently-bought items become tappable chips at their last price; a qty stepper avoids re-adding the same item multiple times. |
| **"Where Your Money Went"** | Home dashboard | Every shopping item is auto-categorized (Grocery, Vegetables & Fruit, Dairy, etc.) by keyword matching — zero manual tagging — and totalled per category for the current month. |

---

## Design System

| Role | Hex |
|---|---|
| Primary (Navy) | `#1E3A5F` |
| Accent (Teal) | `#0D9488` |
| Gold (highlight) | `#C9A227` |
| Amber (due soon) | `#D97706` |
| Danger (overdue) | `#DC2626` |
| Success | `#15803D` |
| Background | `#F4F6F9` |

Typography: Poppins (headings) + Inter (body/numbers), via `google_fonts`.

## 🔔 Notification Permissions (Bill Reminders)

Bill reminders use `flutter_local_notifications`. The plugin auto-merges most Android manifest entries, but confirm these after running `flutter create .`:

- **Android 13+**: runtime notification permission is requested automatically at first launch (handled in `notification_service.dart`) — no manual step needed.
- **Exact-time scheduling** (Android 12+): if reminders don't fire at the scheduled time on some devices, add this to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:
  ```xml
  <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
  ```
- **iOS**: alert/badge/sound permissions are requested automatically on first launch.
- Not available on Web (browsers don't support scheduled local notifications) — calls are safe no-ops there, no crash.

## Tech Stack
Flutter · `google_fonts` · `pdf` · `printing` · `share_plus` · `shared_preferences` · `flutter_secure_storage` · `crypto` · `encrypt` · `local_auth` · `flutter_local_notifications` · `timezone` · `file_picker` · `url_launcher` · `uuid` · `intl` · `flutter_launcher_icons`

## Folder Structure
```
.github/workflows/build_apk.yml
assets/icon/app_icon.png
web/  (index.html, manifest.json, favicon.png, icons/)
lib/
├── main.dart
├── config/theme.dart
├── models/    (shopping_list, shopping_item, contact, udhar_entry, bill)
├── services/  (app_data, storage_service, category_service, pdf_service,
│               backup_service, crypto_service, auth_service,
│               notification_service)
├── screens/   (home/ shopping/ udhar/ bills/ settings/ auth/)
└── widgets/   (buy_again_row, category_breakdown_card, bill_tile,
                contact_balance_tile, summary_card, spending_trend_card,
                budget_progress_card, quick_add_bar, hover_card, status_pill)
.gitignore
LICENSE
PRIVACY_POLICY.md
README.md
DEPLOYMENT.md
```

## Android/iOS platform folders

`android/` and `ios/` are intentionally **not committed** to keep the
source tree small — they're generated on demand by
`flutter create --org com.rozhisab --project-name roz_hisab .`, both
when you set the project up locally (see "Chalane Ke Liye" above) and
automatically inside the CI workflow on every push. This is a
one-line, deterministic step, so there's nothing to keep in sync by
hand.
