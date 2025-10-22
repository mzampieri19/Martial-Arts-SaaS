-- 004_seed_more_classes_and_goals.sql
-- Seed additional classes and detailed goals to test tracking UI

-- 1) Insert sample classes
INSERT INTO public.classes (class_name, difficulty, type_of_class, target_sessions)
VALUES
  ('Karate Basics', 2, 4, 12),
  ('Karate Sparring', 3, 4, 14),
  ('TaeKwonDo Forms', 2, 1, 10),
  ('Hapkido Fundamentals', 2, 2, 10),
  ('Judo Throws', 4, 3, 16),
  ('Advanced Judo', 4, 3, 16),
  ('Mixed Martial Arts Intro', 3, 5, 12)
ON CONFLICT (id) DO NOTHING;

-- 2) Insert more detailed goals for multiple classes
INSERT INTO public.class_goals (class_id, title, description, required_sessions, sort_order)
VALUES
  ((SELECT id FROM public.classes WHERE class_name='Karate Basics' LIMIT 1), 'Stance & Footwork', 'Master front/back stance and basic movement', 3, 10),
  ((SELECT id FROM public.classes WHERE class_name='Karate Basics' LIMIT 1), 'Basic Punches', 'Jab, cross, hook basics', 4, 20),
  ((SELECT id FROM public.classes WHERE class_name='Karate Basics' LIMIT 1), 'Kihon Kata 1', 'Learn kata 1 form', 5, 30),
  ((SELECT id FROM public.classes WHERE class_name='Karate Sparring' LIMIT 1), 'Controlled Sparring', '3 rounds controlled sparring', 6, 10),
  ((SELECT id FROM public.classes WHERE class_name='Karate Sparring' LIMIT 1), 'Defensive Drills', 'Blocking and countering', 4, 20),
  ((SELECT id FROM public.classes WHERE class_name='TaeKwonDo Forms' LIMIT 1), 'Pattern 1', 'Learn pattern 1 sequence', 4, 10),
  ((SELECT id FROM public.classes WHERE class_name='Hapkido Fundamentals' LIMIT 1), 'Joint Locks', 'Basic wrist and arm locks', 5, 10),
  ((SELECT id FROM public.classes WHERE class_name='Judo Throws' LIMIT 1), 'O Goshi', 'Perfect the hip throw O Goshi', 6, 10),
  ((SELECT id FROM public.classes WHERE class_name='Advanced Judo' LIMIT 1), 'Combination Throws', 'Link multiple throws smoothly', 8, 10),
  ((SELECT id FROM public.classes WHERE class_name='Mixed Martial Arts Intro' LIMIT 1), 'Ground Control', 'Basic takedown and ground position control', 5, 10)
ON CONFLICT DO NOTHING;

-- 3) Optionally, insert a few user_goal_progress rows for a real user (replace with real user id)
INSERT INTO public.user_goal_progress (user_id, goal_id, notes)
VALUES
('<24f77771-3c41-419d-83fb-edbb83d80591>', (SELECT id FROM public.class_goals WHERE title='Stance & Footwork' LIMIT 1), 'Good progress'),
('<24f77771-3c41-419d-83fb-edbb83d80591>', (SELECT id FROM public.class_goals WHERE title='Basic Punches' LIMIT 1), NULL)
-- ON CONFLICT DO NOTHING;
