-- Every entry is recorded in the fund's currency.
--
-- A fund has exactly one currency, chosen when it is created. Entries no
-- longer carry a per-entry choice: the currency column stays for history and
-- for the reversal contract, but it must match the fund. The guard runs before
-- insert, after the reversal checks, so a mismatched reversal still reports
-- its own error first.

create or replace function public.fund_currency(target_fund_id uuid)
returns char(3)
language sql
stable
security definer
set search_path = public
as $$
  select default_currency from public.funds where id = target_fund_id;
$$;

revoke execute on function public.fund_currency(uuid) from public;
grant execute on function public.fund_currency(uuid) to authenticated;

create or replace function public.prepare_entry()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  target public.entries%rowtype;
  fund_currency char(3);
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

  if new.reverses_entry_id is not null then
    if new.status <> 'approved' then
      raise exception 'reversals must be approved when created';
    end if;

    select * into target
    from public.entries
    where id = new.reverses_entry_id;

    if not found then
      raise exception 'reversal target % does not exist',
        new.reverses_entry_id;
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
  end if;

  fund_currency := public.fund_currency(new.fund_id);
  if fund_currency is null then
    raise exception 'entry fund % does not exist', new.fund_id;
  end if;
  if new.currency <> fund_currency then
    raise exception 'entry currency must match the fund currency';
  end if;

  return new;
end;
$$;

revoke execute on function public.prepare_entry() from public;
