-- Top Places: takes out the conversations of seed_conversations.sql, with
-- their messages. The conversations people had themselves stay. Made by
-- supabase/tools/generate_seed_conversations.js.

delete from public.conversations as c
where c.id in (
  select md5(c.user_id::text || '/' || key)::uuid
  from unnest(array[
    'cafea-cluj',
    'pizza-brasov',
    'vegan-bucuresti',
    'rezervare',
    'cina-oradea',
    'student-iasi',
    'fish-constanta',
    'de-cluj',
    'it-brasov',
    'fr-sibiu',
    'es-timisoara',
    'hu-targu-mures',
    'mancare-timisoara',
    'cea-mai-buna-cafea',
    'vremea',
    'weekend-sibiu',
    'wine-bucharest',
    'coffee-iasi',
    'burger-shack',
    'seara-constanta',
    'jocuri-galati',
    'smoothie-alba',
    'paste-craiova',
    'mic-dejun-ploiesti',
    'salut',
    'vegan-galati',
    'de-brasov',
    'it-bucarest',
    'prajituri-oradea',
    'suceava',
    'indian-iasi',
    'delta-tulcea',
    'matcha-cluj'
  ]) as key
);
