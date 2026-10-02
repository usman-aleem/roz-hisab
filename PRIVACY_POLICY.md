# Privacy Policy — Roz Hisab

**Last updated:** 1 October 2026

Roz Hisab ("the app") is built around a simple rule: your financial
records belong to you. By default they stay on your own device. If you
choose to sign in with Google, they are also backed up to your own
private cloud space. This policy explains exactly what that means.

## 1. What data the app collects

**Without signing in:** the app collects nothing. There is no account
and no server involved. Everything you enter (shopping lists, Udhar
Khata entries and contacts, bills, daily items) is stored **only on
your own device**.

**If you sign in with Google (optional):** Google Firebase
Authentication receives your Google account's basic profile (name,
email, unique ID) to log you in, and your records are copied to
Google Firebase Firestore so they can be restored on another device.
This only happens after you tap "Google se Login". The app does not
use analytics, advertising SDKs, or crash-reporting services.

## 2. Where your data is stored

- Shopping lists, Udhar Khata records, bills and daily items are stored
  locally using `SharedPreferences`, encrypted at rest with AES-256. The
  encryption key is generated on-device and held in the Android
  Keystore / iOS Keychain via `flutter_secure_storage` — it never
  leaves the device and is never sent to Roz Hisab or anyone else.
- If you turn on App Lock, your PIN is never stored in plain text —
  only its SHA-256 hash, inside the same secure, encrypted storage.
  The same applies to the answer to your security question (used to
  recover a forgotten PIN): only a hash of it is kept, never the
  answer itself.
- Your details (name, optional phone/email) and monthly budget (used
  only to personalize receipts and the budget tracker) are stored
  locally as plain text, since
  they contain no transaction detail.

## 2a. Cloud backup (only if you sign in)

- Your records are stored in Firestore under `users/{your-user-id}`.
  Security rules allow only you (the signed-in user) to read or write
  that area. The data is protected in transit and at rest by Google,
  but it is **not end-to-end encrypted**, which means Google (and the
  app's developer, through the Firebase console) can technically
  access it.
- Logging out keeps the data on your device and in the cloud. "Reset
  App" while logged in deletes the cloud copy as well.
- If the developer enables the optional email-reminder feature, your
  Google email address is used to send due-date reminders through the
  Brevo email service. No other data leaves the cloud for this purpose
  except the reminder text (bill/person name and amount).

## 3. Backups you create yourself

The Settings screen lets you download a readable **PDF backup** of all
your data with one tap, and export a `.json` restore file, using your
device's native share/download feature. That file is created and shared
entirely **by you** — Roz Hisab does not upload it anywhere. Where
it ends up (your own cloud drive, WhatsApp, email, a USB drive) is
your choice, and you're responsible for keeping that file safe,
since it is not encrypted the way on-device storage is.

## 4. Permissions the app requests, and why

| Permission | Purpose |
|---|---|
| Notifications | To remind you when a bill is due (`flutter_local_notifications`). Entirely local — no push server involved. |
| Biometric / device credential | Only if you enable App Lock, to unlock the app with your fingerprint/face instead of typing a PIN. |
| Storage / file access | Only when you choose to export or import a backup file. |

The app does **not** request contacts, location, camera, microphone,
or SMS access. The optional "Remind via WhatsApp" feature for Udhar
contacts opens WhatsApp with a pre-filled message using a phone
number **you typed into the app yourself** — Roz Hisab never reads
your phone's contact list.

## 5. Third-party sharing

Roz Hisab does not sell, rent, or share your data with any third
party. The only places your data goes are places you explicitly send
it to (a WhatsApp/Email alert, a receipt or backup file, or Google
Firebase if you sign in) — for example, sharing a shopping receipt PDF
or a backup file through your device's normal share sheet.

## 6. Data deletion

You are in control of your data:

- Delete a single shopping list, contact, or bill from within the app.
- Use **Settings → Reset App** to permanently erase everything the
  app has stored on this device (and your cloud copy, if logged in).
- Uninstalling the app removes its local data.
- To delete your cloud account data without using the app, contact
  the address in section 9 and it will be removed.

## 7. Children's privacy

Roz Hisab is a general-purpose personal finance tool not directed at
children, and does not knowingly collect data from anyone, child or
adult, and does not collect data unless the user chooses to sign in.

## 8. Changes to this policy

If this policy changes, this document will be updated and the
"Last updated" date above will change accordingly. Any feature that
would send your data off-device will be off by default and clearly
explained before you turn it on.

## 9. Contact

Questions about this policy or the app's data handling can be sent
to: **[email protected]** *(replace with your real contact
address before publishing to an app store)*.

---

*This policy must be hosted at a publicly reachable URL (e.g. GitHub
Pages, or as a raw file link) before submitting Roz Hisab to the
Google Play Console — see [DEPLOYMENT.md](DEPLOYMENT.md) for the
exact step.*