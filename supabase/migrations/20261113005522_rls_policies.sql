-- Role-based access for Chipbook funds.
--
-- All policies target authenticated users. The helper functions are
-- SECURITY DEFINER so they can read memberships without recursing through
-- the memberships policies.

create or replace function public.is_fund_member(target_fund_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.memberships
    where fund_id = target_fund_id
      and user_id = auth.uid()
  );
$$;

revoke execute on function public.is_fund_member(uuid) from public;
grant execute on function public.is_fund_member(uuid) to authenticated;

create or replace function public.is_fund_contributor(target_fund_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.memberships
    where fund_id = target_fund_id
      and user_id = auth.uid()
      and role in ('organizer', 'member')
  );
$$;

revoke execute on function public.is_fund_contributor(uuid) from public;
grant execute on function public.is_fund_contributor(uuid) to authenticated;

create or replace function public.is_fund_organizer(target_fund_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.memberships
    where fund_id = target_fund_id
      and user_id = auth.uid()
      and role = 'organizer'
  );
$$;

revoke execute on function public.is_fund_organizer(uuid) from public;
grant execute on function public.is_fund_organizer(uuid) to authenticated;

-- A fund must always retain at least one organizer.
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

create trigger memberships_guard_change
  before update or delete on public.memberships
  for each row execute function public.guard_membership_change();

-- Funds: members can read; any signed-in user can create one.
create policy "Members can read their funds"
  on public.funds
  for select
  to authenticated
  using (public.is_fund_member(id));

create policy "Users can create funds"
  on public.funds
  for insert
  to authenticated
  with check (created_by = auth.uid());

-- Memberships: members can read; organizers manage.
create policy "Members can read memberships"
  on public.memberships
  for select
  to authenticated
  using (public.is_fund_member(fund_id));

create policy "Organizers can add memberships"
  on public.memberships
  for insert
  to authenticated
  with check (public.is_fund_organizer(fund_id));

create policy "Organizers can change memberships"
  on public.memberships
  for update
  to authenticated
  using (public.is_fund_organizer(fund_id))
  with check (
    public.is_fund_organizer(fund_id)
    or user_id = auth.uid()
  );

create policy "Organizers can remove memberships"
  on public.memberships
  for delete
  to authenticated
  using (public.is_fund_organizer(fund_id));

-- Invites: organizer-only in every direction. Acceptance will go through a
-- SECURITY DEFINER function so invitees never read the invites table.
create policy "Organizers can read invites"
  on public.invites
  for select
  to authenticated
  using (public.is_fund_organizer(fund_id));

create policy "Organizers can create invites"
  on public.invites
  for insert
  to authenticated
  with check (
    public.is_fund_organizer(fund_id)
    and invited_by = auth.uid()
  );

create policy "Organizers can update invites"
  on public.invites
  for update
  to authenticated
  using (public.is_fund_organizer(fund_id))
  with check (public.is_fund_organizer(fund_id));

create policy "Organizers can delete invites"
  on public.invites
  for delete
  to authenticated
  using (public.is_fund_organizer(fund_id));

-- Entries: everyone in the fund reads; contributors add pending entries;
-- organizers add approved entries and reversals, and approve pending ones.
create policy "Members can read entries"
  on public.entries
  for select
  to authenticated
  using (public.is_fund_member(fund_id));

create policy "Contributors can add entries"
  on public.entries
  for insert
  to authenticated
  with check (
    created_by = auth.uid()
    and (
      public.is_fund_organizer(fund_id)
      or (
        public.is_fund_contributor(fund_id)
        and status = 'pending'
        and reverses_entry_id is null
      )
    )
  );

create policy "Organizers can approve entries"
  on public.entries
  for update
  to authenticated
  using (
    public.is_fund_organizer(fund_id)
    and status = 'pending'
  )
  with check (
    public.is_fund_organizer(fund_id)
    and status = 'approved'
  );
