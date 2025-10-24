-- Create analysis_reports table
create table public.analysis_reports (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references public.sessions(id) on delete cascade,
  confidence_score int check (confidence_score between 0 and 100),
  impression_tags jsonb default '[]'::jsonb,
  filler_words jsonb default '{}'::jsonb,
  tone_timeline jsonb default '[]'::jsonb,
  emotion_breakdown jsonb default '{}'::jsonb,
  gaze_eye_contact_pct float check (gaze_eye_contact_pct between 0 and 1),
  feedback text,
  created_at timestamptz default now()
);

-- Enable RLS
alter table public.analysis_reports enable row level security;

-- Policies: users can only access reports for their sessions
create policy "Users can view own reports"
  on public.analysis_reports for select
  using (
    session_id in (
      select id from public.sessions 
      where auth.uid() = user_id or (auth.uid() is null and device_id is not null)
    )
  );

-- Index for fast session lookups
create index analysis_reports_session_id_idx on public.analysis_reports(session_id);

