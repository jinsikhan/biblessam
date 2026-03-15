# BibleSsam (바이블쌤)

> **지금 내 상황에 맞는 말씀**을 찾아 주고, AI가 **쉽게 설명 + 삶에 적용**까지 도와주는 성경 도우미

## 프로젝트 개요

- **제품 한 문장**: "지금 내 상황에 딱 맞는 말씀"을 보여 주고, AI가 쉬운 설명 + 내 삶에 적용하는 한 줄까지 제공하는 성경 도우미
- **핵심 차별점**: (1) AI 쉬운 설명 + 삶 적용 한 줄 (2) 감정/상황 기반 추천 (3) 10분 기준 읽기 스트릭
- **읽기 단위**: 1장(Chapter, 약 20~30절)

## 기술 스택

| 구분 | 기술 |
|------|------|
| **프론트엔드 (웹+앱)** | Flutter (iOS + Android + Web) |
| **백엔드** | Next.js API Routes (Node.js) |
| **성경 API** | 1차: bible-api.com (영어, 키 불필요), 2차: API.Bible (한국어) |
| **AI API** | 1순위: Google Gemini Free, 2순위: OpenRouter Free, 3순위: Groq Free |
| **인증** | 자체 OAuth (구글 + 카카오 + 애플) |
| **로컬 저장** | SharedPreferences (Flutter) |
| **서버 DB** | 즐겨찾기, 최근 읽은 장, 스트릭 동기화용 |
| **배포** | 웹: Vercel/Firebase Hosting, 앱: App Store / Play Store |

## 프로젝트 구조 (목표)

```
Bible/
├── CLAUDE.md
├── PRD-Bible-AI-쌤.md
├── flutter_app/                   # Flutter 앱 (iOS + Android + Web)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/                   # 앱 설정, 라우팅, 테마
│   │   ├── features/              # 기능별 화면
│   │   │   ├── home/              # 홈 탭 (8개 섹션)
│   │   │   ├── reader/            # 장 읽기 + AI 설명
│   │   │   ├── favorites/         # 즐겨찾기
│   │   │   ├── settings/          # 설정
│   │   │   ├── search/            # 검색 + 전체 리스트
│   │   │   └── auth/              # 인증
│   │   ├── services/              # API 서비스, 로컬 저장
│   │   ├── models/                # 데이터 모델
│   │   └── widgets/               # 공용 위젯
│   ├── test/                      # Flutter 테스트
│   ├── android/
│   ├── ios/
│   ├── web/                       # Flutter Web 빌드 설정
│   └── pubspec.yaml
├── web/                           # Next.js API 백엔드 (UI 없음)
│   ├── src/
│   │   ├── app/
│   │   │   └── api/               # API Routes만
│   │   ├── lib/                   # 유틸리티, API 클라이언트
│   │   │   ├── bible-api.ts
│   │   │   ├── ai-api.ts
│   │   │   ├── daily-chapter.ts
│   │   │   ├── streak.ts
│   │   │   └── security/          # 보안 유틸리티
│   │   └── data/                  # 정적 데이터 (JSON)
│   └── public/
└── docs/
```

## 핵심 기능 (MVP 범위)

### 1. 오늘의 말씀 (Daily Chapter)
- 날짜를 시드로 결정적(deterministic)으로 1장 선택
- 성경 전체 1,189장 중 순차 또는 큐레이션 순서
- 같은 날 모든 사용자 동일 장

### 2. AI 쉬운 설명 + 삶 적용
- **On-Demand 호출**: 장 읽기 화면에서 유저가 💡 설명 아이콘을 탭해야 AI API 호출 (자동 호출 아님)
- 아이콘 탭 → 로딩 뷰(Shimmer 스켈레톤) 표시 → AI 응답 수신 → 결과 표시
- 장 전체를 LLM에 전달 → 쉬운 설명(2~3문단) + "오늘 이렇게 적용해 보세요:" 한 줄
- **캐시**: 동일 장 재호출 시 캐시에서 즉시 반환 (API 재호출 방지)
- 교리/해석 금지, 부드러운 제안만

