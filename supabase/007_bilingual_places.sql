-- Top Places, step 7: every place described in Romanian and in English. Run
-- it once in the SQL Editor, after 006_admin_reviews.sql.
--
-- The app shows the description in the language chosen in its settings:
-- description in English, description_ro in Romanian. An operator writes
-- both; a button in the form translates one into the other.

-- 1. The places added before this step have one description, in Romanian
-- (the form had one field). It becomes the Romanian one, and stays as the
-- English one too until the operator writes it.
update public.places
set description_ro = description
where description_ro is null;

-- 2. Both are required from now on, with the same limits.
alter table public.places
  alter column description_ro set not null,
  add constraint description_ro_length
    check (char_length(btrim(description_ro)) between 10 and 300);
