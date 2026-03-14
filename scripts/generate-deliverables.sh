#!/bin/zsh
#
# BibleSsam - 산출물 자동 생성 스크립트
# 구현 완료 시 Mermaid 플로우 + 에이전트별 산출물 + 전체 산출물 리포트 생성
#
# 사용법:
#   ./scripts/generate-deliverables.sh          # 전체 생성
#   ./scripts/generate-deliverables.sh --force   # 진행률 무관 강제 생성
#

set -uo pipefail

ROOT="${0:a:h:h}"
WEB="$ROOT/web"
SRC="$WEB/src"
DOCS="$ROOT/docs"
CHECKLIST="$ROOT/CHECKLIST.md"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

FORCE=false
[[ "${1:-}" == "--force" ]] && FORCE=true

mkdir -p "$DOCS"

# ── 진행률 확인 ──
check_progress() {
  if [[ ! -f "$CHECKLIST" ]]; then
    echo -e "${RED}CHECKLIST.md가 없습니다.${NC}"
    exit 1
  fi

  local total=$(grep -c '^\- \[' "$CHECKLIST" 2>/dev/null || echo 0)
  local done=$(grep -c '^\- \[x\]' "$CHECKLIST" 2>/dev/null || echo 0)
  local pct=0
  [[ $total -gt 0 ]] && pct=$(( done * 100 / total ))

  echo -e "  현재 진행률: ${CYAN}$done / $total ($pct%)${NC}"

  if ! $FORCE && [[ $pct -lt 100 ]]; then
    echo -e "  ${YELLOW}100% 완료 후 자동 생성됩니다. --force 로 강제 생성 가능.${NC}"
    exit 0
  fi
}

# ── 파일 수집 유틸 ──
count_files() {
  local dir="$1" pattern="$2"
  local cnt
  cnt=$(find "$dir" -name "$pattern" 2>/dev/null | wc -l | tr -d '[:space:]')
  echo "$cnt"
}

list_files() {
  local dir="$1" pattern="$2"
  find "$dir" -name "$pattern" 2>/dev/null | sort | sed "s|$ROOT/||g"
}

file_exists_mark() {
  [[ -f "$1" ]] && echo "[x]" || echo "[ ]"
}