### 3. 감정/상황 맞춤 추천
- 10~15개 테마: "위로가 필요해", "감사해", "불안해", "용기가 필요해" 등
- 테마별 대표 구절 + 해당 장 정보 사전 큐레이션 (JSON)
- 구절 탭 → 해당 장 전체 읽기 + AI 설명

### 4. 읽기 스트릭
- 읽기 화면 체류 시간 10분 이상 → 해당 날짜 "읽음"
- 홈 배너: 연속 일수 + 프로그레스 바
- 20분 이상 → 금색 불꽃(열심 등급)

### 5. 즐겨찾기
- 장 읽기 화면에서 하트/북마크 저장
- 비로그인: 로컬(SharedPreferences), 로그인: 서버 동기화

### 6. 최근 읽은 장
- 자동 저장 (최대 20개)
- 홈에서 가로 스크롤 카드

### 7. 오늘의 한 줄 기도
- 오늘의 말씀 기반 AI 기도문 (1~2문장)
- 날짜별 캐시

### 8. 검색
- 책명/장 참조 검색 (예: "요한복음 3장", "시편 23")
- 결과 → 장 전체 읽기 + AI 설명

### 9. 전체 리스트
- 책 목록(구약 39 + 신약 27) → 장 목록 → 장 읽기

## 디자인 시스템 — Instagram 스타일

> 핵심 철학: **콘텐츠가 주인공**. UI는 보이지 않을수록 좋다.
> 인스타그램처럼 단순하고 직관적이며, 누구나 처음 열었을 때 바로 쓸 수 있어야 한다.
>
> 아래 디자인은 Flutter 위젯으로 구현합니다. 사이징 참고값은 개념용입니다.

### 레이아웃 원칙

- **모바일 퍼스트, 싱글 컬럼**: 최대 너비 512px, 데스크톱(Flutter Web)에서 중앙 정렬 + 양쪽 여백
- **하단 3탭 고정**: 홈(책 아이콘) | 즐겨찾기(하트 아이콘) | 설정(톱니바퀴 아이콘)
- **탭 바 높이 고정**: 56px, 상단 safe area 대응
- **콘텐츠 영역**: 탭 바 위 전체 스크롤, 풀스크린 느낌
- **페이지 전환**: 탭 간 전환은 즉시, 상세 화면은 SlideTransition

### 컬러 팔레트

```
Light Mode:
  배경:         #FFFFFF (순백)
  카드 배경:     #FAFAFA
  구분선:        #EFEFEF
  텍스트 기본:   #262626
  텍스트 보조:   #8E8E8E
  포인트:        #8B5CF6 (violet-500)
  포인트 강조:   #7C3AED (violet-600)
  좋아요(하트):  #ED4956 (인스타 레드)
  스트릭 불꽃:   #7C3AED (violet-600)
  링크/액션:     #8B5CF6

Dark Mode:
  배경:         #000000
  카드 배경:     #1A1A1A
  구분선:        #2A2A2A
  텍스트 기본:   #F5F5F5
  텍스트 보조:   #A8A8A8
  포인트:        #A78BFA (violet-400)
  좋아요:        #ED4956
  스트릭 불꽃:   #7C3AED
```

### 타이포그래피

```
제목 (h1):     20sp Bold        — 섹션 타이틀, 책 이름
부제 (h2):     18sp SemiBold    — 카드 타이틀
본문:          16sp Regular (height: 1.6) — 성경 본문 (가독성 최우선)
보조:          14sp, Colors.grey[500] — 참조, 날짜, 부가 정보
캡션:          12sp, Colors.grey[400] — 작은 라벨
```

