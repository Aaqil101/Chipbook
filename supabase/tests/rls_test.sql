-- Executable row-level security suite for Chipbook.
--
-- Run against the linked hosted project with:
--   npx supabase db query --remote --yes --file supabase/tests/rls_test.sql
--
-- Everything runs inside one transaction and is rolled back. A failed
-- assertion raises, so a successful run ends with {"result":"RLS tests passed"}.

begin;

create function pg_temp.assert_true(condition boolean, message text)
returns void
language plpgsql
as $$
begin
  if condition is not true then
    raise exception 'ASSERT FAILED: %', message;
  end if;
end;
$$;

create function pg_temp.assert_eq(actual bigint, expected bigint, message text)
returns void
language plpgsql
as $$
begin
  if actual is distinct from expected then
    raise exception 'ASSERT FAILED: % (expected %, got %)',
      message, expected, actual;
  end if;
end;
$$;

create function pg_temp.assert_eq_text(actual text, expected text, message text)
returns void
language plpgsql
as $$
begin
  if actual is distinct from expected then
    raise exception 'ASSERT FAILED: % (expected %, got %)',
      message, expected, actual;
  end if;
end;
$$;

create function pg_temp.assert_raises(
  statement text,
  expected_sqlstate text,
  message text
)
returns void
language plpgsql
as $$
begin
  begin
    execute statement;
  exception when others then
    if sqlstate <> expected_sqlstate then
      raise exception 'ASSERT FAILED: % (expected SQLSTATE %, got %: %)',
        message, expected_sqlstate, sqlstate, sqlerrm;
    end if;
    return;
  end;
  raise exception 'ASSERT FAILED: % (statement succeeded)', message;
end;
$$;

create function pg_temp.assert_raises_message(
  statement text,
  expected_message text,
  message text
)
returns void
language plpgsql
as $$
begin
  begin
    execute statement;
  exception when others then
    if sqlerrm <> expected_message then
      raise exception 'ASSERT FAILED: % (expected message "%", got "%")',
        message, expected_message, sqlerrm;
    end if;
    return;
  end;
  raise exception 'ASSERT FAILED: % (statement succeeded)', message;
end;
$$;

-- Test users. auth.users only requires an id and supplies the rest.
insert into auth.users (id, email) values
  ('11111111-1111-4111-8111-111111111111', 'organizer@example.com'),
  ('22222222-2222-4222-8222-222222222222', 'member@example.com'),
  ('33333333-3333-4333-8333-333333333333', 'observer@example.com'),
  ('44444444-4444-4444-8444-444444444444', 'outsider@example.com'),
  ('55555555-5555-4555-8555-555555555555', 'wrong@example.com')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Setup: fund, invites, accepted memberships, and a second fund.
-- ---------------------------------------------------------------------------

select set_config(
  'request.jwt.claim.sub',
  '11111111-1111-4111-8111-111111111111',
  true
);
set local role authenticated;

insert into public.funds (id, name, default_currency, created_by)
values (
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'Holiday fund',
  'USD',
  '11111111-1111-4111-8111-111111111111'
);

select pg_temp.assert_eq(
  (
    select count(*)
    from public.memberships
    where fund_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
      and user_id = '11111111-1111-4111-8111-111111111111'
      and role = 'organizer'
  ),
  1,
  'creating a fund makes its creator an organizer'
);

insert into public.invites (id, fund_id, email, role, token, expires_at) values
  (
    'b1111111-1111-4111-8111-111111111111',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'member@example.com',
    'member',
    'c1111111-1111-4111-8111-111111111111',
    now() + interval '7 days'
  ),
  (
    'b2222222-2222-4222-8222-222222222222',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'observer@example.com',
    'observer',
    'c2222222-2222-4222-8222-222222222222',
    now() + interval '7 days'
  ),
  (
    'b3333333-3333-4333-8333-333333333333',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'outsider@example.com',
    'member',
    'c3333333-3333-4333-8333-333333333333',
    now() + interval '7 days'
  ),
  (
    'b4444444-4444-4444-8444-444444444444',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'expired@example.com',
    'member',
    'c4444444-4444-4444-8444-444444444444',
    now() - interval '1 day'
  );

