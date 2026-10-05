// Writes ../seed_demo.sql and ../seed_demo_remove.sql: many places across
// Romania and many reviews, for a demo that looks lived in. The random
// choices come from a fixed seed, so the files are the same every time.
//
//   node supabase/tools/generate_seed_demo.js
const fs = require('fs');
const path = require('path');

// --- Random, but always the same -------------------------------------------

// mulberry32: a small generator with a fixed seed.
let state = 20261006;
function random() {
  state = (state + 0x6d2b79f5) | 0;
  let t = Math.imul(state ^ (state >>> 15), 1 | state);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}
const pick = (list) => list[Math.floor(random() * list.length)];
const between = (min, max) => min + random() * (max - min);
const whole = (min, max) => Math.floor(between(min, max + 1));
/** A number around [mean], from a normal distribution. */
function normal(mean, spread) {
  const u = 1 - random();
  const v = random();
  return mean + spread * Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
}
function uuid() {
  const bytes = Array.from({ length: 16 }, () => whole(0, 255));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = bytes.map((b) => b.toString(16).padStart(2, '0')).join('');
  return [hex.slice(0, 8), hex.slice(8, 12), hex.slice(12, 16), hex.slice(16, 20), hex.slice(20)].join('-');
}
const slug = (text) =>
  text.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()
    .replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const sql = (value) => (value == null ? 'null' : `'${String(value).replace(/'/g, "''")}'`);

// --- The data ------------------------------------------------------------------

const cities = Object.fromEntries(
  JSON.parse(fs.readFileSync(path.join(__dirname, '..', '..', 'assets', 'data', 'romanian_cities.json'), 'utf8'))
    .map((city) => [city.name, city]),
);

const photo = (id) => `https://images.unsplash.com/photo-${id}`;