- 성경 본문은 줄간격 넓게 (`height: 2.0`)로 읽기 편하게
- 폰트: 시스템 폰트 기본, 한글 가독성 우선

### 카드 스타일 (인스타그램 피드 카드)

```
기본 카드:
  Container / Card 위젯
  BorderRadius.circular(16)
  border: Border.all(color: Color(0xFFF0F0F0)) / dark: Color(0xFF2A2A2A)
  그림자 없음 (인스타처럼 flat), elevation: 0
  패딩: EdgeInsets.all(16)
  카드 간 간격: SizedBox(height: 12)
```

- 카드 안은 **텍스트 위주**, 불필요한 장식 없음
- 탭 가능한 카드는 GestureDetector + `Transform.scale(0.98)` 살짝 눌림 효과만

### 핵심 UI 패턴

#### 홈 화면 — 인스타 피드처럼 세로 스크롤

```
┌─────────────────────────┐
│  🔍 검색...              │  ← 상단 검색바 (둥근 pill, 회색 배경)
├─────────────────────────┤
│  🔥 7일 연속 읽는 중!    │  ← 스트릭 배너 (컴팩트, 한 줄)
│  ████████░░  8분/10분    │     LinearProgressIndicator
├─────────────────────────┤
│                         │
│  📖 오늘의 말씀          │  ← 큰 카드 (피드 메인 포스트처럼)
│  요한복음 3장            │     참조 + 대표 구절 1절
│  "하나님이 세상을 이처럼  │
│   사랑하사..."           │
│  읽기 →                  │     CTA 버튼 (탭 → 장 읽기 화면)
│                         │
├─────────────────────────┤
│  지금 어떤 마음인가요?    │  ← 감정 칩 (인스타 스토리 하이라이트처럼)
│  ◯위로 ◯감사 ◯불안 ◯용기│     원형 + 라벨, 가로 스크롤
├─────────────────────────┤
│  구약 추천     모두 보기 >│  ← 가로 스크롤 카드
│  ┌────┐ ┌────┐ ┌────┐   │     작은 카드: 책명 + 장 + 한 줄
│  │창세기│ │시편 │ │잠언 │   │
│  │ 1장 │ │23장│ │ 3장 │   │
│  └────┘ └────┘ └────┘   │
├─────────────────────────┤
│  신약 추천     모두 보기 >│  ← 동일 패턴
├─────────────────────────┤
│  최근 읽은 장             │  ← 가로 스크롤 작은 카드
├─────────────────────────┤
│  🙏 오늘의 한 줄 기도     │  ← 하단 카드 (앰버 배경)
│  "하나님, 오늘도 ..."     │
└─────────────────────────┘
│  🏠     ❤️     ⚙️       │  ← 하단 탭 바 (56px)
└─────────────────────────┘
```

#### 장 읽기 화면 — AI 설명 On-Demand

```
┌─────────────────────────┐
│  ← 뒤로   요한복음 3장  ♡│  ← 심플 AppBar
├─────────────────────────┤
│  1 태초에 말씀이 계시니라 │  ← 성경 본문 (ListView)
│  2 이 말씀이 하나님과...  │     절 번호: Color(0xFFC8956C) Bold
│  3 만물이 그로 말미암아... │     본문: 16sp, height: 2.0
├─────────────────────────┤
│  ♡ 좋아요  💡 설명  💬 공유│  ← 액션 바 (인스타 스타일)
├─────────────────────────┤
│  [💡 탭 시 Shimmer 로딩] │  ← AnimatedSize로 확장
│  [로딩 완료 → FadeIn]    │  ← 쉬운 설명 + 삶 적용 한 줄
└─────────────────────────┘
```

**AI 설명 호출 흐름**:
1. 장 읽기 화면 진입 → 본문만 표시 (AI 미호출, 빠른 로딩)
2. 유저가 💡 설명 아이콘 탭
3. 캐시 확인 → 캐시 히트 시 즉시 표시
4. 캐시 미스 → AI API 호출 + Shimmer 스켈레톤 로딩
5. 응답 수신 → FadeIn으로 결과 표시 + 캐시 저장
6. 다시 탭 → 토글(접기/펼치기), 재호출 없음

