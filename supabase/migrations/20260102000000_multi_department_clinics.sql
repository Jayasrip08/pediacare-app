-- =====================================================================
-- Multi-Department Support Migration
-- Adds department configuration to clinics and specialty tables for:
-- 1. Pediatrics
-- 2. Dermatology
-- 3. Dental
-- 4. Pregnancy Care
-- 5. Ophthalmology (Eye Clinics)
-- 6. Psychiatry & Counselling
-- =====================================================================

-- 1. Add department column to clinics table
alter table public.clinics
  add column if not exists department text not null default 'pediatrics'
  check (department in ('pediatrics', 'dermatology', 'dental', 'pregnancy_care', 'ophthalmology', 'psychiatry'));

create index if not exists clinics_department_idx on public.clinics(department);

-- =====================================================================
-- 2. DENTAL TABLES
-- =====================================================================
create table if not exists public.dental_tooth_records (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.children(id) on delete cascade,
  clinic_id uuid references public.clinics(id) on delete set null,
  tooth_number int not null check (tooth_number between 1 and 32),
  name text not null,
  arch text not null check (arch in ('upper', 'lower')),
  condition text not null default 'sound',
  surfaces text[] default array[]::text[],
  notes text,
  last_treated timestamptz,
  updated_at timestamptz not null default now(),
  unique (patient_id, tooth_number)
);
create index if not exists dental_tooth_patient_idx on public.dental_tooth_records(patient_id);

create table if not exists public.dental_treatment_plans (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.children(id) on delete cascade,
  clinic_id uuid references public.clinics(id) on delete set null,
  procedure_name text not null,
  teeth_involved text not null,
  estimated_cost numeric(10,2) not null default 0,
  is_completed boolean not null default false,
  scheduled_date timestamptz,
  notes text,
  created_at timestamptz not null default now()
);
create index if not exists dental_plans_patient_idx on public.dental_treatment_plans(patient_id);

-- =====================================================================
-- 3. DERMATOLOGY TABLES
-- =====================================================================
create table if not exists public.derma_comparisons (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.children(id) on delete cascade,
  clinic_id uuid references public.clinics(id) on delete set null,
  title text not null,
  affected_area text not null,
  before_date date not null,
  after_date date not null,
  before_photo_url text,
  after_photo_url text,
  treatment_tag text,
  condition_notes text,
  created_at timestamptz not null default now()
);
create index if not exists derma_comp_patient_idx on public.derma_comparisons(patient_id);

create table if not exists public.derma_sessions (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.children(id) on delete cascade,
  clinic_id uuid references public.clinics(id) on delete set null,
  treatment_name text not null,
  session_number int not null default 1,
  total_sessions int not null default 6,
  session_date date not null default current_date,
  energy_parameters text,
  clinical_reaction text,
  next_session_date date,
  notes text,
  is_completed boolean not null default true,
  created_at timestamptz not null default now()
);
create index if not exists derma_sessions_patient_idx on public.derma_sessions(patient_id);

-- =====================================================================
-- 4. PREGNANCY CARE TABLES
-- =====================================================================
create table if not exists public.pregnancy_records (
  patient_id uuid primary key references public.children(id) on delete cascade,
  clinic_id uuid references public.clinics(id) on delete set null,
  lmp date not null,
  edd date not null,
  gravida int not null default 1,
  para int not null default 0,
  blood_group text default 'O+',
  is_high_risk boolean not null default false,
  high_risk_reason text,
  updated_at timestamptz not null default now()
);

create table if not exists public.anc_checkups (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.children(id) on delete cascade,
  clinic_id uuid references public.clinics(id) on delete set null,
  date date not null default current_date,
  gestational_weeks int not null,
  blood_pressure text not null,
  weight_kg numeric(5,2) not null,
  fundal_height_cm numeric(4,1),
  fetal_heart_rate_bpm int,
  urine_sugar_albumin text,
  doctor_advice text,
  created_at timestamptz not null default now()
);
create index if not exists anc_patient_idx on public.anc_checkups(patient_id);

-- =====================================================================
-- 5. OPHTHALMOLOGY & EYE CLINIC TABLES
-- =====================================================================
create table if not exists public.ophthalmology_refractions (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.children(id) on delete cascade,
  clinic_id uuid references public.clinics(id) on delete set null,
  date date not null default current_date,
  od_sphere numeric(4,2) not null default 0.0,
  od_cylinder numeric(4,2) not null default 0.0,
  od_axis int not null default 0,
  od_add numeric(4,2),
  od_va text not null default '6/6',
  os_sphere numeric(4,2) not null default 0.0,
  os_cylinder numeric(4,2) not null default 0.0,
  os_axis int not null default 0,
  os_add numeric(4,2),
  os_va text not null default '6/6',
  pupillary_distance_mm numeric(4,1) not null default 62.0,
  lens_type_advice text,
  notes text,
  created_at timestamptz not null default now()
);
create index if not exists eye_refraction_patient_idx on public.ophthalmology_refractions(patient_id);

