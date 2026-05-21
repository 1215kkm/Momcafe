-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 심박 (Heartbeat) — 데이터베이스 스키마 v0.1
-- 강팀 결정 12건 + 헌법 6원칙 반영
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 실행: Supabase Dashboard > SQL Editor > New query > 이 파일 전체 붙여넣기 > Run

-- ━━━ EXTENSIONS ━━━
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 1. PROFILES — 사용자 + 정체성 데이터
--    Supabase auth.users와 1:1 연결
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname text unique not null,
  -- 정체성 회복(P2) — 결혼 전 이름·직업·전공 (모임이 켤 때만 노출)
  former_name text,
  former_job text,
  former_major text,
  former_hobby text,
  -- 위치 (동네 단위, 시·구까지만)
  region_sido text,
  region_gu text,
  region_dong text,
  -- 메타
  avatar_url text,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

comment on table public.profiles is '심박 사용자 프로필. 결혼 전 정체성은 정체성 회복 모듈에서만 노출.';

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2. CAFES — 모임 (멀티 카페 플랫폼의 기본 단위)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
create type cafe_visibility as enum ('public', 'private', 'invite_only');
create type cafe_status as enum ('alive', 'warning', 'critical', 'deceased');

create table public.cafes (
  id uuid primary key default uuid_generate_v4(),
  slug text unique not null,                    -- URL용
  name text not null,                            -- 모임 이름
  description text,                              -- 한 줄 소개
  -- 분류 (좁을수록 살아남기 쉬움 — 회의 8)
  category text not null,                        -- 모임/동호회/동네/회사/가족/기타
  tags text[] default '{}' not null,             -- 자유 태그 (지역·연령·관심사)
  region_sido text,
  region_gu text,
  region_dong text,
  -- 로고 (이모지 + 자동 색상 — M03 디자인 부담 0)
  logo_emoji text default '🏠',
  accent_color text default '#3D5A47',           -- 카페별 강조색
  -- 운영자
  owner_id uuid references public.profiles(id) on delete restrict not null,
  visibility cafe_visibility default 'public' not null,
  -- Genesis 배지 (회의 8 UX 추가)
  is_genesis boolean default false,
  -- 심박수 (지난 24h, 매 시간 갱신)
  heartbeat_24h integer default 0,
  heartbeat_history jsonb default '[]',          -- 7일 추이
  status cafe_status default 'alive' not null,
  -- 모듈 토글 (4번째 안 3개 + 심박수 + 셋로그)
  modules_enabled jsonb default '{
    "decision_of_day": false,
    "identity_room": false,
    "forward_pass": false,
    "heartbeat_board": true,
    "settlog": true
  }'::jsonb,
  -- 자동 규칙 (M50)
  auto_rules jsonb default '{
    "swear_yellow": {"enabled": true, "threshold": 1, "days": 7},
    "spam_yellow": {"enabled": true, "minutes": 5, "count": 5, "days": 3},
    "ad_yellow": {"enabled": true, "days": 7},
    "report_yellow": {"enabled": true, "count": 5, "days": 14},
    "three_strikes": {"enabled": true, "yellow_limit": 3, "block_days": 14}
  }'::jsonb,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create index idx_cafes_status on public.cafes(status) where status != 'deceased';
create index idx_cafes_region on public.cafes(region_sido, region_gu);
create index idx_cafes_tags on public.cafes using gin(tags);
create index idx_cafes_heartbeat on public.cafes(heartbeat_24h desc) where status = 'alive';

comment on table public.cafes is '모임(카페). 심박수 = (24h 글 × 2) + 댓글 + 모듈 응답 + 신규가입.';

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 3. CAFE_MEMBERS — 가입자 + 역할 위계 (회의 5)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
create type member_role as enum ('owner', 'co_owner', 'board_manager', 'member');

create table public.cafe_members (
  id uuid primary key default uuid_generate_v4(),
  cafe_id uuid references public.cafes(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  role member_role default 'member' not null,
  -- 부운영자 권한 (회의 5 — 체크박스 5종)
  permissions jsonb default '{
    "delete_post": false,
    "kick": false,
    "manage_boards": false,
    "approve_join": false,
    "toggle_modules": false
  }'::jsonb,
  -- 옐로카드 누적 (3진 아웃 자동 탈퇴)
  yellow_count integer default 0 not null,
  yellow_last_at timestamptz,
  banned_until timestamptz,                       -- 정지 종료 시각
  banned_reason text,
  -- 메타
  joined_at timestamptz default now() not null,
  last_active_at timestamptz default now(),
  unique (cafe_id, user_id)
);