### 인터랙션 & 애니메이션

```
원칙: 빠르고 가볍게. 150~200ms 이내. 화려한 애니메이션 금지.

카드 탭:        GestureDetector + Transform.scale(0.98), 150ms
좋아요 하트:    ScaleTransition bounce (0→1.2→1, 300ms) + 빨간색 전환
페이지 전환:    SlideTransition (200ms, Curves.easeOut)
스켈레톤:       Shimmer 위젯
칩 선택:        AnimatedContainer, border 색상 전환 (150ms)
프로그레스 바:   AnimatedContainer width (500ms, Curves.easeOut)
Pull to refresh: RefreshIndicator 위젯
```

### UX 규칙

1. **첫 화면 = 바로 읽기**: 홈 열면 오늘의 말씀이 바로 보임, 로그인 강요 없음
2. **원탭 도달**: 어떤 기능이든 최대 2탭 이내로 도달
3. **뒤로가기 항상 가능**: 모든 상세 화면에 ← 뒤로 버튼
4. **로딩 중에도 스크롤 가능**: 비동기 로딩, 화면 블록 금지
5. **실수 복구 쉬움**: 즐겨찾기 해제 시 "취소" SnackBar 3초
6. **텍스트 최소화**: 버튼에 긴 문장 금지, 아이콘 + 짧은 라벨
7. **가로 스크롤 힌트**: 첫 항목이 살짝 잘려 보이게
8. **하단 탭 항상 표시**: 장 읽기 화면에서도 탭 바 유지
9. **당겨서 새로고침**: RefreshIndicator
10. **다크 모드 즉시 반영**: ThemeMode 전환 시 깜빡임 없음

## UI 구조

- **하단 3탭**: 홈 | 즐겨찾기 | 설정
- **홈 섹션 순서**: 검색바 → 스트릭 배너 → 오늘의 말씀 카드 → 감정/상황 추천 → 구약 추천 → 신약 추천 → 최근 읽은 장 → 오늘의 한 줄 기도

## API 사용 규칙

### 성경 API (bible-api.com)
- Rate limit: 15 req / 30초 (IP 기준)
- 장 조회: `https://bible-api.com/john+3`
- **한국어 미지원** → 별도 소스 필요

### AI API (Google Gemini Free)
- Rate limit: 10 RPM, 250 RPD (Gemini 2.5 Flash)
- **On-Demand 호출**: 유저가 💡 설명 아이콘을 탭할 때만 호출
- **캐시 필수**: Redis 캐시 확인 → 히트 시 AI 미호출
- 폴백 순서: Gemini → OpenRouter → Groq

## 인증

- OAuth 2.0 기반 소셜 로그인 → 자체 JWT 발급
- 최초 로그인 = 자동 회원가입 (별도 폼 없음)
- **비로그인으로도 모든 기능 사용 가능** (SharedPreferences 로컬 저장)
- 로그인은 기기 간 동기화를 위한 선택 사항

## 코딩 컨벤션

### Flutter (프론트엔드)
- **언어**: Dart (null safety)
- **스타일**: Material Design 3 + Instagram 커스텀 테마
- **컴포넌트**: StatelessWidget 우선, 필요 시 StatefulWidget
- **네이밍**: 클래스는 PascalCase, 변수/함수는 camelCase, 파일명은 snake_case
- **상태 관리**: Riverpod 또는 Provider
- **API 호출**: dio 패키지, Next.js API Routes 프록시 사용
- **캐시**: SharedPreferences 로컬 캐시 + 서버 Redis 캐시

