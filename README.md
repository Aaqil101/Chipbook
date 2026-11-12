# Chipbook

A shared ledger for group fundraising. Log contributions, see who gave what,
and keep a clear record everyone can check. Chipbook never holds or moves
money. It only keeps the record.

## Status

Phase 1 is a web-first Flutter app with local, in-memory storage. There is no
backend, auth, roles, invites, or approval UI yet, and entries are lost when
the app restarts.

## Run it

Requires Flutter 3.50+ (Dart 3.14+).

```powershell
flutter pub get
flutter run -d web-server --web-port 8080 --web-hostname 127.0.0.1
```

Open <http://127.0.0.1:8080> in your browser. Use `127.0.0.1` rather than
`localhost` if the page does not load. To launch Chrome directly instead:

```powershell
flutter run -d chrome
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