select pg_temp.assert_eq(
  (select count(*) from public.invites),
  4,
  'organizer can create and read invites'
);

-- A second fund is used to prove fund scoping and cross-fund reversal checks.
insert into public.funds (id, name, default_currency, created_by)
values (
  'abababab-abab-4bab-8bab-abababababab',
  'Gift fund',
  'EUR',
  '11111111-1111-4111-8111-111111111111'
);

insert into public.entries (
  id, fund_id, amount_minor, currency, contributor_name, status
) values (
  'e4444444-4444-4444-8444-444444444444',
  'abababab-abab-4bab-8bab-abababababab',
  700,
  'EUR',
  'Organizer',
  'approved'
);

reset role;

-- ---------------------------------------------------------------------------
-- Invite acceptance.
-- ---------------------------------------------------------------------------

select set_config(
  'request.jwt.claim.sub',
  '22222222-2222-4222-8222-222222222222',
  true
);
set local role authenticated;

select pg_temp.assert_true(
  public.accept_invite('c1111111-1111-4111-8111-111111111111')
    = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'member accepts their invite'
);

select pg_temp.assert_eq_text(
  (
    select role::text
    from public.memberships
    where fund_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
      and user_id = '22222222-2222-4222-8222-222222222222'
  ),
  'member',
  'accepted invite grants the invited role'
);

reset role;

select set_config(
  'request.jwt.claim.sub',
  '33333333-3333-4333-8333-333333333333',
  true
);
set local role authenticated;

select pg_temp.assert_true(
  public.accept_invite('c2222222-2222-4222-8222-222222222222')
    = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'observer accepts their invite'
);

select pg_temp.assert_eq_text(
  (
    select role::text
    from public.memberships
    where fund_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
      and user_id = '33333333-3333-4333-8333-333333333333'
  ),
  'observer',
  'observer role is preserved'
);

reset role;

-- ---------------------------------------------------------------------------
-- Selects per role.
-- ---------------------------------------------------------------------------

select set_config(
  'request.jwt.claim.sub',
  '11111111-1111-4111-8111-111111111111',
  true
);
set local role authenticated;

select pg_temp.assert_eq(
  (select count(*) from public.funds),
  2,
  'organizer sees both funds'
);
select pg_temp.assert_eq(
  (select count(*) from public.memberships),
  4,
  'organizer sees memberships in both funds'
);
select pg_temp.assert_eq(
  (select count(*) from public.entries),
  1,
  'organizer sees the second fund entry'
);
select pg_temp.assert_eq(
  (select count(*) from public.invites),
  4,
  'organizer sees all invites'
);
select pg_temp.assert_eq(
  (select count(*) from public.list_fund_members(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  )),
  3,
  'organizer lists the three fund members'
);
select pg_temp.assert_eq_text(
  (
    select email
    from public.list_fund_members('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa')
    where user_id = '22222222-2222-4222-8222-222222222222'
  ),
  'member@example.com',
  'member directory exposes email addresses to members'
);

reset role;

select set_config(
  'request.jwt.claim.sub',
  '22222222-2222-4222-8222-222222222222',
  true
);
set local role authenticated;

select pg_temp.assert_eq(
  (select count(*) from public.funds),
  1,
  'member sees only their fund'
);
select pg_temp.assert_eq(
  (select count(*) from public.funds
    where id = 'abababab-abab-4bab-8bab-abababababab'),
  0,
  'member cannot see another fund'
);
select pg_temp.assert_eq(
  (select count(*) from public.memberships),
  3,
  'member sees the fund memberships'
);
select pg_temp.assert_eq(
  (select count(*) from public.entries),
  0,
  'member sees entries after they are added'
);
select pg_temp.assert_eq(
  (select count(*) from public.invites),
  0,
  'member cannot read invites'
);
select pg_temp.assert_eq(
  (select count(*) from public.list_fund_members(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  )),
  3,
  'member can list fund members'
);

