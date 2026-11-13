-- Payouts: recording money leaving a fund.
--
-- A payout is an ordinary append-only entry whose kind is 'payout'. It is
-- organizer-only, approved when it is created, and reduces the fund's balance
-- for its currency. Reversals keep the kind of the entry they correct, so
-- reversing a payout puts the money back.

create type public.entry_kind as enum ('contribution', 'payout');

alter table public.entries
  add column kind public.entry_kind not null default 'contribution';

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

  -- A payout is an organizer decision, so it can never wait for approval and
  -- it has to say what it paid for.
  if new.kind = 'payout' and new.reverses_entry_id is null then
    if new.status <> 'approved' then
      raise exception 'payouts must be approved when created';
    end if;
    if btrim(new.note) = '' then
      raise exception 'a payout needs a reason';
    end if;
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
  if target.kind <> new.kind then
    raise exception 'reversal kind must match the target';
  end if;

  return new;
end;
$$;

revoke execute on function public.prepare_entry() from public;

-- The kind of an approved entry is as immutable as its amount.
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
    or new.kind is distinct from old.kind
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

-- Contributors may only record contributions. Payouts stay organizer-only.
drop policy "Contributors can add entries" on public.entries;

create policy "Contributors can add entries"
  on public.entries
  for insert
  to authenticated
  with check (
    created_by = auth.uid()
    and public.is_fund_active(fund_id)
    and (
      public.is_fund_organizer(fund_id)
      or (
        public.is_fund_contributor(fund_id)
        and kind = 'contribution'
        and status = 'pending'
        and reverses_entry_id is null
      )
    )
  );
