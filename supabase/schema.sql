-- Top Places: accounts, places and moderation, for a new Supabase project.
-- Run it once, as a whole, in the dashboard: SQL Editor > New query > Run.
--
-- Who can do what (enforced here, in the database, not only in the app):
--   everyone   sees approved places, except those of suspended operators
--   user       edits their own name and can ask to become an operator
--   operator   adds places and edits their own; every edit goes back to review
--   admin      approves, rejects or suspends places (with a reason), approves
--              operators, edits names and roles, suspends accounts (with a
--              reason) and edits any place
--
-- The first admin is made by hand, after signing up in the app:
--   update public.profiles set role = 'admin' where email = 'you@example.com';

-- 1. Tables ------------------------------------------------------------------

-- One row per account, created by a trigger when someone signs up.
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null default '',
  first_name text not null default '' check (char_length(first_name) <= 50),
  last_name text not null default '' check (char_length(last_name) <= 50),
  role text not null default 'user'
    check (role in ('user', 'operator', 'admin')),
  -- A user's request to become an operator; null when there is none.
  operator_request text check (operator_request in ('pending', 'rejected')),
  -- Suspended when there is a reason. The admin must give one.
  suspended_reason text check (char_length(suspended_reason) <= 300),
  suspended_at timestamptz,
  created_at timestamptz not null default now(),
  check ((suspended_reason is null) = (suspended_at is null))
);

create table public.places (
  id text primary key default gen_random_uuid()::text,
  name text not null check (char_length(btrim(name)) between 2 and 80),
  address text not null check (char_length(btrim(address)) between 3 and 120),
  city text not null check (char_length(btrim(city)) between 2 and 40),
  -- Inside Romania, roughly.
  lat double precision not null check (lat between 43.5 and 48.5),
  lng double precision not null check (lng between 20 and 30),
  image_url text not null default ''
    check (image_url = '' or image_url like 'https://%'),
  description text not null
    check (char_length(btrim(description)) between 10 and 300),
  -- The Romanian translation, for the places whose description is English.
  description_ro text check (char_length(description_ro) <= 300),
  -- Null for a new place, shown as "Nou" in the app. From 004_ratings.sql
  -- on, the average of the users' ratings.
  rating numeric(2, 1) check (rating between 1 and 5),
  owner_id uuid references public.profiles (id) on delete set null,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'suspended')),
  -- Why the place was rejected or suspended. Required for those two.
  status_reason text check (char_length(status_reason) <= 300),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((status in ('rejected', 'suspended')) = (status_reason is not null))
);

create index places_owner_id_idx on public.places (owner_id);

-- 2. Helpers used by the rules -----------------------------------------------
-- "security definer" lets them read profiles even where the rules below
-- would not, so a rule on places can ask about the place's owner.

create function public.is_admin() returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'admin' and suspended_at is null
  );
$$;

create function public.is_active_operator() returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'operator' and suspended_at is null
  );
$$;

