# Chipbook

A shared ledger for group fundraising. Log contributions, see who gave what,
and keep a clear record everyone can check. Chipbook never holds or moves
money. It only keeps the record.

## Status

Phase 1 is a web-first Flutter app with local, in-memory storage. There is no
backend, auth, roles, invites, or approval UI yet, and entries are lost when
the app restarts.

## Supabase setup

Phase 2 uses a hosted Supabase project. The app reads its configuration at
build time from `.env`.

1. Copy `.env.example` to `.env`.
2. Fill in `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` from the project's
   **Connect** dialog. The publishable key is client-safe; the database
   password and `service_role`/secret key are server-only and must never be
   committed.
3. Link the project once, then push migrations:

```powershell
npx supabase login
npx supabase link --project-ref <project-ref>
npx supabase db push --remote
```

Migrations live in `supabase/migrations/`. Create one with
`npx supabase migration new <name>` and apply it with
`npx supabase db push --remote`.

In **Authentication > URL Configuration**, set the Site URL to
`http://127.0.0.1:8080` and add `http://127.0.0.1:8080/**` as a redirect URL.
Email magic links are enabled by default, so no extra provider setup is
needed; links expire after one hour.

## Run it

Requires Flutter 3.50+ (Dart 3.14+).

```powershell
flutter pub get
flutter run -d web-server --web-port 8080 --web-hostname 127.0.0.1 --dart-define-from-file=.env
```

Open <http://127.0.0.1:8080> in your browser. Use `127.0.0.1` rather than
`localhost` if the page does not load. To launch Chrome directly instead:

```powershell
flutter run -d chrome --dart-define-from-file=.env
```

## Test it

```powershell
flutter analyze
flutter test
flutter test test/domain/ledger_test.dart --plain-name "reversal"
```

## How it works

- `lib/models/entry.dart` — append-only `Entry` with integer `amountMinor`.
- `lib/domain/` — totals, reversal rules, money parsing/formatting, and
  validation.
- `lib/repositories/` — `EntryRepository` interface plus the in-memory
  implementation used by the app.
- `lib/state/` — `LedgerController` (`ChangeNotifier`).
- `lib/screens/` — entries list and add-entry form.

Only approved entries count toward the running total. Pending entries are
listed separately and never affect it. Corrections are new entries that
reverse an earlier one; nothing is edited or deleted.

## License

GPL-3.0. See [LICENSE](LICENSE).
