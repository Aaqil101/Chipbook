# AGENTS.md

## What this is
Chipbook is a Flutter web app: a shared, record-only ledger for money raised
with friends. It never holds, moves, or processes money. No payments, wallets,
balances, or custody features, ever.

## Current state (phase 2)
- Web-first (`flutter run -d chrome` or a web server). No `android/` or `ios/`
  directories by design.
- Hosted Supabase backend with magic-link auth, funds, per-fund roles,
  approvals, reversals, invites, and entries in the fund currency.
- Data lives in Supabase. The in-memory entry repository is test-only.
- Phase 2 is implemented (issues #11-#22); setup and deploy notes are in
  `README.md`.
- Roles are `organizer`, `member`, and `observer`. The database is the
  authority; `FundPermissions` mirrors it for the UI.

## Commands
    flutter pub get
    flutter analyze
    flutter test
    flutter test test/domain/ledger_test.dart --plain-name "reversal"
    flutter run -d web-server --web-port 8080 --web-hostname 127.0.0.1 --dart-define-from-file=.env
    flutter run -d chrome --dart-define-from-file=.env
    flutter build web --release --dart-define-from-file=.env
    npx supabase login
    npx supabase link --project-ref <project-ref>
    npx supabase db push --remote
    npx supabase migration new <name>
    npx supabase db query --remote --yes --file supabase/tests/rls_test.sql

Run `flutter analyze` and `flutter test` before calling any work done. Both
must pass. Run the SQL suite when changing schema, RLS policies, or role
rules.

## Environment
- Copy `.env.example` to `.env` and fill in `SUPABASE_URL` and
  `SUPABASE_PUBLISHABLE_KEY`.
- `.env` is gitignored. Only the publishable key is client-safe. Never commit
  or pass a `service_role`/secret key, database password, or personal access
  token to a client build.
- Pass configuration with `--dart-define-from-file=.env`; values are baked
  into web builds, so rebuild after changing them.
- `supabase/.temp/` contains linked-project state and is gitignored.
- Supabase Auth needs a Site URL and redirect URLs matching the origin used to
  run the app (local `http://127.0.0.1:8080` or the deployed URL).

## Architecture rules
- Approved entries are append-only. Never add update or delete for them. The
  only permitted mutations are `pending -> approved` and deleting a pending
  entry that was never approved; corrections are new entries with
  `reversesEntryId` set.
- Funds are never destroyed while they hold a ledger. Organizers archive them
  instead; only a fund with no entries may be deleted. Archived funds are
  read-only (`is_fund_active` gates every write policy).
- A fund has one currency, chosen at creation. Every entry, including a
  reversal, must use it; the database rejects any other code. Reversals keep
  the target entry's currency and require a reason. Never mix currencies in a
  total.
- A payout is an approved organizer entry with `kind = 'payout'`. It reduces
  the balance but not the raised figure, requires a reason, and its reversal
  keeps the payout kind. Show raised, paid out, and balance in the fund
  currency.
- Money is `int amountMinor` (smallest currency unit). Never use `double` for
  money and never parse amounts through `double`. `CurrencyCatalog` supplies
  ISO 4217 fraction digits; `intl` formats grouped whole units.
- All data access goes through repository interfaces in `lib/repositories/`.
  UI must never depend on a concrete repository. Supabase implementations are
  wired in `lib/main.dart`.
- Roles are enforced by RLS and triggers in `supabase/migrations/`. UI checks
  use `FundPermissions` and are advisory; keep them in sync with SQL.
- Business logic lives in plain Dart under `lib/domain/` and `lib/models/`.
  No totals, reversal, currency, or validation logic in widgets.
- Group totals per currency; never sum amounts across currencies.
- The display name lives only in `AppInfo.name` (`lib/app_info.dart`). Don't
  hardcode "Chipbook" elsewhere in Dart.
- State management is `ChangeNotifier`/`ListenableBuilder` built into Flutter.
  Don't add packages without stating why in the commit message.
- Supabase functions need a fixed `search_path`; grant execute to
  `authenticated` only (not `anon` or `public`) unless there is a documented
  reason. Keep migrations in `supabase/migrations/`.
- `supabase/tests/rls_test.sql` is an executable SQL suite. It runs inside one
  transaction and rolls back; keep it that way so it is safe against a hosted
  project.

## Conventions
- This is an application, so `pubspec.lock` is committed (it is deliberately
  not in `.gitignore`).
- Tests live in `test/` and mirror the `lib/` path they cover.
- Import Material widgets from `package:material_ui/material_ui.dart`,
  matching the Flutter 3.50 scaffold; don't mix in `flutter/material.dart`.
- New source files are GPL-3.0.
- Keep `.env.example` to placeholders only; never add real credentials or
  machine-specific values to tracked files.
