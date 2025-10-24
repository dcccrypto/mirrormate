-- Create user_quotas table for free tier daily limits
create table public.user_quotas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  device_id text unique,
  last_analysis_date date,
  daily_count int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Enable RLS
alter table public.user_quotas enable row level security;

-- Policies
create policy "Users can view own quotas"
  on public.user_quotas for select
  using (auth.uid() = user_id or (auth.uid() is null and device_id is not null));

create policy "Users can insert own quotas"
  on public.user_quotas for insert
  with check (auth.uid() = user_id or (auth.uid() is null and device_id is not null));

create policy "Users can update own quotas"
  on public.user_quotas for update
  using (auth.uid() = user_id or (auth.uid() is null and device_id is not null));

-- Index for fast lookups
create index user_quotas_user_id_idx on public.user_quotas(user_id);
create index user_quotas_device_id_idx on public.user_quotas(device_id);

-- Function to check and increment quota
create or replace function public.check_and_increment_quota(p_device_id text, p_user_id uuid default null)
returns boolean
language plpgsql
security definer
as $$
declare
  v_quota record;
  v_today date := current_date;
begin
  -- Find or create quota record
  select * into v_quota from public.user_quotas
  where (p_user_id is not null and user_id = p_user_id)
     or (p_user_id is null and device_id = p_device_id)
  for update;

  if not found then
    -- Create new quota record
    insert into public.user_quotas (user_id, device_id, last_analysis_date, daily_count)
    values (p_user_id, p_device_id, v_today, 1);
    return true;
  end if;

  -- Reset count if new day
  if v_quota.last_analysis_date < v_today then
    update public.user_quotas
    set last_analysis_date = v_today, daily_count = 1, updated_at = now()
    where id = v_quota.id;
    return true;
  end if;

  -- Check if under limit (1 per day for free users)
  if v_quota.daily_count < 1 then
    update public.user_quotas
    set daily_count = daily_count + 1, updated_at = now()
    where id = v_quota.id;
    return true;
  end if;

  return false;
end;
$$;

