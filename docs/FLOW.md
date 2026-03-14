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

    style READER fill:#EFF6FF,stroke:#3B82F6,stroke-width:2px
    style AI_SHOW fill:#EFF6FF,stroke:#3B82F6
    style AI_LOADING fill:#F5F5F5,stroke:#DDD
    style STREAK_DONE fill:#EFF6FF,stroke:#2563EB
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

    style MARK fill:#EFF6FF,stroke:#2563EB,stroke-width:2px
    style FIRE2 fill:#EFF6FF,stroke:#2563EB
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
    style 서버 fill:#EFF6FF,stroke:#3B82F6
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
