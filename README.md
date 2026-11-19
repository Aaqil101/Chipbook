# Chipbook

A shared ledger for group fundraising. Log contributions, see who gave what,
and keep a clear record everyone can check. Chipbook never holds or moves
money. It only keeps the record.

## Status

Phase 2 is implemented on a hosted Supabase backend:

- Google sign-in, with an email magic link as a fallback
- A user-chosen username in the member list, with email addresses kept private
- Multiple funds, with the creator becoming the first organizer
- Organizer approvals and reversals with a required reason
- Organizer payouts for money leaving the fund
- One-off, weekly, monthly, or yearly fund timing with an optional period target
- Member management with expiring invite codes
- One currency per fund, with raised, paid-out, and balance totals

The app is web-first, and also builds as an Android app for phones and
emulators. There is deliberately no `ios/` directory, and there is no payment,
wallet, or custody functionality.

Data lives in Supabase. This repository does not include a hosted project or
any credentials; follow the setup below to connect your own.

## Roles

| Role      | Can do                                                        |
| --------- | ------------------------------------------------------------- |
| Organizer | Invite, approve, delete pending entries, record payouts, reverse, change roles, remove members, archive or delete a fund |
| Member    | Add entries (pending until approved) and view the ledger      |
| Observer  | View the ledger only                                          |

Approved entries are append-only: nobody can edit or delete one. A correction is
a new entry that reverses the original, and the original stays visible. An
organizer may delete a pending entry that was never approved, since it never
counted toward a total. Only approved entries count toward a total.

A contribution adds to the fund. A payout records money leaving it, such as
paying a supplier at the end of a collection; the organizer must give a payee
and a reason, and a payout is approved as soon as it is recorded. Totals show
raised, paid out, and the remaining balance in the fund's currency. Chipbook
only keeps the record; it never moves the money.

A fund can be a one-off collection or repeat weekly, monthly, or yearly. An
organizer can set an optional target in the fund's default currency, and the
ledger shows progress for the current calendar period above the lifetime
totals. Weeks start on Monday, months on the 1st, and years on 1 January, using
the device's local time. Changing the timing never edits entries: the figures
are derived from the ledger, and a reversal corrects the period of the entry it
reverses.

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
   - **Redirect URLs:** `http://127.0.0.1:8080`,
     `http://127.0.0.1:8080/**`, and `chipbook://login-callback`

   The last entry returns magic links to the Android app; keep it even if you
   only develop on the web.

   The email provider is enabled by default, and magic links expire after one
   hour. Google sign-in returns through the same allow list, so no extra
   redirect URL is needed. If you use a different local port or host, update
   both values to match.

   **Email fallback.** A hosted project sends auth mail through Supabase's
   built-in sender, which allows 2 emails per hour per project and only
   delivers to addresses in your organization. Anyone else fails with
   `email_address_not_authorized`. Add a custom SMTP provider under
   **Authentication > Emails > SMTP Settings** so friends outside the
   organization can receive a link. The built-in sender is only for trying the
   app yourself; `supabase start` serves the same flows locally through Mailpit
   with no email limit.

   **SMTP provider.** Auth mail is sent from `noreply@mail.<domain>` through
   Resend: host `smtp.resend.com`, port 465, username `resend`, password is an
   API key created with sending access for that subdomain. The API key lives in
   the dashboard only. The sending subdomain is verified with a DKIM TXT record
   on `resend._domainkey.mail.<domain>` and two CNAMEs for the return path,
   `send.mail.<domain>` and `rsend.mail.<domain>`. All three stay DNS only; a
   proxied CNAME silently never verifies. The default 30 emails per hour is
   ample for a friends-scale app, so raise it only if real load demands it.

   **Inbound mail.** Cloudflare Email Routing handles the apex so an address on
   the domain can receive mail. It adds MX records for
   `route1/2/3.mx.cloudflare.net` and one SPF TXT record,
   `v=spf1 include:_spf.mx.cloudflare.net ~all`. Never add a second SPF record
   to the same name; SPF fails silently when a name has two. DMARC lives on
   `_dmarc.<domain>`, with the root policy also covering the sending subdomain.
   Start at `p=none`, then tighten to `p=quarantine; pct=25`, `pct=100`, and
   finally `p=reject` as reports confirm SPF and DKIM keep passing. Keep one
   `_dmarc` record only; a duplicate makes the policy invalid and DMARC falls
   back to observing.

   **Google sign-in.** Google is the primary sign-in. In the Google Cloud
   Console, create an OAuth 2.0 Client ID of type **Web application** and add
   `https://<project-ref>.supabase.co/auth/v1/callback` as an authorized
   redirect URI. Then open **Authentication > Providers > Google** in
   Supabase, enable it, and paste the client ID and secret. Web and Android
   both sign in through the browser and return to the app through the
   `chipbook://login-callback` redirect.