// What each kind of place looks like: photos, and descriptions in English
// and Romanian.
const kinds = {
  coffee: {
    photos: ['1501339847302-ac426a4a7cbb', '1554118811-1e0d58224f24', '1495474472287-4d71bcdd2085',
      '1521017432531-fbd92d768814', '1498804103079-a6351b050096', '1511920170033-f8396924c348',
      '1442512595331-e89e73853f31', '1509042239860-f550ce710b93'],
    text: [
      ['Specialty coffee roasted in small batches, with a calm room for reading or work.',
        'Cafea de specialitate prăjită în loturi mici, într-o sală liniștită pentru citit sau lucru.'],
      ['Espresso, filter coffee and home-made cakes, served by baristas who know their beans.',
        'Espresso, cafea la filtru și prăjituri de casă, servite de bariști care își cunosc boabele.'],
      ['A small café with big windows, good flat whites and a few seats in the sun.',
        'O cafenea mică, cu ferestre mari, flat white bun și câteva locuri în soare.'],
    ],
  },
  tea: {
    photos: ['1445116572660-236099ec97a0'],
    text: [
      ['Over forty teas from all over the world, served slowly, in a quiet room with cushions.',
        'Peste patruzeci de ceaiuri din toată lumea, servite fără grabă, într-o cameră liniștită cu perne.'],
      ['A tea house with board games, soft music and home-made biscuits.',
        'O ceainărie cu jocuri de societate, muzică încet și biscuiți de casă.'],
    ],
  },
  italian: {
    photos: ['1563379926898-05f4575a45d8', '1414235077428-338989a2e8c0', '1537047902294-62a40c20a6ae'],
    text: [
      ['Hand-made pasta and slow-cooked sauces, with a short list of Italian wines.',
        'Paste făcute în casă și sosuri gătite îndelung, cu o listă scurtă de vinuri italienești.'],
      ['A family trattoria with recipes from Tuscany and tiramisu made every morning.',
        'O trattorie de familie cu rețete din Toscana și tiramisu făcut în fiecare dimineață.'],
    ],
  },
  pizza: {
    photos: ['1513104890138-7c749659a591', '1565299624946-b28f40a0ae38', '1574071318508-1cdbab80d002',
      '1458642849426-cfb724f15ef7', '1506354666786-959d6d497f1a'],
    text: [
      ['Neapolitan pizza from a wood-fired oven, with a thin base and puffy crust.',
        'Pizza napoletană la cuptor cu lemne, cu blat subțire și margini pufoase.'],
      ['Pizza by the slice or whole, with dough left to rise for 48 hours.',
        'Pizza la felie sau întreagă, cu aluat lăsat la dospit 48 de ore.'],
    ],
  },
  sushi: {
    photos: ['1579871494447-9811cf80d66c', '1553621042-f6e147245754'],
    text: [
      ['Fresh sushi and sashimi made in front of you, at a long wooden counter.',
        'Sushi și sashimi proaspete, făcute sub ochii tăi, la un bar lung din lemn.'],
      ['Japanese rolls, poke bowls and green tea, in a minimalist room.',
        'Rulouri japoneze, poke bowls și ceai verde, într-o sală minimalistă.'],
    ],
  },
  ramen: {
    photos: ['1569718212165-3a8278d5f624', '1585032226651-759b368d7246', '1504674900247-0877df9cc836'],
    text: [
      ['Ramen with broth simmered for hours, gyoza and cold Japanese beer.',
        'Ramen cu bulion fiert ore întregi, gyoza și bere japoneză rece.'],
      ['Steaming noodle soups and spicy bowls, quick and filling after work.',
        'Supe aburinde cu tăiței și boluri picante, rapide și sățioase după program.'],
    ],
  },
  vietnamese: {
    photos: ['1585032226651-759b368d7246', '1504674900247-0877df9cc836'],
    text: [
      ['Pho with fresh herbs, crispy spring rolls and Vietnamese iced coffee.',
        'Pho cu ierburi proaspete, rulouri de primăvară crocante și cafea vietnameză cu gheață.'],
    ],
  },
  romanian: {
    photos: ['1529042410759-befb1204b468', '1552566626-52f8b828add9', '1555396273-367ea4eb4db5'],
    text: [
      ['Romanian food like at grandma’s: sour soups, sarmale with polenta and papanași.',
        'Mâncare românească ca la bunica: ciorbe, sarmale cu mămăligă și papanași.'],
      ['Grilled mici, traditional stews and local wines, in a courtyard with long tables.',
        'Mici la grătar, tocănițe tradiționale și vinuri locale, într-o curte cu mese lungi.'],
    ],
  },
  bistro: {
    photos: ['1533777857889-4be7c70b33f7', '1517248135467-4c7edcad34c4', '1505275350441-83dcda8eeef5',
      '1555396273-367ea4eb4db5'],
    text: [
      ['A modern bistro with a menu that changes with the seasons and a good wine list.',
        'Un bistro modern, cu un meniu care se schimbă după anotimp și o listă bună de vinuri.'],
      ['Lunch menu on weekdays, slow dinners in the evening, all made from local produce.',
        'Meniu de prânz în timpul săptămânii, cine fără grabă seara, totul din produse locale.'],
    ],
  },
  brunch: {
    photos: ['1528207776546-365bb710ee93', '1484723091739-30a097e8f929', '1525351484163-7529414344d8',
      '1424847651672-bf20a4b0982b'],
    text: [
      ['All-day brunch: eggs Benedict, fluffy pancakes and fresh orange juice.',
        'Brunch toată ziua: ouă Benedict, clătite pufoase și suc proaspăt de portocale.'],
      ['Avocado toast, granola bowls and good coffee, in a bright room full of plants.',
        'Toast cu avocado, boluri cu granola și cafea bună, într-o sală luminoasă plină de plante.'],
    ],
  },
  bakery: {
    photos: ['1525351484163-7529414344d8', '1565958011703-44f9829ba187'],
    text: [
      ['Sourdough bread, butter croissants and cinnamon rolls, baked every morning.',
        'Pâine cu maia, cornuri cu unt și rulouri cu scorțișoară, coapte în fiecare dimineață.'],
    ],
  },
  dessert: {
    photos: ['1565958011703-44f9829ba187', '1484723091739-30a097e8f929'],
    text: [
      ['Artisan gelato and cakes made in house, with seasonal fruit.',
        'Înghețată artizanală și prăjituri făcute în casă, cu fructe de sezon.'],
      ['A pastry shop with French cakes, macarons and hot chocolate.',
        'O cofetărie cu prăjituri franțuzești, macarons și ciocolată caldă.'],
    ],
  },
  vegan: {
    photos: ['1546069901-ba9599a7e63c', '1540189549336-e6e99c3679fe', '1512621776951-a57141f2eefd',
      '1550989460-0adf9ea622e2'],
    text: [
      ['Plant-based bowls, soups and burgers, with gluten-free options every day.',
        'Boluri, supe și burgeri pe bază de plante, cu opțiuni fără gluten în fiecare zi.'],
      ['Colourful vegan food made from local vegetables, and cold-pressed juices.',
        'Mâncare vegană colorată din legume locale și sucuri presate la rece.'],
    ],
  },
  burger: {
    photos: ['1568901346375-23c9450c58cd', '1550547660-d9450f859349', '1571091718767-18b5b1457add',
      '1466978913421-dad2ebd01d17'],
    text: [
      ['Smash burgers from local beef, crispy fries and milkshakes.',
        'Burgeri smash din carne de vită locală, cartofi crocanți și milkshake-uri.'],
      ['Juicy burgers in brioche buns, with a vegetarian one on every menu.',
        'Burgeri suculenți în chifle brioșă, cu unul vegetarian în fiecare meniu.'],
    ],
  },
  steak: {
    photos: ['1600891964092-4316c288032e', '1544025162-d76694265947', '1600565193348-f74bd3c7ccdf'],
    text: [
      ['Dry-aged steaks cooked over charcoal, with sides to share.',
        'Fripturi maturate, gătite pe jar de cărbune, cu garnituri de împărțit.'],
      ['A grill house with ribs, steaks and a big terrace for summer evenings.',
        'Un grill cu coaste, fripturi și o terasă mare pentru serile de vară.'],
    ],
  },
  seafood: {
    photos: ['1559339352-11d035aa65de', '1414235077428-338989a2e8c0'],
    text: [
      ['Fresh fish and seafood, mussels in white wine and a view of the water.',
        'Pește proaspăt și fructe de mare, midii în vin alb și vedere spre apă.'],
      ['Fish soup from the Danube Delta, grilled fish and cold white wine.',
        'Ciorbă de pește din Delta Dunării, pește la grătar și vin alb rece.'],
    ],
  },
  greek: {
    photos: ['1559339352-11d035aa65de', '1540189549336-e6e99c3679fe'],
    text: [
      ['A Greek taverna with gyros, grilled octopus and a big Greek salad.',
        'O tavernă grecească cu gyros, caracatiță la grătar și salată grecească mare.'],
    ],
  },
  mexican: {
    photos: ['1424847651672-bf20a4b0982b', '1504674900247-0877df9cc836'],
    text: [
      ['Tacos, burritos and fresh guacamole, with Mexican music and margaritas.',
        'Tacos, burritos și guacamole proaspăt, cu muzică mexicană și margarita.'],
    ],
  },
  indian: {
    photos: ['1504674900247-0877df9cc836', '1585032226651-759b368d7246'],
    text: [
      ['Indian curries, naan from a tandoor oven and lassi, as spicy as you like.',
        'Curry indian, naan din cuptorul tandoor și lassi, cât de iute vrei.'],
    ],
  },
  lebanese: {
    photos: ['1512621776951-a57141f2eefd', '1546069901-ba9599a7e63c'],
    text: [
      ['Hummus, falafel and grilled meat from Lebanon, with mezze to share.',
        'Hummus, falafel și carne la grătar din Liban, cu mezze de împărțit.'],
    ],
  },
  pub: {
    photos: ['1514933651103-005eec06c04b', '1470337458703-46ad1756a187'],
    text: [
      ['Craft beer on tap from Romanian breweries, quiz nights and live sports.',
        'Bere artizanală la draft de la berării românești, seri de quiz și sport live.'],
      ['A cosy pub with local beers, burgers and concerts at the weekend.',
        'Un pub primitor, cu beri locale, burgeri și concerte în weekend.'],
    ],
  },
  wine: {
    photos: ['1510812431401-41d2bd2722f3', '1470337458703-46ad1756a187'],
    text: [
      ['A wine bar with over 200 Romanian labels, cheese boards and wine tastings.',
        'Un wine bar cu peste 200 de etichete românești, platouri cu brânzeturi și degustări.'],
    ],
  },
  cocktails: {
    photos: ['1497534446932-c925b458314e', '1470337458703-46ad1756a187'],
    text: [
      ['Cocktails and fresh juices by the sea, with music until late.',
        'Cocktailuri și sucuri proaspete lângă mare, cu muzică până târziu.'],
    ],
  },
  juice: {
    photos: ['1497534446932-c925b458314e', '1546069901-ba9599a7e63c'],
    text: [
      ['Smoothies, cold-pressed juices and acai bowls, with no added sugar.',
        'Smoothie-uri, sucuri presate la rece și boluri acai, fără zahăr adăugat.'],
    ],
  },
};

