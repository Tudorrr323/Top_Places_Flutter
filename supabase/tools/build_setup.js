// Writes ../setup.sql: every SQL file of the project in one, in the order
// they are run, for a new Supabase project.
//
//   node supabase/tools/build_setup.js
const fs = require('fs');
const path = require('path');

const files = [
  'schema.sql',
  '002_public_places.sql',
  '003_reviews_by_admins.sql',
  '004_ratings.sql',
  '005_reviews.sql',
  '006_admin_reviews.sql',
  '007_bilingual_places.sql',
  '008_conversations.sql',
  'conturi_test.sql',
  'seed_demo.sql',
  'seed_conversations.sql',
];

const header = `-- Top Places: everything in one file, for a new Supabase project. The
-- tables and their rules, the test accounts (all with the password in
-- conturi_test.sql), the demo places, reviews, requests and places waiting
-- for an admin, and the demo conversations. Run it once, in the SQL Editor
-- of an empty project.
--
-- Made by supabase/tools/build_setup.js from the files below: change those,
-- not this one.
`;

const parts = files.map((file) => {
  const text = fs.readFileSync(path.join(__dirname, '..', file), 'utf8').trimEnd();
  return `\n-- ${'='.repeat(70)}\n-- ${file}\n-- ${'='.repeat(70)}\n\n${text}\n`;
});

fs.writeFileSync(path.join(__dirname, '..', 'setup.sql'), header + parts.join(''));
console.log(`setup.sql: ${files.length} files`);