### Next.js (백엔드 API)
- **언어**: TypeScript (strict mode)
- **에러 처리**: API 폴백 패턴 적용 (Gemini → OpenRouter → Groq)
- **응답 형식**: `{ success: boolean, data?: T, error?: string }`
- **캐시**: AI 응답은 반드시 서버 측 Redis 캐시
- **한국어 UI**: 기본 언어는 한국어, AI 설명 언어는 설정에서 변경 가능

## 주의사항

- AI 설명은 "해석"이 아니라 "쉬운 설명 + 삶 적용 제안"임을 명확히 유지
- AI 기도문은 특정 교단/교리에 치우치지 않는 중립적 문구
- 성경 번역본 저작권/이용 조건 준수
- 무료 API 한도 내 운영을 위해 캐시 전략 철저히 적용
- 비로그인 사용자도 모든 기능을 로컬에서 사용 가능해야 함

## QA (품질 보증)

### 테스트 구조
```
flutter_app/test/
├── unit/                  # 단위 테스트
│   ├── services/
│   └── models/
├── widget/                # 위젯 테스트
│   ├── home/
│   ├── reader/
│   └── common/
└── integration/           # 통합 테스트
    └── app_test.dart

web/src/__tests__/         # 백엔드 API 테스트
├── unit/                  # 보안 유틸리티 단위 테스트
├── security/              # XSS/Injection 보안 테스트
└── integration/           # API Route 통합 테스트
```

### 테스트 실행
```bash
# Flutter 테스트
cd flutter_app && flutter test                    # 전체
cd flutter_app && flutter test test/unit/          # 단위만
cd flutter_app && flutter test test/widget/        # 위젯만
cd flutter_app && flutter test --coverage          # 커버리지

# 백엔드 API 테스트
cd web && npm run test                             # Jest 전체
cd web && npm run test:security                    # 보안 테스트
./scripts/qa.sh                                    # 전체 QA
./scripts/security-audit.sh                        # 보안 감사
```

### 커버리지 목표
- 전체: 60% 이상
- 보안 유틸리티: 90% 이상
- API Routes: 70% 이상

## 보안

### 보안 유틸리티 (`web/src/lib/security/`)
| 파일 | 역할 |
|------|------|
| `sanitize.ts` | XSS 방어, 입력값 살균, 검색 쿼리/성경 참조 검증 |
| `rate-limit.ts` | IP 기반 요청 제한 (기본 30/분, AI 5/분, Auth 10/분) |
| `headers.ts` | OWASP 보안 헤더 + CSP |
| `env.ts` | 환경 변수 검증, 서버 전용 변수 보호, NEXT_PUBLIC_ 노출 감지 |
| `cors.ts` | CORS 화이트리스트, 프리플라이트 처리 |

### 보안 원칙
1. **입력은 항상 살균**: API 경계에서 `sanitizeSearchQuery()`, `validateBibleRef()` 사용
2. **Rate Limiting 필수**: 모든 API 엔드포인트에 적용, AI/Auth는 강화된 제한
3. **서버 전용 변수 보호**: `getServerEnv()`로만 접근
4. **보안 헤더 자동 적용**: middleware에서 `applySecurityHeaders()` 호출
5. **CORS 화이트리스트**: 허용된 origin만 접근 가능
6. **의존성 감사**: `npm audit`으로 주기적 검사
7. **Flutter 입력 검증**: 클라이언트에서도 기본 입력 검증 (서버 검증이 최종 방어선)

## 에이전트

| 에이전트 | 역할 |
|----------|------|
| `backend-api` | Next.js API Routes (백엔드 전용), 성경/AI API 연동, 캐싱, DB |
| `flutter-app` | Flutter 프론트엔드 (iOS + Android + Web), Instagram 스타일 UI, 전체 화면 구현 |
| `bible-data` | 성경 데이터 처리, 감정/상황 큐레이션, 검색 |
| `auth` | 인증 시스템 (소셜 로그인, JWT, 동기화) |
