-- Top Places, step 6: the admins' own reviews. Run it once in the SQL
-- Editor, after 005_reviews.sql.
--
-- The admins accept the reviews of a place without an operator, and nobody
-- decides about their own review. So an admin's review of such a place
-- would wait forever with a single admin. It is accepted at once instead:
-- the admins are trusted, and nobody else would decide. An admin's review
-- of an operator's place still waits for that operator.

-- 1. Where a new or changed review starts.
create function public.new_rating_status(place text) returns text
language sql stable set search_path = ''
as $$
  select case
    when public.is_admin() and exists (
      select 1 from public.places where id = place and owner_id is null
    ) then 'approved'
    else 'pending'
  end;
$$;

-- 2. The same trigger as in 005, starting reviews with that status.
create or replace function public.guard_rating() returns trigger
language plpgsql set search_path = ''
as $$
begin
  new.comment := nullif(btrim(new.comment), '');

  if tg_op = 'INSERT' then
    new.status := public.new_rating_status(new.place_id);
    new.status_reason := null;
    new.created_at := now();
    new.updated_at := now();
    return new;
  end if;

  -- A review never moves to another place or account.
  new.place_id := old.place_id;
  new.user_id := old.user_id;
  new.created_at := old.created_at;

  if new.user_id = (select auth.uid()) then
    if new.stars is distinct from old.stars
       or new.comment is distinct from old.comment then
      new.status := public.new_rating_status(new.place_id);
      new.status_reason := null;
      new.updated_at := now();
    else
      new.status := old.status;
      new.status_reason := old.status_reason;
      new.updated_at := old.updated_at;
    end if;
    return new;
  end if;

  new.stars := old.stars;
  new.comment := old.comment;
  new.updated_at := old.updated_at;
  if new.status <> 'rejected' then
    new.status_reason := null;
  elsif coalesce(btrim(new.status_reason), '') = '' then
    raise exception 'A reason is required to reject a review.';
  end if;
  return new;
end;
$$;

-- 3. The admins' reviews that already wait for this reason are accepted now.
update public.ratings as r
set status = 'approved'
where r.status = 'pending'
  and exists (
    select 1 from public.profiles as u
    where u.id = r.user_id and u.role = 'admin'
  )
  and exists (
    select 1 from public.places as p
    where p.id = r.place_id and p.owner_id is null
  );
