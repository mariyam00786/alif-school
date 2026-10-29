create table if not exists public.notification_devices (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('student', 'parent', 'teacher', 'admin')),
  app_name text not null check (app_name in ('admin', 'student_teacher')),
  platform text not null check (platform in ('android', 'ios', 'web', 'macos', 'windows', 'linux', 'unknown')),
  device_token text not null unique,
  notifications_enabled boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (profile_id, app_name, device_token)
);

create index if not exists idx_notification_devices_profile_id
  on public.notification_devices(profile_id);

create index if not exists idx_notification_devices_enabled
  on public.notification_devices(notifications_enabled);

create trigger trg_notification_devices_updated_at
before update on public.notification_devices
for each row execute function public.set_updated_at();

alter table public.notification_devices enable row level security;

create policy "admin all notification_devices" on public.notification_devices
for all using (public.is_admin()) with check (public.is_admin());

create policy "user own notification_devices" on public.notification_devices
for all using (profile_id = auth.uid()) with check (profile_id = auth.uid());