// A little more about the place, added to some descriptions.
const extras = [
  ['A quiet terrace in summer.', 'O terasă liniștită vara.'],
  ['Live music on Friday evenings.', 'Muzică live vineri seara.'],
  ['Pets are welcome.', 'Animalele de companie sunt binevenite.'],
  ['Open until late.', 'Deschis până târziu.'],
  ['A student discount on weekdays.', 'Reducere pentru studenți în timpul săptămânii.'],
  ['Good Wi-Fi and plugs at every table.', 'Wi-Fi bun și prize la fiecare masă.'],
  ['A corner for children.', 'Un colț pentru copii.'],
  ['Booking is a good idea at weekends.', 'În weekend e bine să rezervi.'],
];

// The places: name, city, kind, street, and whether the test operator owns
// it (so that the operator has reviews to accept).
const places = [
  ['Trattoria Nonna Lucia', 'București', 'italian', 'Str. Covaci'],
  ['Sushi Kaze', 'București', 'sushi', 'Calea Dorobanților'],
  ['Ramen Koen', 'București', 'ramen', 'Str. Popa Nan'],
  ['Cafeneaua Artiștilor', 'București', 'coffee', 'Str. Lipscani'],
  ['La Mici și Bere', 'București', 'romanian', 'Str. Franceză'],
  ['Taverna Olimpia', 'București', 'greek', 'Calea Floreasca'],
  ['Green Spoon', 'București', 'vegan', 'Bd. Dacia', true],
  ['Brunch & Co', 'București', 'brunch', 'Calea Victoriei'],
  ['The Cellar Wine Bar', 'București', 'wine', 'Str. Smârdan'],
  ['Roastery Someș', 'Cluj-Napoca', 'coffee', 'Str. Memorandumului'],
  ['Casa cu Grădină', 'Cluj-Napoca', 'romanian', 'Str. Napoca'],
  ['Forno Vecchio', 'Cluj-Napoca', 'pizza', 'Piața Muzeului'],
  ['Taco Loco', 'Cluj-Napoca', 'mexican', 'Str. Iuliu Maniu', true],
  ['Ceainăria Sub Tei', 'Cluj-Napoca', 'tea', 'Str. Eroilor'],
  ['Burger Factory', 'Cluj-Napoca', 'burger', 'Bd. 21 Decembrie 1989'],
  ['Bistro Botanic', 'Cluj-Napoca', 'bistro', 'Str. Republicii'],
  ['Bastion Craft Beer', 'Timișoara', 'pub', 'Str. Hector'],
  ['Pho Saigon', 'Timișoara', 'vietnamese', 'Str. Alba Iulia'],
  ['La Ceaun Bănățean', 'Timișoara', 'romanian', 'Str. Mercy'],
  ['Gelateria Bega', 'Timișoara', 'dessert', 'Splaiul Tudor Vladimirescu'],
  ['Steakhouse Unirii', 'Timișoara', 'steak', 'Piața Unirii'],
  ['Café Mercy', 'Timișoara', 'coffee', 'Str. Mercy', true],
  ['Bistro Copou', 'Iași', 'bistro', 'Bd. Carol I'],
  ['Masala House', 'Iași', 'indian', 'Str. Cuza Vodă'],
  ['Brutăria Moldovei', 'Iași', 'bakery', 'Str. Lăpușneanu'],
  ['Vinoteca Junimea', 'Iași', 'wine', 'Str. Arcu'],
  ['Smoothie Point', 'Iași', 'juice', 'Bd. Ștefan cel Mare', true],
  ['Pizzeria Palas', 'Iași', 'pizza', 'Str. Palat'],
  ['Bistroul din Piața Sfatului', 'Brașov', 'bistro', 'Piața Sfatului'],
  ['Pilsner Haus', 'Brașov', 'pub', 'Str. Republicii'],
  ['Cafeneaua de sub Tâmpa', 'Brașov', 'coffee', 'Str. Mureșenilor'],
  ['Pizzeria Schei', 'Brașov', 'pizza', 'Str. Prundului'],
  ['Ciorbe și Plăcinte', 'Brașov', 'romanian', 'Str. Michael Weiss'],
  ['Kaffeehaus Hermann', 'Sibiu', 'coffee', 'Piața Mică'],
  ['Crama Sibiană', 'Sibiu', 'romanian', 'Piața Mare'],
  ['Sushi Nomi', 'Sibiu', 'sushi', 'Str. Nicolae Bălcescu'],
  ['Brunch Corner', 'Sibiu', 'brunch', 'Str. Avram Iancu', true],
  ['Vinul Turnului', 'Sibiu', 'wine', 'Piața Mică'],
  ['Pescăria Farului', 'Constanța', 'seafood', 'Bd. Tomis'],
  ['Taverna Mykonos', 'Constanța', 'greek', 'Str. Traian'],
  ['Sunset Beach Bar', 'Constanța', 'cocktails', 'Bd. Mamaia'],
  ['Café Cazino', 'Constanța', 'coffee', 'Bd. Regina Elisabeta'],
  ['Burger Port', 'Constanța', 'burger', 'Str. Mircea cel Bătrân', true],
  ['Bistro Art Nouveau', 'Oradea', 'bistro', 'Str. Republicii'],
  ['Cedrus', 'Oradea', 'lebanese', 'Piața Unirii'],
  ['Patiseria Crișana', 'Oradea', 'dessert', 'Str. Vasile Alecsandri'],
  ['Casa Băniei Bistro', 'Craiova', 'bistro', 'Str. Matei Basarab'],
  ['Napoli Express', 'Craiova', 'pizza', 'Calea Unirii'],
  ['Cafeneaua Englezească', 'Craiova', 'coffee', 'Str. Lipscani'],
  ['Faleza Fish House', 'Galați', 'seafood', 'Str. Portului'],
  ['Vegan Garden', 'Galați', 'vegan', 'Str. Domnească'],
  ['Ceainăria Prahova', 'Ploiești', 'tea', 'Bd. Republicii'],
  ['Grill Station', 'Ploiești', 'steak', 'Str. Mihai Bravu'],
  ['Cafeneaua Teatrului', 'Arad', 'coffee', 'Bd. Revoluției'],
  ['Trattoria Mamma Mia', 'Arad', 'italian', 'Str. Mețianu'],
  ['Bistro Trandafirilor', 'Târgu Mureș', 'bistro', 'Piața Trandafirilor'],
  ['Udon Bar', 'Târgu Mureș', 'ramen', 'Str. Bolyai'],
  ['Hanul Domnesc', 'Suceava', 'romanian', 'Str. Curtea Domnească'],
  ['Cetatea Coffee', 'Alba Iulia', 'coffee', 'Str. Mihai Viteazu'],
  ['Old Mine Pub', 'Baia Mare', 'pub', 'Piața Libertății'],
  ['Dunărea Bistro', 'Brăila', 'seafood', 'Str. Mihai Eminescu'],
  ['Burger & Beer', 'Pitești', 'burger', 'Str. Victoriei'],
  ['Delta Fish', 'Tulcea', 'seafood', 'Str. Isaccei'],
  ['Kyoto Sushi', 'Bacău', 'sushi', 'Str. Nicolae Bălcescu'],
];

