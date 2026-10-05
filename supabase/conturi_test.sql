-- Top Places: test accounts, one for every role and state.
-- Run it in the SQL Editor of your Supabase project. Running it again is
-- safe: existing accounts get the password and the role again.
--
-- All of them use the same password, set below. The accounts live only in
-- the project you run it in, so a public password is fine for a demo; just
-- delete them (Authentication > Users) before real people use the project.
do $$
declare
  test_password constant text := 'Test123!';
  account record;
  account_id uuid;
begin
  for account in
    select * from (values
      ('admin@test.ro', 'Ana', 'Admin', 'admin', null, null),
      ('operator@test.ro', 'Olga', 'Operator', 'operator', null, null),
      ('user@test.ro', 'Ion', 'Utilizator', 'user', null, null),
      ('cerere@test.ro', 'Cristi', 'Cerere', 'user', 'pending', null),
      ('suspendat@test.ro', 'Sorin', 'Suspendat', 'user', null,
        'Cont de test, suspendat ca să vezi cum arată.')
    ) as a (email, first_name, last_name, role, operator_request,
      suspended_reason)
  loop
    select id into account_id from auth.users where email = account.email;

    if account_id is null then
      -- A confirmed account, as Supabase Auth makes it. The empty strings
      -- matter: Auth cannot read these token columns when they are null.
      account_id := gen_random_uuid();
      insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at, confirmation_token, email_change,
        email_change_token_new, recovery_token
      ) values (
        '00000000-0000-0000-0000-000000000000', account_id, 'authenticated',
        'authenticated', account.email,
        extensions.crypt(test_password, extensions.gen_salt('bf', 10)),
        now(), '{"provider": "email", "providers": ["email"]}',
        jsonb_build_object('first_name', account.first_name,
          'last_name', account.last_name),
        now(), now(), '', '', '', ''
      );
      -- The email "identity" that signing in with a password looks for.
      insert into auth.identities (
        id, user_id, provider_id, identity_data, provider,
        last_sign_in_at, created_at, updated_at
      ) values (
        gen_random_uuid(), account_id, account_id::text,
        jsonb_build_object('sub', account_id::text, 'email', account.email,
          'email_verified', true),
        'email', now(), now(), now()
      );
    else
      -- Already there, e.g. made in the dashboard: the test password, and
      -- confirmed.
      update auth.users
      set encrypted_password =
            extensions.crypt(test_password, extensions.gen_salt('bf', 10)),
          email_confirmed_at = coalesce(email_confirmed_at, now())
      where id = account_id;
    end if;

    -- The profile exists already (a trigger made it); now the role and
    -- the state. The SQL Editor may change them, unlike the app.
    update public.profiles
    set first_name = account.first_name,
        last_name = account.last_name,
        role = account.role,
        operator_request = account.operator_request,
        suspended_reason = account.suspended_reason,
        suspended_at = case
          when account.suspended_reason is null then null
          else coalesce(suspended_at, now())
        end
    where id = account_id;
  end loop;
end $$;

-- What was made, to check.
select email, first_name, last_name, role, operator_request,
  suspended_reason is not null as suspended
from public.profiles
where email like '%@test.ro'
order by email;