reset role;

select set_config(
  'request.jwt.claim.sub',
  '33333333-3333-4333-8333-333333333333',
  true
);
set local role authenticated;

select pg_temp.assert_eq(
  (select count(*) from public.funds),
  1,
  'observer sees their fund'
);
select pg_temp.assert_eq(
  (select count(*) from public.memberships),
  3,
  'observer sees the fund memberships'
);
select pg_temp.assert_eq(
  (select count(*) from public.entries),
  0,
  'observer sees entries'
);
select pg_temp.assert_eq(
  (select count(*) from public.invites),
  0,
  'observer cannot read invites'
);

reset role;

select set_config(
  'request.jwt.claim.sub',
  '44444444-4444-4444-8444-444444444444',
  true
);
set local role authenticated;

select pg_temp.assert_eq(
  (select count(*) from public.funds),
  0,
  'outsider sees no funds'
);
select pg_temp.assert_eq(
  (select count(*) from public.memberships),
  0,
  'outsider sees no memberships'
);
select pg_temp.assert_eq(
  (select count(*) from public.entries),
  0,
  'outsider sees no entries'
);
select pg_temp.assert_eq(
  (select count(*) from public.invites),
  0,
  'outsider sees no invites'
);
select pg_temp.assert_eq(
  (select count(*) from public.list_fund_members(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  )),
  0,
  'outsider cannot list fund members'
);

reset role;

-- ---------------------------------------------------------------------------
-- Entry inserts and role checks.
-- ---------------------------------------------------------------------------

select set_config(
  'request.jwt.claim.sub',
  '22222222-2222-4222-8222-222222222222',
  true
);
set local role authenticated;

insert into public.entries (
  id, fund_id, amount_minor, currency, contributor_name, status
) values (
  'e1111111-1111-4111-8111-111111111111',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  1000,
  'USD',
  'Member',
  'pending'
);

select pg_temp.assert_eq(
  (select count(*) from public.entries),
  1,
  'member can add a pending entry'
);

select pg_temp.assert_raises(
  $stmt$
    insert into public.entries (
      id, fund_id, amount_minor, currency, contributor_name, status
    ) values (
      'e5555555-5555-4555-8555-555555555555',
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      1000,
      'USD',
      'Member',
      'approved'
    )
  $stmt$,
  '42501',
  'member cannot add an approved entry'
);

select pg_temp.assert_raises(
  $stmt$
    insert into public.entries (
      id, fund_id, amount_minor, currency, contributor_name, status
    ) values (
      'e5555555-5555-4555-8555-555555555555',
      'abababab-abab-4bab-8bab-abababababab',
      1000,
      'EUR',
      'Member',
      'pending'
    )
  $stmt$,
  '42501',
  'member cannot add an entry to another fund'
);

reset role;

select set_config(
  'request.jwt.claim.sub',
  '11111111-1111-4111-8111-111111111111',
  true
);
set local role authenticated;

insert into public.entries (
  id, fund_id, amount_minor, currency, contributor_name, status
) values (
  'e2222222-2222-4222-8222-222222222222',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  5000,
  'USD',
  'Organizer',
  'approved'
);

select pg_temp.assert_eq(
  (select count(*) from public.entries),
  3,
  'organizer can add an approved entry'
);

reset role;

select set_config(
  'request.jwt.claim.sub',
  '33333333-3333-4333-8333-333333333333',
  true
);
set local role authenticated;

select pg_temp.assert_raises(
  $stmt$
    insert into public.entries (
      id, fund_id, amount_minor, currency, contributor_name, status
    ) values (
      'e5555555-5555-4555-8555-555555555555',
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      1000,
      'USD',
      'Observer',
      'pending'
    )
  $stmt$,
  '42501',
  'observer cannot add an entry'
);

select pg_temp.assert_raises(
  $stmt$
    insert into public.entries (
      id, fund_id, amount_minor, currency, contributor_name, status,
      reverses_entry_id
    ) values (
      'e5555555-5555-4555-8555-555555555555',
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      5000,
      'USD',
      'Observer',
      'approved',
      'e2222222-2222-4222-8222-222222222222'
    )
  $stmt$,
  '42501',
  'observer cannot add a reversal'
);

