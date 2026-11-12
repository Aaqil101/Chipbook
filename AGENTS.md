# AGENTS.md

## What this is
Chipbook is a Flutter app: a shared, record-only ledger for money raised
with friends. It never holds, moves, or processes money. No payments,
wallets, balances, or custody features, ever.

## Current state (phase 1)
- Web-first (`flutter run -d chrome`). No `android/` or `ios/` directories
  by design.
- Local only: in-memory storage. No backend, auth, roles, invites, or
  approval UI. Don't add or stub these without an issue.
- Data is lost on restart; that is expected until the Supabase phase.
- Phase 1 is implemented (entries list, add-entry form, totals, tests).
  Work is tracked in the `Phase 1` milestone (issues #1-#10).

## Commands
    flutter pub get
    flutter analyze
    flutter test
    flutter test test/domain/ledger_test.dart --plain-name "reversal"
    flutter run -d chrome
    flutter run -d web-server --web-port 8080 --web-hostname 127.0.0.1

Run `flutter analyze` and `flutter test` before calling any work done.
Both must pass.

## Architecture rules
- Entries are append-only. Never add update or delete. Corrections are
  new entries with `reversesEntryId` set.
- All data access goes through `EntryRepository`
  (`lib/repositories/`). UI must never depend on a concrete repository.
- Money is `int amountMinor` (smallest currency unit). Never use `double`
  for money and never parse amounts through `double`.
- Business logic lives in plain Dart under `lib/domain/` and
  `lib/models/`. No totals, reversal, or validation logic in widgets.
- The display name lives only in `AppInfo.name` (`lib/app_info.dart`).
  Don't hardcode "Chipbook" elsewhere in Dart.
- State management is `ChangeNotifier`/`ListenableBuilder` built into
  Flutter. Don't add packages without stating why in the commit message.

## Conventions
- This is an application, so `pubspec.lock` is committed (it is
  deliberately not in `.gitignore`).
- Tests live in `test/` and mirror the `lib/` path they cover.
- Import Material widgets from `package:material_ui/material_ui.dart`,
  matching the Flutter 3.50 scaffold; don't mix in `flutter/material.dart`.
- New source files are GPL-3.0.
