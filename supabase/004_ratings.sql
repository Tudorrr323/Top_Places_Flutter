-- Top Places, step 4: ratings from the users. Run it once in the SQL Editor,
-- after 003_reviews_by_admins.sql.
--
-- A signed-in account gives a public place 1 to 5 stars, once, and can
-- change them later. The place's rating is the average, kept up to date by
-- the triggers below, so the app only reads it. Nobody rates their own place
-- or a place that is not public, and a suspended account neither rates nor
-- counts in the averages until it is reactivated.

-- 1. The rating a place had before this step (the old app's, for the
-- original 20) stays until its first rating here. rating_count says how many
-- ratings the average is made of.
alter table public.places
  add column starting_rating numeric(2, 1)
    check (starting_rating between 1 and 5),
  add column rating_count integer not null default 0
    check (rating_count >= 0);

update public.places set starting_rating = rating;

-- 2. One rating per account and place.
create table public.ratings (
  place_id text not null references public.places (id) on delete cascade,
  user_id uuid not null default auth.uid()
    references public.profiles (id) on delete cascade,
  stars smallint not null check (stars between 1 and 5),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (place_id, user_id)
);

create index ratings_user_id_idx on public.ratings (user_id);

-- 3. Who may rate a place: an active account that does not own it, while
-- the place is public.
create function public.can_rate(place text) returns boolean
language sql stable security definer set search_path = ''
as $$
  select (select auth.uid()) is not null
    and not public.is_suspended((select auth.uid()))
    and exists (
      select 1 from public.places
      where id = place
        and status = 'approved'
        and owner_id is distinct from (select auth.uid())
        and (owner_id is null or not public.is_suspended(owner_id))
    );
$$;

-- 4. The average, from the accounts that are not suspended. Without
-- ratings, the place keeps the rating it started with (none for a new one).
create function public.refresh_place_rating(place text) returns void
language sql security definer set search_path = ''
as $$
  update public.places as p
  set (rating, rating_count) = (
    select coalesce(round(avg(r.stars), 1), p.starting_rating), count(*)
    from public.ratings as r
    join public.profiles as u on u.id = r.user_id
    where r.place_id = p.id and u.suspended_at is null
  )
  where p.id = place;
$$;

-- Only the triggers below call it.
revoke execute on function public.refresh_place_rating(text)
  from public, anon, authenticated;

create function public.guard_rating() returns trigger
language plpgsql set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' then
    -- Only the stars change: a rating never moves to another place or
    -- account.
    new.place_id := old.place_id;
    new.user_id := old.user_id;
    new.created_at := old.created_at;
  else
    new.created_at := now();
  end if;
  new.updated_at := now();
  return new;
end;
$$;

create trigger guard_rating
  before insert or update on public.ratings
  for each row execute function public.guard_rating();

create function public.on_rating_change() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  perform public.refresh_place_rating(coalesce(new.place_id, old.place_id));
  return null;
end;
$$;

create trigger refresh_place_rating
  after insert or update or delete on public.ratings
  for each row execute function public.on_rating_change();

-- Suspending an account takes its ratings out of the averages, and
-- reactivating it puts them back.
create function public.on_suspension_change() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  perform public.refresh_place_rating(place_id)
  from public.ratings
  where user_id = new.id;
  return null;
end;
$$;

create trigger refresh_ratings_on_suspension
  after update on public.profiles
  for each row
  when (old.suspended_at is distinct from new.suspended_at)
  execute function public.on_suspension_change();

-- 5. Nobody sets the rating by hand in the app any more, admins included:
-- the same triggers as in schema.sql, with the rating columns kept.
create or replace function public.guard_place_insert() returns trigger
language plpgsql set search_path = ''
as $$
begin
  if current_user not in ('anon', 'authenticated') then
    return new;
  end if;
  new.owner_id := (select auth.uid());
  new.created_at := now();
  new.updated_at := now();
  -- A new place has no ratings yet.
  new.rating := null;
  new.starting_rating := null;
  new.rating_count := 0;
  -- An operator's new place waits for an admin.
  if not public.is_admin() then
    new.status := 'pending';
    new.status_reason := null;
  end if;
  return new;
end;
$$;

create or replace function public.guard_place_update() returns trigger
language plpgsql set search_path = ''
as $$
begin
  -- The SQL editor, the service key and the rating triggers are trusted.
  if current_user not in ('anon', 'authenticated') then
    new.updated_at := now();
    return new;
  end if;

  new.id := old.id;
  new.owner_id := old.owner_id;
  new.created_at := old.created_at;
  new.updated_at := now();
  -- Only the ratings change the rating.
  new.rating := old.rating;
  new.starting_rating := old.starting_rating;
  new.rating_count := old.rating_count;

  if public.is_admin() then
    -- A reason only belongs to a rejected or suspended place.
    if new.status in ('pending', 'approved') then
      new.status_reason := null;
    elsif coalesce(btrim(new.status_reason), '') = '' then
      raise exception 'A reason is required to reject or suspend a place.';
    end if;
    return new;
  end if;

  -- The owner changes the content; an admin checks it again.
  new.status := 'pending';
  new.status_reason := null;
  return new;
end;
$$;

-- 6. The public list, with how many ratings each average has: the view of
-- 002, with rating_count added at the end.
create or replace view public.public_places
with (security_invoker = true) as
select id, name, address, city, lat, lng, image_url, description,
  description_ro, rating, owner_id, created_at, rating_count
from public.places
where status = 'approved'
  and (owner_id is null or not public.is_suspended(owner_id));

-- 7. Row Level Security: each account sees and changes only its own
-- ratings; the averages are public, on the places.
alter table public.ratings enable row level security;

create policy "Users see their own ratings"
  on public.ratings for select to authenticated
  using (user_id = (select auth.uid()));

create policy "Users rate the places they may rate"
  on public.ratings for insert to authenticated
  with check (user_id = (select auth.uid()) and public.can_rate(place_id));

create policy "Users change their own ratings while they may rate"
  on public.ratings for update to authenticated
  using (user_id = (select auth.uid()) and public.can_rate(place_id))
  with check (user_id = (select auth.uid()));

-- A rating is changed, never deleted, in the app.
revoke all on public.ratings from anon, authenticated;
grant select, insert, update on public.ratings to authenticated;
grant execute on function public.can_rate(text) to authenticated;
