-- fridge-note database for Supabase.
-- Paste this into the SQL editor of a new project and run it once.
--
-- Every synced table has two bookkeeping columns next to its real ones:
--   field_times  jsonb   column name -> time of its last change (ms since epoch)
--   updated_at   bigint  the newest of those times
--
-- The app never writes rows directly. It calls apply_patch(), which merges a
-- change column by column: for each column the newer time wins. That is the
-- same rule the app uses locally (lib/core/sync/merge.dart), so the phone and
-- the server always end up with the same row.
--
-- Nothing is hard deleted: rows get deleted = true, so deletes sync like any
-- other change.

-- ------------------------------------------------------------------ tables

create table public.profiles (
  id          text primary key,
  name        text not null default '',
  color       bigint not null default 4285751538,
  field_times jsonb not null default '{}',
  updated_at  bigint not null default 0
);

create table public.lists (
  id              text primary key,
  name            text not null,
  store           text not null default '',
  owner_id        text not null,
  shopper_id      text,
  trip_started_at bigint,
  created_at      bigint not null default 0,
  deleted         boolean not null default false,
  field_times     jsonb not null default '{}',
  updated_at      bigint not null default 0
);

-- id is "<list_id>:<user_id>"
create table public.list_members (
  id          text primary key,
  list_id     text not null references public.lists (id) on delete cascade,
  user_id     text not null,
  deleted     boolean not null default false,
  field_times jsonb not null default '{}',
  updated_at  bigint not null default 0
);
create index list_members_user_idx on public.list_members (user_id);

create table public.items (
  id          text primary key,
  list_id     text not null references public.lists (id) on delete cascade,
  name        text not null,
  category    text not null default 'other',
  quantity    integer not null default 1,
  unit        text not null default 'pcs',
  price       double precision not null default 0,
  checked     boolean not null default false,
  checked_by  text,
  position    double precision not null default 0,
  added_by    text not null,
  created_at  bigint not null default 0,
  deleted     boolean not null default false,
  field_times jsonb not null default '{}',
  updated_at  bigint not null default 0
);
create index items_list_idx on public.items (list_id);

create table public.activities (
  id          text primary key,
  list_id     text not null references public.lists (id) on delete cascade,
  actor_id    text not null,
  kind        text not null,
  item_name   text not null default '',
  created_at  bigint not null,
  field_times jsonb not null default '{}',
  updated_at  bigint not null default 0
);
create index activities_list_idx on public.activities (list_id, created_at desc);

create table public.usuals (
  id           text primary key,
  owner_id     text not null,
  name         text not null,
  category     text not null default 'other',
  quantity     integer not null default 1,
  unit         text not null default 'pcs',
  price        double precision not null default 0,
  badge        text,
  favorite     boolean not null default false,
  times_bought integer not null default 0,
  deleted      boolean not null default false,
  field_times  jsonb not null default '{}',
  updated_at   bigint not null default 0
);

-- Only touched by the invite functions further down.
create table public.invites (
  code       text primary key,
  list_id    text not null references public.lists (id) on delete cascade,
  created_by text not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '14 days'
);

-- ------------------------------------------------------- row level security

-- Security definer so it can read list_members without running into the
-- policies on list_members itself.
create or replace function public.is_member(p_list_id text)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from list_members m
    where m.list_id = p_list_id and m.user_id = auth.uid()::text and not m.deleted
  ) or exists (
    select 1 from lists l
    where l.id = p_list_id and l.owner_id = auth.uid()::text
  );
$$;

alter table public.profiles enable row level security;
alter table public.lists enable row level security;
alter table public.list_members enable row level security;
alter table public.items enable row level security;
alter table public.activities enable row level security;
alter table public.usuals enable row level security;
alter table public.invites enable row level security;

create policy "profiles: read" on public.profiles
  for select to authenticated using (true);
create policy "profiles: insert own" on public.profiles
  for insert to authenticated with check (id = auth.uid()::text);
create policy "profiles: update own" on public.profiles
  for update to authenticated using (id = auth.uid()::text);

-- The owner_id check matters for a brand new list: insert ... on conflict
-- also checks the new row against the select policy, and is_member() can't
-- find a row that isn't there yet.
create policy "lists: read" on public.lists
  for select to authenticated using (owner_id = auth.uid()::text or public.is_member(id));
create policy "lists: create own" on public.lists
  for insert to authenticated with check (owner_id = auth.uid()::text);
create policy "lists: members edit" on public.lists
  for update to authenticated using (owner_id = auth.uid()::text or public.is_member(id));

create policy "members: read" on public.list_members
  for select to authenticated using (public.is_member(list_id));
-- People add themselves to lists they own. Everyone else joins with an invite.
create policy "members: owner adds self" on public.list_members
  for insert to authenticated with check (
    user_id = auth.uid()::text
    and exists (select 1 from public.lists l where l.id = list_id and l.owner_id = auth.uid()::text)
  );
create policy "members: edit" on public.list_members
  for update to authenticated using (public.is_member(list_id));

create policy "items: read" on public.items
  for select to authenticated using (public.is_member(list_id));
create policy "items: add" on public.items
  for insert to authenticated with check (public.is_member(list_id));
create policy "items: edit" on public.items
  for update to authenticated using (public.is_member(list_id));

create policy "activities: read" on public.activities
  for select to authenticated using (public.is_member(list_id));
create policy "activities: add own" on public.activities
  for insert to authenticated with check (public.is_member(list_id) and actor_id = auth.uid()::text);
create policy "activities: edit own" on public.activities
  for update to authenticated using (actor_id = auth.uid()::text);

