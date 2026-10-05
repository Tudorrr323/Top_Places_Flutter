-- Top Places, step 5: reviews. Run it once in the SQL Editor, after
-- 004_ratings.sql.
--
-- A rating becomes a review: the stars, plus a message if the author wants
-- one. A new or changed review waits for the place's operator (an admin, for
-- a place without one), who accepts it or rejects it with a reason. Only
-- accepted reviews count in the average, and everyone sees them, signed-out
-- visitors too. The author can delete their review, and so can an admin.

-- 1. The message and the decision. The ratings given before this step were
-- already public, so they start accepted; new ones start waiting.
alter table public.ratings
  add column comment text check (char_length(comment) <= 500),
  add column status text not null default 'approved'
    check (status in ('pending', 'approved', 'rejected')),
  add column status_reason text check (char_length(status_reason) <= 300),
  add constraint rejected_reviews_have_a_reason
    check ((status = 'rejected') = (status_reason is not null));

alter table public.ratings alter column status set default 'pending';

-- 2. Who decides about the reviews of a place: its operator, while active,
-- and the admins.
create function public.can_moderate_ratings(place text) returns boolean
language sql stable security definer set search_path = ''
as $$
  select public.is_admin() or (
    public.is_active_operator() and exists (
      select 1 from public.places
      where id = place and owner_id = (select auth.uid())
    )
  );
$$;

-- 3. The average counts only the accepted reviews. The same function as in
-- 004, with that one condition more.
create or replace function public.refresh_place_rating(place text) returns void
language sql security definer set search_path = ''
as $$
  update public.places as p
  set (rating, rating_count) = (
    select coalesce(round(avg(r.stars), 1), p.starting_rating), count(*)
    from public.ratings as r
    join public.profiles as u on u.id = r.user_id
    where r.place_id = p.id and r.status = 'approved'
      and u.suspended_at is null
  )
  where p.id = place;
$$;

-- 4. What each side may change. The author writes the review, and a changed
-- review waits again; whoever moderates only decides, with a reason to
-- reject. Nobody decides about their own review.
create or replace function public.guard_rating() returns trigger
language plpgsql set search_path = ''
as $$
begin
  new.comment := nullif(btrim(new.comment), '');

  if tg_op = 'INSERT' then
    new.status := 'pending';
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
      new.status := 'pending';
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

-- 5. How an author is shown in public: first name and the initial of the
-- last name ("Ana P."), never the email.
create function public.rating_author(first_name text, last_name text)
returns text
language sql immutable set search_path = ''
as $$
  select coalesce(
    nullif(concat_ws(' ',
      nullif(btrim(first_name), ''),
      nullif(left(btrim(last_name), 1) || '.', '.')), ''),
    'Utilizator');
$$;

-- The accepted reviews of a public place, newest first, from accounts that
-- are not suspended. "mine" marks the reader's own review.
create function public.place_ratings(place text)
returns table (
  author text, stars smallint, comment text, updated_at timestamptz,
  mine boolean
)
language sql stable security definer set search_path = ''
as $$
  select public.rating_author(u.first_name, u.last_name), r.stars,
    r.comment, r.updated_at,
    coalesce(r.user_id = (select auth.uid()), false)
  from public.ratings as r
  join public.profiles as u on u.id = r.user_id
  join public.places as p on p.id = r.place_id
  where r.place_id = place
    and r.status = 'approved'
    and u.suspended_at is null
    and p.status = 'approved'
    and (p.owner_id is null or not public.is_suspended(p.owner_id))
  order by r.updated_at desc;
$$;

-- The reviews the reader decides about, in every status, oldest first:
-- an operator's places, or every place for an admin. Never their own.
create function public.ratings_to_moderate()
returns table (
  place_id text, place_name text, user_id uuid, author text,
  stars smallint, comment text, status text, status_reason text,
  updated_at timestamptz
)
language sql stable security definer set search_path = ''
as $$
  select r.place_id, p.name, r.user_id,
    public.rating_author(u.first_name, u.last_name), r.stars, r.comment,
    r.status, r.status_reason, r.updated_at
  from public.ratings as r
  join public.places as p on p.id = r.place_id
  join public.profiles as u on u.id = r.user_id
  where public.can_moderate_ratings(r.place_id)
    and r.user_id <> (select auth.uid())
  order by r.updated_at;
$$;

-- 6. Row Level Security, added to the rules of 004.
create policy "Moderators see the reviews of their places"
  on public.ratings for select to authenticated
  using (public.can_moderate_ratings(place_id));

create policy "Moderators decide about the reviews of others"
  on public.ratings for update to authenticated
  using (
    public.can_moderate_ratings(place_id)
    and user_id <> (select auth.uid())
  )
  with check (
    public.can_moderate_ratings(place_id)
    and user_id <> (select auth.uid())
  );

create policy "Authors delete their own reviews unless suspended"
  on public.ratings for delete to authenticated
  using (user_id = (select auth.uid()) and not public.is_suspended(user_id));

create policy "Admins delete any review"
  on public.ratings for delete to authenticated
  using (public.is_admin());

grant delete on public.ratings to authenticated;
revoke execute on function public.ratings_to_moderate() from public, anon;
grant execute on function public.ratings_to_moderate() to authenticated;
grant execute on function public.place_ratings(text), public.rating_author(text, text)
  to anon, authenticated;
grant execute on function public.can_moderate_ratings(text) to authenticated;
