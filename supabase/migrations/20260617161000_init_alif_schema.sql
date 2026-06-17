create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.current_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_role() = 'admin', false);
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text unique not null,
  full_name text not null,
  full_name_ml text,
  role text not null check (role in ('student', 'parent', 'teacher', 'admin')),
  profile_photo text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.batches (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  name_ml text,
  description text,
  capacity integer,
  timing text,
  status text default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  name_ml text,
  level text,
  batch_id uuid references public.batches(id) on delete set null,
  status text default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.teachers (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid unique references public.profiles(id) on delete cascade,
  email text,
  qualification text,
  status text default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid unique references public.profiles(id) on delete set null,
  parent_phone text not null,
  father_name text,
  mother_name text,
  date_of_birth date,
  gender text check (gender in ('male', 'female')),
  batch_id uuid references public.batches(id) on delete set null,
  class_id uuid references public.classes(id) on delete set null,
  address text,
  enrollment_date date default current_date,
  status text default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.parent_students (
  id uuid primary key default gen_random_uuid(),
  parent_profile_id uuid references public.profiles(id) on delete cascade,
  student_id uuid references public.students(id) on delete cascade,
  relationship text default 'parent',
  created_at timestamptz default now(),
  unique(parent_profile_id, student_id)
);

create table if not exists public.teacher_batches (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid references public.teachers(id) on delete cascade,
  batch_id uuid references public.batches(id) on delete cascade,
  created_at timestamptz default now(),
  unique(teacher_id, batch_id)
);

create table if not exists public.activity_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  name_ml text,
  icon text,
  display_order integer default 0,
  status text default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.activities (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.activity_categories(id) on delete cascade,
  name text not null,
  name_ml text,
  display_order integer default 0,
  has_quantity boolean default false,
  status text default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.activity_ratings (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.activities(id) on delete cascade,
  rating_name text not null,
  rating_name_ml text,
  marks integer not null check (marks >= 0),
  color text,
  display_order integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(activity_id, rating_name)
);

create table if not exists public.activity_logs (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  activity_id uuid not null references public.activities(id) on delete cascade,
  rating_id uuid not null references public.activity_ratings(id) on delete restrict,
  log_date date not null,
  quantity integer,
  marks_earned integer not null check (marks_earned >= 0),
  parent_approved boolean default false,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(student_id, activity_id, log_date)
);

create table if not exists public.badges (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  name_ml text,
  description text,
  icon text,
  criteria jsonb,
  bonus_points integer default 0,
  status text default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.student_badges (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  badge_id uuid not null references public.badges(id) on delete cascade,
  earned_at timestamptz default now(),
  unique(student_id, badge_id)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text,
  target_type text check (target_type in ('all', 'batch', 'class', 'student')),
  target_id uuid,
  scheduled_at timestamptz,
  sent_at timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now()
);

create table if not exists public.teacher_remarks (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  remark text not null,
  created_at timestamptz default now()
);

create index if not exists idx_students_batch on public.students(batch_id);
create index if not exists idx_activity_logs_student_date on public.activity_logs(student_id, log_date);
create index if not exists idx_activity_logs_date on public.activity_logs(log_date);
create index if not exists idx_notifications_target on public.notifications(target_type, target_id);

create trigger trg_profiles_updated_at before update on public.profiles
for each row execute function public.set_updated_at();
create trigger trg_batches_updated_at before update on public.batches
for each row execute function public.set_updated_at();
create trigger trg_classes_updated_at before update on public.classes
for each row execute function public.set_updated_at();
create trigger trg_teachers_updated_at before update on public.teachers
for each row execute function public.set_updated_at();
create trigger trg_students_updated_at before update on public.students
for each row execute function public.set_updated_at();
create trigger trg_activity_categories_updated_at before update on public.activity_categories
for each row execute function public.set_updated_at();
create trigger trg_activities_updated_at before update on public.activities
for each row execute function public.set_updated_at();
create trigger trg_activity_ratings_updated_at before update on public.activity_ratings
for each row execute function public.set_updated_at();
create trigger trg_activity_logs_updated_at before update on public.activity_logs
for each row execute function public.set_updated_at();
create trigger trg_badges_updated_at before update on public.badges
for each row execute function public.set_updated_at();

create or replace view public.daily_student_summary as
select
  s.id as student_id,
  al.log_date,
  coalesce(sum(al.marks_earned), 0) as total_marks,
  count(al.id) as activities_completed,
  s.batch_id
from public.students s
left join public.activity_logs al on s.id = al.student_id
group by s.id, al.log_date, s.batch_id;

create or replace view public.weekly_leaderboard as
select
  s.id as student_id,
  p.full_name,
  b.name as batch_name,
  coalesce(sum(al.marks_earned), 0) as total_marks,
  rank() over (order by coalesce(sum(al.marks_earned), 0) desc) as rank
from public.students s
join public.profiles p on s.profile_id = p.id
left join public.batches b on s.batch_id = b.id
left join public.activity_logs al
  on s.id = al.student_id
  and al.log_date >= date_trunc('week', current_date)::date
group by s.id, p.full_name, b.name;

alter table public.profiles enable row level security;
alter table public.batches enable row level security;
alter table public.classes enable row level security;
alter table public.teachers enable row level security;
alter table public.students enable row level security;
alter table public.parent_students enable row level security;
alter table public.teacher_batches enable row level security;
alter table public.activity_categories enable row level security;
alter table public.activities enable row level security;
alter table public.activity_ratings enable row level security;
alter table public.activity_logs enable row level security;
alter table public.badges enable row level security;
alter table public.student_badges enable row level security;
alter table public.notifications enable row level security;
alter table public.teacher_remarks enable row level security;

create policy "profile self read" on public.profiles
for select using (id = auth.uid() or public.is_admin());
create policy "profile self update" on public.profiles
for update using (id = auth.uid() or public.is_admin()) with check (id = auth.uid() or public.is_admin());

create policy "admin all batches" on public.batches
for all using (public.is_admin()) with check (public.is_admin());
create policy "authenticated read batches" on public.batches
for select using (auth.role() = 'authenticated');

create policy "admin all classes" on public.classes
for all using (public.is_admin()) with check (public.is_admin());
create policy "authenticated read classes" on public.classes
for select using (auth.role() = 'authenticated');

create policy "admin all teachers" on public.teachers
for all using (public.is_admin()) with check (public.is_admin());
create policy "teacher own row" on public.teachers
for select using (profile_id = auth.uid() or public.is_admin());

create policy "admin all students" on public.students
for all using (public.is_admin()) with check (public.is_admin());
create policy "student own row" on public.students
for select using (profile_id = auth.uid());
create policy "parent linked students" on public.students
for select using (
  exists (
    select 1 from public.parent_students ps
    where ps.student_id = students.id and ps.parent_profile_id = auth.uid()
  )
);
create policy "teacher assigned batch students" on public.students
for select using (
  exists (
    select 1
    from public.teachers t
    join public.teacher_batches tb on tb.teacher_id = t.id
    where t.profile_id = auth.uid() and tb.batch_id = students.batch_id
  )
);

create policy "admin all parent_students" on public.parent_students
for all using (public.is_admin()) with check (public.is_admin());
create policy "parent own links" on public.parent_students
for select using (parent_profile_id = auth.uid());

create policy "admin all teacher_batches" on public.teacher_batches
for all using (public.is_admin()) with check (public.is_admin());
create policy "teacher own assignments" on public.teacher_batches
for select using (
  exists (
    select 1 from public.teachers t
    where t.id = teacher_batches.teacher_id and t.profile_id = auth.uid()
  )
);

create policy "authenticated read categories" on public.activity_categories
for select using (auth.role() = 'authenticated');
create policy "admin write categories" on public.activity_categories
for all using (public.is_admin()) with check (public.is_admin());

create policy "authenticated read activities" on public.activities
for select using (auth.role() = 'authenticated');
create policy "admin write activities" on public.activities
for all using (public.is_admin()) with check (public.is_admin());

create policy "authenticated read ratings" on public.activity_ratings
for select using (auth.role() = 'authenticated');
create policy "admin write ratings" on public.activity_ratings
for all using (public.is_admin()) with check (public.is_admin());

create policy "admin all logs" on public.activity_logs
for all using (public.is_admin()) with check (public.is_admin());
create policy "student own logs read" on public.activity_logs
for select using (
  exists (
    select 1 from public.students s
    where s.id = activity_logs.student_id and s.profile_id = auth.uid()
  )
);
create policy "student own logs insert_update" on public.activity_logs
for insert with check (
  exists (
    select 1 from public.students s
    where s.id = activity_logs.student_id and s.profile_id = auth.uid()
  )
);
create policy "student own logs update" on public.activity_logs
for update using (
  exists (
    select 1 from public.students s
    where s.id = activity_logs.student_id and s.profile_id = auth.uid()
  )
) with check (
  exists (
    select 1 from public.students s
    where s.id = activity_logs.student_id and s.profile_id = auth.uid()
  )
);
create policy "parent linked logs read" on public.activity_logs
for select using (
  exists (
    select 1
    from public.parent_students ps
    where ps.student_id = activity_logs.student_id and ps.parent_profile_id = auth.uid()
  )
);
create policy "teacher assigned logs read" on public.activity_logs
for select using (
  exists (
    select 1
    from public.students s
    join public.teachers t on t.profile_id = auth.uid()
    join public.teacher_batches tb on tb.teacher_id = t.id
    where s.id = activity_logs.student_id and tb.batch_id = s.batch_id
  )
);

create policy "authenticated read badges" on public.badges
for select using (auth.role() = 'authenticated');
create policy "admin write badges" on public.badges
for all using (public.is_admin()) with check (public.is_admin());

create policy "admin all student_badges" on public.student_badges
for all using (public.is_admin()) with check (public.is_admin());
create policy "student own student_badges" on public.student_badges
for select using (
  exists (
    select 1 from public.students s
    where s.id = student_badges.student_id and s.profile_id = auth.uid()
  )
);
create policy "parent linked student_badges" on public.student_badges
for select using (
  exists (
    select 1
    from public.parent_students ps
    where ps.student_id = student_badges.student_id and ps.parent_profile_id = auth.uid()
  )
);

create policy "admin all notifications" on public.notifications
for all using (public.is_admin()) with check (public.is_admin());
create policy "authenticated read notifications" on public.notifications
for select using (auth.role() = 'authenticated');

create policy "admin all remarks" on public.teacher_remarks
for all using (public.is_admin()) with check (public.is_admin());
create policy "teacher create remark" on public.teacher_remarks
for insert with check (
  exists (
    select 1 from public.teachers t
    where t.id = teacher_remarks.teacher_id and t.profile_id = auth.uid()
  )
);
create policy "teacher parent student read remarks" on public.teacher_remarks
for select using (
  public.is_admin()
  or exists (
    select 1 from public.teachers t
    where t.id = teacher_remarks.teacher_id and t.profile_id = auth.uid()
  )
  or exists (
    select 1 from public.parent_students ps
    where ps.student_id = teacher_remarks.student_id and ps.parent_profile_id = auth.uid()
  )
  or exists (
    select 1 from public.students s
    where s.id = teacher_remarks.student_id and s.profile_id = auth.uid()
  )
);

grant select on public.daily_student_summary to authenticated;
grant select on public.weekly_leaderboard to authenticated;
