insert into public.activity_categories (name, name_ml, icon, display_order)
values
  ('Prayer', 'നമസ്കാരം', 'mosque', 1),
  ('Sunnah Prayers', 'സുന്നത്ത് നമസ്കാരങ്ങൾ', 'auto_awesome', 2),
  ('Daily Routine', 'ദിനചര്യ', 'calendar_today', 3)
on conflict do nothing;

with categories as (
  select id, name from public.activity_categories
)
insert into public.activities (category_id, name, name_ml, display_order, has_quantity)
select c.id, x.name, x.name_ml, x.display_order, x.has_quantity
from categories c
join (
  values
    ('Prayer', 'Subhi', 'സുബ്ഹി', 1, false),
    ('Prayer', 'Zuhr', 'ളുഹ്ർ', 2, false),
    ('Prayer', 'Asr', 'അസർ', 3, false),
    ('Prayer', 'Maghrib', 'മഗ്‌രിബ്', 4, false),
    ('Prayer', 'Isha', 'ഇശാഅ്', 5, false),
    ('Sunnah Prayers', 'Before Subhi', 'സുബ്ഹിക്ക് മുമ്പ്', 1, false),
    ('Sunnah Prayers', 'Before Zuhr', 'ളുഹ്റിന് മുമ്പ്', 2, false),
    ('Sunnah Prayers', 'After Zuhr', 'ളുഹ്റിന് ശേഷം', 3, false),
    ('Sunnah Prayers', 'After Maghrib', 'മഗ്‌രിബിന് ശേഷം', 4, false),
    ('Sunnah Prayers', 'After Isha', 'ഇശാഇന് ശേഷം', 5, false),
    ('Daily Routine', 'Quran Recitation', 'ഖുർആൻ പാരായണം', 1, true),
    ('Daily Routine', 'Quran Study', 'ഖുർആൻ അർത്ഥ പഠനം', 2, false),
    ('Daily Routine', 'Hifz', 'ഹിഫ്സ്', 3, false),
    ('Daily Routine', 'Dhikr & Duas', 'ദിക്ർ, ദുആകൾ', 4, false),
    ('Daily Routine', 'Discipline & Cleanliness', 'ചിട്ടയും വൃത്തിയും', 5, false)
) as x(category_name, name, name_ml, display_order, has_quantity)
  on x.category_name = c.name
where not exists (
  select 1
  from public.activities a
  where a.category_id = c.id and a.name = x.name
);

insert into public.activity_ratings (activity_id, rating_name, rating_name_ml, marks, color, display_order)
select
  a.id,
  r.rating_name,
  r.rating_name_ml,
  r.marks,
  r.color,
  r.display_order
from public.activities a
cross join (
  values
    ('excellent', 'മികച്ചത്', 10, '#3FA34D', 1),
    ('satisfactory', 'തൃപ്തികരം', 5, '#F1B500', 2),
    ('needs_improvement', 'തൃപ്തികരമല്ല', 2, '#E07A11', 3),
    ('not_done', 'ചെയ്തില്ല', 0, '#9CA3AF', 4)
) as r(rating_name, rating_name_ml, marks, color, display_order)
where not exists (
  select 1
  from public.activity_ratings ar
  where ar.activity_id = a.id and ar.rating_name = r.rating_name
);

insert into public.badges (name, name_ml, description, criteria, bonus_points)
values
  (
    '7-Day Streak',
    '7 ദിവസത്തെ തുടർച്ച',
    'Logged activities for 7 consecutive days',
    '{"type":"streak","days":7}'::jsonb,
    25
  ),
  (
    '30-Day Streak',
    '30 ദിവസത്തെ തുടർച്ച',
    'Logged activities for 30 consecutive days',
    '{"type":"streak","days":30}'::jsonb,
    100
  ),
  (
    'Quran Master',
    'ഖുർആൻ മാസ്റ്റർ',
    'Completed configured Hifz target',
    '{"type":"hifz_target","value":1}'::jsonb,
    120
  ),
  (
    'Perfect Prayer Week',
    'പൂർണ്ണ നമസ്കാര ആഴ്ച',
    'Excellent in all mandatory prayers for 7 days',
    '{"type":"perfect_prayer_week","days":7}'::jsonb,
    75
  ),
  (
    'Monthly Top Performer',
    'മാസത്തിലെ മികച്ച പ്രകടനം',
    'Top rank in monthly leaderboard',
    '{"type":"leaderboard_rank","period":"monthly","rank":1}'::jsonb,
    150
  )
on conflict do nothing;