create policy "usuals: own" on public.usuals
  for all to authenticated
  using (owner_id = auth.uid()::text)
  with check (owner_id = auth.uid()::text);

-- invites has no policies on purpose: nobody can read it directly.

-- ------------------------------------------------------------ apply_patch

create or replace function public.apply_patch(
  p_table text,
  p_id text,
  p_values jsonb,
  p_times jsonb
)
returns void
language plpgsql
security invoker -- so row level security still applies
set search_path = public
as $$
declare
  current_row  jsonb;
  merged       jsonb;
  merged_times jsonb;
  k            text;
  new_time     bigint;
  old_time     bigint;
  column_list  text;
  update_list  text;
begin
  if p_table not in ('profiles', 'lists', 'list_members', 'items', 'activities', 'usuals') then
    raise exception 'unknown table %', p_table;
  end if;

  execute format('select to_jsonb(t) from public.%I t where id = $1 for update', p_table)
    into current_row
    using p_id;

  if current_row is null then
    merged := '{}'::jsonb;
    merged_times := '{}'::jsonb;
  else
    merged := current_row - 'field_times' - 'updated_at';
    merged_times := coalesce(current_row -> 'field_times', '{}'::jsonb);
  end if;

  -- Per-field last-write-wins. On an exact tie the bigger JSON value wins,
  -- the same arbitrary but stable rule as the app.
  for k in select jsonb_object_keys(p_values) loop
    continue when k in ('id', 'field_times', 'updated_at');
    new_time := coalesce((p_times ->> k)::bigint, 0);
    old_time := (merged_times ->> k)::bigint;

    if old_time is null
       or new_time > old_time
       or (new_time = old_time and (p_values -> k)::text > coalesce((merged -> k)::text, 'null')) then
      merged := jsonb_set(merged, array[k], p_values -> k, true);
      merged_times := jsonb_set(merged_times, array[k], to_jsonb(new_time), true);
    end if;
  end loop;

  merged := merged || jsonb_build_object(
    'id', p_id,
    'field_times', merged_times,
    'updated_at', coalesce((select max(value::bigint) from jsonb_each_text(merged_times)), 0)
  );

  -- Only write the columns we have, so a new row still gets its defaults.
  select
    string_agg(format('%I', column_name), ', '),
    string_agg(format('%I = excluded.%I', column_name, column_name), ', ')
      filter (where column_name <> 'id')
  into column_list, update_list
  from information_schema.columns
  where table_schema = 'public' and table_name = p_table and merged ? column_name;

  execute format(
    'insert into public.%I (%s) select %s from jsonb_populate_record(null::public.%I, $1) '
    'on conflict (id) do update set %s',
    p_table, column_list, column_list, p_table, update_list
  )
  using merged;
end;
$$;

grant execute on function public.apply_patch(text, text, jsonb, jsonb) to authenticated;

-- ---------------------------------------------------------------- invites

create or replace function public.create_invite(p_list_id text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  -- No 0/O or 1/I, they are easy to mix up when typing a code.
  alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  new_code text;
begin
  if not is_member(p_list_id) then
    raise exception 'not a member of this list';
  end if;

  loop
    new_code := '';
    for i in 1..6 loop
      new_code := new_code || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from invites where code = new_code);
  end loop;

  insert into invites (code, list_id, created_by) values (new_code, p_list_id, auth.uid()::text);
  return new_code;
end;
$$;

create or replace function public.preview_invite(p_code text)
returns table (
  list_id        text,
  list_name      text,
  inviter_name   text,
  member_count   int,
  item_count     int,
  already_member boolean
)
language sql
security definer
stable
set search_path = public
as $$
  select
    l.id,
    l.name,
    coalesce(p.name, 'Someone'),
    (select count(*)::int from list_members m where m.list_id = l.id and not m.deleted),
    (select count(*)::int from items i where i.list_id = l.id and not i.deleted),
    exists (
      select 1 from list_members m
      where m.list_id = l.id and m.user_id = auth.uid()::text and not m.deleted
    )
  from invites inv
  join lists l on l.id = inv.list_id
  left join profiles p on p.id = inv.created_by
  where inv.code = upper(p_code) and inv.expires_at > now() and not l.deleted;
$$;

create or replace function public.join_list(p_code text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  target text;
  me     text := auth.uid()::text;
  now_ms bigint := (extract(epoch from clock_timestamp()) * 1000)::bigint;
begin
  select inv.list_id into target
  from invites inv
  where inv.code = upper(p_code) and inv.expires_at > now();

  if target is null then
    raise exception 'invite not valid';
  end if;

  insert into list_members (id, list_id, user_id, deleted, field_times, updated_at)
  values (
    target || ':' || me, target, me, false,
    jsonb_build_object('list_id', now_ms, 'user_id', now_ms, 'deleted', now_ms),
    now_ms
  )
  on conflict (id) do update set
    deleted = false,
    field_times = list_members.field_times || jsonb_build_object('deleted', now_ms),
    updated_at = now_ms;

  insert into activities (id, list_id, actor_id, kind, item_name, created_at, field_times, updated_at)
  values (
    gen_random_uuid()::text, target, me, 'joined', '', now_ms,
    jsonb_build_object('list_id', now_ms, 'actor_id', now_ms, 'kind', now_ms, 'item_name', now_ms, 'created_at', now_ms),
    now_ms
  );

  return target;
end;
$$;

grant execute on function public.create_invite(text) to authenticated;
grant execute on function public.preview_invite(text) to authenticated;
grant execute on function public.join_list(text) to authenticated;

-- --------------------------------------------------------------- realtime

alter publication supabase_realtime
  add table public.profiles, public.lists, public.list_members,
            public.items, public.activities, public.usuals;