create function public.is_suspended(user_id uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce(
    (select suspended_at is not null from public.profiles where id = user_id),
    false
  );
$$;

-- 3. Triggers: what each role may change -------------------------------------

-- A profile for every new account, with the names given at sign-up.
create function public.create_profile() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, email, first_name, last_name)
  values (
    new.id,
    coalesce(new.email, ''),
    left(btrim(coalesce(new.raw_user_meta_data ->> 'first_name', '')), 50),
    left(btrim(coalesce(new.raw_user_meta_data ->> 'last_name', '')), 50)
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.create_profile();

create function public.guard_profile_update() returns trigger
language plpgsql set search_path = ''
as $$
begin
  -- The SQL editor and the service key are trusted: no limits there.
  if current_user not in ('anon', 'authenticated') then
    return new;
  end if;

  new.id := old.id;
  new.email := old.email;
  new.created_at := old.created_at;

  if public.is_admin() then
    if new.id = (select auth.uid())
       and (new.role <> old.role or new.suspended_reason is not null) then
      raise exception 'An admin cannot change their own role or suspend themselves.';
    end if;
    if btrim(new.suspended_reason) = '' then
      raise exception 'A reason is required to suspend an account.';
    end if;
    -- Suspended from now on, or not suspended.
    new.suspended_at := case
      when new.suspended_reason is null then null
      else coalesce(old.suspended_at, now())
    end;
    -- Approving a request means giving the operator role.
    if new.role <> 'user' then
      new.operator_request := null;
    end if;
    return new;
  end if;

  -- Everyone else edits only their name, and may ask to become an operator.
  new.role := old.role;
  new.suspended_reason := old.suspended_reason;
  new.suspended_at := old.suspended_at;
  if new.operator_request is distinct from old.operator_request
     and not (new.operator_request = 'pending' and old.role = 'user') then
    new.operator_request := old.operator_request;
  end if;
  return new;
end;
$$;

create trigger guard_profile_update
  before update on public.profiles
  for each row execute function public.guard_profile_update();

create function public.guard_place_insert() returns trigger
language plpgsql set search_path = ''
as $$
begin
  if current_user not in ('anon', 'authenticated') then
    return new;
  end if;
  new.owner_id := (select auth.uid());
  new.created_at := now();
  new.updated_at := now();
  -- An operator's new place waits for an admin.
  if not public.is_admin() then
    new.status := 'pending';
    new.status_reason := null;
    new.rating := null;
  end if;
  return new;
end;
$$;

create trigger guard_place_insert
  before insert on public.places
  for each row execute function public.guard_place_insert();

create function public.guard_place_update() returns trigger
language plpgsql set search_path = ''
as $$
begin
  if current_user not in ('anon', 'authenticated') then
    new.updated_at := now();
    return new;
  end if;

  new.id := old.id;
  new.owner_id := old.owner_id;
  new.created_at := old.created_at;
  new.updated_at := now();

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
  new.rating := old.rating;
  new.status := 'pending';
  new.status_reason := null;
  return new;
end;
$$;

create trigger guard_place_update
  before update on public.places
  for each row execute function public.guard_place_update();

-- 4. Row Level Security: which rows each role sees and changes ---------------

alter table public.profiles enable row level security;
alter table public.places enable row level security;

create policy "Users see their own profile"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()));

create policy "Admins see every profile"
  on public.profiles for select to authenticated
  using (public.is_admin());

create policy "Users edit their own profile unless suspended"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()) and not public.is_suspended(id))
  with check (id = (select auth.uid()));

create policy "Admins edit every profile"
  on public.profiles for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy "Everyone sees approved places of active owners"
  on public.places for select
  using (
    status = 'approved'
    and (owner_id is null or not public.is_suspended(owner_id))
  );

create policy "Owners see their own places"
  on public.places for select to authenticated
  using (owner_id = (select auth.uid()));

create policy "Admins see every place"
  on public.places for select to authenticated
  using (public.is_admin());

create policy "Operators and admins add places"
  on public.places for insert to authenticated
  with check (
    owner_id = (select auth.uid())
    and (public.is_active_operator() or public.is_admin())
  );

create policy "Active operators edit their own places unless suspended"
  on public.places for update to authenticated
  using (
    owner_id = (select auth.uid())
    and public.is_active_operator()
    and status <> 'suspended'
  )
  with check (owner_id = (select auth.uid()));

create policy "Admins edit every place"
  on public.places for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Nobody deletes through the app: places are rejected or suspended instead.
revoke all on public.profiles, public.places from anon, authenticated;
grant select on public.places to anon;
grant select, insert, update on public.places to authenticated;
grant select, update on public.profiles to authenticated;
grant execute on function public.is_admin(), public.is_active_operator(),
  public.is_suspended(uuid) to anon, authenticated;

-- 5. The 20 places of the original app, already approved ---------------------
insert into public.places
  (id, name, address, city, lat, lng, image_url, description, description_ro, rating, status)
