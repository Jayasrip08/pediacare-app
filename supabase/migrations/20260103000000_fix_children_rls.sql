-- Migration: 20260103000000_fix_children_rls.sql
-- Fix Row Level Security policies for children, child_vaccines and profile check constraints

-- 1. Relax profile full_name check so single-letter or trimmed names never fail
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_full_name_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_full_name_check CHECK (char_length(trim(full_name)) >= 1);

-- 2. Drop existing children policies
DROP POLICY IF EXISTS children_select ON public.children;
DROP POLICY IF EXISTS children_insert ON public.children;
DROP POLICY IF EXISTS children_update ON public.children;
DROP POLICY IF EXISTS children_delete ON public.children;

-- 3. Direct parent ownership check on children
-- Using parent_id = auth.uid() directly enables PostgreSQL INSERT ... RETURNING * to evaluate cleanly
CREATE POLICY children_select ON public.children FOR SELECT TO authenticated
  USING (
    parent_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.clinic_patients cp
      JOIN public.clinics cl ON cl.id = cp.clinic_id
      WHERE cp.child_id = children.id AND cl.doctor_id = auth.uid()
    )
  );

CREATE POLICY children_insert ON public.children FOR INSERT TO authenticated
  WITH CHECK (parent_id = auth.uid());

CREATE POLICY children_update ON public.children FOR UPDATE TO authenticated
  USING (parent_id = auth.uid()) WITH CHECK (parent_id = auth.uid());

CREATE POLICY children_delete ON public.children FOR DELETE TO authenticated
  USING (parent_id = auth.uid());

-- 4. Ensure automatic vaccine schedule trigger can insert rows
DROP POLICY IF EXISTS cv_insert ON public.child_vaccines;
CREATE POLICY cv_insert ON public.child_vaccines FOR INSERT TO authenticated
  WITH CHECK (true);

-- 5. Grant table privileges to authenticated role
GRANT ALL ON public.children TO authenticated;
GRANT ALL ON public.child_vaccines TO authenticated;
GRANT ALL ON public.profiles TO authenticated;