6. Continue with **Run it**, sign in, and choose a username. The member list
   shows that handle instead of an email address, and existing accounts see
   the setup screen once. The database trigger makes a fund's creator its
   first organizer. Invite codes are shared manually; Chipbook does not send
   invitation emails.

### Email templates

The sign-in, signup confirmation and invitation mail bodies live in
`supabase/templates/` so style changes are reviewable. The hosted project still
uses the copies in **Authentication > Emails**; `supabase db push` does not sync
them and this CLI version does not compare them in `config diff`, so update the
dashboard by hand.
The files also feed `supabase start` for local mail. Avoid `supabase config push`
for templates: it would also push dev-only values such as the local Site URL and
email rate limit.

Email confirmation is off (`enable_confirmations = false`), so a first-time
sign-in sends the magic-link template rather than a separate confirmation mail.
The confirmation template is kept so re-enabling confirmation still produces
styled mail, and so local runs match the hosted project.

Never commit SMTP credentials, Gmail App Passwords, OAuth client secrets, or
the project's service key. Those belong only in the Supabase dashboard.

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

### Android

The Android target uses Google sign-in or the same magic link. Supabase returns
a sign-in to the app through the `chipbook://login-callback` deep link, so that
URL must be in the project's redirect allow list (step 5 above). After the
emulator is running:

```powershell
flutter emulators --launch <emulator-id>
flutter run -d emulator-5554 --dart-define-from-file=.env
```

`emulator-5554` is the first emulator; use `flutter devices` to find others.
The build reads `.env` the same way, and only the publishable key belongs in
it.

### Signed release builds

A release build uses whatever keystore `android/key.properties` points at, and
falls back to the debug key when that file is missing, so `flutter run
--release` works on a fresh checkout. The debug key must not be used for
anything you hand out: anyone can sign a build that Android will accept as an
update over it.

Create the keystore once and keep it out of the repository:

```powershell
keytool -genkey -v -keystore $HOME\chipbook-release.jks -keyalg RSA `
  -keysize 2048 -validity 10000 -alias chipbook
```

Then write `android/key.properties`, which is already gitignored:

```properties
storePassword=<keystore password>
keyPassword=<key password>
keyAlias=chipbook
storeFile=C:/Users/<you>/chipbook-release.jks
```

Build and check which certificate signed the result:

```powershell
flutter build apk --release --dart-define-from-file=.env
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

The certificate should be your alias, not `CN=Android Debug`. Losing the
keystore means every future update needs a new application ID, so back it up
somewhere durable.

## Using it

1. Sign in with Google, or use an email link as a fallback. The first sign-in
   asks for a username, which is what other members see; your email address is
   never shown in a member list. **Home** lists every fund you can open; tap
   one to view its ledger. Create a fund from Home and you become its first
   organizer. Pick a one-off, weekly, monthly, or yearly cadence and an
   optional target.
2. Add entries; they are recorded in the fund currency and start pending.
3. Organizers approve pending entries. Approved entries count toward the
   fund balance.
4. Organizers can record a **Payout** from the add-entry form. It needs a
   payee and a reason, is approved immediately, and reduces the balance. A
   payout larger than the balance warns but is still recorded.
5. Open **Members** to invite an email with a role, then copy the invite code.
   The invitee signs in with that same address, through Google or a magic link,
   and uses **Redeem an invite**.
6. To correct an approved entry, use **Reverse** and give a reason. The
   original stays visible and the reversal reduces the fund balance.
7. Use the settings icon on the ledger, or **Settings > Manage fund**, to
   change the **Timing and target**, archive the active fund, or delete it
   when it has no entries. Archived funds are listed on Home, where they can
   be restored. **Settings** also shows the signed-in account, lets you change
   your username, and holds sign out and the **About** page.

## Troubleshooting

### Clicks do nothing on the web

Flutter web draws the app into a canvas, so browser extensions that intercept
pointer events can swallow a click before the app sees it. Vimium is a known
case: the sign-in field ignores mouse clicks until the site is excluded. Add
the app's origin to the extension's exclusions or disable it for the site, then
reload. The app needs no change.

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
selects, inserts, approvals, reversals, invites, profile usernames and their
privacy, fund cadence and targets, fund archival and deletion, and the
last-organizer guard for every role. `supabase test db` is not used because it
requires Docker.

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

   - **Site URL:** `https://chipbook.aaqil.cc`
   - **Redirect URLs:** `https://chipbook.aaqil.cc` and
     `https://chipbook.aaqil.cc/**`

   Keep the local `http://127.0.0.1:8080` entries only if the Site URL is also
   local; they are not consulted otherwise. Magic links and Google sign-in
   return to the Site URL, so it must match the deployed origin.

   The web build passes no `redirectTo`, because `authRedirect()` returns null
   on the web, so the Site URL is always used. A sign-in started on
   `http://127.0.0.1:8080` therefore returns to the deployed host and fails the
   code exchange: the PKCE verifier is stored under the origin that requested
   it. Test auth against the deployed site, or point a second Supabase project
   at the local origin.