// The 20 places of the original app: the kind of food, for the reviews,
// and the rating they had, which their reviews stay close to. Three keep
// no reviews, to show the rating of the old app.
const originals = [
  ['the-literary-coffee-house-citadel', 'coffee', 4.8],
  ['restaurant-the-old-inn', 'romanian', 4.5],
  ['the-global-wok-bistro', 'ramen', 4.2],
  ['cafe-new-world', 'brunch', 4.7],
  ['pizzeria-il-drago', 'pizza', 4.6],
  ['vegan-restaurant-the-green-garden', 'vegan', 4.9],
  ['coffee-shop-by-the-faculty', 'coffee', 4.0],
  ['burger-shack', 'burger', 4.4],
  ['tea-house-sunset', 'tea', 4.7, 'no reviews'],
  ['restaurant-pescaresc-the-sea', 'seafood', 4.5],
  ['bistro-at-the-forest', 'bistro', 4.3],
  ['gaming-coffee-shop-restart', 'coffee', 4.1],
  ['trattoria-bella-vita', 'italian', 4.6],
  ['bread-and-coffee', 'bakery', 4.8, 'no reviews'],
  ['fast-food-doner-king', 'burger', 3.9],
  ['restaurant-the-citadel', 'romanian', 4.4, 'no reviews'],
  ['smoothie-bar-energy', 'juice', 4.9],
  ['restaurant-grandma-s-house', 'romanian', 4.3],
  ['irish-pub-the-shamrock', 'pub', 4.5],
  ['coffee-shop-zen', 'coffee', 4.7],
];

