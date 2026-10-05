-- Top Places, step 6: the admins' own reviews. Run it once in the SQL
-- Editor, after 005_reviews.sql.
--
-- The admins are trusted: their reviews are public at once, on every place,
-- without waiting for anyone. Waiting would not even end on a place without
-- an operator, whose reviews the admins accept, since nobody decides about
-- their own review.

-- 1. Where a new or changed review starts.
create function public.new_rating_status() returns text
language sql stable set search_path = ''
as $$
  select case when public.is_admin() then 'approved' else 'pending' end;
$$;

-- 2. The same trigger as in 005, starting reviews with that status.
create or replace function public.guard_rating() returns trigger
language plpgsql set search_path = ''
as $$
begin
  new.comment := nullif(btrim(new.comment), '');

  if tg_op = 'INSERT' then
    new.status := public.new_rating_status();
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
      new.status := public.new_rating_status();
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

-- 3. The admins' reviews that already wait are accepted now.
update public.ratings as r
set status = 'approved'
where r.status = 'pending'
  and exists (
    select 1 from public.profiles as u
    where u.id = r.user_id and u.role = 'admin'
  );
