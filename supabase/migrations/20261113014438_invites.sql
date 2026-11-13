-- Member directory and invite acceptance.
--
-- Memberships only store user ids. The directory function joins auth.users
-- behind a SECURITY DEFINER check so fund members can see who else belongs,
-- without exposing auth.users through a policy.
--
-- Invites are organizer-only at the table level, so invitees accept them
-- through accept_invite() instead of reading or writing the invites table.

create or replace function public.list_fund_members(target_fund_id uuid)
returns table (
  user_id uuid,
  email text,
  role public.member_role,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    m.user_id,
    coalesce(u.email, '') as email,
    m.role,
    m.created_at
  from public.memberships m
  join auth.users u on u.id = m.user_id
  where m.fund_id = target_fund_id
    and public.is_fund_member(target_fund_id)
  order by m.created_at;
$$;

revoke execute on function public.list_fund_members(uuid) from public;
grant execute on function public.list_fund_members(uuid) to authenticated;

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