// The reviewers: names from Romania and a few from abroad. They only write
// reviews: their accounts have no password and cannot sign in.
const firstNames = ['Andrei', 'Maria', 'Elena', 'Mihai', 'Ioana', 'Alexandru', 'Ana', 'Cristian',
  'Diana', 'Gabriel', 'Irina', 'Bogdan', 'Raluca', 'Vlad', 'Oana', 'Radu', 'Simona', 'Florin',
  'Roxana', 'Adrian', 'Larisa', 'Paul', 'Bianca', 'Sorin', 'Teodora', 'Daniel', 'Alina', 'Ștefan',
  'Corina', 'Tudor', 'Medeea', 'Victor', 'Iulia', 'Horia', 'Denisa', 'Matei', 'Sabina', 'Lucian',
  'Carmen', 'Emil'];
const lastNames = ['Popescu', 'Ionescu', 'Popa', 'Dumitrescu', 'Stan', 'Stoica', 'Gheorghe', 'Matei',
  'Ciobanu', 'Rusu', 'Munteanu', 'Constantinescu', 'Marin', 'Florea', 'Lungu', 'Dobre', 'Barbu',
  'Nistor', 'Moldovan', 'Toma', 'Sârbu', 'Pavel', 'Cristea', 'Neagu', 'Enache', 'Mocanu', 'Diaconu',
  'Vasile'];
const foreignNames = [['James', 'Smith'], ['Sophie', 'Müller'], ['Lukas', 'Novak'], ['Giulia', 'Rossi'],
  ['Pierre', 'Dubois'], ['Anna', 'Kowalska'], ['Tom', 'Brown'], ['Emma', 'Johansson'],
  ['Marco', 'Bianchi'], ['Sarah', 'Miller'], ['David', 'Cohen'], ['Laura', 'García']];

// What reviewers write, by stars, in Romanian and English.
const comments = {
  5: {
    ro: ['Totul a fost perfect, de la primire până la desert.', 'Cel mai bun loc din zonă, revin cu drag.',
      'Personal extrem de amabil și mâncare excelentă.', 'Atmosferă superbă, porții generoase, prețuri corecte.',
      'Am venit la recomandarea unui prieten și nu am regretat deloc.',
      'Un loc în care te simți ca acasă. Recomand cu încredere!', 'Servire rapidă, totul proaspăt și foarte gustos.',
      'Merită fiecare leu. Abia aștept să revin.', 'Experiență de 10 pe linie. Bravo echipei!',
      'Am sărbătorit o aniversare aici și a fost impecabil.',
      'Detaliile fac diferența: muzica, lumina, ospitalitatea.', 'De departe preferatul meu din oraș.',
      'Gust autentic și ingrediente de calitate.', 'Ne-am simțit minunat, mulțumim!'],
    en: ['Absolutely loved it, from the welcome to dessert.', 'Best spot in the area, we will be back.',
      'Friendly staff and outstanding food.', 'Great atmosphere, generous portions, fair prices.',
      'A hidden gem. Highly recommended!', 'Everything was fresh and full of flavour.',
      'Worth every penny. Can’t wait to come back.', 'Perfect evening, thank you!'],
  },
  4: {
    ro: ['Foarte bun, doar că a durat puțin servirea.', 'Mâncare gustoasă, locul e cam aglomerat în weekend.',
      'Îmi place mult, aș mai adăuga câteva opțiuni vegetariene.', 'Raport calitate-preț bun. Revin sigur.',
      'Personal drăguț, atmosferă plăcută, desertul putea fi mai bun.',
      'O experiență bună per total, recomand rezervarea din timp.',
      'Locație frumoasă, muzica puțin prea tare pentru gustul meu.',
      'Porții bune și gustoase, parcare greu de găsit.', 'Aproape perfect, aș mai lucra la viteza servirii.',
      'Merită încercat, mai ales seara.', 'Calitate constantă de fiecare dată când am venit.'],
    en: ['Very good, service was a bit slow though.', 'Tasty food, gets crowded on weekends.',
      'Good value for money. Will be back.', 'Nice place, music a little too loud for me.',
      'Almost perfect, booking ahead is a good idea.', 'Solid choice, consistent quality every time.'],
  },
  3: {
    ro: ['Decent, dar nimic special.', 'Mâncarea a fost ok, servirea lentă.',
      'Prețuri puțin cam mari pentru ce primești.', 'Atmosfera e frumoasă, mâncarea medie.',
      'Nu a fost rău, dar nici nu m-a impresionat.', 'Am așteptat mult la masă, în rest acceptabil.',
      'Unele preparate bune, altele uitabile.', 'Curat și liniștit, dar meniul e cam limitat.',
      'Ok pentru o oprire rapidă.'],
    en: ['Decent, but nothing special.', 'Food was okay, service was slow.', 'A bit pricey for what you get.',
      'Nice vibe, average food.', 'Fine for a quick stop.'],
  },
  2: {
    ro: ['Am așteptat aproape o oră pentru comandă.', 'Mâncarea a venit rece, iar ospătarul nu a părut interesat.',
      'Prea scump pentru porțiile mici.', 'Masa nu era curată când ne-am așezat.',
      'Dezamăgitor față de recenziile pe care le citisem.', 'Zgomot mare și servire haotică.',
      'Gustul a fost ok, dar comanda a fost greșită de două ori.'],
    en: ['Waited almost an hour for our order.', 'Food arrived cold and the staff seemed uninterested.',
      'Too expensive for small portions.', 'Disappointing compared to the reviews.'],
  },
  1: {
    ro: ['Cea mai proastă experiență din ultima vreme.', 'Nu recomand. Mâncare fără gust și personal nepoliticos.',
      'Ni s-a adus nota greșit și nimeni nu și-a cerut scuze.',
      'Am plecat fără să mâncăm, după 45 de minute de așteptare.', 'Igiena lasă de dorit.'],
    en: ['Worst experience in a long time.', 'Would not recommend. Bland food and rude staff.',
      'We left without eating after 45 minutes.'],
  },
};