# ═══════════════════════════════════════
# 1. Mermaid 전체 플로우 다이어그램
# ═══════════════════════════════════════
generate_mermaid() {
  echo -e "${CYAN}[1/3]${NC} Mermaid 플로우 다이어그램 생성..."

  cat > "$DOCS/FLOW.md" << 'MERMAID_EOF'
# BibleSsam 전체 플로우

> 자동 생성됨 — `scripts/generate-deliverables.sh`

---

## 1. 사용자 전체 플로우 (User Journey)

```mermaid
flowchart TD
    START([앱 실행]) --> HOME[홈 화면]

    HOME --> SEARCH[🔍 검색]
    HOME --> STREAK[🔥 스트릭 배너]
    HOME --> DAILY[📖 오늘의 말씀 카드]
    HOME --> EMOTION[😊 감정/상황 칩]
    HOME --> OT_REC[구약 추천]
    HOME --> NT_REC[신약 추천]
    HOME --> RECENT[최근 읽은 장]
    HOME --> PRAYER[🙏 한 줄 기도]

    SEARCH --> SEARCH_RESULT[검색 결과]
    SEARCH --> BOOK_LIST[전체 리스트<br/>책 → 장]
    SEARCH_RESULT --> READER
    BOOK_LIST --> READER

    DAILY --> READER[장 읽기 화면]
    EMOTION --> VERSE_LIST[구절 카드 리스트]
    VERSE_LIST --> READER
    OT_REC --> READER
    NT_REC --> READER
    RECENT --> READER

    READER --> |💡 설명 탭| AI_CALL{캐시 확인}
    AI_CALL --> |히트| AI_SHOW[AI 설명 즉시 표시]
    AI_CALL --> |미스| AI_LOADING[스켈레톤 로딩]
    AI_LOADING --> |API 응답| AI_SHOW
    AI_SHOW --> |다시 💡 탭| AI_TOGGLE[접기/펼치기]

    READER --> |♡ 탭| FAV_ADD[즐겨찾기 저장]
    READER --> |체류 10분+| STREAK_DONE[✅ 읽음 처리]

    HOME --> TAB_FAV[❤️ 즐겨찾기 탭]
    TAB_FAV --> FAV_LIST[저장 목록]
    FAV_LIST --> READER

    HOME --> TAB_SET[⚙️ 설정 탭]
    TAB_SET --> LOGIN[로그인/로그아웃]
    TAB_SET --> CALENDAR[📊 스트릭 달력]
    TAB_SET --> PREFS[번역본/언어/다크모드]

    LOGIN --> |로그인 시| SYNC[데이터 동기화]

    style READER fill:#FFF8F0,stroke:#C8956C,stroke-width:2px
    style AI_SHOW fill:#FFF8F0,stroke:#C8956C
    style AI_LOADING fill:#F5F5F5,stroke:#DDD
    style STREAK_DONE fill:#FFF3E0,stroke:#FD8D14
    style FAV_ADD fill:#FFE8EA,stroke:#ED4956
```

---

## 2. AI 설명 On-Demand 호출 플로우

```mermaid
sequenceDiagram
    participant U as 👤 사용자
    participant FE as 📱 프론트엔드
    participant API as 🖥️ Next.js API
    participant Redis as 💾 Redis 캐시
    participant AI as 🤖 AI API

    U->>FE: 장 읽기 화면 진입
    FE->>API: GET /api/bible/chapter
    API-->>FE: 성경 본문 반환
    FE-->>U: 본문만 표시 (빠른 로딩)

    Note over U,FE: 💡 설명 아이콘 탭

    U->>FE: 💡 탭
    FE->>API: GET /api/ai/explanation?book=john&chapter=3
    API->>Redis: 캐시 확인 (ai:explanation:john:3:ko)

    alt 캐시 히트
        Redis-->>API: 캐시된 AI 응답
        API-->>FE: 즉시 반환
        FE-->>U: 설명 즉시 표시
    else 캐시 미스
        Redis-->>API: null
        FE-->>U: 스켈레톤 로딩 표시
        API->>AI: Gemini API 호출
        alt Gemini 실패
            AI-->>API: 에러/한도초과
            API->>AI: OpenRouter 폴백
            alt OpenRouter 실패
                AI-->>API: 에러
                API->>AI: Groq 폴백
            end
        end
        AI-->>API: AI 응답 (설명 + 삶 적용)
        API->>Redis: 캐시 저장 (TTL: 영구)
        API-->>FE: AI 응답 반환
        FE-->>U: fade-in 결과 표시
    end

    Note over U,FE: 다시 💡 탭 → 토글 (재호출 없음)
```

---

## 3. 인증 & 데이터 동기화 플로우

```mermaid
sequenceDiagram
    participant U as 👤 사용자
    participant App as 📱 앱/웹
    participant Auth as 🔑 Auth API
    participant Social as 🌐 소셜 (구글/카카오/애플)
    participant DB as 🗄️ PostgreSQL

    Note over U,App: 비로그인 상태 — 모든 기능 로컬 동작

    U->>App: 로그인 버튼 탭
    App->>Social: OAuth 요청
    Social-->>App: 소셜 토큰
    App->>Auth: POST /api/auth/login (소셜 토큰)
    Auth->>Social: 토큰 검증
    Social-->>Auth: 유저 정보
    Auth->>DB: 사용자 확인/생성
    Auth-->>App: JWT (access + refresh)

    Note over App,DB: 로컬 → 서버 동기화

    App->>Auth: POST /api/auth/sync (로컬 데이터)
    Auth->>DB: 즐겨찾기 병합
    Auth->>DB: 최근 읽은 장 병합
    Auth->>DB: 스트릭 기록 병합
    Auth-->>App: 동기화 완료
```

---

## 4. 읽기 스트릭 플로우

```mermaid
flowchart TD
    ENTER([장 읽기 화면 진입]) --> TIMER_START[⏱️ 타이머 시작]
    TIMER_START --> READING[읽기 중...]

    READING --> |백그라운드 진입| PAUSE[⏸️ 타이머 일시정지]
    PAUSE --> |포그라운드 복귀| READING

    READING --> |체류 시간 체크| CHECK{누적 ≥ 10분?}
    CHECK --> |아니오| READING
    CHECK --> |예| MARK[✅ 오늘 읽음 처리]

    MARK --> STREAK_CALC[연속 일수 계산]
    STREAK_CALC --> SAVE{로그인?}
    SAVE --> |예| SERVER[서버 DB 저장]
    SAVE --> |아니오| LOCAL[로컬 저장]

    MARK --> LEVEL{누적 ≥ 20분?}
    LEVEL --> |아니오| FIRE1[🔥 불꽃 1개]
    LEVEL --> |예| FIRE2[🔥🔥 금색 불꽃]

    style MARK fill:#FFF3E0,stroke:#FD8D14,stroke-width:2px
    style FIRE2 fill:#FFF3E0,stroke:#FD8D14
```

---

## 5. 데이터 저장 플로우

```mermaid
flowchart LR
    subgraph 비로그인
        LOCAL_FAV[즐겨찾기<br/>localStorage]
        LOCAL_RECENT[최근 읽은 장<br/>localStorage]
        LOCAL_STREAK[스트릭<br/>localStorage]
        LOCAL_AI[AI 설명 캐시<br/>localStorage]
    end

    subgraph 서버 (로그인 시)
        DB_FAV[(즐겨찾기<br/>PostgreSQL)]
        DB_RECENT[(최근 읽은 장<br/>PostgreSQL)]
        DB_STREAK[(스트릭<br/>PostgreSQL)]
        REDIS_AI[(AI 캐시<br/>Redis)]
    end

    LOCAL_FAV -.->|로그인 시 동기화| DB_FAV
    LOCAL_RECENT -.->|로그인 시 동기화| DB_RECENT
    LOCAL_STREAK -.->|로그인 시 동기화| DB_STREAK
    LOCAL_AI -.->|서버 캐시와 별도| REDIS_AI

    style 비로그인 fill:#F0F8FF,stroke:#4A90D9
    style 서버 fill:#FFF8F0,stroke:#C8956C
```

---

## 6. API 아키텍처

```mermaid
flowchart TB
    subgraph Client
        WEB[🌐 Next.js 웹]
        APP[📱 Flutter 앱]
    end

    subgraph "Next.js API Routes"
        BIBLE_API[/api/bible/*<br/>장 조회, 책 목록, 검색/]
        DAILY_API[/api/daily<br/>오늘의 말씀/]
        AI_API[/api/ai/*<br/>설명, 기도문/]
        REC_API[/api/recommendations/*<br/>감정/상황 추천/]
        FAV_API[/api/favorites<br/>즐겨찾기 CRUD/]
        HIST_API[/api/history<br/>최근 읽은 장/]
        STREAK_API[/api/streak<br/>읽기 스트릭/]
        AUTH_API[/api/auth/*<br/>로그인, JWT/]
    end

    subgraph External
        BIBLE_EXT[(bible-api.com)]
        GEMINI[(Google Gemini)]
        OPENROUTER[(OpenRouter)]
        GROQ[(Groq)]
    end

    subgraph Storage
        PG[(PostgreSQL)]
        RD[(Redis)]
    end

    WEB --> BIBLE_API & DAILY_API & AI_API & REC_API & FAV_API & HIST_API & STREAK_API & AUTH_API
    APP --> BIBLE_API & DAILY_API & AI_API & REC_API & FAV_API & HIST_API & STREAK_API & AUTH_API

    BIBLE_API --> BIBLE_EXT
    AI_API --> RD
    AI_API --> GEMINI
    AI_API -.->|폴백| OPENROUTER
    AI_API -.->|폴백| GROQ
    FAV_API & HIST_API & STREAK_API & AUTH_API --> PG
    AI_API --> RD

    style Client fill:#E8F5E9,stroke:#4CAF50
    style External fill:#FFF3E0,stroke:#FF9800
    style Storage fill:#E3F2FD,stroke:#2196F3
```
MERMAID_EOF

  echo -e "  ${GREEN}docs/FLOW.md 생성 완료${NC}"
}