reset role;

select set_config(
  'request.jwt.claim.sub',
  '44444444-4444-4444-8444-444444444444',
  true
);
set local role authenticated;

select pg_temp.assert_raises(
  $stmt$
    insert into public.entries (
      id, fund_id, amount_minor, currency, contributor_name, status
    ) values (
      'e5555555-5555-4555-8555-555555555555',
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      1000,
      'USD',
      'Outsider',
      'pending'
    )
  $stmt$,
  '42501',
  'outsider cannot add an entry'
);

reset role;

select set_config(
  'request.jwt.claim.sub',
  '22222222-2222-4222-8222-222222222222',
  true
);
set local role authenticated;

select pg_temp.assert_raises(
  $stmt$
    insert into public.entries (
      id, fund_id, amount_minor, currency, contributor_name, status,
      reverses_entry_id
    ) values (
      'e5555555-5555-4555-8555-555555555555',
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      5000,
      'USD',
      'Member',
      'approved',
      'e2222222-2222-4222-8222-222222222222'
    )
  $stmt$,
  '42501',
  'member cannot add a reversal'
);

reset role;

-- ---------------------------------------------------------------------------
-- Organizer reversals and their guards.
-- ---------------------------------------------------------------------------

select set_config(
  'request.jwt.claim.sub',
  '11111111-1111-4111-8111-111111111111',
  true
);
set local role authenticated;

insert into public.entries (
  id, fund_id, amount_minor, currency, contributor_name, status,
  reverses_entry_id
) values (
  'e3333333-3333-4333-8333-333333333333',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  5000,
  'USD',
  'Organizer',
  'approved',
  'e2222222-2222-4222-8222-222222222222'
);

select pg_temp.assert_eq(
  (select count(*) from public.entries),
  4,
  'organizer can add an approved reversal'
);

select pg_temp.assert_raises(
  $stmt$
    insert into public.entries (
      id, fund_id, amount_minor, currency, contributor_name, status,
      reverses_entry_id
    ) values (
      'e6666666-6666-4666-8666-666666666666',
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      5000,
      'USD',
      'Organizer',
      'approved',
      'e2222222-2222-4222-8222-222222222222'
    )
  $stmt$,
  '23505',
  'an entry can only be reversed once'
);

select pg_temp.assert_raises_message(
  $stmt$
    insert into public.entries (
      id, fund_id, amount_minor, currency, contributor_name, status,
      reverses_entry_id
    ) values (
      'e6666666-6666-4666-8666-666666666666',
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      1000,
      'USD',
      'Organizer',
      'approved',
      'e1111111-1111-4111-8111-111111111111'
    )
  $stmt$,
  'reversal must target an approved entry',
  'reversals cannot target pending entries'
);

select pg_temp.assert_raises_message(
  $stmt$
    insert into public.entries (
      id, fund_id, amount_minor, currency, contributor_name, status,
      reverses_entry_id
    ) values (
      'e6666666-6666-4666-8666-666666666666',
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      5000,
      'EUR',
      'Organizer',
      'approved',
      'e2222222-2222-4222-8222-222222222222'
    )
  $stmt$,
  'reversal currency must match the target',
  'reversals cannot switch currency'
);

select pg_temp.assert_raises_message(
  $stmt$
    insert into public.entries (
      id, fund_id, amount_minor, currency, contributor_name, status,
      reverses_entry_id
    ) values (
      'e6666666-6666-4666-8666-666666666666',
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      700,
      'EUR',
      'Organizer',
      'approved',
      'e4444444-4444-4444-8444-444444444444'
    )
  $stmt$,
  'reversal must target an entry in the same fund',
  'reversals cannot target another fund'
);

reset role;

-- ---------------------------------------------------------------------------
-- Approvals and immutability.
-- ---------------------------------------------------------------------------