// About the food itself, by kind: [good, bad], each [Romanian, English].
const aboutFood = {
  coffee: [['Cel mai bun flat white din oraș.', 'Best flat white in town.'],
    ['Cafeaua a venit călduță și amară.', 'The coffee came lukewarm and bitter.']],
  tea: [['Ceaiul oolong servit ca la carte, într-o liniște totală.', 'Oolong served by the book, in total quiet.'],
    ['Ceaiul era prea slab, iar ceainicul ciobit.', 'The tea was weak and the teapot chipped.']],
  italian: [['Carbonara făcută ca la carte, fără smântână.', 'Proper carbonara, no cream in sight.'],
    ['Pastele erau mult prea fierte.', 'The pasta was overcooked.']],
  pizza: [['Blatul e subțire și crocant, exact ca în Napoli.', 'Thin, crisp base, just like in Naples.'],
    ['Pizza a venit rece și cu prea puțin sos.', 'The pizza came cold, with too little sauce.']],
  sushi: [['Peștele e proaspăt, iar orezul perfect.', 'The fish is fresh and the rice perfect.'],
    ['Rulourile se desfăceau, orezul era tare.', 'The rolls fell apart and the rice was hard.']],
  ramen: [['Bulionul de ramen e bogat, se simte că fierbe ore întregi.', 'Rich ramen broth, you can tell it simmers for hours.'],
    ['Supa a fost prea sărată.', 'The soup was far too salty.']],
  vietnamese: [['Pho-ul e aromat și generos.', 'The pho is fragrant and generous.'],
    ['Rulourile de primăvară erau pline de ulei.', 'The spring rolls were greasy.']],
  romanian: [['Sarmalele cu mămăligă merită drumul.', 'The sarmale with polenta are worth the trip.'],
    ['Mâncarea a fost sărată și grasă.', 'The food was salty and greasy.']],
  bistro: [['Meniul de prânz e cea mai bună afacere din zonă.', 'The lunch menu is the best deal around.'],
    ['Porțiile sunt mici pentru preț.', 'Small portions for the price.']],
  brunch: [['Ouăle Benedict au fost perfecte.', 'The eggs Benedict were perfect.'],
    ['Am așteptat 40 de minute pentru clătite.', 'We waited 40 minutes for pancakes.']],
  bakery: [['Cornurile sunt făcute în casă și se simte.', 'The croissants are home-made and you can tell.'],
    ['Pâinea era de ieri.', 'The bread was a day old.']],
  dessert: [['Înghețata de fistic e de neratat.', 'The pistachio gelato is a must.'],
    ['Prăjiturile erau prea dulci.', 'The cakes were far too sweet.']],
  vegan: [['Bowl-ul cu tofu a fost surprinzător de sățios.', 'The tofu bowl was surprisingly filling.'],
    ['Porții mici pentru preț.', 'Small portions for the price.']],
  burger: [['Burgerul e suculent, cartofii crocanți.', 'Juicy burger, crispy fries.'],
    ['Carnea a fost prea făcută, chifla uscată.', 'Overcooked meat and a dry bun.']],
  steak: [['Friptura a fost gătită exact cum am cerut, medium rare.', 'The steak was done exactly as asked, medium rare.'],
    ['Friptura a venit mult prea făcută.', 'The steak came well overdone.']],
  seafood: [['Midiile în sos de vin alb au fost excelente.', 'The mussels in white wine were excellent.'],
    ['Peștele nu părea proaspăt.', 'The fish did not taste fresh.']],
  greek: [['Gyros generos și tzatziki proaspăt.', 'Generous gyros and fresh tzatziki.'],
    ['Caracatița era tare.', 'The octopus was rubbery.']],
  mexican: [['Tacos cu carnitas foarte gustoase.', 'Delicious carnitas tacos.'],
    ['Guacamole părea din borcan.', 'The guacamole tasted store-bought.']],
  indian: [['Curry-ul are exact cât trebuie de iuțeală.', 'The curry has just the right heat.'],
    ['Naan-ul a venit ars.', 'The naan came burnt.']],
  lebanese: [['Hummus-ul și falafelul sunt excelente.', 'Excellent hummus and falafel.'],
    ['Carnea de pe platou era uscată.', 'The meat on the platter was dry.']],
  pub: [['Bere artizanală bună și atmosferă relaxată.', 'Good craft beer and a relaxed vibe.'],
    ['Prea zgomotos ca să poți vorbi.', 'Too loud to talk.']],
  wine: [['Ne-au recomandat o Fetească Neagră excelentă.', 'They recommended an excellent Fetească Neagră.'],
    ['Vinul la pahar era oxidat.', 'The wine by the glass was oxidised.']],
  cocktails: [['Cocktailurile sunt creative, iar apusul e superb.', 'Creative cocktails and a stunning sunset.'],
    ['Cocktailurile erau mai mult gheață.', 'The cocktails were mostly ice.']],
  juice: [['Smoothie-urile sunt proaspete, fără zahăr adăugat.', 'Fresh smoothies with no added sugar.'],
    ['Sucul nu era proaspăt stors.', 'The juice was not freshly squeezed.']],
};

