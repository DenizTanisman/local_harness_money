# 1B$ — Para

Local, offline Android money tracker (Flutter). One month per screen, each
day shows whether it ended plus or minus against the daily spendable amount:

    günlük harcanabilir = (ana para − ödenmezler) / süre

- **ana para** — every income minus every outcome entered.
- **ödenmezler** — rent, bills, subscriptions (recurring). If the previous one
  was paid, the next one is ignored until 5 days before its due date.
- **süre** — days until the next expected income, else until month end.
- Overspending a day is deducted from the following day(s); a recalculate
  button restarts the daily amount from today.

Data stays on the device in an encrypted SQLite database. See HARNESS.md.

```sh
flutter pub get
flutter test
flutter build apk
```
