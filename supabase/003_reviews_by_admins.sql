-- Top Places, step 3: what admins decide. Run it once in the SQL Editor,
-- after 002_public_places.sql.

-- 1. Ratings will come from the people who visit a place, not from the
-- admin who approves it. A new place is approved without one, and the app
-- shows it as "Nou".
alter table public.places drop constraint approved_places_have_a_rating;

-- 2. A rejected request to become an operator says why, like a rejected
-- place does.
alter table public.profiles
  add column operator_request_reason text
  check (char_length(operator_request_reason) <= 300);

-- Requests rejected before this step get a reason, so the rule below holds.
update public.profiles
set operator_request_reason = 'Respinsă înainte să existe motive.'
where operator_request = 'rejected';

alter table public.profiles
  add constraint rejected_requests_have_a_reason check (
    case
      when operator_request = 'rejected'
        then coalesce(btrim(operator_request_reason), '') <> ''
      else operator_request_reason is null
    end
  );

-- 3. The same trigger as in schema.sql, with the reason, and one more rule:
-- a suspended account is reactivated before anything else changes on it.
create or replace function public.guard_profile_update() returns trigger
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
    if old.suspended_reason is not null and new.suspended_reason is not null
       and (new.role <> old.role
         or new.first_name <> old.first_name
         or new.last_name <> old.last_name) then
      raise exception 'Reactivate the account before changing it.';
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
    -- A reason belongs only to a rejected request.
    if new.operator_request is distinct from 'rejected' then
      new.operator_request_reason := null;
    end if;
    return new;
  end if;

  -- Everyone else edits only their name, and may ask to become an operator.
  new.role := old.role;
  new.suspended_reason := old.suspended_reason;
  new.suspended_at := old.suspended_at;
  new.operator_request_reason := old.operator_request_reason;
  if new.operator_request is distinct from old.operator_request then
    if new.operator_request = 'pending' and old.role = 'user' then
      -- Asking again clears the answer to the last request.
      new.operator_request_reason := null;
    else
      new.operator_request := old.operator_request;
    end if;
  end if;
  return new;
end;
$$;
