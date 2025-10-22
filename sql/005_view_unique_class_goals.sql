-- 005_view_unique_class_goals.sql
-- Create a server-side deduplicated view of class goals so the client gets a single canonical goal per class/title

CREATE OR REPLACE VIEW public.view_unique_class_goals AS
SELECT DISTINCT ON (g.class_id, canonical_title)
  g.id,
  g.class_id,
  g.title,
  g.description,
  g.required_sessions,
  g.sort_order,
  g.created_at,
  canonical_title
FROM (
  SELECT g.*, regexp_replace(lower(coalesce(g.title, '')), '\s+', ' ', 'g') AS canonical_title
  FROM public.class_goals g
) g
ORDER BY g.class_id, canonical_title, g.sort_order, g.id;

GRANT SELECT ON public.view_unique_class_goals TO authenticated;
