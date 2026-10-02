// OPTIONAL: daily 9:00 AM (Pakistan time) email reminders via Brevo.
// Emails every logged-in user whose bills / udhar are due TODAY or
// TOMORROW. The Brevo key lives in a Firebase SECRET - never in the
// Flutter app (anything inside the app can be read by anyone).
//
// Needs: Firebase "Blaze" plan (free quota is plenty for small use).
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');

admin.initializeApp();
const BREVO_KEY = defineSecret('BREVO_API_KEY');

// !!! EDIT THIS: must be a sender you verified inside Brevo !!!
const SENDER = { name: 'Roz Hisab', email: 'muhammadoxmann@gmail.com' };

// Day string in Pakistan time (UTC+5), offset 0 = today, 1 = tomorrow
function pkDay(offset) {
  const d = new Date(Date.now() + 5 * 3600 * 1000 + offset * 86400000);
  return d.toISOString().slice(0, 10);
}

exports.dailyReminders = onSchedule(
  { schedule: '0 9 * * *', timeZone: 'Asia/Karachi', secrets: [BREVO_KEY] },
  async () => {
    const db = admin.firestore();
    const today = pkDay(0);
    const tomorrow = pkDay(1);
    const when = (day) => (day === today ? 'AAJ' : 'KAL');

    const userRefs = await db.collection('users').listDocuments();
    for (const ref of userRefs) {
      const [bills, contacts] = await Promise.all([
        ref.collection('bills').get(),
        ref.collection('contacts').get(),
      ]);
      const lines = [];

      bills.forEach((doc) => {
        const b = doc.data();
        const day = String(b.dueDate || '').slice(0, 10);
        if (!b.isPaid && (day === today || day === tomorrow)) {
          lines.push(`Bill: ${b.name} - Rs. ${Math.round(b.amount || 0)} (${when(day)})`);
        }
      });

      contacts.forEach((doc) => {
        const c = doc.data();
        const entries = (c.entries || []).filter((e) => !e.isSettled);
        const bal = entries.reduce(
          (s, e) => s + (e.type === 'theyOweMe' ? e.amount : -e.amount), 0);
        if (bal === 0) return;
        const wanted = bal > 0 ? 'theyOweMe' : 'iOweThem';
        entries.forEach((e) => {
          const day = String(e.dueDate || '').slice(0, 10);
          if (e.type === wanted && (day === today || day === tomorrow)) {
            lines.push(bal > 0
              ? `${c.name} se Rs. ${Math.round(Math.abs(bal))} lene hain (${when(day)})`
              : `${c.name} ko Rs. ${Math.round(Math.abs(bal))} dene hain (${when(day)})`);
          }
        });
      });

      if (lines.length === 0) continue;

      let email;
      try {
        email = (await admin.auth().getUser(ref.id)).email;
      } catch (_) { continue; }
      if (!email) continue;

      const res = await fetch('https://api.brevo.com/v3/smtp/email', {
        method: 'POST',
        headers: {
          'api-key': BREVO_KEY.value(),
          'content-type': 'application/json',
          accept: 'application/json',
        },
        body: JSON.stringify({
          sender: SENDER,
          to: [{ email }],
          subject: `Roz Hisab: ${lines.length} cheez ki date aa gayi`,
          htmlContent:
            '<h3>Roz Hisab reminder</h3><ul>' +
            lines.map((l) => `<li>${l}</li>`).join('') + '</ul>',
        }),
      });
      if (!res.ok) console.error('Brevo error', res.status, await res.text());
    }
  }
);