create index idx_members_cafe on public.cafe_members(cafe_id);
create index idx_members_user on public.cafe_members(user_id);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 4. BOARDS — 게시판 (운영자가 필요할 때마다 추가)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
create type board_type as enum (
  'free',           -- 자유
  'notice',         -- 공지
  'qa',             -- 질문
  'idea',           -- 아이디어 게시판 (Q4)
  'decision',       -- 오늘의 결정 모듈
  'identity',       -- 이름 회복실
  'forward',        -- 내일의 나에게
  'heartbeat',      -- 심박수
  'confession',     -- 고백 (v1.5)
  'prediction',     -- 예측 시장 (v1.5)
  'trade',          -- 교환 (v1.5)
  'settlog'         -- 셋로그 동시 영상
);

create table public.boards (
  id uuid primary key default uuid_generate_v4(),
  cafe_id uuid references public.cafes(id) on delete cascade not null,
  type board_type not null,
  name text not null,
  description text,
  icon text default '💬',
  position integer default 0 not null,
  -- 일반 게시판 기능 7종 (회의 12)
  features jsonb default '{
    "auto_expire_default": "permanent",
    "force_oneline_summary": true,
    "temperature_meter": true,
    "mini_vote_enabled": true,
    "comment_collapse_threshold": 10,
    "anonymous_post_allowed": false,
    "topic_keyword_whitelist": [],
    "topic_keyword_blacklist": []
  }'::jsonb,
  -- 게시판별 특수 기능
  type_features jsonb default '{}',
  -- 권한
  write_permission text default 'member',          -- member / co_owner / owner
  -- 메타
  manager_ids uuid[] default '{}',                 -- 게시판 담당
  created_at timestamptz default now() not null
);

create index idx_boards_cafe on public.boards(cafe_id);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 5. POSTS — 게시글 (글 자동 만료 F1 포함)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
create type post_expire as enum ('3d', '7d', '30d', 'permanent');
create type post_status as enum ('published', 'hidden', 'expired', 'deleted');

