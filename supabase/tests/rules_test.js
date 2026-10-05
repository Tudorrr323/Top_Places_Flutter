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

async function main() {
  const db = new PGlite();
  await db.exec(fs.readFileSync(path.join(__dirname, 'supabase_env.sql'), 'utf8'));
  await db.exec(fs.readFileSync(path.join(__dirname, '..', 'schema.sql'), 'utf8'));
  await db.exec(fs.readFileSync(path.join(__dirname, '..', '002_public_places.sql'), 'utf8'));
  await db.exec(fs.readFileSync(path.join(__dirname, '..', '003_reviews_by_admins.sql'), 'utf8'));
  await db.exec(fs.readFileSync(path.join(__dirname, '..', '004_ratings.sql'), 'utf8'));

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
    "insert into public.places (name, address, city, lat, lng, description) values ('Test', 'Str. A, 1', 'Iași', 47.1, 27.5, 'O descriere destul de lungă.')")),
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
    "insert into public.places (name, address, city, lat, lng, description, status, rating) " +
    "values ('Ceainăria Ana', 'Str. Lăpușneanu, Nr. 3, Iași', 'Iași', 47.16, 27.58, 'Ceai bun și liniște, aproape de centru.', 'approved', 5) " +
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
    "insert into public.places (name, address, city, lat, lng, description) values ('Alt loc', 'Str. B, 2', 'Iași', 47.1, 27.5, 'O descriere destul de lungă.')")),
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

  console.log('Ratings');
  const dan = await signUp('dan@test.ro', 'Dan', 'Pop');
  const rate = (userId, placeId, stars) => as(userId,
    'insert into public.ratings (place_id, stars) values ($1, $2) ' +
    'on conflict (place_id, user_id) do update set stars = excluded.stars',
    [placeId, stars]);
  const ratingOf = async (placeId) => {
    const found = (await as(null,
      'select rating, rating_count from public.public_places where id = $1', [placeId])).rows[0];
    return [Number(found.rating), found.rating_count];
  };
  check(String(await ratingOf('cafe-new-world')) === '4.7,0',
    'an original place keeps the rating of the old app until rated');
  await rate(dan, 'cafe-new-world', 2);
  check(String(await ratingOf('cafe-new-world')) === '2,1', 'the first rating replaces it');
  await rate(ion, 'cafe-new-world', 5);
  check(String(await ratingOf('cafe-new-world')) === '3.5,2', 'the rating is the average of the ratings');
  await rate(dan, 'cafe-new-world', 3);
  check(String(await ratingOf('cafe-new-world')) === '4,2', 'rating again changes the stars, not the count');
  check(await fails(as(dan, "insert into public.ratings (place_id, stars) values ('cafe-new-world', 1)")),
    'one rating per account and place');
  check(await fails(rate(dan, 'burger-shack', 6)), 'the stars go from 1 to 5');
  check(await fails(as(null, "insert into public.ratings (place_id, stars) values ('burger-shack', 5)")),
    'visitors who are not signed in cannot rate');
  check(await fails(rate(ana, place.id, 5)), 'an operator cannot rate her own place');
  const waiting = (await as(ana,
    "insert into public.places (name, address, city, lat, lng, description) " +
    "values ('Cofetăria Ana', 'Str. Cuza Vodă, Nr. 1, Iași', 'Iași', 47.16, 27.58, 'Prăjituri de casă și cafea bună.') " +
    'returning id')).rows[0];
  check(await fails(rate(dan, waiting.id, 5)), 'a place under review cannot be rated');
  check(await fails(as(dan, "insert into public.ratings (place_id, user_id, stars) values ('burger-shack', $1, 5)", [ion])),
    "nobody rates in someone else's name");
  row = (await as(ion, 'select user_id from public.ratings')).rows;
  check(row.length === 2 && row.every((rating) => rating.user_id === ion), 'each account sees only its own ratings');
  check((await as(dan, 'update public.ratings set stars = 1 where user_id = $1 returning stars', [ion])).rows.length === 0,
    "nobody changes someone else's rating");
  await as(dan, "update public.ratings set place_id = 'burger-shack' where place_id = 'cafe-new-world'");
  row = (await as(dan, 'select place_id from public.ratings')).rows;
  check(row.length === 1 && row[0].place_id === 'cafe-new-world', 'a rating cannot move to another place');
  check(await fails(as(dan, 'delete from public.ratings')), 'ratings are not deleted in the app');
  await as(boss, "update public.profiles set suspended_reason = 'Note false' where id = $1", [ion]);
  check(String(await ratingOf('cafe-new-world')) === '3,1', "a suspended account's ratings stop counting");
  check(await fails(rate(ion, 'burger-shack', 5)), 'and it cannot rate');
  await as(boss, 'update public.profiles set suspended_reason = null where id = $1', [ion]);
  check(String(await ratingOf('cafe-new-world')) === '4,2', 'reactivated, its ratings count again');

  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed === 0 ? 0 : 1);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
