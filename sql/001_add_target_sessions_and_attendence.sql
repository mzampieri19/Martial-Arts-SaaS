-- 1) Ensure classes has target_sessions (safe: uses IF NOT EXISTS)
ALTER TABLE public.classes
  ADD COLUMN IF NOT EXISTS target_sessions integer;

-- Optional backfill heuristic (only sets where NULL)
UPDATE public.classes
SET target_sessions = GREATEST(8, COALESCE((difficulty::integer * 4 + 8), 8))
WHERE target_sessions IS NULL;

-- 2) Create attendance table (one row per attended session)
CREATE TABLE IF NOT EXISTS public.user_class_attendance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  class_id bigint NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
  attended_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

-- 3) Enable RLS and policies (so clients can only see/insert their own rows)
ALTER TABLE public.user_class_attendance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own attendance"
  ON public.user_class_attendance
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own attendance"
  ON public.user_class_attendance
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own attendance"
  ON public.user_class_attendance
  FOR DELETE
  USING (auth.uid() = user_id);


-- 4) Aggregation view: counts per user and class
CREATE OR REPLACE VIEW public.view_user_class_attendance_count AS
SELECT
  user_id,
  class_id,
  COUNT(*)::int AS attended_count,
  MIN(attended_at) AS first_attended_at,
  MAX(attended_at) AS last_attended_at
FROM public.user_class_attendance
GROUP BY user_id, class_id;

GRANT SELECT ON public.view_user_class_attendance_count TO authenticated;


-- 5) RPC: convenience function that returns counts for a user
CREATE OR REPLACE FUNCTION public.get_user_attendance_counts(p_user_id uuid)
RETURNS TABLE(class_id bigint, attended_count int)
LANGUAGE sql STABLE
AS $$
  SELECT class_id, COUNT(*)::int
  FROM public.user_class_attendance
  WHERE user_id = p_user_id
  GROUP BY class_id;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_attendance_counts(uuid) TO authenticated;


-- ========================================
-- 6) MOCK DATA (two classes + two users attendance)
-- Replace the user UUIDs with real user IDs if you want results tied to real accounts.
-- Mock user UUIDs:
--    user1: 11111111-1111-1111-1111-111111111111
--    user2: 22222222-2222-2222-2222-222222222222

-- Insert two sample classes (if they don't already exist)
INSERT INTO public.classes (class_name, difficulty, target_sessions)
VALUES
  ('Karate Basics', 2, 12),
  ('Advanced Judo', 4, 16)
ON CONFLICT (id) DO NOTHING; -- safe if classes already exist and id duplicated

-- Insert attendance rows for user1 (partial progress)
INSERT INTO public.user_class_attendance (user_id, class_id, attended_at)
VALUES
  ('165777ba-aa9a-416f-ac19-22e47868a4b6-1111-1111-111111111111', (SELECT id FROM public.classes WHERE class_name='Karate Basics' LIMIT 1), '2025-10-01T18:00:00Z'),
  ('165777ba-aa9a-416f-ac19-22e47868a4b6-1111-1111-111111111111', (SELECT id FROM public.classes WHERE class_name='Karate Basics' LIMIT 1), '2025-10-08T18:00:00Z'),
  ('165777ba-aa9a-416f-ac19-22e47868a4b6-1111-1111-111111111111', (SELECT id FROM public.classes WHERE class_name='Karate Basics' LIMIT 1), '2025-10-15T18:00:00Z'),
  ('165777ba-aa9a-416f-ac19-22e47868a4b6-1111-1111-111111111111', (SELECT id FROM public.classes WHERE class_name='Advanced Judo' LIMIT 1), '2025-10-05T19:00:00Z');

-- Insert attendance rows for user2 (complete or nearly complete)
INSERT INTO public.user_class_attendance (user_id, class_id, attended_at)
VALUES
  ('24f77771-3c41-419d-83fb-edbb83d80591-2222-2222-222222222222', (SELECT id FROM public.classes WHERE class_name='Karate Basics' LIMIT 1), '2025-09-01T18:00:00Z'),
  ('24f77771-3c41-419d-83fb-edbb83d80591-2222-2222-222222222222', (SELECT id FROM public.classes WHERE class_name='Karate Basics' LIMIT 1), '2025-09-08T18:00:00Z'),
  ('24f77771-3c41-419d-83fb-edbb83d80591-2222-2222-222222222222', (SELECT id FROM public.classes WHERE class_name='Karate Basics' LIMIT 1), '2025-09-15T18:00:00Z'),
  ('24f77771-3c41-419d-83fb-edbb83d80591-2222-2222-222222222222', (SELECT id FROM public.classes WHERE class_name='Karate Basics' LIMIT 1), '2025-09-22T18:00:00Z'),
  ('24f77771-3c41-419d-83fb-edbb83d80591-2222-2222-222222222222', (SELECT id FROM public.classes WHERE class_name='Karate Basics' LIMIT 1), '2025-09-29T18:00:00Z'),
  ('24f77771-3c41-419d-83fb-edbb83d80591-2222-2222-222222222222', (SELECT id FROM public.classes WHERE class_name='Karate Basics' LIMIT 1), '2025-10-06T18:00:00Z'),
  ('24f77771-3c41-419d-83fb-edbb83d80591-2222-2222-222222222222', (SELECT id FROM public.classes WHERE class_name='Karate Basics' LIMIT 1), '2025-10-13T18:00:00Z'),
  ('24f77771-3c41-419d-83fb-edbb83d80591-2222-2222-222222222222', (SELECT id FROM public.classes WHERE class_name='Karate Basics' LIMIT 1), '2025-10-20T18:00:00Z'),
  ('24f77771-3c41-419d-83fb-edbb83d80591-2222-2222-222222222222', (SELECT id FROM public.classes WHERE class_name='Karate Basics' LIMIT 1), '2025-10-27T18:00:00Z'),
  ('24f77771-3c41-419d-83fb-edbb83d80591-2222-2222-222222222222', (SELECT id FROM public.classes WHERE class_name='Karate Basics' LIMIT 1), '2025-11-03T18:00:00Z'),
  ('24f77771-3c41-419d-83fb-edbb83d80591-2222-2222-222222222222', (SELECT id FROM public.classes WHERE class_name='Karate Basics' LIMIT 1), '2025-11-10T18:00:00Z'),
  ('24f77771-3c41-419d-83fb-edbb83d80591-2222-2222-222222222222', (SELECT id FROM public.classes WHERE class_name='Karate Basics' LIMIT 1), '2025-11-17T18:00:00Z');
-- user2 has 12 attendance rows for Karate Basics -> with target_sessions=12 this is 100%


-- 7) Test queries (how to inspect results)

-- Use view:
SELECT * FROM public.view_user_class_attendance_count
WHERE user_id = '165777ba-aa9a-416f-ac19-22e47868a4b6-1111-1111-111111111111';

-- Example expected output for the view (approx):
-- user_id                                | class_id | attended_count | first_attended_at     | last_attended_at
-- 11111111-1111-1111-1111-111111111111    | <id>     | 3              | 2025-10-01T18:00:00Z  | 2025-10-15T18:00:00Z
-- 11111111-1111-1111-1111-111111111111    | <id>     | 1              | 2025-10-05T19:00:00Z  | 2025-10-05T19:00:00Z

-- Call the RPC:
SELECT * FROM public.get_user_attendance_counts('165777ba-aa9a-416f-ac19-22e47868a4b6-1111-1111-111111111111');

-- Example RPC output:
-- class_id | attended_count
-- <id>     | 3
-- <id>     | 1