select set_config(
  'request.jwt.claim.sub',
  '22222222-2222-4222-8222-222222222222',
  true
);
set local role authenticated;

update public.entries
set status = 'approved'
where id = 'e1111111-1111-4111-8111-111111111111';

select pg_temp.assert_eq_text(
  (
    select status::text
    from public.entries
    where id = 'e1111111-1111-4111-8111-111111111111'
  ),
  'pending',
  'member cannot approve an entry'
);

reset role;

select set_config(
  'request.jwt.claim.sub',
  '33333333-3333-4333-8333-333333333333',
  true
);
set local role authenticated;

update public.entries
set status = 'approved'
where id = 'e1111111-1111-4111-8111-111111111111';

select pg_temp.assert_eq_text(
  (
    select status::text
    from public.entries
    where id = 'e1111111-1111-4111-8111-111111111111'
  ),
  'pending',
  'observer cannot approve an entry'
);

reset role;

select set_config(
  'request.jwt.claim.sub',
  '44444444-4444-4444-8444-444444444444',
  true
);
set local role authenticated;

update public.entries
set status = 'approved'
where id = 'e1111111-1111-4111-8111-111111111111';

reset role;

select pg_temp.assert_eq_text(
  (
    select status::text
    from public.entries
    where id = 'e1111111-1111-4111-8111-111111111111'
  ),
  'pending',
  'outsider cannot approve an entry'
);

select set_config(
  'request.jwt.claim.sub',
  '11111111-1111-4111-8111-111111111111',
  true
);
set local role authenticated;

update public.entries
set status = 'approved'
where id = 'e1111111-1111-4111-8111-111111111111';

select pg_temp.assert_eq_text(
  (
    select status::text
    from public.entries
    where id = 'e1111111-1111-4111-8111-111111111111'
  ),
  'approved',
  'organizer can approve an entry'
);
select pg_temp.assert_true(
  (
    select approved_at is not null
    from public.entries
    where id = 'e1111111-1111-4111-8111-111111111111'
  ),
  'approval records a timestamp'
);
select pg_temp.assert_eq_text(
  (
    select approved_by::text
    from public.entries
    where id = 'e1111111-1111-4111-8111-111111111111'
  ),
  '11111111-1111-4111-8111-111111111111',
  'approval records the organizer'
);

select pg_temp.assert_eq(
  (
    select amount_minor
    from public.entries
    where id = 'e2222222-2222-4222-8222-222222222222'
  ),
  5000,
  'member cannot change an approved amount'
);

update public.entries
set amount_minor = 9999
where id = 'e2222222-2222-4222-8222-222222222222';

select pg_temp.assert_eq(
  (
    select amount_minor
    from public.entries
    where id = 'e2222222-2222-4222-8222-222222222222'
  ),
  5000,
  'approved entries stay immutable'
);

select pg_temp.assert_eq(
  (
    select count(*)
    from public.entries
    where id = 'e2222222-2222-4222-8222-222222222222'
  ),
  1,
  'entries cannot be deleted through RLS'
);

delete from public.entries
where id = 'e2222222-2222-4222-8222-222222222222';

select pg_temp.assert_eq(
  (
    select count(*)
    from public.entries
    where id = 'e2222222-2222-4222-8222-222222222222'
  ),
  1,
  'entries remain after a delete attempt'
);

reset role;

select pg_temp.assert_raises_message(
  $stmt$
    update public.entries
    set amount_minor = 9999
    where id = 'e2222222-2222-4222-8222-222222222222'
  $stmt$,
  'approved entries are immutable',
  'the database rejects changes to approved entries'
);

select pg_temp.assert_raises_message(
  $stmt$
    update public.entries
    set status = 'pending'
    where id = 'e2222222-2222-4222-8222-222222222222'
  $stmt$,
  'approved entries are immutable',
  'the database rejects reverting an approval'
);

select pg_temp.assert_raises_message(
  $stmt$
    delete from public.entries
    where id = 'e2222222-2222-4222-8222-222222222222'
  $stmt$,
  'entries cannot be deleted',
  'the database blocks entry deletion'
);