create table if not exists public.eye_exam_records (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.children(id) on delete cascade,
  clinic_id uuid references public.clinics(id) on delete set null,
  date date not null default current_date,
  iop_od numeric(4,1) not null default 15.0,
  iop_os numeric(4,1) not null default 15.0,
  slit_lamp_findings text,
  fundus_findings text,
  diagnosis text,
  eye_drop_medications text,
  created_at timestamptz not null default now()
);
create index if not exists eye_exam_patient_idx on public.eye_exam_records(patient_id);

-- =====================================================================
-- 6. PSYCHIATRY & COUNSELLING TABLES
-- =====================================================================
create table if not exists public.psychiatry_screeners (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.children(id) on delete cascade,
  clinic_id uuid references public.clinics(id) on delete set null,
  date timestamptz not null default now(),
  type text not null check (type in ('phq9', 'gad7')),
  total_score int not null,
  severity_band text not null,
  answers int[] not null,
  clinical_summary text,
  created_at timestamptz not null default now()
);
create index if not exists screener_patient_idx on public.psychiatry_screeners(patient_id);

create table if not exists public.therapy_notes (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.children(id) on delete cascade,
  clinic_id uuid references public.clinics(id) on delete set null,
  date date not null default current_date,
  session_number int not null default 1,
  modality text not null,
  subjective text not null,
  objective text not null,
  assessment text not null,
  plan text not null,
  risk_level text not null default 'Low',
  created_at timestamptz not null default now()
);
create index if not exists therapy_notes_patient_idx on public.therapy_notes(patient_id);

create table if not exists public.coping_goals (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.children(id) on delete cascade,
  clinic_id uuid references public.clinics(id) on delete set null,
  title text not null,
  description text not null,
  category text not null,
  is_completed boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists coping_goals_patient_idx on public.coping_goals(patient_id);

-- =====================================================================
-- ROW LEVEL SECURITY (RLS) FOR ALL NEW TABLES
-- =====================================================================
alter table public.dental_tooth_records enable row level security;
alter table public.dental_treatment_plans enable row level security;
alter table public.derma_comparisons enable row level security;
alter table public.derma_sessions enable row level security;
alter table public.pregnancy_records enable row level security;
alter table public.anc_checkups enable row level security;
alter table public.ophthalmology_refractions enable row level security;
alter table public.eye_exam_records enable row level security;
alter table public.psychiatry_screeners enable row level security;
alter table public.therapy_notes enable row level security;
alter table public.coping_goals enable row level security;

-- Parents see records for their own children; doctors see records for clinic patients
create policy "dental_parent_select" on public.dental_tooth_records for select
  using (patient_id in (select id from public.children where parent_id = auth.uid()));
create policy "dental_doctor_all" on public.dental_tooth_records for all
  using (patient_id in (select child_id from public.clinic_patients where clinic_id in (select id from public.clinics where doctor_id = auth.uid())));

create policy "derma_parent_select" on public.derma_comparisons for select
  using (patient_id in (select id from public.children where parent_id = auth.uid()));
create policy "derma_doctor_all" on public.derma_comparisons for all
  using (patient_id in (select child_id from public.clinic_patients where clinic_id in (select id from public.clinics where doctor_id = auth.uid())));

create policy "pregnancy_parent_select" on public.pregnancy_records for select
  using (patient_id in (select id from public.children where parent_id = auth.uid()));
create policy "pregnancy_doctor_all" on public.pregnancy_records for all
  using (patient_id in (select child_id from public.clinic_patients where clinic_id in (select id from public.clinics where doctor_id = auth.uid())));

create policy "ophthalmology_parent_select" on public.ophthalmology_refractions for select
  using (patient_id in (select id from public.children where parent_id = auth.uid()));
create policy "ophthalmology_doctor_all" on public.ophthalmology_refractions for all
  using (patient_id in (select child_id from public.clinic_patients where clinic_id in (select id from public.clinics where doctor_id = auth.uid())));

create policy "psychiatry_parent_select" on public.psychiatry_screeners for select
  using (patient_id in (select id from public.children where parent_id = auth.uid()));
create policy "psychiatry_doctor_all" on public.psychiatry_screeners for all
  using (patient_id in (select child_id from public.clinic_patients where clinic_id in (select id from public.clinics where doctor_id = auth.uid())));
