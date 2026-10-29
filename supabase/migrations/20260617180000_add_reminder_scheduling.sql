-- Add reminder scheduling columns to notifications table
alter table if exists public.notifications
add column if not exists frequency text check (frequency in ('daily', 'weekly', 'monthly', 'once')),
add column if not exists cron_expression text,
add column if not exists is_active boolean not null default true,
add column if not exists last_sent_at timestamptz,
add column if not exists updated_at timestamptz default now();

-- Add trigger for updated_at
drop trigger if exists trg_notifications_updated_at on public.notifications;
create trigger trg_notifications_updated_at
before update on public.notifications
for each row execute function public.set_updated_at();

-- Add index for active reminders
create index if not exists idx_notifications_active_frequency
  on public.notifications(is_active, frequency)
  where frequency is not null and is_active = true;

-- Add index for last_sent_at
create index if not exists idx_notifications_last_sent
  on public.notifications(last_sent_at);
