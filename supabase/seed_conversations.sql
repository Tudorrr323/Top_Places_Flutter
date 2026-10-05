-- Top Places: 33 conversations with the assistant, in Romanian,
-- English, German, Italian, French, Spanish and Hungarian. Every account
-- that can sign in gets about 40% of them, each its own share, dated over
-- the last months; the demo reviewers of seed_demo.sql get none.
--
-- Run it in the SQL Editor after 008_conversations.sql, and after
-- seed_demo.sql: many answers name its places. Running it again changes
-- nothing, and an account made later gets its share at the next run.
--
-- Made by supabase/tools/generate_seed_conversations.js: change that, not
-- this file. seed_conversations_remove.sql takes them out again.

begin;

create temporary table seed_conversations (
  key text primary key,
  title text not null,
  days integer not null,
  messages jsonb not null
) on commit drop;

insert into seed_conversations (key, title, days, messages) values
  ('cafea-cluj', 'Vreau să beau ceva în Cluj-Napoca', 1,
    '[{"a":"user","t":"Vreau să beau ceva în Cluj-Napoca"},{"a":"bot","t":"În Cluj-Napoca poți bea ceva la: Coffee Shop ''By The Faculty'', Coffee Shop ''Zen''.","c":"Cluj-Napoca"},{"a":"user","t":"Care dintre ele e mai liniștită? Vreau să lucrez pe laptop."},{"a":"ai","t":"Pentru lucru pe laptop îți recomand Coffee Shop ''Zen'', cu design minimalist și muzică de fundal relaxantă. Roastery Someș are și ea o sală liniștită, potrivită pentru citit sau lucru."}]'),
  ('pizza-brasov', 'Pizza în Brașov cu gașca', 3,
    '[{"a":"user","t":"Unde găsesc pizza bună în Brașov?"},{"a":"bot","t":"Am găsit „Pizzeria ''Il Drago''”. Pare a fi ce căutai (din Brașov, care servește pizza).","p":"pizzeria-il-drago"},{"a":"user","t":"Suntem un grup de 10. E ok?"},{"a":"ai","t":"Da, Pizzeria ''Il Drago'' e potrivită pentru grupuri, cu pizza la cuptor cu lemne și ingrediente italiene autentice. Pentru 10 persoane, scrie-le dinainte cu butonul „Rezervă pe WhatsApp”.","p":"pizzeria-il-drago"}]'),
  ('vegan-bucuresti', 'Caut mâncare vegană în București', 5,
    '[{"a":"user","t":"Caut mâncare vegană în București"},{"a":"bot","t":"În București am găsit: The Literary Coffee House ''Citadel'', Vegan Restaurant ''The Green Garden'', Burger Shack.","c":"București"},{"a":"user","t":"Care dintre ele e vegan de tot?"},{"a":"ai","t":"Vegan Restaurant ''The Green Garden'' e cel vegan: are opțiuni pe bază de plante, smoothie-uri proaspete și supe cremă delicioase.","p":"vegan-restaurant-the-green-garden"},{"a":"user","t":"Mersi!"},{"a":"ai","t":"Cu plăcere! Poftă bună!"}]'),
  ('rezervare', 'Cum fac o rezervare?', 9,
    '[{"a":"user","t":"Cum fac o rezervare?"},{"a":"bot","t":"Poți face o rezervare din pagina unui local, cu butonul „Rezervă pe WhatsApp”."},{"a":"user","t":"Pot rezerva pentru 8 persoane la Restaurant ''The Old Inn'' sâmbătă seara?"},{"a":"ai","t":"Nu știu câte locuri libere are Restaurant ''The Old Inn'' sâmbătă, dar le poți scrie direct din pagina localului, cu butonul „Rezervă pe WhatsApp”. Pentru grupuri mari, e bine să scrii cu câteva zile înainte.","p":"restaurant-the-old-inn"}]'),
  ('cina-oradea', 'Aniversare în Oradea', 12,
    '[{"a":"user","t":"Unde pot merge la o cină romantică în Oradea?"},{"a":"ai","t":"Pentru o cină romantică în Oradea îți recomand Bistro ''At The Forest'', cu meniu internațional și terasă verde. Pentru desert, puteți trece apoi pe la Patiseria Crișana."},{"a":"user","t":"Și ceva cu mâncare libaneză?"},{"a":"ai","t":"În Oradea ai Cedrus, cu bucătărie libaneză, chiar în Piața Unirii.","p":"cedrus"}]'),
  ('student-iasi', 'Ceva ieftin de mâncat în Iași, sunt student', 2,
    '[{"a":"user","t":"Ceva ieftin de mâncat în Iași, sunt student"},{"a":"ai","t":"În Iași, Bistro Copou și Pizzeria Palas sunt alegeri bune pentru un buget de student. Seara, Irish Pub ''The Shamrock'' are bere artizanală și seri de quiz."},{"a":"user","t":"Caută Irish Pub"},{"a":"bot","t":"Am găsit „Irish Pub ''The Shamrock''”.","p":"irish-pub-the-shamrock"}]'),
  ('fish-constanta', 'Where can I eat fresh fish in Constanța?', 20,
    '[{"a":"user","t":"Where can I eat fresh fish in Constanța?"},{"a":"ai","t":"Try Restaurant Pescaresc ''The Sea'', with fresh fish and seafood and a view of the sea. Pescăria Farului, on Bd. Tomis, is another good choice."},{"a":"user","t":"Which one is closer to the beach?"},{"a":"ai","t":"Restaurant Pescaresc ''The Sea'' is on Bulevardul Mamaia, right by the sea, so it is the one for a meal after the beach.","p":"restaurant-pescaresc-the-sea"}]'),
  ('de-cluj', 'Wo kann ich in Cluj gut essen?', 4,
    '[{"a":"user","t":"Wo kann ich in Cluj gut essen?"},{"a":"ai","t":"In Cluj-Napoca empfehle ich Ihnen Restaurant ''The Old Inn'', mit traditionellen rumänischen Gerichten, großen Portionen und Live-Volksmusik.","p":"restaurant-the-old-inn"},{"a":"user","t":"Und danach einen guten Kaffee?"},{"a":"ai","t":"Für einen guten Kaffee gehen Sie ins Coffee Shop ''Zen'', mit Specialty Coffee und minimalistischem Design, oder in die Roastery Someș."}]'),
  ('it-brasov', 'Dove posso mangiare una buona pizza a Brașov?', 7,
    '[{"a":"user","t":"Dove posso mangiare una buona pizza a Brașov?"},{"a":"ai","t":"A Brașov ti consiglio Pizzeria ''Il Drago'', con pizza cotta nel forno a legna e ingredienti italiani autentici.","p":"pizzeria-il-drago"},{"a":"user","t":"Grazie! E per un caffè in centro?"},{"a":"ai","t":"In centro puoi provare Cafeneaua de sub Tâmpa, in Str. Mureșenilor, a pochi passi da Piața Sfatului.","p":"cafeneaua-de-sub-tampa"}]'),
  ('fr-sibiu', 'Je cherche un salon de thé à Sibiu.', 15,
    '[{"a":"user","t":"Je cherche un salon de thé à Sibiu."},{"a":"ai","t":"À Sibiu, je vous recommande Tea House ''Sunset'', une oasis de calme avec plus de 50 sortes de thé et une musique d''ambiance.","p":"tea-house-sunset"},{"a":"user","t":"Merci ! Et pour dîner ensuite ?"},{"a":"ai","t":"Pour le dîner, Crama Sibiană, sur la Piața Mare, sert une cuisine roumaine traditionnelle.","p":"crama-sibiana"}]'),
  ('es-timisoara', '¿Dónde puedo tomar una cerveza en Timișoara?', 25,
    '[{"a":"user","t":"¿Dónde puedo tomar una cerveza en Timișoara?"},{"a":"ai","t":"En Timișoara te recomiendo Bastion Craft Beer, en la calle Hector, con cervezas artesanales.","p":"bastion-craft-beer"},{"a":"user","t":"¿Y algo rápido para comer después?"},{"a":"ai","t":"Para algo rápido, Fast-Food ''Döner King'' tiene döner kebab y shawarma, y The Global Wok Bistro ofrece comida asiática rápida y sabrosa."}]'),
  ('hu-targu-mures', 'Hol tudok jól enni Marosvásárhelyen?', 30,
    '[{"a":"user","t":"Hol tudok jól enni Marosvásárhelyen?"},{"a":"ai","t":"Marosvásárhelyen a Restaurant ''The Citadel'' hagyományos erdélyi ételeket kínál, közvetlenül a középkori vár mellett.","p":"restaurant-the-citadel"}]'),
  ('mancare-timisoara', 'Vreau să mănânc ceva', 6,
    '[{"a":"user","t":"Vreau să mănânc ceva"},{"a":"bot","t":"Sigur! În ce oraș ai vrea să mănânci?"},{"a":"user","t":"Timișoara"},{"a":"bot","t":"În Timișoara poți mânca la: The Global Wok Bistro, Fast-Food ''Döner King''.","c":"Timișoara"},{"a":"user","t":"Ceva tradițional bănățean nu e?"},{"a":"ai","t":"Ba da: La Ceaun Bănățean, pe Str. Mercy, gătește mâncare tradițională bănățeană.","p":"la-ceaun-banatean"}]'),
  ('cea-mai-buna-cafea', 'Cea mai bună cafea', 40,
    '[{"a":"user","t":"Cea mai bună cafea"},{"a":"bot","t":"Am găsit „The Literary Coffee House ''Citadel''”. Pare a fi ce căutai (care servește cafea, cu cel mai bun rating).","p":"the-literary-coffee-house-citadel"}]'),
  ('vremea', 'Cum e vremea mâine în Cluj?', 33,
    '[{"a":"user","t":"Cum e vremea mâine în Cluj?"},{"a":"ai","t":"Îmi pare rău, mă ocup doar de localurile din aplicație. Dacă plouă, îți pot recomanda o cafenea liniștită în Cluj-Napoca, de exemplu Coffee Shop ''Zen''.","p":"coffee-shop-zen"}]'),
  ('weekend-sibiu', 'Weekend la Sibiu', 18,
    '[{"a":"user","t":"Merg în weekend la Sibiu cu prietenii. Ce ne recomanzi?"},{"a":"ai","t":"La Sibiu, începeți ziua cu un brunch la Brunch Corner, iar seara mergeți la Crama Sibiană, în Piața Mare, pentru mâncare tradițională. Pentru un pahar de vin, Vinul Turnului e chiar în Piața Mică."},{"a":"user","t":"Unul dintre noi vrea neapărat sushi."},{"a":"ai","t":"Atunci încercați Sushi Nomi, pe Str. Nicolae Bălcescu, cu sushi și rulouri japoneze.","p":"sushi-nomi"},{"a":"user","t":"Super, mulțumim!"},{"a":"ai","t":"Cu plăcere! Weekend frumos la Sibiu!"}]'),
  ('wine-bucharest', 'Is there a good wine bar in Bucharest?', 22,
    '[{"a":"user","t":"Is there a good wine bar in Bucharest?"},{"a":"ai","t":"Yes: The Cellar Wine Bar, on Str. Smârdan in the old town, is a good place for a glass of wine.","p":"the-cellar-wine-bar"},{"a":"user","t":"Anything to eat nearby before that?"},{"a":"ai","t":"Trattoria Nonna Lucia, on Str. Covaci, is close by, with Italian food, and La Mici și Bere, on Str. Franceză, has Romanian grilled dishes."}]'),
  ('coffee-iasi', 'Best coffee in Iași', 11,
    '[{"a":"user","t":"Best coffee in Iași"},{"a":"bot","t":"I found “Café ''New World''”. It looks like what you wanted (in Iași, serving coffee, with the best rating).","p":"cafe-new-world"},{"a":"user","t":"Do they also do brunch on Sundays?"},{"a":"ai","t":"Café ''New World'' is known for a relaxed brunch and great cakes, but I don''t know their Sunday hours. You can ask them from the page of the place, with the WhatsApp button.","p":"cafe-new-world"}]'),
  ('burger-shack', 'Caută Burger Shack', 50,
    '[{"a":"user","t":"Caută Burger Shack"},{"a":"bot","t":"Am găsit „Burger Shack”.","p":"burger-shack"},{"a":"user","t":"Au și burgeri fără carne?"},{"a":"ai","t":"Burger Shack e cunoscut pentru burgerii artizanali cu carne Black Angus și nu știu dacă au variante fără carne. Pentru mâncare vegană în București, încearcă Vegan Restaurant ''The Green Garden''."}]'),
  ('seara-constanta', 'Seară la mare', 60,
    '[{"a":"user","t":"Unde ieșim seara la un cocktail în Constanța?"},{"a":"ai","t":"Pentru cocktailuri în Constanța, Sunset Beach Bar de pe Bd. Mamaia e locul potrivit, mai ales la apus.","p":"sunset-beach-bar"},{"a":"user","t":"Și înainte, o cină grecească?"},{"a":"ai","t":"Taverna Mykonos, pe Str. Traian, are bucătărie grecească și e o alegere bună înainte de cocktailuri.","p":"taverna-mykonos"}]'),
  ('jocuri-galati', 'Plouă și ne plictisim. Unde putem juca board games în…', 27,
    '[{"a":"user","t":"Plouă și ne plictisim. Unde putem juca board games în Galați?"},{"a":"ai","t":"Mergeți la Gaming Coffee Shop ''Restart'', unde găsiți jocuri de societate, console și cafea. E un loc excelent pentru socializare.","p":"gaming-coffee-shop-restart"}]'),
  ('smoothie-alba', 'Vreau un smoothie în Alba Iulia', 35,
    '[{"a":"user","t":"Vreau un smoothie în Alba Iulia"},{"a":"bot","t":"Am găsit „Smoothie Bar ''Energy''”. Pare a fi ce căutai (din Alba Iulia, care servește smoothie).","p":"smoothie-bar-energy"},{"a":"user","t":"Au și boluri acai?"},{"a":"ai","t":"Da, Smoothie Bar ''Energy'' are smoothie-uri, sucuri naturale și boluri acai.","p":"smoothie-bar-energy"}]'),
  ('paste-craiova', 'Unde mănânc paste bune în Craiova?', 70,
    '[{"a":"user","t":"Unde mănânc paste bune în Craiova?"},{"a":"bot","t":"Am găsit „Trattoria ''Bella Vita''”. Pare a fi ce căutai (din Craiova, care servește paste).","p":"trattoria-bella-vita"},{"a":"user","t":"Ai și o variantă mai rapidă, la pachet?"},{"a":"ai","t":"Pentru ceva mai rapid în Craiova, încearcă Napoli Express, pe Calea Unirii, cu pizza.","p":"napoli-express"}]'),
  ('mic-dejun-ploiesti', 'Unde iau micul dejun în Ploiești?', 14,
    '[{"a":"user","t":"Unde iau micul dejun în Ploiești?"},{"a":"ai","t":"În Ploiești îți recomand Bread and Coffee, o brutărie artizanală cu cafea de specialitate, ideală pentru micul dejun.","p":"bread-and-coffee"}]'),
  ('salut', 'Salut!', 0,
    '[{"a":"user","t":"Salut!"},{"a":"bot","t":"Salut! Cu ce te pot ajuta astăzi? Poți să mă întrebi despre localuri sau despre cum funcționează aplicația."},{"a":"user","t":"Ce-mi recomanzi pentru o zi de naștere în Cluj, cu vreo 6 prieteni?"},{"a":"ai","t":"Pentru o zi de naștere în Cluj-Napoca, Restaurant ''The Old Inn'' are porții generoase și muzică populară live. Dacă vreți ceva mai relaxat, Casa cu Grădină e o alegere bună pentru o masă tradițională."}]'),
  ('vegan-galati', 'Any vegan places in Galați?', 55,
    '[{"a":"user","t":"Any vegan places in Galați?"},{"a":"ai","t":"Yes: Vegan Garden, on Str. Domnească, serves vegan food.","p":"vegan-garden"}]'),
  ('de-brasov', 'Wo gibt es gutes Bier in Brașov?', 38,
    '[{"a":"user","t":"Wo gibt es gutes Bier in Brașov?"},{"a":"ai","t":"In Brașov empfehle ich Ihnen das Pilsner Haus in der Str. Republicii, ideal für ein kühles Bier.","p":"pilsner-haus"},{"a":"user","t":"Danke! Und traditionelles Essen?"},{"a":"ai","t":"Für traditionelle Küche gehen Sie ins Restaurant ''Grandma''s House'', mit einem günstigen und leckeren Mittagsmenü wie bei Oma, oder zu Ciorbe și Plăcinte."}]'),
  ('it-bucarest', 'Vorrei un ristorante italiano a Bucarest', 65,
    '[{"a":"user","t":"Vorrei un ristorante italiano a Bucarest"},{"a":"ai","t":"A Bucarest ti consiglio Trattoria Nonna Lucia, in Str. Covaci, nel centro storico.","p":"trattoria-nonna-lucia"}]'),
  ('prajituri-oradea', 'Unde găsesc prăjituri bune în Oradea?', 90,
    '[{"a":"user","t":"Unde găsesc prăjituri bune în Oradea?"},{"a":"ai","t":"În Oradea, Patiseria Crișana, de pe Str. Vasile Alecsandri, e locul potrivit pentru prăjituri.","p":"patiseria-crisana"}]'),
  ('suceava', 'Ce să vizitez în Suceava?', 100,
    '[{"a":"user","t":"Ce să vizitez în Suceava?"},{"a":"ai","t":"Mă ocup doar de localurile din aplicație, așa că nu îți pot face un traseu turistic. Pentru masă, în Suceava îți recomand Hanul Domnesc, cu mâncare tradițională.","p":"hanul-domnesc"}]'),
  ('indian-iasi', 'Am poftă de mâncare indiană, sunt în Iași', 42,
    '[{"a":"user","t":"Am poftă de mâncare indiană, sunt în Iași"},{"a":"ai","t":"În Iași ai Masala House, pe Str. Cuza Vodă, cu mâncare indiană.","p":"masala-house"},{"a":"user","t":"E deschis duminica?"},{"a":"ai","t":"Nu știu programul de la Masala House. Le poți scrie direct din pagina localului, cu butonul „Rezervă pe WhatsApp”.","p":"masala-house"}]'),
  ('delta-tulcea', 'I''m going to Tulcea for the Danube Delta. Where should I…', 120,
    '[{"a":"user","t":"I''m going to Tulcea for the Danube Delta. Where should I eat?"},{"a":"ai","t":"In Tulcea, Delta Fish, on Str. Isaccei, serves fish dishes, a good fit after a day in the Delta.","p":"delta-fish"}]'),
  ('matcha-cluj', 'Unde găsesc matcha în Cluj-Napoca?', 8,
    '[{"a":"user","t":"Unde găsesc matcha în Cluj-Napoca?"},{"a":"bot","t":"Din păcate, nu am găsit niciun local care să corespundă criteriilor tale: din Cluj-Napoca, care servește matcha."},{"a":"user","t":"Atunci un ceai bun?"},{"a":"ai","t":"Pentru ceai în Cluj-Napoca, încearcă Ceainăria Sub Tei, de pe Str. Eroilor.","p":"ceainaria-sub-tei"}]');

