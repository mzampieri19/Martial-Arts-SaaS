-- 002_user_class_stats_and_fields.sql

-- 1) Add optional metadata fields to attendance table
ALTER TABLE public.user_class_attendance
  ADD COLUMN IF NOT EXISTS session_type text,
  ADD COLUMN IF NOT EXISTS duration_minutes integer,
  ADD COLUMN IF NOT EXISTS notes text;

-- 2) Create a richer aggregation view that computes useful stats per user+class
CREATE OR REPLACE VIEW public.view_user_class_stats AS
SELECT
  user_id,
  class_id,
  COUNT(*)::int AS attended_count,
  MIN(attended_at) AS first_attended_at,
  MAX(attended_at) AS last_attended_at,
  COUNT(DISTINCT date_trunc('week', attended_at))::int AS weeks_active,
  (COUNT(*)::numeric / NULLIF(GREATEST(1, COUNT(DISTINCT date_trunc('week', attended_at))), 0))::numeric(10,2) AS avg_per_week,
  SUM(CASE WHEN attended_at >= now() - interval '30 days' THEN 1 ELSE 0 END)::int AS last_30_days_count
FROM public.user_class_attendance
GROUP BY user_id, class_id;

GRANT SELECT ON public.view_user_class_stats TO authenticated;

-- 3) Optional RPC wrapper to fetch stats for a single user (convenience)
CREATE OR REPLACE FUNCTION public.get_user_class_stats(p_user_id uuid)
RETURNS TABLE(
  class_id bigint,
  attended_count int,
  first_attended_at timestamptz,
  last_attended_at timestamptz,
  weeks_active int,
  avg_per_week numeric,
  last_30_days_count int
)
LANGUAGE sql STABLE
AS $$
  SELECT
    class_id,
    COUNT(*)::int AS attended_count,
    MIN(attended_at) AS first_attended_at,
    MAX(attended_at) AS last_attended_at,
    COUNT(DISTINCT date_trunc('week', attended_at))::int AS weeks_active,
    (COUNT(*)::numeric / NULLIF(GREATEST(1, COUNT(DISTINCT date_trunc('week', attended_at))), 0))::numeric(10,2) AS avg_per_week,
    SUM(CASE WHEN attended_at >= now() - interval '30 days' THEN 1 ELSE 0 END)::int AS last_30_days_count
  FROM public.user_class_attendance
  WHERE user_id = p_user_id
  GROUP BY class_id;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_class_stats(uuid) TO authenticated;
