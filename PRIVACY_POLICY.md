# Privacy Policy — Roz Hisab

**Last updated:** 27 September 2026

Roz Hisab ("the app") is built around a simple rule: your financial
records belong to you, stay on your device, and are never sent
anywhere without your explicit action. This policy explains exactly
what that means.

## 1. What data the app collects

Roz Hisab does not collect, transmit, or have access to any of your
data. There is no account, no login, and no server — the app has no
backend at all. Everything you enter (shopping lists, Udhar Khata
entries and contacts, bills) is created and stored **only on your
own device**.

The app does not use analytics, crash reporting, advertising SDKs,
or any other third-party service that would transmit your usage or
personal data off the device.

## 2. Where your data is stored

- Shopping lists, Udhar Khata records, and bills are stored locally
  using `SharedPreferences`, encrypted at rest with AES-256. The
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

## 3. Backups you create yourself

The Settings screen lets you export a backup as a `.json` file using
your device's native share sheet. That file is created and shared
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
party, because it never has a copy of your data to share in the
first place. The only places your data ever goes are places you
explicitly send it to — for example, sharing a shopping receipt PDF
or a backup file through your device's normal share sheet.

## 6. Data deletion

Since all data lives only on your device, you are always in full
control of it:

- Delete a single shopping list, contact, or bill from within the app.
- Use **Settings → Reset App** to permanently erase everything the
  app has stored on this device.
- Uninstalling the app removes all of its local data.

There is no account for Roz Hisab to delete on a server, because no
server-side copy of your data ever exists.

## 7. Children's privacy

Roz Hisab is a general-purpose personal finance tool not directed at
children, and does not knowingly collect data from anyone, child or
adult, since it does not collect data at all.

## 8. Changes to this policy

If this policy changes — for example, if a future version adds an
optional cloud sync feature — this document will be updated and the
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