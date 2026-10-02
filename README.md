# Roz Hisab

A simple, private, and offline-first finance management app designed for everyday financial needs in Pakistan.

Roz Hisab is a personal finance and daily expense management application built to help individuals, families, freelancers, and small businesses manage everyday financial records in one place.

The application focuses on four everyday financial needs: shopping and expense tracking, informal credit management, bill reminders, and daily recurring items (doodh, naan, akhbar and similar).

Designed with simplicity and privacy in mind, Roz Hisab allows users to manage essential financial records without requiring a mandatory account or constant internet connectivity.

## Overview

Managing everyday finances is often more complicated than it needs to be. People commonly rely on paper notes, memory, WhatsApp messages, or separate applications to keep track of purchases, borrowed money, and upcoming bills.

Roz Hisab brings these everyday tasks into a single, easy-to-use application.

The application addresses four common problems:

**Shopping & Expenses** — Keep track of items purchased, quantities, and prices while shopping. Frequently-bought items appear as one-tap "Buy Again" suggestions, so building a list doesn't mean retyping the same items every trip. Every item is automatically sorted into a spend category behind the scenes, so a "where did my money go" breakdown is available on the Home dashboard with no manual tagging. Users can also generate a PDF receipt for their records or for sharing.

**Udhar Khata** — Maintain clear records of money given to or received from friends, relatives, customers, or other individuals. Each person's transactions and current balance are tracked separately, full or partial repayments are recorded with a dedicated "Settle Up" action, and a balance can be followed up on directly via a pre-drafted WhatsApp reminder.

**Bill Reminders** — Record recurring and one-time bills, monitor their due dates, and identify upcoming or overdue payments through clear, color-coded status indicators. Marking a recurring bill as paid automatically schedules the next one, so a reminder never silently stops just because it was forgotten one month.

**Daily Hisab** — Track things you receive every day and settle monthly (milk, bread, newspaper, water bottles, a maid). One tap per day on a month calendar; the month's quantity and total are always ready, and can be sent on WhatsApp or Email.

## Key Features

### 🛒 Shopping List

A quick and practical way to manage shopping and purchase records.

- Create and manage shopping lists
- Add items, quantities, and prices
- "Buy Again" suggestions for frequently bought items, pre-filled with their last price
- A quantity stepper for buying more than one of an item, without adding duplicate rows
- Automatically calculate totals
- Edit or remove items — tap any item to change its name, price, or quantity, or reopen a saved list from the history to correct it later
- Automatic, zero-effort spend categorization (Grocery, Vegetables & Fruit, Dairy, Household, and more)
- Track completed purchases
- Generate PDF receipts
- Share generated receipts

The feature is designed for fast entry, allowing users to record purchases while they are actually shopping rather than relying on memory later.

### 🤝 Udhar Khata

A digital ledger for managing informal lending and borrowing.

- Add people or customers, with an optional phone number
- Record credit and payment transactions
- Maintain individual transaction histories
- Track outstanding balances
- Record full or partial repayments with a dedicated "Settle Up" action
- Optional last date to give back / get back, with a reminder notification
- Edit or delete any individual transaction
- Share a person's full statement on WhatsApp
- Send a friendly, pre-drafted balance reminder directly to WhatsApp
- Clearly identify money receivable and payable
- Maintain an updated running balance

This provides a reliable alternative to handwritten records and memory-based tracking.

### 💡 Bill Reminders

A centralized system for keeping track of important payments.

- Add, edit, or delete one-time or recurring bills
- Set payment amounts and due dates
- Track payment status with clear, color-coded indicators
- Monitor upcoming payments and identify overdue bills
- Recurring bills automatically schedule their next due date once marked paid
- Local notifications on the due date, no internet required

This helps users stay aware of their financial obligations and reduce the chance of missing payment deadlines.

## Who Is Roz Hisab For?

Roz Hisab is designed for anyone who needs a simple way to manage everyday financial records.

**Families** — Track household shopping, recurring bills, and everyday expenses.

**Small Shopkeepers** — Maintain informal customer credit and payment records without relying on physical notebooks.

**Freelancers** — Keep track of personal spending, payments, and financial obligations.

**Individuals** — Manage personal purchases, lending, borrowing, and recurring bills from one application.

**Friends & Relatives** — Maintain transparent records when money is borrowed, lent, or repaid.

## Designed for Everyday Use in Pakistan

Roz Hisab is designed around common financial habits and requirements found in everyday life in Pakistan.

Instead of attempting to replace full-scale accounting or banking software, the application focuses on simple financial activities that people regularly manage themselves.

The goal is straightforward: **make everyday financial record-keeping simple, accessible, and reliable.**

## Privacy & Offline-First Design

Privacy is an important part of the Roz Hisab experience.

**No Mandatory Login** — Users can access the core application without being required to create an account. Signing in with Google is optional and only enables cloud backup.

**Offline-First** — Core financial records are designed to remain accessible without a continuous internet connection.

Without signing in, internet access is only used for features that inherently require it — sharing a receipt or backup file, or opening WhatsApp or Email for an alert. There are no analytics and no ads. If (and only if) you choose to sign in with Google, your records are also stored in your own private area of Google Firebase (Firestore) so you can recover them on another device.

**Optional App Lock** — Protect the app with a 4-digit PIN (plus fingerprint where available). A security question chosen at setup lets you recover access if the PIN is forgotten; a wrong PIN shakes and turns red. The PIN and answer are stored only as hashes in the device's secure storage.

**Local Data** — On Android and iOS, financial records (shopping lists, Udhar Khata entries, bills, daily items) are encrypted at rest with AES-256, with the key held in the Android Keystore / iOS Keychain. On the website, browser storage is used, which gives weaker protection than a phone's secure hardware.

**Optional Cloud Backup** — After Google login, data is synced to Firestore under `users/{your-uid}`; security rules allow only that signed-in user to read or write it. It is not end-to-end encrypted. Settings → Backup also creates a readable PDF of everything with one tap.

This approach reduces unnecessary dependence on online services and gives users greater control over their personal financial records.

See [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for the complete data-handling policy.

## Product Principles

Roz Hisab is built around a small set of practical principles:

**Simplicity** — Financial management should not require accounting expertise.

**Speed** — Common actions should be quick enough to perform during everyday activities such as shopping or recording a payment.

**Privacy** — Personal financial information should remain under the user's control.

**Accessibility** — Essential financial records should remain available even when an internet connection is unavailable.

**Practicality** — Every feature should address a real-world financial need rather than adding unnecessary complexity.

## Technology & Documentation

The application's complete technology stack, architecture, development setup, deployment process (Android, web/PWA), environment configuration, security considerations, and platform-specific instructions are documented separately.

For complete technical documentation, see **[DEPLOYMENT.md](DEPLOYMENT.md)**.

For the complete data-handling and privacy policy, see **[PRIVACY_POLICY.md](PRIVACY_POLICY.md)**.

## Project Status

**Status:** Active Development

Roz Hisab is being developed as a practical everyday finance-management solution focused on simplicity, privacy, offline accessibility, and real-world usability.

## Documentation

| File | Description |
|---|---|
| `README.md` | Product overview, purpose, features, and project information |
| `DEPLOYMENT.md` | Development setup, deployment, configuration, and technical documentation |
| `PRIVACY_POLICY.md` | Full data-handling and privacy policy |

---

**Roz Hisab** — Keep your everyday finances organized.