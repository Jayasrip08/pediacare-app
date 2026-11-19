-- =====================================================================
-- PediaCare - Supabase schema, security (RLS), functions and storage
-- Phase 1 MVP.  Run once in Supabase Dashboard > SQL Editor
-- (or `supabase db push`).  Then run supabase/seed.sql.
--
-- Time zone note: clinic "days" are computed in Asia/Kolkata.
-- =====================================================================
create extension if not exists pgcrypto;

-- ---------- Enums -----------------------------------------------------
create type public.user_role          as enum ('parent', 'doctor');
create type public.vaccine_status     as enum ('pending', 'done', 'skipped');
create type public.appointment_status as enum ('booked', 'in_consult', 'completed', 'cancelled', 'no_show');

-- ---------- Tables ----------------------------------------------------
create table public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  role       public.user_role not null,
  full_name  text not null check (char_length(full_name) between 2 and 120),
  phone      text,
  created_at timestamptz not null default now()
);

create table public.clinics (
  id            uuid primary key default gen_random_uuid(),
  doctor_id     uuid not null unique references public.profiles(id) on delete cascade,
  name          text not null,
  address       text,
  phone         text,
  join_code     text not null unique default upper(substr(encode(gen_random_bytes(5), 'hex'), 1, 8)),
  open_time     time not null default '10:00',
  close_time    time not null default '18:00',
  slot_minutes  int  not null default 15 check (slot_minutes between 5 and 120),
  created_at    timestamptz not null default now()
);

create table public.children (
  id                uuid primary key default gen_random_uuid(),
  parent_id         uuid not null references public.profiles(id) on delete cascade,
  name              text not null check (char_length(name) between 1 and 120),
  dob               date not null check (dob <= current_date),
  gender            text not null check (gender in ('male', 'female', 'other')),
  blood_group       text,
  allergies         text,
  consent_given_at  timestamptz not null,           -- DPDP Act: parental consent
  created_at        timestamptz not null default now()
);
create index children_parent_idx on public.children(parent_id);

create table public.clinic_patients (
  clinic_id     uuid not null references public.clinics(id)  on delete cascade,
  child_id      uuid not null references public.children(id) on delete cascade,
  joined_at     timestamptz not null default now(),
  last_visit_at timestamptz,
  primary key (clinic_id, child_id)
);
create index clinic_patients_child_idx on public.clinic_patients(child_id);

create table public.vaccine_templates (
  id               serial primary key,
  name             text not null,
  protects_against text,
  age_label        text not null,
  offset_days      int  not null
);

create table public.child_vaccines (
  id          uuid primary key default gen_random_uuid(),
  child_id    uuid not null references public.children(id) on delete cascade,
  template_id int  not null references public.vaccine_templates(id),
  due_date    date not null,
  status      public.vaccine_status not null default 'pending',
  given_on    date,
  notes       text,
  unique (child_id, template_id)
);
create index child_vaccines_due_idx on public.child_vaccines(status, due_date);

create table public.growth_records (
  id          uuid primary key default gen_random_uuid(),
  child_id    uuid not null references public.children(id) on delete cascade,
  measured_on date not null default current_date,
  weight_kg   numeric(5,2) check (weight_kg > 0 and weight_kg < 200),
  height_cm   numeric(5,1) check (height_cm > 0 and height_cm < 250),
  head_cm     numeric(4,1) check (head_cm > 0 and head_cm < 80),
  recorded_by uuid default auth.uid() references public.profiles(id),
  created_at  timestamptz not null default now()
);
create index growth_child_idx on public.growth_records(child_id, measured_on);

create table public.appointments (
  id           uuid primary key default gen_random_uuid(),
  clinic_id    uuid not null references public.clinics(id)  on delete cascade,
  child_id     uuid not null references public.children(id) on delete cascade,
  parent_id    uuid not null references public.profiles(id),
  scheduled_at timestamptz not null,
  reason       text,
  symptoms     text,
  status       public.appointment_status not null default 'booked',
  token_no     int,
  created_at   timestamptz not null default now()
);
create unique index appointments_slot_unique
  on public.appointments (clinic_id, scheduled_at)
  where status in ('booked', 'in_consult', 'completed');