-- 1. Who gets which: a hash of the account and the conversation decides, so
-- that the choice stays the same at every run. The id comes from the same
-- two, which is how a second run knows what is already there.
create temporary table seed_targets on commit drop as
select md5(u.id::text || '/' || s.key)::uuid as id, u.id as user_id,
  s.title, s.messages,
  now() - make_interval(hours => s.days * 24
    + (abs(hashtext(s.key || '/' || u.id::text)::bigint) % 20)::integer)
    as started_at
from auth.users as u
join public.profiles as p on p.id = u.id
cross join seed_conversations as s
where u.email not like '%@demo.ro'
  and abs(hashtext(u.id::text || '/' || s.key)::bigint) % 100 < 40;

insert into public.conversations (id, user_id, title, created_at, updated_at)
select id, user_id, title, started_at, started_at
from seed_targets
on conflict (id) do nothing;

-- 2. The messages, 40 seconds apart, for the conversations that have none
-- yet. A place that is not in the database leaves the answer without its
-- button. Each message moves its conversation's time forward.
insert into public.chat_messages
  (conversation_id, author, body, place_id, city, created_at)
select t.id, m.message ->> 'a', m.message ->> 't',
  (select id from public.places where id = m.message ->> 'p'),
  m.message ->> 'c',
  t.started_at + make_interval(secs => (m.position - 1) * 40)
from seed_targets as t
cross join lateral jsonb_array_elements(t.messages)
  with ordinality as m (message, position)
where not exists (
  select 1 from public.chat_messages where conversation_id = t.id
)
order by t.id, m.position;

commit;

-- What each account got, to check.
select u.email, count(*) as conversations
from public.conversations as c
join auth.users as u on u.id = c.user_id
group by u.email
order by u.email;
