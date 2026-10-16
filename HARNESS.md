# local_harness_para — Para

Money app of the Local Harness split (see `docs/HUB_CONTRACT.md`). Origin:
`Takip Uygulaması Android/daily_tracker`, split on 2026-10-04.

| | |
|---|---|
| Role | feature app (publishes a snapshot, reads no peers) |
| applicationId | `dev.deniz.local_harness_para` |
| Hub authority | `dev.deniz.local_harness_para.hub` (`HubProvider`, guarded by `dev.deniz.local_harness.permission.HUB`) |
| Snapshot | schema 1, `app: "para"` — built by `buildHubSnapshot` in `lib/core/hub_snapshot_publisher.dart` |
| DB | encrypted sqlite3mc file `local_harness_para.db`, schema v1 |
| Tables | `transactions`, `money_categories`, `expense_reminders`, `app_settings` |
| Notifications | channel `local_harness_para` / "Para" — monthly expense reminders with a "Sustur" (mute) action |
| Backups | `local_harness_para_<stamp>.dtbak` (AES-256-GCM, `transactions.csv` + `app_settings.json`) |

## What it does

Home is the daily page: one month per page (swipe up/down) with a +/− line
chart and a calendar of each day's result; tapping a day opens its
Outcome | Income entry. The daily spendable amount is
`(ana para − ödenmezler) / süre` — see `lib/features/money/daily_budget.dart`.
The full Money page opens from the app bar: entry form for the selected day
(income / outcome, optional monthly reminders), month overview (balance,
daily-budget sparkline, category donut, budgets), monthly table, categories.
From the app bar: search & filter, reports, upcoming payments, recurring
transactions, settings (CSV/Excel export & import of transactions, encrypted
weekly backup, FLAG_SECURE).

Recurring rules and category budgets are stored as JSON in `app_settings`
(`recurring_rules`, `category_budgets`).

## Hub snapshot (`data`)

`currency`, `month`, `monthIncome`, `monthOutcome`, `monthBalance`,
`allTimeBalance`, `todayIncome`, `todayOutcome`, `recent` (last 5
transactions) and `upcoming` (recurring rules due within 30 days). Published
at startup (after the category-setup / fresh-start / recurring syncs),
debounced 1.5 s after any DB write, and when the app is paused.

## Commands

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift codegen
flutter analyze
flutter test
```