select v.*, 'approved'
from (values
  ('the-literary-coffee-house-citadel', 'The Literary Coffee House ''Citadel''', 'Str. Academiei, Nr. 15, Bucharest', 'București', 44.4363, 26.1018, 'https://images.unsplash.com/photo-1435224654926-ecc9f7fa028c', 'A quiet place, ideal for reading and study sessions. Excellent espresso.', 'Un loc liniștit, ideal pentru citit și studiu. Espresso excelent.', 4.8),
  ('restaurant-the-old-inn', 'Restaurant ''The Old Inn''', 'Piața Unirii, Nr. 4, Cluj-Napoca', 'Cluj-Napoca', 46.7709, 23.5891, 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e', 'Traditional Romanian dishes, generous servings, and live folk music.', 'Mâncăruri tradiționale românești, porții generoase și muzică populară live.', 4.5),
  ('the-global-wok-bistro', 'The Global Wok Bistro', 'Bulevardul Eroilor, Nr. 8, Timișoara', 'Timișoara', 45.7537, 21.2257, 'https://images.unsplash.com/photo-1505483531331-fc3cf89fd382', 'Fast and tasty Asian food, a favorite among Polytechnic students.', 'Mâncare asiatică rapidă și gustoasă, preferată de studenții de la Politehnică.', 4.2),
  ('cafe-new-world', 'Café ''New World''', 'Str. Lăpușneanu, Nr. 12, Iași', 'Iași', 47.1601, 27.5794, 'https://images.unsplash.com/photo-1437622368342-7a3d73a34c8f', 'Modern design, perfect for a relaxed brunch. They have the best cakes.', 'Design modern, perfect pentru un brunch relaxat. Au cele mai bune prăjituri.', 4.7),
  ('pizzeria-il-drago', 'Pizzeria ''Il Drago''', 'Str. Nicolae Bălcescu, Nr. 20, Brașov', 'Brașov', 45.6429, 25.5888, 'https://images.unsplash.com/photo-1469474968028-56623f02e42e', 'Wood-fired oven pizza, authentic Italian ingredients. Excellent for groups.', 'Pizza la cuptor cu lemne, ingrediente italiene autentice. Excelent pentru grupuri.', 4.6),
  ('vegan-restaurant-the-green-garden', 'Vegan Restaurant ''The Green Garden''', 'Splaiul Independenței, Nr. 300, Bucharest', 'București', 44.4379, 26.0463, 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e', 'Healthy, plant-based options. Fresh smoothies and delicious cream soups.', 'Opțiuni sănătoase, pe bază de plante. Smoothie-uri proaspete și supe cremă delicioase.', 4.9),
  ('coffee-shop-by-the-faculty', 'Coffee Shop ''By The Faculty''', 'Str. Observatorului, Nr. 17, Cluj-Napoca', 'Cluj-Napoca', 46.757, 23.5786, 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee', 'Strategic location near the campus. Quick and affordable student lunch menu.', 'Locație strategică lângă campus. Meniu de prânz rapid și accesibil pentru studenți.', 4.0),
  ('burger-shack', 'Burger Shack', 'Calea Moșilor, Nr. 250, Bucharest', 'București', 44.4449, 26.1103, 'https://images.unsplash.com/photo-1501785888041-af3ef285b470', 'The best artisanal burgers in town, featuring Black Angus beef.', 'Cei mai buni burgeri artizanali din oraș, cu carne Black Angus.', 4.4),
  ('tea-house-sunset', 'Tea House ''Sunset''', 'Str. George Enescu, Nr. 3, Sibiu', 'Sibiu', 45.7958, 24.1528, 'https://images.unsplash.com/photo-1470770841072-f978cf4d019e', 'An oasis of calm with over 50 types of tea and ambient music.', 'O oază de liniște cu peste 50 de tipuri de ceai și muzică ambientală.', 4.7),
  ('restaurant-pescaresc-the-sea', 'Restaurant Pescaresc ''The Sea''', 'Bulevardul Mamaia, Nr. 200, Constanța', 'Constanța', 44.1751, 28.6367, 'https://images.unsplash.com/photo-1469474968028-56623f02e42e', 'Fresh fish and seafood specialties, with a view of the sea.', 'Specialități din pește proaspăt și fructe de mare, cu vedere la mare.', 4.5),
  ('bistro-at-the-forest', 'Bistro ''At The Forest''', 'Aleea Parcului, Nr. 7, Oradea', 'Oradea', 47.0506, 21.9161, 'https://images.unsplash.com/photo-1465101162946-4377e57745c3', 'International menu, green terrace. Ideal for a romantic dinner.', 'Meniu internațional, terasă verde. Ideal pentru o cină romantică.', 4.3),
  ('gaming-coffee-shop-restart', 'Gaming Coffee Shop ''Restart''', 'Strada Vasile Alecsandri, Nr. 5, Galați', 'Galați', 45.4385, 28.0559, 'https://images.unsplash.com/photo-1500534623283-312aade485b7', 'Board games, consoles, and coffee. An excellent place for socializing.', 'Jocuri de societate, console și cafea. Un loc excelent pentru socializare.', 4.1),
  ('trattoria-bella-vita', 'Trattoria ''Bella Vita''', 'Bulevardul Carol I, Nr. 18, Craiova', 'Craiova', 44.3297, 23.8, 'https://images.unsplash.com/photo-1462331940025-496dfbfc7564', 'Homemade pasta and Italian wines. Mediterranean atmosphere.', 'Paste de casă și vinuri italienești. Atmosferă mediteraneană.', 4.6),
  ('bread-and-coffee', 'Bread and Coffee', 'Strada Republicii, Nr. 10, Ploiești', 'Ploiești', 44.945, 26.0315, 'https://images.unsplash.com/photo-1435224654926-ecc9f7fa028c', 'Artisanal bakery with specialty coffees. Ideal for breakfast.', 'Brutărie artizanală cu cafea de specialitate. Ideal pentru micul dejun.', 4.8),
  ('fast-food-doner-king', 'Fast-Food ''Döner King''', 'Calea Șagului, Nr. 55, Timișoara', 'Timișoara', 45.7275, 21.2188, 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e', 'Döner Kebab and Shawarma. Quick and filling option after classes.', 'Döner Kebab și Shaorma. Opțiune rapidă și sățioasă după cursuri.', 3.9),
  ('restaurant-the-citadel', 'Restaurant ''The Citadel''', 'Strada Mureșenilor, Nr. 1, Târgu Mureș', 'Târgu Mureș', 46.5459, 24.5623, 'https://images.unsplash.com/photo-1505483531331-fc3cf89fd382', 'Traditional Transylvanian food, next to the Medieval Citadel.', 'Mâncare tradițională ardelenească, lângă Cetatea Medievală.', 4.4),
  ('smoothie-bar-energy', 'Smoothie Bar ''Energy''', 'Bulevardul 1 Decembrie 1918, Nr. 100, Alba Iulia', 'Alba Iulia', 46.0683, 23.5855, 'https://images.unsplash.com/photo-1437622368342-7a3d73a34c8f', 'Smoothies, natural juices, and acai bowls for an energy boost.', 'Smoothie-uri, sucuri naturale și boluri acai pentru un boost de energie.', 4.9),
  ('restaurant-grandma-s-house', 'Restaurant ''Grandma''s House''', 'Strada Republicii, Nr. 45, Brașov', 'Brașov', 45.6425, 25.588, 'https://images.unsplash.com/photo-1469474968028-56623f02e42e', 'Fixed (lunch) menu, cheap and tasty, just like home.', 'Meniu fix (de prânz), ieftin și gustos, ca acasă.', 4.3),
  ('irish-pub-the-shamrock', 'Irish Pub ''The Shamrock''', 'Strada Universității, Nr. 9, Iași', 'Iași', 47.1633, 27.579, 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e', 'Craft beer, quiz nights, and live sports. Popular student spot.', 'Bere artizanală, seri de quiz și sport live. Loc popular printre studenți.', 4.5),
  ('coffee-shop-zen', 'Coffee Shop ''Zen''', 'Strada Dorobanților, Nr. 80, Cluj-Napoca', 'Cluj-Napoca', 46.777, 23.6067, 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee', 'Minimalist design, specialty coffee, and relaxing background music.', 'Design minimalist, cafea de specialitate și muzică de fundal relaxantă.', 4.7)
) as v (id, name, address, city, lat, lng, image_url, description, description_ro, rating);