create index appointments_child_idx  on public.appointments(child_id, scheduled_at desc);
create index appointments_clinic_idx on public.appointments(clinic_id, scheduled_at);

create table public.drug_formulary (
  id                      serial primary key,
  clinic_id               uuid references public.clinics(id) on delete cascade, -- null = global default
  name                    text not null,
  form                    text not null default 'Syrup',
  strength_mg             numeric not null,
  strength_ml             numeric not null,
  mg_per_kg_per_dose      numeric not null,
  doses_per_day           int     not null,
  max_mg_per_kg_per_day   numeric not null,
  max_single_dose_mg      numeric,
  min_age_months          int     not null default 0,
  default_duration_days   int     not null default 3,
  instructions            text,
  reviewed                boolean not null default false  -- set true after clinical review
);

create table public.prescriptions (
  id             uuid primary key default gen_random_uuid(),
  clinic_id      uuid not null references public.clinics(id)  on delete cascade,
  child_id       uuid not null references public.children(id) on delete cascade,
  doctor_id      uuid not null references public.profiles(id),
  appointment_id uuid references public.appointments(id) on delete set null,
  weight_kg      numeric(5,2) not null,
  diagnosis      text,
  items          jsonb not null default '[]'::jsonb,
  notes          text,
  follow_up_date date,
  created_at     timestamptz not null default now()
);
create index prescriptions_child_idx on public.prescriptions(child_id, created_at desc);

create table public.medical_records (
  id          uuid primary key default gen_random_uuid(),
  child_id    uuid not null references public.children(id) on delete cascade,
  uploaded_by uuid not null default auth.uid() references public.profiles(id),
  title       text not null,
  category    text not null default 'report',
  file_path   text not null,
  created_at  timestamptz not null default now()
);
create index records_child_idx on public.medical_records(child_id, created_at desc);

create table public.messages (
  id              uuid primary key default gen_random_uuid(),
  clinic_id       uuid not null references public.clinics(id)  on delete cascade,
  child_id        uuid not null references public.children(id) on delete cascade,
  sender_id       uuid not null default auth.uid() references public.profiles(id),
  sender_role     public.user_role not null,
  body            text,
  attachment_path text,
  created_at      timestamptz not null default now(),
  read_at         timestamptz,
  check (body is not null or attachment_path is not null)
);
create index messages_thread_idx on public.messages(child_id, clinic_id, created_at);

-- ---------- Helper functions (SECURITY DEFINER avoids RLS recursion) ---
create or replace function public.is_doctor() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'doctor');
$$;

create or replace function public.is_clinic_doctor(p_clinic uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from clinics where id = p_clinic and doctor_id = auth.uid());
$$;

create or replace function public.is_child_parent(p_child uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from children where id = p_child and parent_id = auth.uid());
$$;

create or replace function public.my_clinic_id() returns uuid
language sql stable security definer set search_path = public as $$
  select id from clinics where doctor_id = auth.uid() limit 1;
$$;

