# 심박 — 로컬 셋업 가이드 (R1)

이 문서는 *R1 라운드 셋업*을 따라하는 가이드. 5~10분 안에 `localhost:3000`에 디스커버리 홈을 띄울 수 있다.

## 0. 사전 준비

- **Node.js 20+** ([nodejs.org](https://nodejs.org/))
- **Git** (이미 설치됨)
- **Supabase 계정** ([supabase.com](https://supabase.com/) — 무료)

## 1. 의존성 설치

```powershell
cd C:\Users\Administrator\km-Momcafe
npm install
```

처음에 ~2분 정도 걸린다. `next-env.d.ts`도 자동 생성됨.

## 2. Supabase 프로젝트 생성

1. <https://supabase.com/dashboard> 로그인
2. **New project** 클릭
3. 이름: `shimbak` (또는 원하는 이름)
4. Database password 설정 (기억해두기)
5. Region: **Northeast Asia (Seoul)** 권장
6. 무료 플랜 선택
7. 약 2분 대기 (프로젝트 준비 중)

## 3. DB 스키마 적용

1. Supabase Dashboard > **SQL Editor** > **New query**
2. `supabase/schema.sql` 파일 *전체 내용*을 붙여넣기
3. **Run** 클릭
4. 정상 실행 확인 (테이블 11개 + RLS 정책 + 트리거 생성됨)

확인: Dashboard > **Table Editor** 에서 `profiles`, `cafes`, `boards`, `posts` 등 11개 테이블 보임.

## 4. 환경변수 설정

1. `.env.local.example` 파일을 복사해서 `.env.local`로 저장
2. Supabase Dashboard > **Settings** > **API** 에서 값 복사:

```
NEXT_PUBLIC_SUPABASE_URL=https://<your-project-ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<Project API keys - anon public>
SUPABASE_SERVICE_ROLE_KEY=<Project API keys - service_role>
```

⚠️ `.env.local`은 `.gitignore`에 포함되어 *절대 커밋되지 않음*. service_role 키는 외부 공개 절대 금지.

## 5. 개발 서버 실행

```powershell
npm run dev
```

브라우저 → <http://localhost:3000> 접속.

디스커버리 홈(D01)이 보이면 성공:
- 상단: 심박 로고 + 로그인 링크
- "오늘의 모임 결정" 그라데이션 카드
- "내 모임" 빈 상태 + 모임 만들기 카드
- 필터 칩 3개
- 모임 카드 3개 (강서구 7세 엄마 모임 — Genesis 배지, 강서구 비건, 디자이너 출신)
- 결핍 카드 (3-7세 한부모 엄마 모임 없음 알림)

⚠️ R1 라운드에서는 *목업 데이터*로만 보임. 실제 Supabase 연결은 R2.

## 6. 다음 라운드 (R2)

- `app/(auth)/signup/page.tsx` — 회원가입
- `app/(auth)/login/page.tsx` — 로그인
- `app/onboarding/page.tsx` — 정체성 데이터 수집 (S03~S08)
- Supabase 클라이언트 실제 연결 (`lib/supabase/*`)
- 디스커버리 D01을 *실제 DB의 cafes 테이블*에서 읽도록 변경

## 트러블슈팅

### `npm install` 시 오류
- Node.js 20+ 인지 확인: `node -v`
- 권한 오류 시 PowerShell 관리자 권한으로 재시도

### `npm run dev` 시 Supabase 환경변수 오류
- `.env.local` 파일이 *프로젝트 루트*에 있는지 확인 (km-Momcafe/.env.local)
- 키 양쪽에 따옴표 없이 입력
- 개발 서버 재시작

### 스키마 실행 오류
- "extension already exists" 같은 경고는 무시 OK
- "permission denied" → Supabase 프로젝트가 *Free* 플랜이고 활성화됐는지 확인

## 디렉토리 구조 (R1 완료 시점)

```
km-Momcafe/
├── app/
│   ├── layout.tsx           # 루트 레이아웃 + 메타
│   ├── globals.css          # 디자인 시스템 토큰
│   ├── page.tsx             # 디스커버리 D01 (목업)
│   └── page.module.css      # D01 스타일
├── lib/
│   └── supabase/
│       ├── client.ts        # 브라우저 클라이언트
│       ├── server.ts        # 서버 컴포넌트 클라이언트
│       └── middleware.ts    # 미들웨어 인증
├── public/
│   └── manifest.json        # PWA 매니페스트
├── supabase/
│   └── schema.sql           # DB 스키마 v0.1 (테이블 11개)
├── docs/                     # 기획 자산 (R0)
│   ├── 00-team-log.md       # 강팀 회의록 13건
│   ├── 01~08-*.md           # 컨셉·UX·UI·아뱅 카탈로그
│   └── index.html           # 단일 HTML
├── .claude/                  # 강팀 정의
├── middleware.ts             # Next 미들웨어 진입점
├── next.config.mjs
├── package.json
├── tsconfig.json
├── .env.local.example
└── README.md
```