4. If you host under a subpath (for example GitHub Pages), build with the
   matching base path and use that full URL as the Site URL:

   ```powershell
   flutter build web --release --base-href /chipbook/ --dart-define-from-file=.env
   ```

Only the publishable key belongs in a client build. Never add a
`service_role`/secret key, database password, or personal access token to
`.env`, `--dart-define`, or any file tracked by git.

### Domain and DNS

The app is served from `https://chipbook.aaqil.cc`. The `aaqil.cc` apex is
reserved for a hub page and is not attached to the project.

`aaqil.cc` is registered at Cloudflare and uses Cloudflare nameservers, so the
record lives in that account:

| Type | Name | Target | Proxy |
| --- | --- | --- | --- |
| `CNAME` | `chipbook` | `0f9cc118be9321c3.vercel-dns-017.com` | DNS only (grey cloud) |

The target is the value shown on the project's **Domains** page; Vercel also
accepts `cname.vercel-dns.com`. Leave the record unproxied. The host terminates
TLS with its own certificate, so proxying adds a second TLS layer and produces
redirect loops that look like an application bug. `vercel domains verify
chipbook.aaqil.cc` reports `Valid` only after the record resolves.

### Deploy from CI

`.github/workflows/deploy-web.yml` builds and deploys `build/web` to Vercel
when a push to `master` changes something that reaches the bundle (`lib/`,
`web/`, `assets/`, the pubspec, or the workflow itself), and on demand from the
**Actions** tab. It runs `flutter analyze` and `flutter test` first, so a
failing commit never reaches the host. The bundle is built on the GitHub runner
because Vercel's build image has no Flutter SDK, then uploaded as a prebuilt
deployment.

`.github/workflows/ci.yml` runs the same analyze and test steps on every push
and pull request, including the ones that skip the deploy, so no commit goes
unverified.

1. Link this checkout to the Vercel project once:

   ```powershell
   npx vercel link
   ```

   It writes `.vercel/project.json`, which is gitignored, with the org and
   project IDs. Keep the project's **Framework Preset** on **Other** with no
   build command, since the workflow supplies the files.

2. Create a token at <https://vercel.com/account/tokens> that can deploy the
   project's team.

3. Add the repository secrets. The two Supabase values must match `.env`, and
   the IDs are the ones in `.vercel/project.json`:

   ```powershell
   gh secret set VERCEL_TOKEN
   gh secret set VERCEL_ORG_ID
   gh secret set VERCEL_PROJECT_ID
   gh secret set SUPABASE_URL
   gh secret set SUPABASE_PUBLISHABLE_KEY
   ```

   `gh secret set` prompts for each value, so no secret is pasted into a
   tracked file or the workflow itself.

4. Push a bundle change to `master` to deploy production; a push that only
   touches docs, `android/`, `supabase/`, or `test/` runs CI but skips the
   deploy. To run the workflow by hand, open **Deploy web** in the Actions tab
   and pick a **target**: **preview** (the default) uploads the same build to a
   throwaway URL and leaves the live site alone, while **production** redeploys
   the branch you selected. The job summary prints the target and URL.

Preview deployments sit behind Vercel Authentication, so opening one in a
browser asks you to sign in to Vercel.

Because the Supabase values are compiled into the bundle, changing either
secret needs a new deployment rather than a secret edit alone. The workflow
fails before deploying when the token, org ID, or project ID is wrong.

## How it works

- `lib/models/` — `Entry`, `Fund`, `Membership`, `Invite`, `MemberRole`, and
  `Profile`; money is always an integer `amountMinor`.
- `lib/domain/` — approved-entry totals, payouts, and reversals, cadence
  periods, currency grouping, currency catalog, money parsing/formatting,
  username and sign-in validation.
- `lib/repositories/` — interfaces for entries, funds, memberships, invites,
  and profiles, plus Supabase implementations. Tests use the in-memory entry
  store.
- `lib/state/` — `ChangeNotifier` controllers for auth, funds, the active
  ledger, and the signed-in profile.
- `lib/screens/` — sign-in, profile setup, the home fund list, ledger,
  add-entry form, members page, settings, about page, and dialogs.
- `supabase/migrations/` — schema, approval, immutable-entry, and
  last-organizer triggers, invite acceptance, fund archival, and RLS policies.
- `supabase/tests/rls_test.sql` — executable role and RLS suite.

The database is the authority for roles and immutability: RLS limits reads and
writes, triggers enforce approvals and reversals, and the UI mirrors those
rules through `FundPermissions` so it does not show actions that will fail.
Money is never processed, only recorded.

## License

GPL-3.0. See [LICENSE](LICENSE).
