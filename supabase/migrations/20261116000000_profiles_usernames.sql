-- Usernames replace leaked email addresses in the member directory.
--
-- A profile stores only the chosen handle. The verified address stays in
-- auth.users, where accept_invite() checks it, so there is no second copy that
-- can drift from the address the database actually trusts.

create table public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  username text not null check (username ~ '^[a-z0-9_]{3,20}$'),
  created_at timestamptz not null default now()
);

create unique index profiles_username_key on public.profiles (username);

alter table public.profiles enable row level security;

-- A profile is private to its owner. Co-members see usernames only through
-- list_fund_members(), which never returns an address.
create policy "Users can read their own profile"
  on public.profiles
  for select
  to authenticated
  using (user_id = auth.uid());

create policy "Users can create their own profile"
  on public.profiles
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "Users can update their own profile"
  on public.profiles
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

revoke all on public.profiles from anon;
grant select, insert, update on public.profiles to authenticated;

-- The return type changes from email to username, so the function is replaced
-- rather than created over. Existing grants are dropped with it and restored
-- below.
drop function if exists public.list_fund_members(uuid);

create function public.list_fund_members(target_fund_id uuid)
returns table (
  user_id uuid,
  username text,
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
    coalesce(p.username, '') as username,
    m.role,
    m.created_at
  from public.memberships m
  left join public.profiles p on p.user_id = m.user_id
  where m.fund_id = target_fund_id
    and public.is_fund_member(target_fund_id)
  order by m.created_at;
$$;

revoke execute on function public.list_fund_members(uuid) from public, anon;
grant execute on function public.list_fund_members(uuid) to authenticated;