# ═══════════════════════════════════════
# 2. 에이전트별 산출물 리포트
# ═══════════════════════════════════════
generate_agent_reports() {
  echo -e "${CYAN}[2/3]${NC} 에이전트별 산출물 리포트 생성..."

  # --- backend-api ---
  cat > "$DOCS/DELIVERABLE-backend-api.md" << EOF
# 산출물: backend-api 에이전트

> 자동 생성됨 — $(date '+%Y-%m-%d %H:%M')

## API Routes

| 파일 | 상태 |
|------|------|
| \`app/api/bible/chapter/route.ts\` | $(file_exists_mark "$SRC/app/api/bible/chapter/route.ts") |
| \`app/api/bible/books/route.ts\` | $(file_exists_mark "$SRC/app/api/bible/books/route.ts") |
| \`app/api/bible/search/route.ts\` | $(file_exists_mark "$SRC/app/api/bible/search/route.ts") |
| \`app/api/daily/route.ts\` | $(file_exists_mark "$SRC/app/api/daily/route.ts") |
| \`app/api/ai/explanation/route.ts\` | $(file_exists_mark "$SRC/app/api/ai/explanation/route.ts") |
| \`app/api/ai/prayer/route.ts\` | $(file_exists_mark "$SRC/app/api/ai/prayer/route.ts") |
| \`app/api/recommendations/emotion/route.ts\` | $(file_exists_mark "$SRC/app/api/recommendations/emotion/route.ts") |
| \`app/api/favorites/route.ts\` | $(file_exists_mark "$SRC/app/api/favorites/route.ts") |
| \`app/api/history/route.ts\` | $(file_exists_mark "$SRC/app/api/history/route.ts") |
| \`app/api/streak/route.ts\` | $(file_exists_mark "$SRC/app/api/streak/route.ts") |
| \`app/api/auth/login/route.ts\` | $(file_exists_mark "$SRC/app/api/auth/login/route.ts") |

## 라이브러리

| 파일 | 상태 |
|------|------|
| \`lib/bible-api.ts\` | $(file_exists_mark "$SRC/lib/bible-api.ts") |
| \`lib/ai-api.ts\` | $(file_exists_mark "$SRC/lib/ai-api.ts") |
| \`lib/daily-chapter.ts\` | $(file_exists_mark "$SRC/lib/daily-chapter.ts") |
| \`lib/streak.ts\` | $(file_exists_mark "$SRC/lib/streak.ts") |

## 파일 통계

- API Route 파일: $(count_files "$SRC/app/api" "route.ts")개
- lib 파일: $(count_files "$SRC/lib" "*.ts")개
EOF

  # --- frontend-web ---
  cat > "$DOCS/DELIVERABLE-frontend-web.md" << EOF
# 산출물: frontend-web 에이전트

> 자동 생성됨 — $(date '+%Y-%m-%d %H:%M')

## 페이지

| 파일 | 상태 |
|------|------|
| \`app/layout.tsx\` | $(file_exists_mark "$SRC/app/layout.tsx") |
| \`app/page.tsx\` (홈) | $(file_exists_mark "$SRC/app/page.tsx") |
| \`app/favorites/page.tsx\` | $(file_exists_mark "$SRC/app/favorites/page.tsx") |
| \`app/settings/page.tsx\` | $(file_exists_mark "$SRC/app/settings/page.tsx") |
| \`app/reader/[book]/[chapter]/page.tsx\` | $(file_exists_mark "$SRC/app/reader/[book]/[chapter]/page.tsx") |
| \`app/search/page.tsx\` | $(file_exists_mark "$SRC/app/search/page.tsx") |
| \`app/books/page.tsx\` | $(file_exists_mark "$SRC/app/books/page.tsx") |

## 컴포넌트 — layout

| 파일 | 상태 |
|------|------|
$(for f in BottomNav PageLayout; do
  echo "| \`components/layout/$f.tsx\` | $(file_exists_mark "$SRC/components/layout/$f.tsx") |"
done)

## 컴포넌트 — home

| 파일 | 상태 |
|------|------|
$(for f in SearchBar StreakBanner DailyChapterCard EmotionChips RecommendationCards RecentlyRead DailyPrayer; do
  echo "| \`components/home/$f.tsx\` | $(file_exists_mark "$SRC/components/home/$f.tsx") |"
done)

## 컴포넌트 — reader

| 파일 | 상태 |
|------|------|
$(for f in ChapterReader ReaderActionBar AiExplanation AiExplanationSkeleton LifeApplication FavoriteButton; do
  echo "| \`components/reader/$f.tsx\` | $(file_exists_mark "$SRC/components/reader/$f.tsx") |"
done)

## 컴포넌트 — favorites / settings / common

| 파일 | 상태 |
|------|------|
$(for f in favorites/FavoriteList settings/ProfileCard settings/StreakCalendar settings/SettingsMenu common/Card common/Chip common/ProgressBar common/Skeleton common/EmptyState common/Toast; do
  echo "| \`components/$f.tsx\` | $(file_exists_mark "$SRC/components/$f.tsx") |"
done)

## 파일 통계

- 페이지 파일: $(count_files "$SRC/app" "page.tsx")개
- 컴포넌트 파일: $(count_files "$SRC/components" "*.tsx")개
- hooks 파일: $(count_files "$SRC/hooks" "*.ts" 2>/dev/null || echo 0)개
EOF

  # --- bible-data ---
  cat > "$DOCS/DELIVERABLE-bible-data.md" << EOF
# 산출물: bible-data 에이전트

> 자동 생성됨 — $(date '+%Y-%m-%d %H:%M')

## 정적 데이터 파일

| 파일 | 상태 |
|------|------|
| \`data/bible-books.json\` | $(file_exists_mark "$SRC/data/bible-books.json")$(file_exists_mark "$SRC/data/bible-books.ts" | grep -q x && echo " (.ts)") |
| \`data/emotion-themes.json\` | $(file_exists_mark "$SRC/data/emotion-themes.json")$(file_exists_mark "$SRC/data/emotion-themes.ts" | grep -q x && echo " (.ts)") |

## 타입 정의

| 파일 | 상태 |
|------|------|
| \`types/bible.ts\` | $(file_exists_mark "$SRC/types/bible.ts") |
| \`types/emotion.ts\` | $(file_exists_mark "$SRC/types/emotion.ts") |
| \`types/ai.ts\` | $(file_exists_mark "$SRC/types/ai.ts") |

## 데이터 검증

$(if [[ -f "$SRC/data/bible-books.json" ]]; then
  local books=$(python3 -c "import json; print(len(json.load(open('$SRC/data/bible-books.json'))))" 2>/dev/null || echo "?")
  echo "- 성경 책 수: ${books}개 (목표: 66개)"
elif [[ -f "$SRC/data/bible-books.ts" ]]; then
  echo "- 성경 책 데이터: bible-books.ts 존재"
else
  echo "- 성경 책 데이터: 미생성"
fi)

$(if [[ -f "$SRC/data/emotion-themes.json" ]]; then
  local themes=$(python3 -c "import json; print(len(json.load(open('$SRC/data/emotion-themes.json'))))" 2>/dev/null || echo "?")
  echo "- 감정 테마 수: ${themes}개 (목표: 10~15개)"
elif [[ -f "$SRC/data/emotion-themes.ts" ]]; then
  echo "- 감정 테마 데이터: emotion-themes.ts 존재"
else
  echo "- 감정 테마 데이터: 미생성"
fi)

## 파일 통계

- data 파일: $(count_files "$SRC/data" "*.*")개
- types 파일: $(count_files "$SRC/types" "*.ts")개
EOF

  # --- auth ---
  cat > "$DOCS/DELIVERABLE-auth.md" << EOF
# 산출물: auth 에이전트

> 자동 생성됨 — $(date '+%Y-%m-%d %H:%M')

## API Routes

| 파일 | 상태 |
|------|------|
| \`app/api/auth/login/route.ts\` | $(file_exists_mark "$SRC/app/api/auth/login/route.ts") |
| \`app/api/auth/refresh/route.ts\` | $(file_exists_mark "$SRC/app/api/auth/refresh/route.ts") |
| \`app/api/auth/logout/route.ts\` | $(file_exists_mark "$SRC/app/api/auth/logout/route.ts") |
| \`app/api/auth/me/route.ts\` | $(file_exists_mark "$SRC/app/api/auth/me/route.ts") |
| \`app/api/auth/sync/route.ts\` | $(file_exists_mark "$SRC/app/api/auth/sync/route.ts") |

## 미들웨어 & 유틸

| 파일 | 상태 |
|------|------|
| \`middleware.ts\` | $(file_exists_mark "$SRC/middleware.ts") |
| \`lib/auth.ts\` | $(file_exists_mark "$SRC/lib/auth.ts") |

## 인증 제공자

$(grep -rl "google.*auth\|google.*sign\|GoogleAuth" "$SRC" 2>/dev/null | head -1 | grep -q . && echo "- [x] 구글 로그인" || echo "- [ ] 구글 로그인")
$(grep -rl "kakao.*auth\|kakao.*sign\|KakaoAuth" "$SRC" 2>/dev/null | head -1 | grep -q . && echo "- [x] 카카오 로그인" || echo "- [ ] 카카오 로그인")
$(grep -rl "jwt\|JWT\|jsonwebtoken" "$SRC" 2>/dev/null | head -1 | grep -q . && echo "- [x] JWT 토큰 관리" || echo "- [ ] JWT 토큰 관리")
$(grep -rl "sync\|동기화\|merge.*local" "$SRC" 2>/dev/null | head -1 | grep -q . && echo "- [x] 데이터 동기화" || echo "- [ ] 데이터 동기화")
EOF

  # --- flutter-app ---
  local FLUTTER="$ROOT/flutter_app"
  cat > "$DOCS/DELIVERABLE-flutter-app.md" << EOF
# 산출물: flutter-app 에이전트

> 자동 생성됨 — $(date '+%Y-%m-%d %H:%M')

## 프로젝트 상태

$(if [[ -f "$FLUTTER/pubspec.yaml" ]]; then
  echo "- [x] Flutter 프로젝트 생성"
  echo "- 파일 수: $(find "$FLUTTER/lib" -name "*.dart" 2>/dev/null | wc -l | tr -d ' ')개 (.dart)"
else
  echo "- [ ] Flutter 프로젝트 미생성 (Phase 2)"
fi)

## 주요 파일

| 파일 | 상태 |
|------|------|
| \`pubspec.yaml\` | $(file_exists_mark "$FLUTTER/pubspec.yaml") |
| \`lib/main.dart\` | $(file_exists_mark "$FLUTTER/lib/main.dart") |
| \`lib/app/theme.dart\` | $(file_exists_mark "$FLUTTER/lib/app/theme.dart") |
| \`lib/app/router.dart\` | $(file_exists_mark "$FLUTTER/lib/app/router.dart") |
| \`lib/features/reader/ai_explanation.dart\` | $(file_exists_mark "$FLUTTER/lib/features/reader/ai_explanation.dart") |
| \`lib/features/reader/ai_explanation_skeleton.dart\` | $(file_exists_mark "$FLUTTER/lib/features/reader/ai_explanation_skeleton.dart") |
EOF

  echo -e "  ${GREEN}에이전트별 산출물 5개 생성 완료${NC}"
}


# ═══════════════════════════════════════
# 3. 전체 산출물 통합 리포트
# ═══════════════════════════════════════
generate_total_report() {
  echo -e "${CYAN}[3/3]${NC} 전체 산출물 통합 리포트 생성..."

  local total_ts=$(find "$SRC" -name "*.ts" -o -name "*.tsx" 2>/dev/null | wc -l | tr -d ' ')
  local total_api=$(count_files "$SRC/app/api" "route.ts")
  local total_components=$(count_files "$SRC/components" "*.tsx")
  local total_pages=$(count_files "$SRC/app" "page.tsx")
  local total_lib=$(count_files "$SRC/lib" "*.ts")
  local total_hooks=$(count_files "$SRC/hooks" "*.ts" 2>/dev/null || echo 0)
  local total_types=$(count_files "$SRC/types" "*.ts")
  local total_data=$(count_files "$SRC/data" "*.*")

  local checklist_total=$(grep -c '^\- \[' "$CHECKLIST" 2>/dev/null || echo 0)
  local checklist_done=$(grep -c '^\- \[x\]' "$CHECKLIST" 2>/dev/null || echo 0)
  local checklist_pct=0
  [[ $checklist_total -gt 0 ]] && checklist_pct=$(( checklist_done * 100 / checklist_total ))

  cat > "$DOCS/DELIVERABLE-TOTAL.md" << EOF
# BibleSsam 전체 산출물 리포트

> 자동 생성됨 — $(date '+%Y-%m-%d %H:%M')

---

## 프로젝트 진행률

**체크리스트: $checklist_done / $checklist_total ($checklist_pct%)**

---

## 파일 통계

| 구분 | 수량 |
|------|------|
| TypeScript 전체 (.ts + .tsx) | ${total_ts}개 |
| API Route 파일 | ${total_api}개 |
| React 컴포넌트 | ${total_components}개 |
| 페이지 | ${total_pages}개 |
| 라이브러리 (lib/) | ${total_lib}개 |
| 커스텀 훅 (hooks/) | ${total_hooks}개 |
| 타입 정의 (types/) | ${total_types}개 |
| 정적 데이터 (data/) | ${total_data}개 |

---

## 에이전트별 산출물 요약

### backend-api
- API Routes: ${total_api}개
- 라이브러리: ${total_lib}개
- 상세: [DELIVERABLE-backend-api.md](./DELIVERABLE-backend-api.md)

### frontend-web
- 페이지: ${total_pages}개
- 컴포넌트: ${total_components}개
- 상세: [DELIVERABLE-frontend-web.md](./DELIVERABLE-frontend-web.md)

### bible-data
- 데이터 파일: ${total_data}개
- 타입 정의: ${total_types}개
- 상세: [DELIVERABLE-bible-data.md](./DELIVERABLE-bible-data.md)

### auth
- 인증 API: $(count_files "$SRC/app/api/auth" "route.ts" 2>/dev/null || echo 0)개
- 상세: [DELIVERABLE-auth.md](./DELIVERABLE-auth.md)

### flutter-app
$(if [[ -f "$ROOT/flutter_app/pubspec.yaml" ]]; then
  echo "- Dart 파일: $(find "$ROOT/flutter_app/lib" -name "*.dart" 2>/dev/null | wc -l | tr -d ' ')개"
else
  echo "- 상태: Phase 2 (미생성)"
fi)
- 상세: [DELIVERABLE-flutter-app.md](./DELIVERABLE-flutter-app.md)

---

## 다이어그램

모든 Mermaid 플로우 다이어그램: [FLOW.md](./FLOW.md)

1. 사용자 전체 플로우 (User Journey)
2. AI 설명 On-Demand 호출 플로우
3. 인증 & 데이터 동기화 플로우
4. 읽기 스트릭 플로우
5. 데이터 저장 플로우
6. API 아키텍처

---

## 전체 파일 목록

\`\`\`
$(find "$SRC" \( -name "*.ts" -o -name "*.tsx" -o -name "*.json" \) 2>/dev/null | sort | sed "s|$ROOT/||g")
\`\`\`

---

## Docker 환경

| 서비스 | 이미지 | 포트 |
|--------|--------|------|
| web | Next.js (standalone) | 3000 |
| db | postgres:16-alpine | 5432 |
| redis | redis:7-alpine | 6379 |

---

*리포트 생성 시각: $(date '+%Y-%m-%d %H:%M:%S')*
EOF

  echo -e "  ${GREEN}docs/DELIVERABLE-TOTAL.md 생성 완료${NC}"
}


# ═══════════════════════════════════════
# 실행
# ═══════════════════════════════════════

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  BibleSsam 산출물 자동 생성${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

check_progress
echo ""

generate_mermaid
generate_agent_reports
generate_total_report

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${GREEN}산출물 생성 완료!${NC}"
echo ""
echo -e "  📄 docs/FLOW.md                    — Mermaid 플로우 다이어그램 (6개)"
echo -e "  📄 docs/DELIVERABLE-backend-api.md  — backend-api 산출물"
echo -e "  📄 docs/DELIVERABLE-frontend-web.md — frontend-web 산출물"
echo -e "  📄 docs/DELIVERABLE-bible-data.md   — bible-data 산출물"
echo -e "  📄 docs/DELIVERABLE-auth.md         — auth 산출물"
echo -e "  📄 docs/DELIVERABLE-flutter-app.md  — flutter-app 산출물"
echo -e "  📄 docs/DELIVERABLE-TOTAL.md        — ${CYAN}전체 통합 리포트${NC}"
echo ""
