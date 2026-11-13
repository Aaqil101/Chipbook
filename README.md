# Chipbook

A shared ledger for group fundraising. Log contributions, see who gave what,
and keep a clear record everyone can check. Chipbook never holds or moves
money. It only keeps the record.

## Status

Phase 2 is implemented on a hosted Supabase backend:

- Magic-link email sign-in and a session gate
- Multiple funds, with the creator becoming the first organizer
- Organizer approvals and reversals with a required reason
- Organizer payouts for money leaving the fund
- Member management with expiring invite codes
- Per-currency raised, paid-out, and balance totals

The app is web-first. There are deliberately no `android/` or `ios/`
directories, and there is no payment, wallet, or custody functionality.

Data lives in Supabase. This repository does not include a hosted project or
any credentials; follow the setup below to connect your own.

## Roles

| Role      | Can do                                                        |
| --------- | ------------------------------------------------------------- |
| Organizer | Invite, approve, record payouts, reverse, change roles, remove members, archive or delete a fund |
| Member    | Add entries (pending until approved) and view the ledger      |
| Observer  | View the ledger only                                          |

Entries are append-only: nobody can edit or delete one. A correction is a new
entry that reverses the original, and the original stays visible. Only
approved entries count toward a total.

A contribution adds to the fund. A payout records money leaving it, such as
paying a supplier at the end of a collection; the organizer must give a payee
and a reason, and a payout is approved as soon as it is recorded. Totals show
raised, paid out, and the remaining balance per currency. Chipbook only keeps
the record; it never moves the money.

A fund is never destroyed while it has a ledger. An organizer can archive it:
it disappears from the fund list, its entries stay readable, and it can be
restored later. A fund with no entries can be deleted outright. Archived funds
are read-only and cannot receive entries, invites, or new members.

## Supabase setup

1. Create a project at <https://supabase.com/dashboard> and note its project
   ref, project URL, and publishable key.
2. Copy `.env.example` to `.env` and fill in the two values:

   ```text
   SUPABASE_URL=https://<project-ref>.supabase.co
   SUPABASE_PUBLISHABLE_KEY=sb_publishable_<key>
   ```

   The publishable key is client-safe and is shipped in the web build. The
   database password and the `service_role`/secret key are server-only and must
   never be put in `.env` or committed. `.env` is gitignored.

3. Log in with the Supabase CLI and link the project (npx downloads the CLI
   if needed):

   ```powershell
   npx supabase login
   npx supabase link --project-ref <project-ref>
   ```

4. Apply the migrations:

   ```powershell
   npx supabase db push --remote
   ```

   Migrations live in `supabase/migrations/`. Create one with
   `npx supabase migration new <name>` and apply it with
   `npx supabase db push --remote`. CLI 3.x defaults to a local database, so
   keep the `--remote` flag for the hosted project.

5. In the Supabase dashboard, open **Authentication > URL Configuration** and
   set:

   - **Site URL:** `http://127.0.0.1:8080`
   - **Redirect URLs:** `http://127.0.0.1:8080` and
     `http://127.0.0.1:8080/**`

   The email provider is enabled by default, and magic links expire after one
   hour. If you use a different local port or host, update both values to
   match. Hosted projects enforce email rate limits; check
   **Authentication > Rate Limits** if magic links stop arriving.

6. Continue with **Run it**, sign in, and create a fund. The database trigger
   makes the creator its first organizer. Invite codes are shared manually;
   Chipbook does not send invitation emails.

## Run it

Requires Flutter 3.50+ (Dart 3.14+), Node.js for `npx supabase`, and a
filled-in `.env`.

```powershell
flutter pub get
flutter run -d web-server --web-port 8080 --web-hostname 127.0.0.1 --dart-define-from-file=.env
```

Open <http://127.0.0.1:8080>. Use `127.0.0.1` rather than `localhost` if the
page does not load. To launch Chrome directly instead:

```powershell
flutter run -d chrome --dart-define-from-file=.env
```

## Using it

1. Sign in with a magic link and create a fund. You become its first organizer.
2. Add entries with a currency; new entries start pending.
3. Organizers approve pending entries. Approved entries count toward the
   balance for that currency only.
4. Organizers can record a **Payout** from the add-entry form. It needs a
   payee and a reason, is approved immediately, and reduces the balance. A
   payout larger than the balance warns but is still recorded.
5. Open **Members** to invite an email with a role, then copy the invite code.
   The invitee signs in with that email and uses **Redeem an invite**.
6. To correct an approved entry, use **Reverse** and give a reason. The
   original stays visible and the reversal reduces the same currency's balance.
7. Use **Fund settings** in the fund menu to archive the active fund, or to
   delete it when it has no entries. Archived funds are listed on the
   no-funds page, where they can be restored.

## Test it

```powershell
flutter analyze
flutter test
flutter test test/domain/ledger_test.dart --plain-name "reversal"
```

The database rules have a separate executable SQL suite. It runs inside a
transaction and rolls back, so it is safe against the hosted project:

```powershell
npx supabase db query --remote --yes --file supabase/tests/rls_test.sql
```

A successful run ends with `{"result":"RLS tests passed"}`. The suite covers
selects, inserts, approvals, reversals, invites, fund archival and deletion,
and the last-organizer guard for every role. `supabase test db` is not used
because it requires Docker.

## Deploy

Chipbook is a static Flutter web app plus Supabase. No server process of its
own is required.

1. Build with the production environment values:

   ```powershell
   flutter build web --release --dart-define-from-file=.env
   ```

   The output is `build/web`. Values from `.env` are compiled into the build,
   so rebuild whenever the Supabase URL or key changes.

2. Publish `build/web` to any static host: Cloudflare Pages, Netlify, Vercel,
   GitHub Pages, or a static bucket. If the host needs a single-page-app
   rewrite, rewrite unknown paths to `index.html`.

3. Add the production origin to Supabase under **Authentication > URL
   Configuration**:

   - **Site URL:** `https://your-domain.example`
   - **Redirect URLs:** `https://your-domain.example` and
     `https://your-domain.example/**`

   Keep the local `http://127.0.0.1:8080` entries too if you still develop
   against the same project. Magic links return to the Site URL, so it must
   match the deployed origin.

4. If you host under a subpath (for example GitHub Pages), build with the
   matching base path and use that full URL as the Site URL:

   ```powershell
   flutter build web --release --base-href /chipbook/ --dart-define-from-file=.env
   ```

Only the publishable key belongs in a client build. Never add a
`service_role`/secret key, database password, or personal access token to
`.env`, `--dart-define`, or any file tracked by git.

## How it works

- `lib/models/` — `Entry`, `Fund`, `Membership`, `Invite`, `MemberRole`; money
  is always an integer `amountMinor`.
- `lib/domain/` — append-only totals, payouts, and reversals, per-currency
  grouping, currency catalog, money parsing/formatting, and validation.
- `lib/repositories/` — interfaces for entries, funds, memberships, and
  invites, plus Supabase implementations. Tests use the in-memory entry store.
- `lib/state/` — `ChangeNotifier` controllers for auth, funds, and the active
  ledger.
- `lib/screens/` — sign-in, fund shell, ledger, add-entry form, members page,
  and dialogs.
- `supabase/migrations/` — schema, append-only and last-organizer triggers,
  invite acceptance, fund archival, and RLS policies.
- `supabase/tests/rls_test.sql` — executable role and RLS suite.

The database is the authority for roles and immutability: RLS limits reads and
writes, triggers enforce approvals and reversals, and the UI mirrors those
rules through `FundPermissions` so it does not show actions that will fail.
Money is never processed, only recorded.

## License

GPL-3.0. See [LICENSE](LICENSE).
