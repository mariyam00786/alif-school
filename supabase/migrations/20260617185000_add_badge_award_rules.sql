-- Add badge auto-award rules table
create table if not exists public.badge_award_rules (
  id uuid primary key default gen_random_uuid(),
  badge_id uuid not null references public.badges(id) on delete cascade,
  rule_type text not null check (rule_type in ('activity_count', 'total_marks', 'activity_streak', 'first_completion')),
  rule_config jsonb not null, -- e.g., {"activity_id": "uuid", "threshold": 10, "period": "daily"}
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Add awarded_at tracking to student_badges for history
alter table if exists public.student_badges
add column if not exists awarded_by text default 'auto', -- 'auto' | 'admin' | 'manual'
add column if not exists awarded_reason text; -- Description of why badge was awarded

-- Create index for auto-award query optimization
create index if not exists idx_badge_award_rules_badge_active
  on public.badge_award_rules(badge_id, is_active)
  where is_active = true;

create index if not exists idx_student_badges_earned
  on public.student_badges(student_id, earned_at);

-- Create trigger for updated_at
drop trigger if exists trg_badge_award_rules_updated_at on public.badge_award_rules;
create trigger trg_badge_award_rules_updated_at
before update on public.badge_award_rules
for each row execute function public.set_updated_at();

-- Enable RLS for badge award rules
alter table public.badge_award_rules enable row level security;

-- RLS policies for badge award rules (admin only)
create policy "admin all badge_award_rules" on public.badge_award_rules
for all using (public.is_admin()) with check (public.is_admin());
