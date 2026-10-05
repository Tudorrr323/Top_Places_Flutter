-- Top Places, step 2: the public list of places. Run it once in the SQL
-- Editor, after schema.sql.

-- What Explore shows, the same list for every role: approved places whose
-- owner is not suspended. Without it an admin, who may read every place,
-- would also see the places waiting for review. security_invoker keeps the
-- rules on places in force for whoever asks.
create view public.public_places
with (security_invoker = true) as
select id, name, address, city, lat, lng, image_url, description,
  description_ro, rating, owner_id, created_at
from public.places
where status = 'approved'
  and (owner_id is null or not public.is_suspended(owner_id));

grant select on public.public_places to anon, authenticated;

-- The app shows a rating on every public place, so an admin gives one when
-- approving.
alter table public.places
  add constraint approved_places_have_a_rating
  check (status <> 'approved' or rating is not null);