create or replace function public.can_access_child(p_child uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select public.is_child_parent(p_child)
      or exists (select 1 from clinic_patients cp
                 join clinics cl on cl.id = cp.clinic_id
                 where cp.child_id = p_child and cl.doctor_id = auth.uid());
$$;

create or replace function public.is_linked(p_clinic uuid, p_child uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from clinic_patients where clinic_id = p_clinic and child_id = p_child);
$$;

create or replace function public.parent_linked_to_clinic(p_clinic uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from clinic_patients cp
                 join children c on c.id = cp.child_id
                 where cp.clinic_id = p_clinic and c.parent_id = auth.uid());
$$;

create or replace function public.doctor_sees_parent(p_profile uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from children c
                 join clinic_patients cp on cp.child_id = c.id
                 join clinics cl on cl.id = cp.clinic_id
                 where c.parent_id = p_profile and cl.doctor_id = auth.uid());
$$;

-- ---------- Triggers ---------------------------------------------------
create or replace function public.prevent_role_change() returns trigger
language plpgsql as $$
begin
  if new.role <> old.role then raise exception 'Role cannot be changed'; end if;
  return new;
end $$;
create trigger profiles_no_role_change before update on public.profiles
  for each row execute function public.prevent_role_change();

-- Build the vaccine schedule automatically when a child is added
create or replace function public.generate_child_vaccines() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into child_vaccines (child_id, template_id, due_date)
  select new.id, t.id, new.dob + t.offset_days from vaccine_templates t;
  return new;
end $$;
create trigger children_generate_vaccines after insert on public.children
  for each row execute function public.generate_child_vaccines();

-- Sequential daily token per clinic
create or replace function public.assign_token() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_day date := (new.scheduled_at at time zone 'Asia/Kolkata')::date;
begin
  perform pg_advisory_xact_lock(hashtext(new.clinic_id::text || v_day::text));
  select coalesce(max(token_no), 0) + 1 into new.token_no
  from appointments
  where clinic_id = new.clinic_id
    and (scheduled_at at time zone 'Asia/Kolkata')::date = v_day;
  return new;
end $$;
create trigger appointments_assign_token before insert on public.appointments
  for each row execute function public.assign_token();

-- Parents may only cancel; doctors manage the queue
create or replace function public.guard_appointment_update() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if public.is_clinic_doctor(old.clinic_id) then return new; end if;
  if new.status is distinct from old.status and new.status <> 'cancelled' then
    raise exception 'Parents can only cancel appointments';
  end if;
  if new.scheduled_at is distinct from old.scheduled_at
     or new.clinic_id is distinct from old.clinic_id
     or new.child_id  is distinct from old.child_id then
    raise exception 'Appointment cannot be modified';
  end if;
  return new;
end $$;
create trigger appointments_guard before update on public.appointments
  for each row execute function public.guard_appointment_update();

create or replace function public.touch_last_visit() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'completed' and old.status is distinct from 'completed' then
    update clinic_patients set last_visit_at = now()
    where clinic_id = new.clinic_id and child_id = new.child_id;
  end if;
  return new;
end $$;
create trigger appointments_touch_visit after update on public.appointments
  for each row execute function public.touch_last_visit();

-- ---------- Row Level Security ----------------------------------------
alter table public.profiles          enable row level security;
alter table public.clinics           enable row level security;
alter table public.children          enable row level security;
alter table public.clinic_patients   enable row level security;
alter table public.vaccine_templates enable row level security;
alter table public.child_vaccines    enable row level security;
alter table public.growth_records    enable row level security;
alter table public.appointments      enable row level security;
alter table public.drug_formulary    enable row level security;
alter table public.prescriptions     enable row level security;
alter table public.medical_records   enable row level security;
alter table public.messages          enable row level security;

-- profiles
create policy profiles_select on public.profiles for select to authenticated
  using (id = auth.uid() or role = 'doctor' or public.doctor_sees_parent(id));
create policy profiles_insert on public.profiles for insert to authenticated
  with check (id = auth.uid());
create policy profiles_update on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- clinics
create policy clinics_select on public.clinics for select to authenticated
  using (doctor_id = auth.uid() or public.parent_linked_to_clinic(id));
create policy clinics_insert on public.clinics for insert to authenticated
  with check (doctor_id = auth.uid() and public.is_doctor());
create policy clinics_update on public.clinics for update to authenticated
  using (doctor_id = auth.uid()) with check (doctor_id = auth.uid());

-- children
create policy children_select on public.children for select to authenticated
  using (public.can_access_child(id));
create policy children_insert on public.children for insert to authenticated
  with check (parent_id = auth.uid());
create policy children_update on public.children for update to authenticated
  using (parent_id = auth.uid()) with check (parent_id = auth.uid());
create policy children_delete on public.children for delete to authenticated
  using (parent_id = auth.uid());

-- clinic_patients (rows are created only through join_clinic())
create policy cp_select on public.clinic_patients for select to authenticated
  using (public.is_clinic_doctor(clinic_id) or public.is_child_parent(child_id));
create policy cp_delete on public.clinic_patients for delete to authenticated
  using (public.is_child_parent(child_id));

-- vaccines
create policy vt_select on public.vaccine_templates for select to authenticated using (true);
create policy cv_select on public.child_vaccines for select to authenticated
  using (public.can_access_child(child_id));
create policy cv_update on public.child_vaccines for update to authenticated
  using (public.can_access_child(child_id)) with check (public.can_access_child(child_id));

-- growth
create policy gr_select on public.growth_records for select to authenticated
  using (public.can_access_child(child_id));
create policy gr_insert on public.growth_records for insert to authenticated
  with check (public.can_access_child(child_id));
create policy gr_delete on public.growth_records for delete to authenticated
  using (public.can_access_child(child_id) and recorded_by = auth.uid());

-- appointments
create policy ap_select on public.appointments for select to authenticated
  using (parent_id = auth.uid() or public.is_clinic_doctor(clinic_id));
create policy ap_insert on public.appointments for insert to authenticated
  with check (parent_id = auth.uid()
              and public.is_child_parent(child_id)
              and public.is_linked(clinic_id, child_id));
create policy ap_update on public.appointments for update to authenticated
  using (parent_id = auth.uid() or public.is_clinic_doctor(clinic_id));

-- formulary (doctors only)
create policy df_select on public.drug_formulary for select to authenticated
  using (public.is_doctor() and (clinic_id is null or clinic_id = public.my_clinic_id()));
create policy df_write on public.drug_formulary for all to authenticated
  using (clinic_id is not null and clinic_id = public.my_clinic_id())
  with check (clinic_id is not null and clinic_id = public.my_clinic_id());

-- prescriptions are immutable medical records: insert + select only
create policy rx_select on public.prescriptions for select to authenticated
  using (public.can_access_child(child_id));
create policy rx_insert on public.prescriptions for insert to authenticated
  with check (doctor_id = auth.uid()
              and public.is_clinic_doctor(clinic_id)
              and public.is_linked(clinic_id, child_id));

-- records vault
create policy mr_select on public.medical_records for select to authenticated
  using (public.can_access_child(child_id));
create policy mr_insert on public.medical_records for insert to authenticated
  with check (public.can_access_child(child_id) and uploaded_by = auth.uid());
create policy mr_delete on public.medical_records for delete to authenticated
  using (uploaded_by = auth.uid());

-- chat
create policy msg_select on public.messages for select to authenticated
  using (public.is_clinic_doctor(clinic_id) or public.is_child_parent(child_id));
create policy msg_insert on public.messages for insert to authenticated
  with check (
    sender_id = auth.uid() and public.is_linked(clinic_id, child_id) and (
      (sender_role = 'parent' and public.is_child_parent(child_id)) or
      (sender_role = 'doctor' and public.is_clinic_doctor(clinic_id))));
create policy msg_update on public.messages for update to authenticated
  using (public.is_clinic_doctor(clinic_id) or public.is_child_parent(child_id));
-- only the read receipt may be changed
revoke update on public.messages from authenticated;
grant  update (read_at) on public.messages to authenticated;

-- ---------- Views (RLS-aware) ------------------------------------------
create view public.missed_followups with (security_invoker = true) as
select p.id as prescription_id, p.clinic_id, p.child_id, c.name as child_name,
       p.follow_up_date, p.diagnosis
from public.prescriptions p
join public.children c on c.id = p.child_id
where p.follow_up_date < (now() at time zone 'Asia/Kolkata')::date
  and not exists (
    select 1 from public.appointments a
    where a.child_id = p.child_id and a.clinic_id = p.clinic_id
      and a.scheduled_at >= p.created_at
      and a.status in ('booked', 'in_consult', 'completed'));

create view public.clinic_pending_vaccines with (security_invoker = true) as
select cp.clinic_id, cv.id as child_vaccine_id, cv.child_id, c.name as child_name,
       vt.name as vaccine_name, cv.due_date
from public.child_vaccines cv
join public.children c           on c.id  = cv.child_id
join public.clinic_patients cp   on cp.child_id = cv.child_id
join public.vaccine_templates vt on vt.id = cv.template_id
where cv.status = 'pending'
  and cv.due_date <= (now() at time zone 'Asia/Kolkata')::date + 7;

-- ---------- RPC functions ----------------------------------------------
create or replace function public.join_clinic(p_code text, p_child uuid) returns json
language plpgsql security definer set search_path = public as $$
declare v_clinic clinics%rowtype;
begin
  if not exists (select 1 from children where id = p_child and parent_id = auth.uid()) then
    raise exception 'Child not found';
  end if;
  select * into v_clinic from clinics where join_code = upper(trim(p_code));
  if not found then raise exception 'Invalid clinic code'; end if;
  delete from clinic_patients where child_id = p_child and clinic_id <> v_clinic.id;
  insert into clinic_patients (clinic_id, child_id) values (v_clinic.id, p_child)
    on conflict do nothing;
  return to_json(v_clinic);
end $$;

create or replace function public.taken_slots(p_clinic uuid, p_day date) returns setof timestamptz
language sql stable security definer set search_path = public as $$
  select scheduled_at from appointments
  where clinic_id = p_clinic
    and (scheduled_at at time zone 'Asia/Kolkata')::date = p_day
    and status in ('booked', 'in_consult', 'completed')
    and (public.parent_linked_to_clinic(p_clinic) or public.is_clinic_doctor(p_clinic));
$$;

create or replace function public.queue_status(p_appointment uuid) returns json
language plpgsql stable security definer set search_path = public as $$
declare a appointments%rowtype; v_day date; v_ahead int; v_serving int;
begin
  select * into a from appointments where id = p_appointment and parent_id = auth.uid();
  if not found then return null; end if;
  v_day := (a.scheduled_at at time zone 'Asia/Kolkata')::date;
  select count(*) into v_ahead from appointments x
   where x.clinic_id = a.clinic_id and x.status in ('booked', 'in_consult')
     and (x.scheduled_at at time zone 'Asia/Kolkata')::date = v_day
     and x.scheduled_at < a.scheduled_at;
  select token_no into v_serving from appointments x
   where x.clinic_id = a.clinic_id and x.status = 'in_consult'
     and (x.scheduled_at at time zone 'Asia/Kolkata')::date = v_day
   order by x.scheduled_at limit 1;
  return json_build_object('token', a.token_no, 'ahead', v_ahead, 'now_serving', v_serving);
end $$;

create or replace function public.doctor_stats(p_clinic uuid) returns json
language sql stable set search_path = public as $$
  select json_build_object(
    'patients',            (select count(*) from clinic_patients where clinic_id = p_clinic),
    'pending_vaccines',    (select count(*) from clinic_pending_vaccines where clinic_id = p_clinic),
    'missed_followups',    (select count(*) from missed_followups where clinic_id = p_clinic),
    'unread_messages',     (select count(*) from messages
                             where clinic_id = p_clinic and sender_role = 'parent' and read_at is null),
    'todays_appointments', (select count(*) from appointments
                             where clinic_id = p_clinic
                               and (scheduled_at at time zone 'Asia/Kolkata')::date =
                                   (now() at time zone 'Asia/Kolkata')::date
                               and status in ('booked', 'in_consult', 'completed')));
$$;

create or replace function public.doctor_chat_threads(p_clinic uuid)
returns table (child_id uuid, child_name text, last_body text, last_at timestamptz, unread bigint)
language sql stable set search_path = public as $$
  select m.child_id, c.name,
         (array_agg(coalesce(m.body, 'Attachment') order by m.created_at desc))[1],
         max(m.created_at),
         count(*) filter (where m.sender_role = 'parent' and m.read_at is null)
  from messages m join children c on c.id = m.child_id
  where m.clinic_id = p_clinic
  group by m.child_id, c.name
  order by max(m.created_at) desc;
$$;

-- ---------- Storage (private bucket, folder = child id) ----------------
insert into storage.buckets (id, name, public) values ('child-files', 'child-files', false)
  on conflict (id) do nothing;

create policy child_files_select on storage.objects for select to authenticated
  using (bucket_id = 'child-files' and public.can_access_child(((storage.foldername(name))[1])::uuid));
create policy child_files_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'child-files' and public.can_access_child(((storage.foldername(name))[1])::uuid));
create policy child_files_delete on storage.objects for delete to authenticated
  using (bucket_id = 'child-files' and owner = auth.uid());

-- ---------- Realtime ---------------------------------------------------
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.appointments;