-- ---------------------------------------------------------------------------
-- Invite write rules and failure paths.
-- ---------------------------------------------------------------------------

select set_config(
  'request.jwt.claim.sub',
  '22222222-2222-4222-8222-222222222222',
  true
);
set local role authenticated;

select pg_temp.assert_raises(
  $stmt$
    insert into public.invites (fund_id, email, role)
    values (
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'new@example.com',
      'member'
    )
  $stmt$,
  '42501',
  'member cannot create invites'
);

reset role;

select set_config(
  'request.jwt.claim.sub',
  '33333333-3333-4333-8333-333333333333',
  true
);
set local role authenticated;

select pg_temp.assert_raises(
  $stmt$
    insert into public.invites (fund_id, email, role)
    values (
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'new@example.com',
      'member'
    )
  $stmt$,
  '42501',
  'observer cannot create invites'
);

reset role;

select set_config(
  'request.jwt.claim.sub',
  '44444444-4444-4444-8444-444444444444',
  true
);
set local role authenticated;

select pg_temp.assert_raises(
  $stmt$
    insert into public.invites (fund_id, email, role)
    values (
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'new@example.com',
      'member'
    )
  $stmt$,
  '42501',
  'outsider cannot create invites'
);

select set_config(
  'request.jwt.claim.sub',
  '55555555-5555-4555-8555-555555555555',
  true
);

select pg_temp.assert_raises_message(
  $stmt$
    select public.accept_invite('c3333333-3333-4333-8333-333333333333')
  $stmt$,
  'This invite was sent to a different email address',
  'invites are tied to the invited email'
);

reset role;

select set_config(
  'request.jwt.claim.sub',
  '22222222-2222-4222-8222-222222222222',
  true
);
set local role authenticated;

select pg_temp.assert_raises_message(
  $stmt$
    select public.accept_invite('c1111111-1111-4111-8111-111111111111')
  $stmt$,
  'Invite was already used',
  'an invite cannot be accepted twice'
);

reset role;

select set_config(
  'request.jwt.claim.sub',
  '11111111-1111-4111-8111-111111111111',
  true
);
set local role authenticated;

select pg_temp.assert_raises_message(
  $stmt$
    select public.accept_invite('c4444444-4444-4444-8444-444444444444')
  $stmt$,
  'Invite has expired',
  'expired invites cannot be accepted'
);

select pg_temp.assert_raises_message(
  $stmt$
    select public.accept_invite('00000000-0000-4000-8000-000000000000')
  $stmt$,
  'Invite not found',
  'unknown invite codes are rejected'
);

-- Members cannot delete invites; organizers can cancel them.
select set_config(
  'request.jwt.claim.sub',
  '22222222-2222-4222-8222-222222222222',
  true
);
delete from public.invites
where id = 'b4444444-4444-4444-8444-444444444444';

reset role;

select set_config(
  'request.jwt.claim.sub',
  '11111111-1111-4111-8111-111111111111',
  true
);
set local role authenticated;

select pg_temp.assert_eq(
  (
    select count(*)
    from public.invites
    where id = 'b4444444-4444-4444-8444-444444444444'
  ),
  1,
  'member cannot cancel an invite'
);

delete from public.invites
where id = 'b4444444-4444-4444-8444-444444444444';

select pg_temp.assert_eq(
  (
    select count(*)
    from public.invites
    where id = 'b4444444-4444-4444-8444-444444444444'
  ),
  0,
  'organizer can cancel an invite'
);

-- ---------------------------------------------------------------------------
-- Last-organizer guard and role changes.
-- ---------------------------------------------------------------------------

select pg_temp.assert_raises_message(
  $stmt$
    update public.memberships
    set role = 'member'
    where fund_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
      and user_id = '11111111-1111-4111-8111-111111111111'
  $stmt$,
  'a fund must keep at least one organizer',
  'the last organizer cannot be demoted'
);

select pg_temp.assert_raises_message(
  $stmt$
    delete from public.memberships
    where fund_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
      and user_id = '11111111-1111-4111-8111-111111111111'
  $stmt$,
  'a fund must keep at least one organizer',
  'the last organizer cannot be removed'
);