create table public.posts (
  id uuid primary key default uuid_generate_v4(),
  board_id uuid references public.boards(id) on delete cascade not null,
  cafe_id uuid references public.cafes(id) on delete cascade not null,
  author_id uuid references public.profiles(id) on delete set null,
  -- 익명 글 (F6) — 게시판 설정에 따라
  is_anonymous boolean default false,
  -- F2 한 줄 요약 강제
  title text not null,
  oneline_summary text,
  body text not null,
  -- F1 글 자동 만료
  expire_setting post_expire default 'permanent' not null,
  expires_at timestamptz,
  -- F3 글 온도계
  temperature smallint default 0,                  -- 0=찬, 1=미지근, 2=뜨거움
  -- F4 미니 투표 (선택)
  mini_vote jsonb,                                 -- {option_a, option_b, votes_a, votes_b}
  -- 메트릭
  comment_count integer default 0 not null,
  like_count integer default 0 not null,
  report_count integer default 0 not null,
  -- 상태
  status post_status default 'published' not null,
  is_pinned boolean default false,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

create index idx_posts_board_created on public.posts(board_id, created_at desc) where status = 'published';
create index idx_posts_cafe_created on public.posts(cafe_id, created_at desc) where status = 'published';
create index idx_posts_expires on public.posts(expires_at) where expires_at is not null;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 6. COMMENTS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
create table public.comments (
  id uuid primary key default uuid_generate_v4(),
  post_id uuid references public.posts(id) on delete cascade not null,
  parent_id uuid references public.comments(id) on delete cascade,
  author_id uuid references public.profiles(id) on delete set null,
  is_anonymous boolean default false,
  body text not null,
  like_count integer default 0 not null,
  is_deleted boolean default false,
  created_at timestamptz default now() not null
);

create index idx_comments_post on public.comments(post_id, created_at);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 7. DECISIONS — 오늘의 결정 (4번째 안 메커니즘)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
create table public.decisions (
  id uuid primary key default uuid_generate_v4(),
  -- 플랫폼 레벨 (Q1 b)이면 cafe_id null = 플랫폼 결정
  cafe_id uuid references public.cafes(id) on delete cascade,
  question text not null,
  option_a text not null,
  option_b text not null,
  -- 매일 1개 — 노출 윈도우
  show_from timestamptz not null,
  show_until timestamptz not null,
  result_at timestamptz,                           -- 24h 후 결과 노출 시점
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now() not null
);

create table public.decision_responses (
  id uuid primary key default uuid_generate_v4(),
  decision_id uuid references public.decisions(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  choice char(1) check (choice in ('A', 'B')) not null,
  reason_oneline text,                             -- 한 줄 이유 (헌법 P4 — 공감 시 댓글권)
  -- 24h 후 만족·후회 (수익 경로 2)
  satisfaction smallint,                            -- 0=후회, 1=만족, null=미응답
  responded_at timestamptz default now() not null,
  satisfaction_at timestamptz,
  unique (decision_id, user_id)
);

create index idx_responses_decision on public.decision_responses(decision_id);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 8. IDENTITY_ROOM_SESSIONS — 이름 회복실 (4-α)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
create table public.identity_room_sessions (
  id uuid primary key default uuid_generate_v4(),
  cafe_id uuid references public.cafes(id) on delete cascade not null,
  scheduled_at timestamptz not null,
  duration_minutes smallint default 30,
  max_participants smallint default 4,
  status text default 'scheduled',                 -- scheduled/matching/active/ended
  created_at timestamptz default now()
);

create table public.identity_room_participants (
  session_id uuid references public.identity_room_sessions(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  joined_at timestamptz default now(),
  left_at timestamptz,
  primary key (session_id, user_id)
);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 9. SETTLOGS — 셋로그 동시 영상 (메타만, 영상은 폰 P2P)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
create table public.settlog_windows (
  id uuid primary key default uuid_generate_v4(),
  cafe_id uuid references public.cafes(id) on delete cascade not null,
  -- 시간 윈도우 (모임 동네 시간 기준 — Q12)
  open_at timestamptz not null,
  close_at timestamptz not null,                   -- open_at + 5~10분
  status text default 'scheduled',                 -- scheduled/open/closed
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now()
);

create table public.settlog_videos (
  id uuid primary key default uuid_generate_v4(),
  window_id uuid references public.settlog_windows(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  -- 메타만 (영상은 폰)
  thumbnail_url text,                              -- 작은 썸네일 (Supabase Storage)
  duration_seconds smallint,
  taken_at timestamptz default now(),
  unique (window_id, user_id)
);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 10. MODERATION — 옐로카드·강퇴 로그 (회의 5·9)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
create type mod_action as enum ('yellow', 'red', 'kick', 'unban', 'pardon', 'recovery');

create table public.moderation_log (
  id uuid primary key default uuid_generate_v4(),
  cafe_id uuid references public.cafes(id) on delete cascade not null,
  target_user_id uuid references public.profiles(id) on delete cascade not null,
  action mod_action not null,
  reason text,                                     -- 사유 1줄 (필수, 회의 5)
  actor_id uuid references public.profiles(id) on delete set null,
  is_automatic boolean default false,
  rule_triggered text,                             -- 어느 자동 규칙이 발동했나
  created_at timestamptz default now() not null
);

create index idx_mod_cafe on public.moderation_log(cafe_id, created_at desc);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 11. RLS (Row Level Security) — 핵심만 우선
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alter table public.profiles enable row level security;
alter table public.cafes enable row level security;
alter table public.cafe_members enable row level security;
alter table public.boards enable row level security;
alter table public.posts enable row level security;

-- 프로필: 본인만 자기 정체성 데이터 수정 가능, 다른 사용자는 닉네임만
create policy "profile_select_all" on public.profiles for select using (true);
create policy "profile_update_self" on public.profiles for update using (auth.uid() = id);
create policy "profile_insert_self" on public.profiles for insert with check (auth.uid() = id);

-- 카페: public은 모두 읽기, 본인이 만든 카페만 수정
create policy "cafe_select_public" on public.cafes for select
  using (visibility = 'public' or owner_id = auth.uid());
create policy "cafe_insert_authenticated" on public.cafes for insert
  with check (auth.uid() = owner_id);
create policy "cafe_update_owner" on public.cafes for update using (auth.uid() = owner_id);

-- 멤버: 본인 가입 정보 + 같은 카페 멤버 읽기
create policy "member_select_same_cafe" on public.cafe_members for select using (true);
create policy "member_insert_self" on public.cafe_members for insert
  with check (auth.uid() = user_id);

-- 게시판·게시글: 카페가 public이거나 가입자만
create policy "board_select" on public.boards for select using (true);
create policy "post_select" on public.posts for select using (status = 'published');
create policy "post_insert_member" on public.posts for insert
  with check (auth.uid() = author_id);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 12. 트리거 — updated_at 자동 갱신
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_profiles_updated before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger trg_cafes_updated before update on public.cafes
  for each row execute function public.set_updated_at();
create trigger trg_posts_updated before update on public.posts
  for each row execute function public.set_updated_at();

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 13. 신규 사용자 가입 시 profiles 자동 생성
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, nickname)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nickname', '심박' || substr(new.id::text, 1, 6))
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 끝. v0.2에서 추가될 것:
-- - Indexes 보강
-- - 모더레이션 자동 트리거
-- - 심박수 계산 함수 + cron job
-- - 모듈별 RLS 세분화
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
