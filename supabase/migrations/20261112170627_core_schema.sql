-- Core ledger schema: funds, memberships, entries, and invites.
--
-- Row Level Security is enabled at the end of this migration without
-- policies. Policies arrive in the next migration; until then only the
-- service role can read or write these tables.

create type public.member_role as enum ('organizer', 'member', 'observer');
create type public.entry_status as enum ('pending', 'approved');

create table public.funds (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 80),
  default_currency char(3) not null default 'USD'
    check (default_currency ~ '^[A-Z]{3}$'),
  created_by uuid not null default auth.uid()
    references auth.users (id) on delete restrict,
  created_at timestamptz not null default now()
);

create table public.memberships (
  fund_id uuid not null references public.funds (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role public.member_role not null default 'member',
  created_at timestamptz not null default now(),
  primary key (fund_id, user_id)
);

create table public.invites (
  id uuid primary key default gen_random_uuid(),
  fund_id uuid not null references public.funds (id) on delete cascade,
  email text not null check (position('@' in email) > 1),
  role public.member_role not null default 'member',
  token uuid not null default gen_random_uuid() unique,
  invited_by uuid default auth.uid()
    references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '7 days',
  accepted_at timestamptz,
  accepted_by uuid references auth.users (id) on delete set null
);

create unique index invites_pending_email_key
  on public.invites (fund_id, lower(email))
  where accepted_at is null;

create table public.entries (
  id uuid primary key default gen_random_uuid(),
  fund_id uuid not null references public.funds (id) on delete restrict,
  amount_minor bigint not null check (amount_minor > 0),
  currency char(3) not null check (currency ~ '^[A-Z]{3}$'),
  contributor_name text not null
    check (char_length(btrim(contributor_name)) between 1 and 120),
  note text not null default '',
  status public.entry_status not null default 'pending',
  reverses_entry_id uuid references public.entries (id) on delete restrict,
  created_by uuid default auth.uid()
    references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  approved_at timestamptz,
  approved_by uuid references auth.users (id) on delete set null,
  constraint entries_no_self_reversal
    check (reverses_entry_id is null or reverses_entry_id <> id),
  constraint entries_one_reversal
    unique (reverses_entry_id),
  constraint entries_approval_consistency check (
    (status = 'pending' and approved_at is null and approved_by is null)
    or (status = 'approved' and approved_at is not null)
  )
);

create index entries_fund_created_idx
  on public.entries (fund_id, created_at desc);
create index entries_fund_status_idx
  on public.entries (fund_id, status);
create index memberships_user_idx on public.memberships (user_id);
create index invites_fund_idx on public.invites (fund_id);
create index invites_email_idx on public.invites (lower(email));

-- A fund's creator becomes its first organizer in the same transaction.
create or replace function public.add_fund_creator()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.memberships (fund_id, user_id, role)
  values (new.id, new.created_by, 'organizer');
  return new;
end;
$$;

revoke execute on function public.add_fund_creator() from public;

create trigger funds_add_creator
  after insert on public.funds
  for each row execute function public.add_fund_creator();

-- Fill approval metadata and validate reversals before rows land.
create or replace function public.prepare_entry()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  target public.entries%rowtype;
begin
  if new.status = 'approved' then
    new.approved_at := now();
    new.approved_by := auth.uid();
  else
    new.approved_at := null;
    new.approved_by := null;
  end if;

  if new.reverses_entry_id is null then
    return new;
  end if;

  if new.status <> 'approved' then
    raise exception 'reversals must be approved when created';
  end if;

  select * into target
  from public.entries
  where id = new.reverses_entry_id;

  if not found then
    raise exception 'reversal target % does not exist', new.reverses_entry_id;
  end if;
  if target.fund_id <> new.fund_id then
    raise exception 'reversal must target an entry in the same fund';
  end if;
  if target.status <> 'approved' then
    raise exception 'reversal must target an approved entry';
  end if;
  if target.currency <> new.currency then
    raise exception 'reversal currency must match the target';
  end if;

  return new;
end;
$$;

revoke execute on function public.prepare_entry() from public;

create trigger entries_prepare_insert
  before insert on public.entries
  for each row execute function public.prepare_entry();

-- Only a pending -> approved transition is allowed. Every other column is
-- immutable, and approved rows never change again.
create or replace function public.guard_entry_update()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if old.status = 'approved' then
    raise exception 'approved entries are immutable';
  end if;

  if new.status <> 'approved' then
    raise exception 'entries may only transition from pending to approved';
  end if;

  if new.id is distinct from old.id
    or new.fund_id is distinct from old.fund_id
    or new.amount_minor is distinct from old.amount_minor
    or new.currency is distinct from old.currency
    or new.contributor_name is distinct from old.contributor_name
    or new.note is distinct from old.note
    or new.created_by is distinct from old.created_by
    or new.created_at is distinct from old.created_at
    or new.reverses_entry_id is distinct from old.reverses_entry_id then
    raise exception 'entries are append-only; only approval may change';
  end if;

  new.approved_at := now();
  new.approved_by := auth.uid();
  return new;
end;
$$;

revoke execute on function public.guard_entry_update() from public;

create trigger entries_guard_update
  before update on public.entries
  for each row execute function public.guard_entry_update();

create or replace function public.block_entry_delete()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  raise exception 'entries cannot be deleted';
end;
$$;

revoke execute on function public.block_entry_delete() from public;

create trigger entries_block_delete
  before delete on public.entries
  for each row execute function public.block_entry_delete();

alter table public.funds enable row level security;
alter table public.memberships enable row level security;
alter table public.entries enable row level security;
alter table public.invites enable row level security;
