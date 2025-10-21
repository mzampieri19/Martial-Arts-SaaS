-- 008_remove_goals_achieved_from_classes.sql
-- Diagnostics + safe migration to remove legacy `goals_achieved` from `public.classes`.
-- Run the SELECTs below first to inspect current schema and constraint names.

-- 1) Inspect columns on classes
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'classes';

-- 2) Show foreign key constraints on classes
SELECT tc.constraint_name, kcu.column_name, ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name, pg_get_constraintdef(pc.oid) as def
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name
JOIN pg_constraint pc ON pc.conname = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema='public' AND tc.table_name='classes';

-- 3) Optional: show any triggers/functions that mention goals_achieved
SELECT proname, pg_get_functiondef(p.oid) AS definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE pg_get_functiondef(p.oid) ILIKE '%goals_achieved%';

-- ==================================================
-- If you confirmed a constraint named `classes_goals_achieved_fkey` exists and
-- you do not rely on the `goals_achieved` column, run the DROP commands below.
-- NOTE: it's safer to RENAME the column first so you can roll back quickly.
-- ==================================================

-- Safe rename (recommended before dropping):
-- ALTER TABLE public.classes RENAME COLUMN goals_achieved TO goals_achieved_deprecated;

-- Drop the FK constraint if present, then drop the column
ALTER TABLE public.classes DROP CONSTRAINT IF EXISTS classes_goals_achieved_fkey;
ALTER TABLE public.classes DROP COLUMN IF EXISTS goals_achieved;

-- After running, re-run the SELECTs above to confirm the column/constraint are gone.