const rejectionReasons = ['Limbaj nepotrivit.', 'Nu e despre local.', 'Conține reclamă la alt local.',
  'Recenzie dublă.'];

// --- Making the rows ------------------------------------------------------------

const reviewers = [];
const usedEmails = new Set();
for (let i = 0; reviewers.length < 90; i++) {
  const foreign = i % 7 === 6;
  const [first, last] = foreign
    ? foreignNames[(i / 7 | 0) % foreignNames.length]
    : [pick(firstNames), pick(lastNames)];
  const email = `${slug(first)}.${slug(last)}@demo.ro`;
  if (usedEmails.has(email)) continue;
  usedEmails.add(email);
  // Most write in Romanian; the reviewers from abroad, and a few others, in
  // English.
  reviewers.push({ id: uuid(), email, first, last, english: foreign || random() < 0.12 });
}

const placeRows = [];
const seen = new Set();
for (const [name, city, kind, street, owned] of places) {
  const center = cities[city];
  if (!center) throw new Error(`No city ${city}`);
  const id = slug(name);
  if (seen.has(id)) throw new Error(`Twice: ${id}`);
  seen.add(id);
  const [en, ro] = pick(kinds[kind].text);
  const extra = random() < 0.6 ? pick(extras) : null;
  placeRows.push({
    id, name, city, kind, owned: Boolean(owned),
    address: `${street}, Nr. ${whole(1, 120)}, ${city}`,
    lat: +(center.lat + between(-0.008, 0.008)).toFixed(5),
    lng: +(center.lng + between(-0.012, 0.012)).toFixed(5),
    image: photo(pick(kinds[kind].photos)),
    description: extra ? `${en} ${extra[0]}` : en,
    descriptionRo: extra ? `${ro} ${extra[1]}` : ro,
    // How good the place is, around which its reviews fall: most good,
    // some poor.
    quality: 4.9 - 2.4 * Math.pow(random(), 2.2),
    // A few new places have no reviews yet, and show as "Nou".
    reviews: random() < 0.12 ? 0 : Math.round(3 + 72 * Math.pow(random(), 1.7)),
    createdDaysAgo: whole(30, 720),
  });
}
for (const place of placeRows) {
  for (const [label, value, min, max] of [['name', place.name, 2, 80], ['address', place.address, 3, 120],
    ['description', place.description, 10, 300], ['description_ro', place.descriptionRo, 10, 300]]) {
    if (value.trim().length < min || value.length > max) throw new Error(`${place.id}: ${label}`);
  }
  if (place.lat < 43.5 || place.lat > 48.5 || place.lng < 20 || place.lng > 30) throw new Error(place.id);
}

const reviewed = [
  ...placeRows.map((place) => ({ id: place.id, kind: place.kind, quality: place.quality, count: place.reviews })),
  ...originals.filter((o) => !o[3]).map(([id, kind, rating]) => ({
    id, kind, quality: rating, count: whole(8, 55),
  })),
];