update public.memberships
set role = 'organizer'
where fund_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  and user_id = '22222222-2222-4222-8222-222222222222';

select pg_temp.assert_eq(
  (
    select count(*)
    from public.memberships
    where fund_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
      and role = 'organizer'
  ),
  2,
  'a fund can have multiple organizers'
);

update public.memberships
set role = 'member'
where fund_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  and user_id = '11111111-1111-4111-8111-111111111111';

select pg_temp.assert_eq(
  (
    select count(*)
    from public.memberships
    where fund_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
      and role = 'organizer'
  ),
  1,
  'one organizer can step down when another remains'
);

reset role;

select set_config(
  'request.jwt.claim.sub',
  '22222222-2222-4222-8222-222222222222',
  true
);
set local role authenticated;

delete from public.memberships
where fund_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  and user_id = '11111111-1111-4111-8111-111111111111';

select pg_temp.assert_eq(
  (
    select count(*)
    from public.memberships
    where fund_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
      and user_id = '11111111-1111-4111-8111-111111111111'
  ),
  0,
  'an organizer can remove another organizer when one remains'
);

select pg_temp.assert_raises_message(
  $stmt$
    update public.memberships
    set role = 'member'
    where fund_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
      and user_id = '22222222-2222-4222-8222-222222222222'
  $stmt$,
  'a fund must keep at least one organizer',
  'the new last organizer cannot demote themselves'
);

select pg_temp.assert_raises_message(
  $stmt$
    update public.memberships
    set fund_id = 'abababab-abab-4bab-8bab-abababababab'
    where fund_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
      and user_id = '33333333-3333-4333-8333-333333333333'
  $stmt$,
  'membership keys cannot change',
  'membership keys are immutable'
);

-- ---------------------------------------------------------------------------
-- Fund archival and deletion.
-- ---------------------------------------------------------------------------

reset role;

insert into auth.users (id, email) values
  ('77777777-7777-4777-8777-777777777777', 'archive@example.com')
on conflict (id) do nothing;

select set_config(
  'request.jwt.claim.sub',
  '22222222-2222-4222-8222-222222222222',
  true
);
set local role authenticated;

-- Left pending so accepting an invite can be checked against archival.
insert into public.invites (id, fund_id, email, role, token, expires_at) values (
  'b5555555-5555-4555-8555-555555555555',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'archive@example.com',
  'member',
  'c5555555-5555-4555-8555-555555555555',
  now() + interval '7 days'
);

-- An observer cannot archive or delete a fund.
select set_config(
  'request.jwt.claim.sub',
  '33333333-3333-4333-8333-333333333333',
  true
);

update public.funds
set archived_at = now()
where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

select pg_temp.assert_eq(
  (
    select count(*)
    from public.funds
    where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
      and archived_at is null
  ),
  1,
  'a non-organizer cannot archive a fund'
);

select pg_temp.assert_raises_message(
  $stmt$ select public.delete_fund('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') $stmt$,
  'only an organizer can delete this fund',
  'a non-organizer cannot delete a fund'
);

-- An organizer can archive, and the archive is attributed to them.
select set_config(
  'request.jwt.claim.sub',
  '22222222-2222-4222-8222-222222222222',
  true
);

select pg_temp.assert_raises_message(
  $stmt$
    update public.funds
    set name = 'Renamed fund'
    where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  $stmt$,
  'funds are immutable; only archival may change',
  'a fund cannot be renamed'
);

update public.funds
set archived_at = now()
where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

select pg_temp.assert_eq(
  (
    select count(*)
    from public.funds
    where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
      and archived_at is not null
      and archived_by = '22222222-2222-4222-8222-222222222222'
  ),
  1,
  'an organizer can archive a fund'
);

-- An archived fund keeps its ledger readable but accepts no new records.
select pg_temp.assert_true(
  (
    select count(*) > 0
    from public.entries
    where fund_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  ),
  'an archived fund still shows its entries'
);

