// Writes ../seed_conversations.sql and ../seed_conversations_remove.sql:
// conversations with the assistant for the accounts that can sign in, so
// that the history of the chat looks lived in.
//
//   node supabase/tools/generate_seed_conversations.js
//
// The answers are what the app gives: those of the rules word for word
// (checked with BotEngine), those of Gemini in its style, short and naming
// only places that exist in the app.
const fs = require('fs');
const path = require('path');

const sql = (value) => (value == null ? 'null' : `'${String(value).replace(/'/g, "''")}'`);

// What the app uses as a title: the first message, cut at a word near 60
// characters. The same rule as titleFrom in lib/models/conversation.dart.
function titleFrom(message) {
  const text = message.trim().replace(/\s+/g, ' ');
  if (text.length <= 60) return text;
  const cut = text.lastIndexOf(' ', 60);
  return `${text.slice(0, cut > 30 ? cut : 60).trimEnd()}…`;
}

// A message: who wrote it, the text, and what "Arată pe hartă" shows.
const user = (text) => ({ a: 'user', t: text });
const bot = (text, show = {}) => ({ a: 'bot', t: text, ...show });
const ai = (text, show = {}) => ({ a: 'ai', t: text, ...show });
const place = (id) => ({ p: id });
const city = (name) => ({ c: name });

