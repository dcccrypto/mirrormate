-- Create sessions table
create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  device_id text,
  created_at timestamptz default now(),
  video_path text,
  duration_sec int,
  status text check (status in ('queued', 'processing', 'complete', 'error')) default 'queued',
  progress float default 0.0,
  error_message text
);

-- Enable RLS
alter table public.sessions enable row level security;

-- Policies: users can only access their own sessions
create policy "Users can view own sessions"
  on public.sessions for select
  using (auth.uid() = user_id or (auth.uid() is null and device_id is not null));

create policy "Users can insert own sessions"
  on public.sessions for insert
  with check (auth.uid() = user_id or (auth.uid() is null and device_id is not null));

create policy "Users can update own sessions"
  on public.sessions for update
  using (auth.uid() = user_id or (auth.uid() is null and device_id is not null));

-- Index for fast lookups
create index sessions_user_id_idx on public.sessions(user_id);
create index sessions_device_id_idx on public.sessions(device_id);
create index sessions_status_idx on public.sessions(status);

