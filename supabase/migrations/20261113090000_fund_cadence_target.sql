-- Fund cadence and per-period targets.
--
-- A fund is either a one-off collection or repeats on a calendar period. The
-- optional target is expressed in the fund's default currency and applies to
-- the current period; a one-off fund treats it as a lifetime goal. Nothing is
-- stored per period: totals stay derived from the ledger.

create type public.fund_cadence as enum ('one_off', 'weekly', 'monthly', 'yearly');

alter table public.funds
  add column cadence public.fund_cadence not null default 'one_off',
  add column target_minor bigint
    check (target_minor is null or target_minor > 0);

comment on column public.funds.cadence is
  'How often the collection period repeats.';
comment on column public.funds.target_minor is
  'Optional period target in default_currency; null means no goal.';

-- Funds stay immutable apart from archival, and now their timing and target.
-- Creation still goes through the insert policy, and an archived fund accepts
-- no setting changes at all, so restoring it is always safe.
create or replace function public.guard_fund_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.id is distinct from old.id
    or new.name is distinct from old.name
    or new.default_currency is distinct from old.default_currency
    or new.created_by is distinct from old.created_by
    or new.created_at is distinct from old.created_at then
    raise exception 'funds are immutable; only archival may change';
  end if;

  if old.archived_at is not null
    and (new.cadence is distinct from old.cadence
      or new.target_minor is distinct from old.target_minor) then
    raise exception 'archived funds are read-only';
  end if;

  if new.archived_at is null then
    new.archived_by := null;
  elsif new.archived_at is distinct from old.archived_at then
    new.archived_by := auth.uid();
  else
    new.archived_by := old.archived_by;
  end if;

  return new;
end;
$$;

revoke execute on function public.guard_fund_update() from public;