// [key, days ago, messages, title when the user renamed it]
const conversations = [
  ['cafea-cluj', 1, [
    user('Vreau să beau ceva în Cluj-Napoca'),
    bot("În Cluj-Napoca poți bea ceva la: Coffee Shop 'By The Faculty', Coffee Shop 'Zen'.", city('Cluj-Napoca')),
    user('Care dintre ele e mai liniștită? Vreau să lucrez pe laptop.'),
    ai("Pentru lucru pe laptop îți recomand Coffee Shop 'Zen', cu design minimalist și muzică de fundal relaxantă. Roastery Someș are și ea o sală liniștită, potrivită pentru citit sau lucru."),
  ]],
  ['pizza-brasov', 3, [
    user('Unde găsesc pizza bună în Brașov?'),
    bot("Am găsit „Pizzeria 'Il Drago'”. Pare a fi ce căutai (din Brașov, care servește pizza).", place('pizzeria-il-drago')),
    user('Suntem un grup de 10. E ok?'),
    ai("Da, Pizzeria 'Il Drago' e potrivită pentru grupuri, cu pizza la cuptor cu lemne și ingrediente italiene autentice. Pentru 10 persoane, scrie-le dinainte cu butonul „Rezervă pe WhatsApp”.", place('pizzeria-il-drago')),
  ], 'Pizza în Brașov cu gașca'],
  ['vegan-bucuresti', 5, [
    user('Caut mâncare vegană în București'),
    bot("În București am găsit: The Literary Coffee House 'Citadel', Vegan Restaurant 'The Green Garden', Burger Shack.", city('București')),
    user('Care dintre ele e vegan de tot?'),
    ai("Vegan Restaurant 'The Green Garden' e cel vegan: are opțiuni pe bază de plante, smoothie-uri proaspete și supe cremă delicioase.", place('vegan-restaurant-the-green-garden')),
    user('Mersi!'),
    ai('Cu plăcere! Poftă bună!'),
  ]],
  ['rezervare', 9, [
    user('Cum fac o rezervare?'),
    bot('Poți face o rezervare din pagina unui local, cu butonul „Rezervă pe WhatsApp”.'),
    user("Pot rezerva pentru 8 persoane la Restaurant 'The Old Inn' sâmbătă seara?"),
    ai("Nu știu câte locuri libere are Restaurant 'The Old Inn' sâmbătă, dar le poți scrie direct din pagina localului, cu butonul „Rezervă pe WhatsApp”. Pentru grupuri mari, e bine să scrii cu câteva zile înainte.", place('restaurant-the-old-inn')),
  ]],
  ['cina-oradea', 12, [
    user('Unde pot merge la o cină romantică în Oradea?'),
    ai("Pentru o cină romantică în Oradea îți recomand Bistro 'At The Forest', cu meniu internațional și terasă verde. Pentru desert, puteți trece apoi pe la Patiseria Crișana."),
    user('Și ceva cu mâncare libaneză?'),
    ai('În Oradea ai Cedrus, cu bucătărie libaneză, chiar în Piața Unirii.', place('cedrus')),
  ], 'Aniversare în Oradea'],
  ['student-iasi', 2, [
    user('Ceva ieftin de mâncat în Iași, sunt student'),
    ai("În Iași, Bistro Copou și Pizzeria Palas sunt alegeri bune pentru un buget de student. Seara, Irish Pub 'The Shamrock' are bere artizanală și seri de quiz."),
    user('Caută Irish Pub'),
    bot("Am găsit „Irish Pub 'The Shamrock'”.", place('irish-pub-the-shamrock')),
  ]],
  ['fish-constanta', 20, [
    user('Where can I eat fresh fish in Constanța?'),
    ai("Try Restaurant Pescaresc 'The Sea', with fresh fish and seafood and a view of the sea. Pescăria Farului, on Bd. Tomis, is another good choice."),
    user('Which one is closer to the beach?'),
    ai("Restaurant Pescaresc 'The Sea' is on Bulevardul Mamaia, right by the sea, so it is the one for a meal after the beach.", place('restaurant-pescaresc-the-sea')),
  ]],
  ['de-cluj', 4, [
    user('Wo kann ich in Cluj gut essen?'),
    ai("In Cluj-Napoca empfehle ich Ihnen Restaurant 'The Old Inn', mit traditionellen rumänischen Gerichten, großen Portionen und Live-Volksmusik.", place('restaurant-the-old-inn')),
    user('Und danach einen guten Kaffee?'),
    ai("Für einen guten Kaffee gehen Sie ins Coffee Shop 'Zen', mit Specialty Coffee und minimalistischem Design, oder in die Roastery Someș."),
  ]],
  ['it-brasov', 7, [
    user('Dove posso mangiare una buona pizza a Brașov?'),
    ai("A Brașov ti consiglio Pizzeria 'Il Drago', con pizza cotta nel forno a legna e ingredienti italiani autentici.", place('pizzeria-il-drago')),
    user('Grazie! E per un caffè in centro?'),
    ai('In centro puoi provare Cafeneaua de sub Tâmpa, in Str. Mureșenilor, a pochi passi da Piața Sfatului.', place('cafeneaua-de-sub-tampa')),
  ]],
  ['fr-sibiu', 15, [
    user('Je cherche un salon de thé à Sibiu.'),
    ai("À Sibiu, je vous recommande Tea House 'Sunset', une oasis de calme avec plus de 50 sortes de thé et une musique d'ambiance.", place('tea-house-sunset')),
    user('Merci ! Et pour dîner ensuite ?'),
    ai('Pour le dîner, Crama Sibiană, sur la Piața Mare, sert une cuisine roumaine traditionnelle.', place('crama-sibiana')),
  ]],
  ['es-timisoara', 25, [
    user('¿Dónde puedo tomar una cerveza en Timișoara?'),
    ai('En Timișoara te recomiendo Bastion Craft Beer, en la calle Hector, con cervezas artesanales.', place('bastion-craft-beer')),
    user('¿Y algo rápido para comer después?'),
    ai("Para algo rápido, Fast-Food 'Döner King' tiene döner kebab y shawarma, y The Global Wok Bistro ofrece comida asiática rápida y sabrosa."),
  ]],
  ['hu-targu-mures', 30, [
    user('Hol tudok jól enni Marosvásárhelyen?'),
    ai("Marosvásárhelyen a Restaurant 'The Citadel' hagyományos erdélyi ételeket kínál, közvetlenül a középkori vár mellett.", place('restaurant-the-citadel')),
  ]],
  ['mancare-timisoara', 6, [
    user('Vreau să mănânc ceva'),
    bot('Sigur! În ce oraș ai vrea să mănânci?'),
    user('Timișoara'),
    bot("În Timișoara poți mânca la: The Global Wok Bistro, Fast-Food 'Döner King'.", city('Timișoara')),
    user('Ceva tradițional bănățean nu e?'),
    ai('Ba da: La Ceaun Bănățean, pe Str. Mercy, gătește mâncare tradițională bănățeană.', place('la-ceaun-banatean')),
  ]],
  ['cea-mai-buna-cafea', 40, [
    user('Cea mai bună cafea'),
    bot("Am găsit „The Literary Coffee House 'Citadel'”. Pare a fi ce căutai (care servește cafea, cu cel mai bun rating).", place('the-literary-coffee-house-citadel')),
  ]],
  ['vremea', 33, [
    user('Cum e vremea mâine în Cluj?'),
    ai('Îmi pare rău, mă ocup doar de localurile din aplicație. Dacă plouă, îți pot recomanda o cafenea liniștită în Cluj-Napoca, de exemplu Coffee Shop \'Zen\'.', place('coffee-shop-zen')),
  ]],
  ['weekend-sibiu', 18, [
    user('Merg în weekend la Sibiu cu prietenii. Ce ne recomanzi?'),
    ai('La Sibiu, începeți ziua cu un brunch la Brunch Corner, iar seara mergeți la Crama Sibiană, în Piața Mare, pentru mâncare tradițională. Pentru un pahar de vin, Vinul Turnului e chiar în Piața Mică.'),
    user('Unul dintre noi vrea neapărat sushi.'),
    ai('Atunci încercați Sushi Nomi, pe Str. Nicolae Bălcescu, cu sushi și rulouri japoneze.', place('sushi-nomi')),
    user('Super, mulțumim!'),
    ai('Cu plăcere! Weekend frumos la Sibiu!'),
  ], 'Weekend la Sibiu'],
  ['wine-bucharest', 22, [
    user('Is there a good wine bar in Bucharest?'),
    ai('Yes: The Cellar Wine Bar, on Str. Smârdan in the old town, is a good place for a glass of wine.', place('the-cellar-wine-bar')),
    user('Anything to eat nearby before that?'),
    ai('Trattoria Nonna Lucia, on Str. Covaci, is close by, with Italian food, and La Mici și Bere, on Str. Franceză, has Romanian grilled dishes.'),
  ]],
  ['coffee-iasi', 11, [
    user('Best coffee in Iași'),
    bot("I found “Café 'New World'”. It looks like what you wanted (in Iași, serving coffee, with the best rating).", place('cafe-new-world')),
    user('Do they also do brunch on Sundays?'),
    ai("Café 'New World' is known for a relaxed brunch and great cakes, but I don't know their Sunday hours. You can ask them from the page of the place, with the WhatsApp button.", place('cafe-new-world')),
  ]],
  ['burger-shack', 50, [
    user('Caută Burger Shack'),
    bot('Am găsit „Burger Shack”.', place('burger-shack')),
    user('Au și burgeri fără carne?'),
    ai("Burger Shack e cunoscut pentru burgerii artizanali cu carne Black Angus și nu știu dacă au variante fără carne. Pentru mâncare vegană în București, încearcă Vegan Restaurant 'The Green Garden'."),
  ]],
  ['seara-constanta', 60, [
    user('Unde ieșim seara la un cocktail în Constanța?'),
    ai('Pentru cocktailuri în Constanța, Sunset Beach Bar de pe Bd. Mamaia e locul potrivit, mai ales la apus.', place('sunset-beach-bar')),
    user('Și înainte, o cină grecească?'),
    ai('Taverna Mykonos, pe Str. Traian, are bucătărie grecească și e o alegere bună înainte de cocktailuri.', place('taverna-mykonos')),
  ], 'Seară la mare'],
  ['jocuri-galati', 27, [
    user('Plouă și ne plictisim. Unde putem juca board games în Galați?'),
    ai("Mergeți la Gaming Coffee Shop 'Restart', unde găsiți jocuri de societate, console și cafea. E un loc excelent pentru socializare.", place('gaming-coffee-shop-restart')),
  ]],
  ['smoothie-alba', 35, [
    user('Vreau un smoothie în Alba Iulia'),
    bot("Am găsit „Smoothie Bar 'Energy'”. Pare a fi ce căutai (din Alba Iulia, care servește smoothie).", place('smoothie-bar-energy')),
    user('Au și boluri acai?'),
    ai("Da, Smoothie Bar 'Energy' are smoothie-uri, sucuri naturale și boluri acai.", place('smoothie-bar-energy')),
  ]],
  ['paste-craiova', 70, [
    user('Unde mănânc paste bune în Craiova?'),
    bot("Am găsit „Trattoria 'Bella Vita'”. Pare a fi ce căutai (din Craiova, care servește paste).", place('trattoria-bella-vita')),
    user('Ai și o variantă mai rapidă, la pachet?'),
    ai('Pentru ceva mai rapid în Craiova, încearcă Napoli Express, pe Calea Unirii, cu pizza.', place('napoli-express')),
  ]],
  ['mic-dejun-ploiesti', 14, [
    user('Unde iau micul dejun în Ploiești?'),
    ai('În Ploiești îți recomand Bread and Coffee, o brutărie artizanală cu cafea de specialitate, ideală pentru micul dejun.', place('bread-and-coffee')),
  ]],
  ['salut', 0, [
    user('Salut!'),
    bot('Salut! Cu ce te pot ajuta astăzi? Poți să mă întrebi despre localuri sau despre cum funcționează aplicația.'),
    user('Ce-mi recomanzi pentru o zi de naștere în Cluj, cu vreo 6 prieteni?'),
    ai("Pentru o zi de naștere în Cluj-Napoca, Restaurant 'The Old Inn' are porții generoase și muzică populară live. Dacă vreți ceva mai relaxat, Casa cu Grădină e o alegere bună pentru o masă tradițională."),
  ]],
  ['vegan-galati', 55, [
    user('Any vegan places in Galați?'),
    ai('Yes: Vegan Garden, on Str. Domnească, serves vegan food.', place('vegan-garden')),
  ]],
  ['de-brasov', 38, [
    user('Wo gibt es gutes Bier in Brașov?'),
    ai('In Brașov empfehle ich Ihnen das Pilsner Haus in der Str. Republicii, ideal für ein kühles Bier.', place('pilsner-haus')),
    user('Danke! Und traditionelles Essen?'),
    ai("Für traditionelle Küche gehen Sie ins Restaurant 'Grandma's House', mit einem günstigen und leckeren Mittagsmenü wie bei Oma, oder zu Ciorbe și Plăcinte."),
  ]],
  ['it-bucarest', 65, [
    user('Vorrei un ristorante italiano a Bucarest'),
    ai('A Bucarest ti consiglio Trattoria Nonna Lucia, in Str. Covaci, nel centro storico.', place('trattoria-nonna-lucia')),
  ]],
  ['prajituri-oradea', 90, [
    user('Unde găsesc prăjituri bune în Oradea?'),
    ai('În Oradea, Patiseria Crișana, de pe Str. Vasile Alecsandri, e locul potrivit pentru prăjituri.', place('patiseria-crisana')),
  ]],
  ['suceava', 100, [
    user('Ce să vizitez în Suceava?'),
    ai('Mă ocup doar de localurile din aplicație, așa că nu îți pot face un traseu turistic. Pentru masă, în Suceava îți recomand Hanul Domnesc, cu mâncare tradițională.', place('hanul-domnesc')),
  ]],
  ['indian-iasi', 42, [
    user('Am poftă de mâncare indiană, sunt în Iași'),
    ai('În Iași ai Masala House, pe Str. Cuza Vodă, cu mâncare indiană.', place('masala-house')),
    user('E deschis duminica?'),
    ai('Nu știu programul de la Masala House. Le poți scrie direct din pagina localului, cu butonul „Rezervă pe WhatsApp”.', place('masala-house')),
  ]],
  ['delta-tulcea', 120, [
    user("I'm going to Tulcea for the Danube Delta. Where should I eat?"),
    ai('In Tulcea, Delta Fish, on Str. Isaccei, serves fish dishes, a good fit after a day in the Delta.', place('delta-fish')),
  ]],
  ['matcha-cluj', 8, [
    user('Unde găsesc matcha în Cluj-Napoca?'),
    bot('Din păcate, nu am găsit niciun local care să corespundă criteriilor tale: din Cluj-Napoca, care servește matcha.'),
    user('Atunci un ceai bun?'),
    ai('Pentru ceai în Cluj-Napoca, încearcă Ceainăria Sub Tei, de pe Str. Eroilor.', place('ceainaria-sub-tei')),
  ]],
];

