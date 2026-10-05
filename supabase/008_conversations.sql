-- Top Places, step 8: the history of the chat. Run it once in the SQL
-- Editor, after 007_bilingual_places.sql.
--
-- A signed-in account keeps its conversations with the assistant, on every
-- device: it opens them again, renames them and deletes them. They are
-- private: nobody else reads them, admins included. Visitors who are not
-- signed in chat as before, without a history.

-- 1. The conversations, and their messages in order. Deleting an account
-- or a conversation deletes its messages too.
create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references public.profiles (id) on delete cascade,
  title text not null check (char_length(title) between 1 and 80),
  created_at timestamptz not null default now(),
  -- The time of the last message: the newest conversations come first.
  updated_at timestamptz not null default now()
);

create index conversations_of_an_account
  on public.conversations (user_id, updated_at desc);

create table public.chat_messages (
  id bigint generated always as identity primary key,
  conversation_id uuid not null
    references public.conversations (id) on delete cascade,
  -- Who wrote it: the user, the assistant's rules, or Gemini.
  author text not null check (author in ('user', 'bot', 'ai')),
  body text not null check (char_length(body) between 1 and 4000),
  -- What "Arată pe hartă" shows under an answer: one place, or a city.
  place_id text references public.places (id) on delete set null,
  city text check (char_length(city) <= 80),
  created_at timestamptz not null default now(),
  constraint one_thing_on_the_map check (place_id is null or city is null),
  constraint only_answers_show_on_the_map
    check (author <> 'user' or (place_id is null and city is null))
);

create index chat_messages_in_order
  on public.chat_messages (conversation_id, created_at, id);

-- 2. A title without spaces around it, so that one of only spaces is
-- refused.
create function public.trim_conversation_title() returns trigger
language plpgsql set search_path = ''
as $$
begin
  new.title := btrim(new.title);
  return new;
end;
$$;

create trigger trim_conversation_title
  before insert or update of title on public.conversations
  for each row execute function public.trim_conversation_title();

-- A new message brings its conversation to the top of the list. The
-- account may only rename a conversation, so this runs as the owner.
create function public.touch_conversation() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  update public.conversations
  set updated_at = greatest(updated_at, new.created_at)
  where id = new.conversation_id;
  return null;
end;
$$;

create trigger touch_conversation
  after insert on public.chat_messages
  for each row execute function public.touch_conversation();

-- 3. Row Level Security: each account, its own conversations. The grants
-- limit the columns: a conversation is started with a title and only
-- renamed afterwards; a message is never changed, and its time is the
-- database's.
alter table public.conversations enable row level security;
alter table public.chat_messages enable row level security;

create policy "Accounts see their own conversations"
  on public.conversations for select to authenticated
  using (user_id = (select auth.uid()));

create policy "Accounts start their own conversations"
  on public.conversations for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "Accounts rename their own conversations"
  on public.conversations for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "Accounts delete their own conversations"
  on public.conversations for delete to authenticated
  using (user_id = (select auth.uid()));

create policy "Accounts read the messages of their conversations"
  on public.chat_messages for select to authenticated
  using (exists (
    select 1 from public.conversations as c
    where c.id = conversation_id and c.user_id = (select auth.uid())
  ));

create policy "Accounts write in their own conversations"
  on public.chat_messages for insert to authenticated
  with check (exists (
    select 1 from public.conversations as c
    where c.id = conversation_id and c.user_id = (select auth.uid())
  ));

revoke all on public.conversations, public.chat_messages
  from anon, authenticated;
grant select, delete on public.conversations to authenticated;
grant insert (title), update (title) on public.conversations to authenticated;
grant select on public.chat_messages to authenticated;
grant insert (conversation_id, author, body, place_id, city)
  on public.chat_messages to authenticated;