const ratingRows = [];
for (const place of reviewed) {
  const authors = [...reviewers].sort(() => random() - 0.5).slice(0, Math.min(place.count, reviewers.length));
  const usedComments = new Set();
  for (const author of authors) {
    const stars = Math.max(1, Math.min(5, Math.round(normal(place.quality, 0.85))));
    let comment = null;
    if (random() < 0.72) {
      const language = author.english || random() < 0.1 ? 'en' : 'ro';
      const [good, bad] = aboutFood[place.kind];
      const food = stars >= 4 ? good : stars <= 2 ? bad : null;
      for (let attempt = 0; attempt < 5 && comment == null; attempt++) {
        const text = food && random() < 0.35
          ? food[language === 'ro' ? 0 : 1]
          : pick(comments[stars][language]);
        if (!usedComments.has(text)) comment = text;
      }
      if (comment) usedComments.add(comment);
    }
    // A few reviews wait for the operator or an admin, and a few were
    // rejected; the rest are public.
    const roll = random();
    const status = roll < 0.05 ? 'pending' : roll < 0.07 ? 'rejected' : 'approved';
    ratingRows.push({
      place: place.id, user: author.id, stars, comment, status,
      reason: status === 'rejected' ? pick(rejectionReasons) : null,
      days: whole(1, 540), hours: whole(0, 23),
    });
  }
}

// --- The SQL ----------------------------------------------------------------------

const ago = (days, hours = 0) => `now() - interval '${days} days ${hours} hours'`;
const lines = [];
const out = (text) => lines.push(text);

out(`-- Top Places: a large demo, ${placeRows.length} more places across Romania and ` +
  `${ratingRows.length} reviews by ${reviewers.length} people.`);
out(`-- Run it in the SQL Editor after 007_bilingual_places.sql, and after
-- conturi_test.sql if you use it: the test operator then owns a few of the
-- places and has reviews to accept. Running it again changes nothing.
--
-- Made by supabase/tools/generate_seed_demo.js: change that, not this file.
-- seed_demo_remove.sql takes it all out again.

begin;

-- 1. The reviewers. They only write reviews: without a password, their
-- accounts cannot sign in. A trigger makes their profiles, with the names.
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token
) values`);
out(reviewers.map((r) => `  ('00000000-0000-0000-0000-000000000000', '${r.id}', 'authenticated', 'authenticated', ` +
  `${sql(r.email)}, '', now(), '{"provider": "email", "providers": ["email"]}', ` +
  `${sql(JSON.stringify({ first_name: r.first, last_name: r.last }))}, now(), now(), '', '', '', '')`).join(',\n') +
  '\non conflict (id) do nothing;');

out(`
-- 2. The places, approved, in both languages.
insert into public.places (
  id, name, address, city, lat, lng, image_url, description, description_ro,
  status, owner_id, created_at
) values`);
out(placeRows.map((p) => `  (${sql(p.id)}, ${sql(p.name)}, ${sql(p.address)}, ${sql(p.city)}, ${p.lat}, ${p.lng}, ` +
  `${sql(p.image)}, ${sql(p.description)}, ${sql(p.descriptionRo)}, 'approved', ` +
  `${p.owned ? "(select id from public.profiles where email = 'operator@test.ro')" : 'null'}, ` +
  `${ago(p.createdDaysAgo)})`).join(',\n') + '\non conflict (id) do nothing;');

out(`
-- 3. The reviews, each written on its own day. The trigger that would stamp
-- them with today and send them to review waits meanwhile; the one that
-- keeps the averages up to date works as always.
alter table public.ratings disable trigger guard_rating;

insert into public.ratings (
  place_id, user_id, stars, comment, status, status_reason, created_at,
  updated_at
)
select place_id, user_id::uuid, stars, comment, status, status_reason,
  now() - make_interval(days => days, hours => hours),
  now() - make_interval(days => days, hours => hours)
from (values`);
out(ratingRows.map((r) => `  (${sql(r.place)},'${r.user}',${r.stars},${sql(r.comment)},'${r.status}',` +
  `${sql(r.reason)},${r.days},${r.hours})`).join(',\n'));
out(`) as review (
  place_id, user_id, stars, comment, status, status_reason, days, hours
)
on conflict (place_id, user_id) do nothing;`);

out(`
alter table public.ratings enable trigger guard_rating;

commit;

-- What was made, to check.
select
  (select count(*) from public.public_places) as public_places,
  (select count(*) from public.ratings where status = 'approved') as public_reviews,
  (select count(*) from public.ratings where status = 'pending') as waiting_reviews;
`);
fs.writeFileSync(path.join(__dirname, '..', 'seed_demo.sql'), lines.join('\n'));

fs.writeFileSync(path.join(__dirname, '..', 'seed_demo_remove.sql'), `-- Top Places: takes out the demo of seed_demo.sql. The reviewers go with
-- their reviews, and the places with theirs. Made by
-- supabase/tools/generate_seed_demo.js.

begin;

delete from auth.users where email like '%@demo.ro';

delete from public.places where id in (
${placeRows.map((p) => `  ${sql(p.id)}`).join(',\n')}
);

commit;
`);

console.log(`${placeRows.length} places, ${reviewers.length} reviewers, ${ratingRows.length} reviews ` +
  `(${ratingRows.filter((r) => r.status === 'pending').length} waiting, ` +
  `${ratingRows.filter((r) => r.status === 'rejected').length} rejected, ` +
  `${ratingRows.filter((r) => r.comment).length} with a message)`);
