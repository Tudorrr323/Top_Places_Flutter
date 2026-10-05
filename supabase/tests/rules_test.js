// Runs schema.sql on a real Postgres (PGlite) and checks every rule, acting
// as anonymous visitors, users, operators and admins the way Supabase does:
// SET ROLE anon/authenticated plus the request.jwt.claims setting.
const { PGlite } = require('@electric-sql/pglite');
const fs = require('fs');
const path = require('path');

let passed = 0;
let failed = 0;
function check(condition, name) {
  if (condition) {
    passed++;
    console.log('  ok   ' + name);
  } else {
    failed++;
    console.log('  FAIL ' + name);
  }
}

// The SQL files of the project, in the order they are run in Supabase.
const steps = [
  'schema.sql',
  '002_public_places.sql',
  '003_reviews_by_admins.sql',
  '004_ratings.sql',
  '005_reviews.sql',
  '006_admin_reviews.sql',
  '007_bilingual_places.sql',
  '008_conversations.sql',
];

// A new database with the first [count] steps run.
async function newDatabase(count = steps.length) {
  const db = new PGlite();
  await db.exec(fs.readFileSync(path.join(__dirname, 'supabase_env.sql'), 'utf8'));
  for (const step of steps.slice(0, count)) {
    await db.exec(fs.readFileSync(path.join(__dirname, '..', step), 'utf8'));
  }
  return db;
}