// Checks, so that a mistake fails here and not in the SQL Editor.
const keys = new Set();
for (const [key, days, messages, renamed] of conversations) {
  if (keys.has(key)) throw new Error(`Twice: ${key}`);
  keys.add(key);
  if (!Number.isInteger(days) || days < 0) throw new Error(`${key}: days`);
  if (messages[0].a !== 'user') throw new Error(`${key}: starts with the user`);
  const title = renamed ?? titleFrom(messages[0].t);
  if (title.length < 1 || title.length > 80) throw new Error(`${key}: title`);
  for (const message of messages) {
    if (message.t.length < 1 || message.t.length > 4000) throw new Error(`${key}: ${message.t}`);
    if (message.a === 'user' && (message.p || message.c)) throw new Error(`${key}: user action`);
  }
}

// --- The SQL ----------------------------------------------------------------------

const lines = [];
const out = (text) => lines.push(text);

out(`-- Top Places: ${conversations.length} conversations with the assistant, in Romanian,
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

insert into seed_conversations (key, title, days, messages) values`);
out(conversations.map(([key, days, messages, renamed]) =>
  `  (${sql(key)}, ${sql(renamed ?? titleFrom(messages[0].t))}, ${days},\n` +
  `    ${sql(JSON.stringify(messages))})`).join(',\n') + ';');
out(`
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
order by u.email;`);

fs.writeFileSync(path.join(__dirname, '..', 'seed_conversations.sql'), lines.join('\n') + '\n');

fs.writeFileSync(path.join(__dirname, '..', 'seed_conversations_remove.sql'),
  `-- Top Places: takes out the conversations of seed_conversations.sql, with
-- their messages. The conversations people had themselves stay. Made by
-- supabase/tools/generate_seed_conversations.js.

delete from public.conversations as c
where c.id in (
  select md5(c.user_id::text || '/' || key)::uuid
  from unnest(array[
${conversations.map(([key]) => `    ${sql(key)}`).join(',\n')}
  ]) as key
);
`);

console.log(`${conversations.length} conversations written.`);
