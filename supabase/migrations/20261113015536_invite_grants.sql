-- Supabase grants EXECUTE on new public functions to anon by default.
-- These functions are for signed-in users only; the authenticated role was
-- granted explicitly in the invites migration.
revoke execute on function public.list_fund_members(uuid) from anon;
revoke execute on function public.accept_invite(uuid) from anon;
