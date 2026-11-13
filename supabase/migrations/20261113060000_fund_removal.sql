-- Fund archival and removal.
--
-- A fund is never destroyed while it holds a ledger. An organizer archives
-- it instead: the fund drops out of the fund list, every entry stays readable,
-- and it can be restored later. Only a fund with no entries may be deleted
-- outright, which is how stray or mistaken funds get cleaned up.
--
-- Archived funds are read-only. New entries, invites, and memberships are
-- rejected while the fund is archived, so restoring it is always safe.

alter table public.funds
  add column archived_at timestamptz,
  add column archived_by uuid references auth.users (id) on delete set null;

-- A fund's settings are fixed once it exists; only archival may change.
-- archived_by is always derived from the session, so a client cannot forge it.
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

create trigger funds_guard_update
  before update on public.funds
  for each row execute function public.guard_fund_update();

create or replace function public.is_fund_active(target_fund_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.funds
    where id = target_fund_id
      and archived_at is null
  );
$$;

revoke execute on function public.is_fund_active(uuid) from public;
grant execute on function public.is_fund_active(uuid) to authenticated;

create policy "Organizers can archive funds"
  on public.funds
  for update
  to authenticated
  using (public.is_fund_organizer(id))
  with check (public.is_fund_organizer(id));

-- Archived funds accept no new entries. Approval is a write as well.
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
        and status = 'pending'
        and reverses_entry_id is null
      )
    )
  );

drop policy "Organizers can approve entries" on public.entries;

create policy "Organizers can approve entries"
  on public.entries
  for update
  to authenticated
  using (
    public.is_fund_organizer(fund_id)
    and public.is_fund_active(fund_id)
    and status = 'pending'
  )
  with check (
    public.is_fund_organizer(fund_id)
    and public.is_fund_active(fund_id)
    and status = 'approved'
  );

drop policy "Organizers can add memberships" on public.memberships;

create policy "Organizers can add memberships"
  on public.memberships
  for insert
  to authenticated
  with check (
    public.is_fund_organizer(fund_id)
    and public.is_fund_active(fund_id)
  );

drop policy "Organizers can create invites" on public.invites;

create policy "Organizers can create invites"
  on public.invites
  for insert
  to authenticated
  with check (
    public.is_fund_organizer(fund_id)
    and public.is_fund_active(fund_id)
    and invited_by = auth.uid()
  );

-- Invite acceptance bypasses RLS, so it checks archival itself.
create or replace function public.accept_invite(invite_token uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  pending public.invites%rowtype;
  current_email text;
begin
  if auth.uid() is null then
    raise exception 'Sign in to accept an invite';
  end if;

  select * into pending
  from public.invites
  where token = invite_token
  for update;

  if not found then
    raise exception 'Invite not found';
  end if;

  if pending.accepted_at is not null then
    raise exception 'Invite was already used';
  end if;

  if pending.expires_at <= now() then
    raise exception 'Invite has expired';
  end if;

  if not public.is_fund_active(pending.fund_id) then
    raise exception 'This fund is archived';
  end if;

  select email into current_email
  from auth.users
  where id = auth.uid();

  if current_email is null
    or lower(current_email) <> lower(pending.email) then
    raise exception 'This invite was sent to a different email address';
  end if;

  insert into public.memberships (fund_id, user_id, role)
  values (pending.fund_id, auth.uid(), pending.role)
  on conflict (fund_id, user_id) do nothing;

  update public.invites
  set accepted_at = now(),
      accepted_by = auth.uid()
  where id = pending.id;

  return pending.fund_id;
end;
$$;

revoke execute on function public.accept_invite(uuid) from public;
grant execute on function public.accept_invite(uuid) to authenticated;

-- A fund delete cascades into memberships. That cascade is the only case in
-- which the last organizer may disappear, so the guard skips it: the fund row
-- is on its way out and the rule no longer applies.
create or replace function public.guard_membership_change()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  organizers integer;
begin
  if tg_op = 'UPDATE' then
    if new.fund_id <> old.fund_id or new.user_id <> old.user_id then
      raise exception 'membership keys cannot change';
    end if;

    if old.role = 'organizer' and new.role <> 'organizer' then
      select count(*) into organizers
      from public.memberships
      where fund_id = old.fund_id
        and role = 'organizer';

      if organizers <= 1 then
        raise exception 'a fund must keep at least one organizer';
      end if;
    end if;

    return new;
  end if;

  if tg_op = 'DELETE' and old.role = 'organizer' then
    if pg_trigger_depth() > 1
      or not exists (select 1 from public.funds where id = old.fund_id) then
      return old;
    end if;

    select count(*) into organizers
    from public.memberships
    where fund_id = old.fund_id
      and role = 'organizer';

    if organizers <= 1 then
      raise exception 'a fund must keep at least one organizer';
    end if;
  end if;

  return old;
end;
$$;

revoke execute on function public.guard_membership_change() from public;

-- Deleting a fund is organizer-only and refuses a fund that has a ledger, so
-- the caller gets a useful message instead of a foreign-key violation.
create or replace function public.delete_fund(target_fund_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_fund_organizer(target_fund_id) then
    raise exception 'only an organizer can delete this fund';
  end if;

  if exists (
    select 1 from public.entries where fund_id = target_fund_id
  ) then
    raise exception 'this fund has entries; archive it instead';
  end if;

  delete from public.funds where id = target_fund_id;
end;
$$;

revoke execute on function public.delete_fund(uuid) from public;
grant execute on function public.delete_fund(uuid) to authenticated;