select pg_temp.assert_raises(
  $stmt$
    insert into public.entries (
      fund_id, amount_minor, currency, contributor_name, status
    ) values (
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 100, 'USD', 'Organizer',
      'approved'
    )
  $stmt$,
  '42501',
  'an archived fund accepts no new entries'
);

select pg_temp.assert_raises(
  $stmt$
    insert into public.invites (fund_id, email, role)
    values (
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'new@example.com', 'member'
    )
  $stmt$,
  '42501',
  'an archived fund accepts no new invites'
);

select pg_temp.assert_raises(
  $stmt$
    insert into public.memberships (fund_id, user_id, role)
    values (
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      '55555555-5555-4555-8555-555555555555',
      'member'
    )
  $stmt$,
  '42501',
  'an archived fund accepts no new memberships'
);

select set_config(
  'request.jwt.claim.sub',
  '77777777-7777-4777-8777-777777777777',
  true
);

select pg_temp.assert_raises_message(
  $stmt$
    select public.accept_invite('c5555555-5555-4555-8555-555555555555')
  $stmt$,
  'This fund is archived',
  'an invite to an archived fund cannot be accepted'
);

-- Restoring clears the archive and its attribution.
select set_config(
  'request.jwt.claim.sub',
  '22222222-2222-4222-8222-222222222222',
  true
);

update public.funds
set archived_at = null
where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

select pg_temp.assert_eq(
  (
    select count(*)
    from public.funds
    where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
      and archived_at is null
      and archived_by is null
  ),
  1,
  'an organizer can restore a fund'
);

-- A fund with no entries can be deleted outright.
insert into public.funds (id, name, default_currency) values (
  'acacacac-acac-4cac-8cac-acacacacacac',
  'Stray fund',
  'USD'
);

select public.delete_fund('acacacac-acac-4cac-8cac-acacacacacac');

select pg_temp.assert_eq(
  (
    select count(*)
    from public.funds
    where id = 'acacacac-acac-4cac-8cac-acacacacacac'
  ),
  0,
  'an organizer can delete a fund with no entries'
);

-- The organizer guard must not block the membership cascade.
reset role;

select pg_temp.assert_eq(
  (
    select count(*)
    from public.memberships
    where fund_id = 'acacacac-acac-4cac-8cac-acacacacacac'
  ),
  0,
  'deleting a fund removes its memberships'
);

set local role authenticated;

select pg_temp.assert_raises_message(
  $stmt$ select public.delete_fund('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') $stmt$,
  'this fund has entries; archive it instead',
  'a fund with entries cannot be deleted'
);

reset role;

-- ---------------------------------------------------------------------------
-- Fund creation with RETURNING.
--
-- The app inserts with RETURNING to read the new fund. The returned row is
-- checked against the SELECT policy before the AFTER INSERT trigger adds the
-- creator's membership, which is why the policy also admits the creator.
-- ---------------------------------------------------------------------------

reset role;

insert into auth.users (id, email) values
  ('66666666-6666-4666-8666-666666666666', 'creator@example.com')
on conflict (id) do nothing;

select set_config(
  'request.jwt.claim.sub',
  '66666666-6666-4666-8666-666666666666',
  true
);
set local role authenticated;

create temp table returning_fund on commit drop as
select * from public.funds where false;

with created as (
  insert into public.funds (name, default_currency)
  values ('Returning fund', 'USD')
  returning *
)
insert into returning_fund
select * from created;

select pg_temp.assert_eq(
  (select count(*) from returning_fund),
  1,
  'a fund insert can return the new row'
);
select pg_temp.assert_eq(
  (select count(*) from public.funds),
  1,
  'the creator can read the fund they just made'
);
select pg_temp.assert_eq(
  (
    select count(*)
    from public.memberships
    where fund_id = (select id from returning_fund)
      and user_id = '66666666-6666-4666-8666-666666666666'
      and role = 'organizer'
  ),
  1,
  'the fund creator still becomes an organizer'
);

select 'RLS tests passed' as result;

rollback;