async function main() {
  const db = await newDatabase();

  async function signUp(email, firstName, lastName) {
    const result = await db.query(
      'insert into auth.users (email, raw_user_meta_data) values ($1, $2) returning id',
      [email, { first_name: firstName, last_name: lastName }],
    );
    return result.rows[0].id;
  }

  // Runs [sql] as the app would for [userId] (null: not signed in).
  async function as(userId, sql, params = []) {
    await db.exec('reset role');
    const claims = userId ? JSON.stringify({ sub: userId, role: 'authenticated' }) : '';
    await db.query("select set_config('request.jwt.claims', $1, false)", [claims]);
    await db.exec(userId ? 'set role authenticated' : 'set role anon');
    try {
      return await db.query(sql, params);
    } finally {
      await db.exec('reset role');
    }
  }

  async function fails(promise) {
    try {
      await promise;
      return false;
    } catch (error) {
      return true;
    }
  }

  // Runs [sql] as the SQL editor in the dashboard (postgres, no limits).
  const asOwner = (sql, params = []) => db.query(sql, params);

  const publicCount = async () =>
    Number((await as(null, 'select count(*) from public.places')).rows[0].count);

  console.log('Everyone');
  check((await publicCount()) === 20, 'sees the 20 seeded places');
  check(await fails(as(null, "update public.places set name = 'X'")), 'cannot edit places');
  check(await fails(as(null, 'select * from public.profiles')), 'cannot read profiles');

  console.log('Sign-up');
  const ana = await signUp('ana@test.ro', 'Ana', 'Pop');
  const ion = await signUp('ion@test.ro', 'Ion', 'Ionescu');
  const boss = await signUp('boss@test.ro', 'Maria', 'Admin');
  let row = (await as(ana, 'select * from public.profiles')).rows;
  check(row.length === 1 && row[0].first_name === 'Ana' && row[0].role === 'user',
    'a new account gets a profile with its name and the user role');

  console.log('User');
  await as(ana, "update public.profiles set role = 'admin', first_name = 'Anca' where id = $1", [ana]);
  row = (await as(ana, 'select role, first_name from public.profiles')).rows[0];
  check(row.role === 'user' && row.first_name === 'Anca', 'can rename herself but not make herself admin');
  await as(ana, "update public.profiles set suspended_reason = 'x' where id = $1", [ana]);
  row = (await as(ana, 'select suspended_at from public.profiles')).rows[0];
  check(row.suspended_at === null, 'cannot touch suspension fields');
  check((await as(ana, 'select * from public.profiles where id = $1', [ion])).rows.length === 0,
    "cannot read someone else's profile");
  check(await fails(as(ana,
    "insert into public.places (name, address, city, lat, lng, description, description_ro) values ('Test', 'Str. A, 1', 'Iași', 47.1, 27.5, 'A description long enough.', 'O descriere destul de lungă.')")),
    'cannot add places');
  await as(ana, "update public.profiles set operator_request = 'pending' where id = $1", [ana]);
  row = (await as(ana, 'select operator_request from public.profiles')).rows[0];
  check(row.operator_request === 'pending', 'can ask to become an operator');

  console.log('Admin');
  await asOwner("update public.profiles set role = 'admin' where email = 'boss@test.ro'");
  check((await as(boss, 'select * from public.profiles')).rows.length === 3, 'sees every profile');
  await as(boss, "update public.profiles set role = 'operator' where id = $1", [ana]);
  row = (await as(ana, 'select role, operator_request from public.profiles')).rows[0];
  check(row.role === 'operator' && row.operator_request === null, 'approves an operator, which clears the request');
  await as(boss, "update public.profiles set last_name = 'Popescu' where id = $1", [ion]);
  row = (await as(ion, 'select last_name from public.profiles')).rows[0];
  check(row.last_name === 'Popescu', "edits a user's name");
  check(await fails(as(boss, "update public.profiles set suspended_reason = 'x' where id = $1", [boss])),
    'cannot suspend herself');
  check(await fails(as(boss, "update public.profiles set role = 'user' where id = $1", [boss])),
    'cannot change her own role');

  console.log('Operator');
  const inserted = await as(ana,
    "insert into public.places (name, address, city, lat, lng, description, description_ro, status, rating) " +
    "values ('Ceainăria Ana', 'Str. Lăpușneanu, Nr. 3, Iași', 'Iași', 47.16, 27.58, 'Good tea and quiet, near the centre.', 'Ceai bun și liniște, aproape de centru.', 'approved', 5) " +
    'returning id, status, rating, owner_id');
  const place = inserted.rows[0];
  check(place.status === 'pending' && place.rating === null && place.owner_id === ana,
    'adds a place, which waits for approval with no rating');
  check((await publicCount()) === 20, 'a pending place is not public');
  check((await as(ana, 'select * from public.places where id = $1', [place.id])).rows.length === 1,
    'the owner sees her pending place');
  await as(ana, "update public.places set status = 'approved' where id = $1", [place.id]);
  row = (await as(ana, 'select status from public.places where id = $1', [place.id])).rows[0];
  check(row.status === 'pending', 'cannot approve her own place');
  check((await as(ana, "update public.places set name = 'X' where id = 'cafe-new-world' returning id")).rows.length === 0,
    "cannot edit someone else's place");

  console.log('Moderating places');
  check(await fails(as(boss, "update public.places set status = 'rejected' where id = $1", [place.id])),
    'rejecting without a reason fails');
  await as(boss, "update public.places set status = 'approved' where id = $1", [place.id]);
  check((await publicCount()) === 21, 'an approved place becomes public');
  await as(ion, 'insert into public.ratings (place_id, stars) values ($1, 4)', [place.id]);
  await as(ana, "update public.ratings set status = 'approved' where place_id = $1", [place.id]);
  await as(ana, "update public.places set description = 'Ceai bun, liniște și prăjituri de casă.' where id = $1", [place.id]);
  row = (await as(ana, 'select status, rating from public.places where id = $1', [place.id])).rows[0];
  check(row.status === 'pending' && Number(row.rating) === 4, "the owner's edit goes back to review and keeps the rating");
  check((await publicCount()) === 20, 'and is hidden until approved again');
  await as(boss, "update public.places set status = 'approved' where id = $1", [place.id]);
  await as(boss, "update public.places set status = 'suspended', status_reason = 'Reclamații repetate' where id = 'burger-shack'");
  check((await publicCount()) === 20, 'a suspended place is hidden');
  check((await as(boss, "update public.places set name = 'Burger Shack 2' where id = 'burger-shack' returning id")).rows.length === 1,
    'the admin still edits a suspended place');
  await as(boss, "update public.places set status = 'approved' where id = 'burger-shack'");
  row = (await as(null, "select status_reason from public.places where id = 'burger-shack'")).rows[0];
  check(row && row.status_reason === null, 'approving again clears the reason');

  console.log('Suspending an operator');
  check((await publicCount()) === 21, 'before: 21 public places');
  await as(boss, "update public.profiles set suspended_reason = 'Date false' where id = $1", [ana]);
  row = (await as(ana, 'select suspended_at, suspended_reason from public.profiles')).rows[0];
  check(row.suspended_at !== null && row.suspended_reason === 'Date false', 'she sees that she is suspended, and why');
  check((await publicCount()) === 20, "her approved place is hidden from everyone");
  check((await as(ana, 'select * from public.places where owner_id = $1', [ana])).rows.length === 1,
    'she still sees her own place');
  check((await as(ana, "update public.places set name = 'Y' where id = $1 returning id", [place.id])).rows.length === 0,
    'she cannot edit it');
  check(await fails(as(ana,
    "insert into public.places (name, address, city, lat, lng, description, description_ro) values ('Alt loc', 'Str. B, 2', 'Iași', 47.1, 27.5, 'A description long enough.', 'O descriere destul de lungă.')")),
    'she cannot add places');
  check((await as(ana, "update public.profiles set first_name = 'Z' returning id")).rows.length === 0,
    'she cannot edit her profile');
  check(await fails(as(boss, "update public.profiles set suspended_reason = '  ' where id = $1", [ion])),
    'suspending without a reason fails');
  await as(boss, 'update public.profiles set suspended_reason = null where id = $1', [ana]);
  check((await publicCount()) === 21, 'reactivated: her place is public again');

  console.log('The public list (public_places)');
  const publicView = async (userId) =>
    Number((await as(userId, 'select count(*) from public.public_places')).rows[0].count);
  check((await publicView(null)) === 21, 'everyone sees the 21 approved places');
  await as(ana, "update public.places set description = 'Ceai bun, liniște și cozonac de casă.' where id = $1", [place.id]);
  const adminReads = Number((await as(boss, 'select count(*) from public.places')).rows[0].count);
  check(adminReads === 21 && (await publicView(boss)) === 20,
    'an admin reads every place, but the public list hides the one under review');
  await as(boss, "update public.places set status = 'approved', rating = 1 where id = $1", [place.id]);
  row = (await as(null, 'select rating, rating_count from public.public_places where id = $1', [place.id])).rows[0];
  check(row && Number(row.rating) === 4 && row.rating_count === 1,
    'an admin approves a place but cannot set its rating: users give it');
  row = (await asOwner("select reloptions from pg_class where relname = 'public_places'")).rows[0];
  check(String(row.reloptions).includes('security_invoker=true'),
    'the public list still applies the rules of whoever reads it');

  console.log('Requests to become an operator');
  await as(ion, "update public.profiles set operator_request = 'pending' where id = $1", [ion]);
  check(await fails(as(boss, "update public.profiles set operator_request = 'rejected' where id = $1", [ion])),
    'rejecting a request without a reason fails');
  await as(boss, "update public.profiles set operator_request = 'rejected', operator_request_reason = 'Nu ai un local' where id = $1", [ion]);
  row = (await as(ion, 'select operator_request, operator_request_reason from public.profiles')).rows[0];
  check(row.operator_request === 'rejected' && row.operator_request_reason === 'Nu ai un local',
    'he sees that the request was rejected, and why');
  await as(ion, "update public.profiles set operator_request_reason = 'Altceva' where id = $1", [ion]);
  row = (await as(ion, 'select operator_request_reason from public.profiles')).rows[0];
  check(row.operator_request_reason === 'Nu ai un local', 'he cannot change the reason');
  await as(ion, "update public.profiles set operator_request = 'pending' where id = $1", [ion]);
  row = (await as(ion, 'select operator_request, operator_request_reason from public.profiles')).rows[0];
  check(row.operator_request === 'pending' && row.operator_request_reason === null,
    'asking again clears the old answer');

  console.log('A suspended account');
  await as(boss, "update public.profiles set suspended_reason = 'Spam' where id = $1", [ion]);
  check(await fails(as(boss, "update public.profiles set first_name = 'Nou' where id = $1", [ion])),
    'cannot be renamed until it is reactivated');
  check(await fails(as(boss, "update public.profiles set role = 'operator' where id = $1", [ion])),
    'cannot get a new role until it is reactivated');
  await as(boss, 'update public.profiles set suspended_reason = null where id = $1', [ion]);
  await as(boss, "update public.profiles set first_name = 'Ionuț' where id = $1", [ion]);
  row = (await as(boss, 'select first_name from public.profiles where id = $1', [ion])).rows[0];
  check(row.first_name === 'Ionuț', 'once reactivated, it can be changed again');

  console.log('Reviews');
  const dan = await signUp('dan@test.ro', 'Dan', 'Pop');
  const rate = (userId, placeId, stars, comment = null) => as(userId,
    'insert into public.ratings (place_id, stars, comment) values ($1, $2, $3) ' +
    'on conflict (place_id, user_id) do update set stars = excluded.stars, comment = excluded.comment',
    [placeId, stars, comment]);
  const decide = (moderator, placeId, userId, status, reason = null) => as(moderator,
    'update public.ratings set status = $3, status_reason = $4 ' +
    'where place_id = $1 and user_id = $2 returning status',
    [placeId, userId, status, reason]);
  const ratingOf = async (placeId) => {
    const found = (await as(null,
      'select rating, rating_count from public.public_places where id = $1', [placeId])).rows[0];
    return String([Number(found.rating), found.rating_count]);
  };
  const reviewsOf = async (userId, placeId) =>
    (await as(userId, 'select * from public.place_ratings($1)', [placeId])).rows;

  check((await ratingOf('cafe-new-world')) === '4.7,0', 'an original place keeps the rating of the old app');
  await rate(dan, 'cafe-new-world', 2);
  check((await ratingOf('cafe-new-world')) === '4.7,0', 'a new review waits, and does not count yet');
  check((await reviewsOf(null, 'cafe-new-world')).length === 0, 'nor is it public');
  row = (await decide(dan, 'cafe-new-world', dan, 'approved')).rows[0];
  check(row.status === 'pending', 'the author cannot accept their own review');
  await decide(boss, 'cafe-new-world', dan, 'approved');
  check((await ratingOf('cafe-new-world')) === '2,1', 'accepted, it replaces the old rating');
  await rate(ion, 'cafe-new-world', 5);
  await decide(boss, 'cafe-new-world', ion, 'approved');
  check((await ratingOf('cafe-new-world')) === '3.5,2', 'the rating is the average of the accepted reviews');
  await rate(dan, 'cafe-new-world', 3, '  Cafea bună, dar aglomerat.  ');
  check((await ratingOf('cafe-new-world')) === '5,1', 'a changed review waits again, and stops counting');
  row = (await as(dan, "select status, comment from public.ratings where place_id = 'cafe-new-world'")).rows[0];
  check(row.status === 'pending' && row.comment === 'Cafea bună, dar aglomerat.', 'the message is kept, without the spaces around it');
  check(await fails(decide(boss, 'cafe-new-world', dan, 'rejected')), 'rejecting a review without a reason fails');
  await decide(boss, 'cafe-new-world', dan, 'rejected', 'Limbaj nepotrivit');
  row = (await as(dan, "select status, status_reason from public.ratings where place_id = 'cafe-new-world'")).rows[0];
  check(row.status === 'rejected' && row.status_reason === 'Limbaj nepotrivit', 'the author sees that it was rejected, and why');
  await as(boss, "update public.ratings set stars = 1, comment = 'Altceva' where place_id = 'cafe-new-world' and user_id = $1", [dan]);
  row = (await as(dan, "select stars, comment from public.ratings where place_id = 'cafe-new-world'")).rows[0];
  check(row.stars === 3 && row.comment === 'Cafea bună, dar aglomerat.', 'whoever moderates cannot change what the author wrote');
  await decide(boss, 'cafe-new-world', dan, 'approved');
  check((await ratingOf('cafe-new-world')) === '4,2', 'accepted again, it counts again');
  row = await reviewsOf(null, 'cafe-new-world');
  check(row.length === 2 && row[0].author === 'Dan P.' && row[0].comment === 'Cafea bună, dar aglomerat.' && row[0].stars === 3,
    'everyone reads the accepted reviews, newest first');
  check(!('user_id' in row[0]) && !('email' in row[0]) && row.every((review) => !review.mine),
    'with only the first name and an initial, never the account');
  check((await reviewsOf(dan, 'cafe-new-world')).filter((review) => review.mine).map((review) => review.author).join() === 'Dan P.',
    'the author sees which review is theirs');

  console.log('The rules of a review');
  check(await fails(as(dan, "insert into public.ratings (place_id, stars) values ('cafe-new-world', 1)")),
    'one review per account and place');
  check(await fails(rate(dan, 'burger-shack', 6)), 'the stars go from 1 to 5');
  check(await fails(rate(dan, 'burger-shack', 4, 'x'.repeat(501))), 'the message has at most 500 characters');
  check(await fails(as(null, "insert into public.ratings (place_id, stars) values ('burger-shack', 5)")),
    'visitors who are not signed in cannot review');
  check(await fails(rate(ana, place.id, 5)), 'an operator cannot review her own place');
  const waiting = (await as(ana,
    "insert into public.places (name, address, city, lat, lng, description, description_ro) " +
    "values ('Cofetăria Ana', 'Str. Cuza Vodă, Nr. 1, Iași', 'Iași', 47.16, 27.58, 'Home-made cakes and good coffee.', 'Prăjituri de casă și cafea bună.') " +
    'returning id')).rows[0];
  check(await fails(rate(dan, waiting.id, 5)), 'a place under review cannot be reviewed');
  check(await fails(as(dan, "insert into public.ratings (place_id, user_id, stars) values ('burger-shack', $1, 5)", [ion])),
    "nobody reviews in someone else's name");
  await as(dan, "update public.ratings set place_id = 'burger-shack' where place_id = 'cafe-new-world'");
  check((await as(dan, "select 1 from public.ratings where place_id = 'burger-shack'")).rows.length === 0,
    'a review cannot move to another place');
  check((await as(dan, 'update public.ratings set stars = 1 where user_id = $1 returning stars', [ion])).rows.length === 0,
    "nobody changes someone else's review");
  row = (await as(ion, 'select user_id from public.ratings')).rows;
  check(row.length === 2 && row.every((review) => review.user_id === ion), 'a user sees only their own reviews');

  console.log('The operator decides');
  await rate(dan, place.id, 5, 'Ceai foarte bun.');
  row = (await as(ana, 'select * from public.ratings_to_moderate()')).rows;
  check(row.length === 2 && row.every((review) => review.place_id === place.id) &&
    row.some((review) => review.author === 'Dan P.' && review.status === 'pending' && review.place_name === 'Ceainăria Ana'),
    'the operator sees the reviews of her places, and only those');
  check((await as(dan, 'select * from public.ratings_to_moderate()')).rows.length === 0, 'a user has nothing to decide');
  check(await fails(as(null, 'select * from public.ratings_to_moderate()')), 'nor have visitors');
  check((await decide(ion, place.id, dan, 'approved')).rows.length === 0, 'nobody else decides about them');
  await decide(ana, place.id, dan, 'approved');
  check((await ratingOf(place.id)) === '4.5,2', 'she accepts a review, and it counts');
  check((await as(boss, 'select * from public.ratings_to_moderate()')).rows.length === 4, 'an admin sees the reviews of every place');

  console.log('Deleting a review');
  check((await as(ion, 'delete from public.ratings where user_id = $1 returning 1', [dan])).rows.length === 0,
    "nobody deletes someone else's review");
  await as(dan, 'delete from public.ratings where place_id = $1', [place.id]);
  check((await ratingOf(place.id)) === '4,1', 'the author deletes their review, and it stops counting');
  await as(boss, "delete from public.ratings where place_id = 'cafe-new-world' and user_id = $1", [dan]);
  check((await ratingOf('cafe-new-world')) === '5,1', 'an admin deletes any review');

  console.log('Suspended accounts');
  await rate(dan, 'cafe-new-world', 3);
  await decide(boss, 'cafe-new-world', dan, 'approved');
  check((await ratingOf('cafe-new-world')) === '4,2', 'before: two accepted reviews');
  await as(boss, "update public.profiles set suspended_reason = 'Note false' where id = $1", [ion]);
  check((await ratingOf('cafe-new-world')) === '3,1', "a suspended account's reviews stop counting");
  check((await reviewsOf(null, 'cafe-new-world')).length === 1, 'and are hidden');
  check(await fails(rate(ion, 'burger-shack', 5)), 'it cannot review');
  check((await as(ion, 'delete from public.ratings returning 1')).rows.length === 0, 'nor delete its reviews');
  await as(boss, 'update public.profiles set suspended_reason = null where id = $1', [ion]);
  check((await ratingOf('cafe-new-world')) === '4,2', 'reactivated, its reviews count again');

  console.log("An admin's own reviews");
  const statusOf = async (userId, placeId) => (await as(userId,
    'select status from public.ratings where place_id = $1 and user_id = $2', [placeId, userId])).rows[0].status;
  await rate(boss, 'burger-shack', 4, 'Burgeri buni.');
  check((await statusOf(boss, 'burger-shack')) === 'approved' && (await reviewsOf(null, 'burger-shack')).length === 1,
    'on a place without an operator, it is public at once');
  await rate(boss, 'burger-shack', 5, 'Burgeri foarte buni.');
  check((await statusOf(boss, 'burger-shack')) === 'approved', 'and stays public when changed');
  await rate(boss, place.id, 5);
  check((await statusOf(boss, place.id)) === 'approved', "on an operator's place too: admins wait for nobody");
  await rate(dan, 'burger-shack', 2);
  check((await statusOf(dan, 'burger-shack')) === 'pending', "a user's review still waits");

  console.log('Step 6 on a database with reviews');
  const old = await newDatabase(steps.indexOf('006_admin_reviews.sql'));
  const oldAdmin = (await old.query(
    "insert into auth.users (email, raw_user_meta_data) values ('sef@test.ro', '{}') returning id")).rows[0].id;
  await old.query("update public.profiles set role = 'admin' where id = $1", [oldAdmin]);
  await old.query("select set_config('request.jwt.claims', $1, false)", [JSON.stringify({ sub: oldAdmin, role: 'authenticated' })]);
  await old.exec('set role authenticated');
  await old.query("insert into public.ratings (place_id, stars) values ('burger-shack', 4)");
  // A place with an operator, too.
  await old.exec('reset role');
  const oldOperator = (await old.query(
    "insert into auth.users (email, raw_user_meta_data) values ('op@test.ro', '{}') returning id")).rows[0].id;
  await old.query("update public.profiles set role = 'operator' where id = $1", [oldOperator]);
  await old.query("update public.places set owner_id = $1 where id = 'cafe-new-world'", [oldOperator]);
  await old.exec('set role authenticated');
  await old.query("insert into public.ratings (place_id, stars) values ('cafe-new-world', 5)");
  await old.exec('reset role');
  // Then step 6, run in the SQL Editor: no one signed in.
  await old.query("select set_config('request.jwt.claims', '', false)");
  await old.exec(fs.readFileSync(path.join(__dirname, '..', '006_admin_reviews.sql'), 'utf8'));
  row = (await old.query("select r.status, p.rating_count from public.ratings r join public.places p on p.id = r.place_id")).rows;
  check(row.length === 2 && row.every((review) => review.status === 'approved' && review.rating_count === 1),
    "an admin's reviews that were waiting become public, and count");

  console.log('Two languages');
  const addPlace = (description, descriptionRo) => as(ana,
    'insert into public.places (name, address, city, lat, lng, description, description_ro) ' +
    "values ('Bistro Ana', 'Str. Arcu, Nr. 5, Iași', 'Iași', 47.16, 27.58, $1, $2) returning id",
    [description, descriptionRo]);
  check(await fails(addPlace('Good food and a quiet terrace.', null)), 'a place needs the Romanian description');
  check(await fails(addPlace('Good food and a quiet terrace.', '   ')), 'not just spaces');
  check(await fails(addPlace('Good food and a quiet terrace.', 'Scurt')), 'with the same length as the English one');
  check((await addPlace('Good food and a quiet terrace.', 'Mâncare bună și o terasă liniștită.')).rows.length === 1,
    'with both, it is added');

  console.log('Step 7 on a database with places in one language');
  const oneLanguage = await newDatabase(steps.indexOf('007_bilingual_places.sql'));
  await oneLanguage.query(
    "insert into public.places (id, name, address, city, lat, lng, description, status) " +
    "values ('local-test', 'Local Test', 'Str. Test, Nr. 1, Iași', 'Iași', 47.16, 27.58, 'Descriere local test', 'approved')");
  await oneLanguage.exec(fs.readFileSync(path.join(__dirname, '..', '007_bilingual_places.sql'), 'utf8'));
  row = (await oneLanguage.query("select description, description_ro from public.places where id = 'local-test'")).rows[0];
  check(row.description_ro === 'Descriere local test' && row.description === 'Descriere local test',
    'its one description becomes the Romanian one too');

  console.log('Conversations with the assistant');
  const start = (userId, title) => as(userId,
    'insert into public.conversations (title) values ($1) returning id, user_id, title', [title]);
  const say = (userId, conversationId, author, body, placeId = null, city = null) => as(userId,
    'insert into public.chat_messages (conversation_id, author, body, place_id, city) ' +
    'values ($1, $2, $3, $4, $5) returning id', [conversationId, author, body, placeId, city]);
  row = (await start(dan, '  Cafea în Cluj  ')).rows[0];
  const chat = row.id;
  check(row.user_id === dan && row.title === 'Cafea în Cluj', 'an account starts a conversation, titled without spaces around');
  check(await fails(start(dan, '   ')), 'a title of only spaces is refused');
  check(await fails(start(dan, 'x'.repeat(81))), 'a title has at most 80 characters');
  check(await fails(as(null, "insert into public.conversations (title) values ('X')")),
    'visitors who are not signed in have no history');
  check(await fails(as(dan, "insert into public.conversations (title, user_id) values ('X', $1)", [ion])),
    "nobody starts a conversation in someone else's name");
  await say(dan, chat, 'user', 'Vreau să beau ceva în Cluj-Napoca');
  await say(dan, chat, 'bot', 'În Cluj-Napoca poți bea ceva la: Coffee Shop Zen.', null, 'Cluj-Napoca');
  await say(dan, chat, 'ai', 'Îți recomand Coffee Shop Zen.', 'coffee-shop-zen');
  row = (await as(dan, 'select author, place_id, city from public.chat_messages where conversation_id = $1 order by created_at, id', [chat])).rows;
  check(row.map((message) => [message.author, message.place_id, message.city].join()).join('|') ===
    'user,,|bot,,Cluj-Napoca|ai,coffee-shop-zen,', 'its messages come back in order, with what they show on the map');
  check(await fails(say(dan, chat, 'user', 'Arată-mi', 'coffee-shop-zen')), "the user's messages show nothing on the map");
  check(await fails(say(dan, chat, 'ai', 'Două', 'coffee-shop-zen', 'Cluj-Napoca')), 'an answer shows one thing, not two');
  check(await fails(say(dan, chat, 'robot', 'Bip')), 'the author is the user, the rules or Gemini');
  check(await fails(say(dan, chat, 'user', '')), 'a message is not empty');
  check(await fails(as(dan,
    "insert into public.chat_messages (conversation_id, author, body, created_at) values ($1, 'user', 'Ieri', now() - interval '1 day')", [chat])),
    'nor dated by the app');
  check(await fails(as(dan, "update public.chat_messages set body = 'Altceva' where conversation_id = $1", [chat])),
    'a message is never changed afterwards');

  check((await as(ion, 'select * from public.conversations')).rows.length === 0 &&
    (await as(ion, 'select * from public.chat_messages')).rows.length === 0,
    "nobody else reads someone's conversations");
  check((await as(boss, 'select * from public.conversations')).rows.length === 0 &&
    (await as(boss, 'select * from public.chat_messages')).rows.length === 0,
    'not even an admin');
  // Without "returning": that alone would fail, since he cannot read the row.
  check(await fails(as(ion, "insert into public.chat_messages (conversation_id, author, body) values ($1, 'user', 'Salut')", [chat])),
    "nobody writes in someone else's conversation");
  check((await as(ion, "update public.conversations set title = 'X' where id = $1 returning id", [chat])).rows.length === 0 &&
    (await as(ion, 'delete from public.conversations where id = $1 returning id', [chat])).rows.length === 0,
    'nor renames or deletes it');
  row = (await as(dan, "update public.conversations set title = ' Cafele în Cluj ' where id = $1 returning title", [chat])).rows[0];
  check(row.title === 'Cafele în Cluj', 'the owner renames it');
  check(await fails(as(dan, 'update public.conversations set user_id = $1 where id = $2', [ion, chat])),
    'a conversation never changes hands');

  const other = (await start(dan, 'Pizza')).rows[0].id;
  const newest = async () => (await as(dan, 'select id from public.conversations order by updated_at desc limit 1')).rows[0].id;
  check((await newest()) === other, 'the newest conversation comes first');
  await say(dan, chat, 'user', 'Și un ceai?');
  check((await newest()) === chat, 'a new message brings its conversation to the top');
  await as(dan, 'delete from public.conversations where id = $1', [chat]);
  check(Number((await asOwner('select count(*) from public.chat_messages where conversation_id = $1', [chat])).rows[0].count) === 0,
    'deleting a conversation deletes its messages');
  const eva = await signUp('eva@test.ro', 'Eva', 'Pop');
  const evaChat = (await start(eva, 'Salut')).rows[0].id;
  await say(eva, evaChat, 'user', 'Salut!');
  await asOwner('delete from auth.users where id = $1', [eva]);
  check(Number((await asOwner('select count(*) from public.conversations where id = $1', [evaChat])).rows[0].count) === 0,
    'deleting an account deletes its conversations');

  console.log('The demo (seed_demo.sql)');
  const demo = await newDatabase();
  const operatorId = (await demo.query(
    "insert into auth.users (email, raw_user_meta_data) values ('operator@test.ro', '{}') returning id")).rows[0].id;
  await demo.query("update public.profiles set role = 'operator' where id = $1", [operatorId]);
  const seed = fs.readFileSync(path.join(__dirname, '..', 'seed_demo.sql'), 'utf8');
  await demo.exec(seed);
  const count = async (query, params = []) => Number((await demo.query(query, params)).rows[0].count);
  check((await count('select count(*) from public.public_places')) === 84, 'adds 64 public places to the 20');
  const reviews = await count("select count(*) from public.ratings where status = 'approved'");
  check(reviews > 1500, `with many public reviews (${reviews})`);
  check((await count("select count(*) from public.ratings where status = 'pending'")) > 0 &&
    (await count("select count(*) from public.ratings where status = 'rejected' and status_reason is not null")) > 0,
    'and some waiting or rejected, with a reason');
  check((await count(`select count(*) from public.places p where p.rating_count <> (
      select count(*) from public.ratings r where r.place_id = p.id and r.status = 'approved')
    or (p.rating_count > 0 and p.rating <> (select round(avg(r.stars), 1) from public.ratings r
      where r.place_id = p.id and r.status = 'approved'))`)) === 0,
    'every rating is the average of the public reviews');
  check((await count('select count(*) from (select distinct stars from public.ratings) s')) === 5,
    'the reviews have every number of stars');
  check((await count('select count(*) from (select distinct updated_at::date from public.ratings) d')) > 300,
    'each written on its own day, not all today');
  check((await count('select count(*) from public.public_places where rating is null')) > 0,
    'a few new places have no reviews yet');
  check((await count("select count(*) from public.places where id in ('tea-house-sunset', 'bread-and-coffee') and rating_count = 0 and rating is not null")) === 2,
    'and a few original places keep the rating of the old app');
  check((await count('select count(*) from public.places where owner_id = $1', [operatorId])) === 6,
    'the test operator owns a few places');
  await demo.query("select set_config('request.jwt.claims', $1, false)", [JSON.stringify({ sub: operatorId, role: 'authenticated' })]);
  await demo.exec('set role authenticated');
  const toDecide = Number((await demo.query("select count(*) from public.ratings_to_moderate() where status = 'pending'")).rows[0].count);
  await demo.exec('reset role');
  await demo.query("select set_config('request.jwt.claims', '', false)");
  check(toDecide > 0, `and has reviews to accept (${toDecide})`);
  const before = await count('select count(*) from public.ratings');
  await demo.exec(seed);
  check((await count('select count(*) from public.ratings')) === before &&
    (await count('select count(*) from public.public_places')) === 84, 'running it again changes nothing');
  const reviewer = (await demo.query("select id from public.profiles where email like '%@demo.ro' order by email limit 1")).rows[0].id;
  await demo.query("select set_config('request.jwt.claims', $1, false)", [JSON.stringify({ sub: reviewer, role: 'authenticated' })]);
  await demo.exec('set role authenticated');
  await demo.query("insert into public.ratings (place_id, stars, comment) values ('the-literary-coffee-house-citadel', 4, 'Nou') " +
    'on conflict (place_id, user_id) do update set stars = excluded.stars, comment = excluded.comment');
  row = (await demo.query("select status, updated_at::date = now()::date as today from public.ratings where place_id = 'the-literary-coffee-house-citadel' and user_id = $1", [reviewer])).rows[0];
  await demo.exec('reset role');
  await demo.query("select set_config('request.jwt.claims', '', false)");
  check(row.status === 'pending' && row.today, 'afterwards, reviews wait and get their date as always');
  await demo.exec(fs.readFileSync(path.join(__dirname, '..', 'seed_demo_remove.sql'), 'utf8'));
  check((await count('select count(*) from public.public_places')) === 20 &&
    (await count("select count(*) from public.profiles where email like '%@demo.ro'")) === 0 &&
    (await count('select count(*) from public.ratings')) === 0,
    'seed_demo_remove.sql takes it all out again');

  console.log('Demo conversations (seed_conversations.sql)');
  const talks = await newDatabase();
  const accounts = [];
  // Fixed ids, so that the shares are the same at every run.
  for (const [n, email] of ['admin@test.ro', 'operator@test.ro', 'user@test.ro'].entries()) {
    accounts.push((await talks.query(
      "insert into auth.users (id, email, raw_user_meta_data) values ($1, $2, '{}') returning id",
      [`00000000-0000-4000-8000-00000000000${n + 1}`, email])).rows[0].id);
  }
  await talks.exec(seed);
  // A conversation of her own, from before.
  const own = (await talks.query(
    "insert into public.conversations (user_id, title) values ($1, 'A mea') returning id", [accounts[2]])).rows[0].id;
  const conversationsSeed = fs.readFileSync(path.join(__dirname, '..', 'seed_conversations.sql'), 'utf8');
  await talks.exec(conversationsSeed);
  const talk = async (query, params = []) => Number((await talks.query(query, params)).rows[0].count);
  const shares = [];
  for (const id of accounts) {
    shares.push((await talks.query('select title from public.conversations where user_id = $1 order by title', [id]))
      .rows.map((conversation) => conversation.title).join('|'));
  }
  check(shares.every((share) => share.split('|').length >= 6), 'every account that can sign in gets conversations');
  check(new Set(shares).size === 3, 'each its own share');
  check((await talk("select count(*) from public.conversations c join auth.users u on u.id = c.user_id where u.email like '%@demo.ro'")) === 0,
    'the demo reviewers get none');
  check((await talk('select count(*) from public.conversations c where not exists (select 1 from public.chat_messages m where m.conversation_id = c.id) and c.id <> $1', [own])) === 0,
    'every conversation has its messages');
  check((await talk(`select count(*) from public.conversations c where c.id <> $1 and c.updated_at <> (
      select max(m.created_at) from public.chat_messages m where m.conversation_id = c.id)`, [own])) === 0,
    'and its time is that of its last message');
  check((await talk("select count(*) from public.chat_messages where author = 'bot'")) > 0 &&
    (await talk("select count(*) from public.chat_messages where author = 'ai'")) > 0 &&
    (await talk('select count(*) from public.chat_messages where place_id is not null')) > 0 &&
    (await talk('select count(*) from public.chat_messages where city is not null')) > 0,
    'with answers of the rules and of Gemini, some with a place or a city on the map');
  check((await talk("select count(*) from public.chat_messages where body like '%empfehle%' or body like '%consiglio%' or body like '%recomiendo%'")) > 0,
    'in several languages');
  check((await talk('select count(*) from (select distinct created_at::date from public.conversations) d')) > 10,
    'from different days');
  const talksBefore = await talk('select count(*) from public.chat_messages');
  await talks.exec(conversationsSeed);
  check((await talk('select count(*) from public.chat_messages')) === talksBefore, 'running it again changes nothing');
  await talks.exec(fs.readFileSync(path.join(__dirname, '..', 'seed_conversations_remove.sql'), 'utf8'));
  check((await talk('select count(*) from public.conversations')) === 1 &&
    (await talk('select count(*) from public.conversations where id = $1', [own])) === 1,
    "seed_conversations_remove.sql takes them out, and keeps people's own");

  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed === 0 ? 0 : 1);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
