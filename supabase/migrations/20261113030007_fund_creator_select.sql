-- The app inserts a fund with RETURNING to get the new row back. PostgREST
-- turns that into INSERT ... RETURNING, whose output is checked against the
-- SELECT policy before the funds_add_creator AFTER INSERT trigger has added
-- the creator's membership. Without this, creating a fund fails with
-- "new row violates row-level security policy for table funds".
--
-- The creator can only see their own fund row; the trigger still grants the
-- organizer membership in the same transaction.
alter policy "Members can read their funds"
  on public.funds
  using (created_by = auth.uid() or public.is_fund_member(id));
