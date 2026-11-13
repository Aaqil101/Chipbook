-- A pending entry has never counted toward the ledger, so an organizer may
-- discard it. Approved entries stay immutable: corrections are reversals.

create or replace function public.block_entry_delete()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if old.status = 'approved' then
    raise exception 'approved entries cannot be deleted';
  end if;
  return old;
end;
$$;

revoke execute on function public.block_entry_delete() from public;

create policy "Organizers can delete pending entries"
  on public.entries
  for delete
  to authenticated
  using (
    public.is_fund_organizer(fund_id)
    and public.is_fund_active(fund_id)
    and status = 'pending'
  );
