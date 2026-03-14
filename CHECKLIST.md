# BibleSsam MVP 체크리스트

> 자동 검증: `scripts/verify-checklist.sh` 실행 시 구현 상태에 따라 체크박스가 자동 업데이트됩니다.

---

## 1. 프로젝트 초기 설정

- [x] `P01` Next.js API 백엔드 프로젝트 (`web/` 디렉토리)
- [x] `P02` TypeScript strict mode 설정
- [x] `P03` Tailwind CSS 설치 (API 백엔드용)
- [x] `P04` App Router 기본 레이아웃 (`web/src/app/layout.tsx`)
- [x] `P05` 환경 변수 파일 설정 (`web/.env.local.example`)
- [x] `P06` TypeScript 타입 정의 파일 (`web/src/types/`)
- [x] `P07` Flutter 프로젝트 생성 (`flutter_app/` 디렉토리)

---

## 2. 정적 데이터

- [x] `D01` 성경 책 목록 JSON (`bible-books.json` — 구약 39 + 신약 27)
- [x] `D02` 감정/상황 테마 큐레이션 JSON (`emotion-themes.json` — 10개 이상 테마)
- [x] `D03` 한글↔영문 책명 매핑 데이터

---

## 3. 백엔드 API

### 3-1. 성경 API 프록시
- [x] `B01` 성경 장 조회 API (`/api/bible/chapter`)
- [x] `B02` 성경 책 목록 API (`/api/bible/books`)
- [x] `B03` 성경 검색 API (`/api/bible/search`)
- [x] `B04` bible-api.com 래퍼 (`web/src/lib/bible-api.ts`)

### 3-2. 오늘의 말씀
- [x] `B05` 오늘의 말씀 결정 로직 (`web/src/lib/daily-chapter.ts`)
- [x] `B06` 오늘의 말씀 API (`/api/daily`)

### 3-3. AI API 연동
- [x] `B07` AI API 래퍼 — Gemini 연동 (`web/src/lib/ai-api.ts`)
- [x] `B08` AI API 폴백 로직 (Gemini → OpenRouter → Groq)
- [x] `B09` AI 쉬운 설명 + 삶 적용 API (`/api/ai/explanation`)
- [x] `B10` AI 오늘의 한 줄 기도 API (`/api/ai/prayer`)
- [x] `B11` AI 응답 캐시 시스템 (장별 캐시)

### 3-4. 감정/상황 추천
- [x] `B12` 감정/상황별 추천 API (`/api/recommendations/emotion`)

### 3-5. 사용자 데이터 API
- [x] `B13` 즐겨찾기 CRUD API (`/api/favorites`)
- [x] `B14` 최근 읽은 장 API (`/api/history`)
- [x] `B15` 읽기 스트릭 API (`/api/streak`)

---

## 4. 프론트엔드 (Flutter) — 레이아웃

- [x] `L01` 하단 3탭 BottomNavigationBar (홈 | 즐겨찾기 | 설정)
- [x] `L02` 반응형 레이아웃 (모바일 + 웹 대응, LayoutBuilder/MediaQuery)
- [x] `L03` 다크 모드 지원 (ThemeData.dark)

---

## 5. 프론트엔드 (Flutter) — 홈 탭 (8개 섹션)

- [ ] `H01` ① 검색 바 (상단 고정, pill형 TextField)
- [x] `H02` ② 읽기 스트릭 배너 (연속 일수 + LinearProgressIndicator)
- [x] `H03` ③ 오늘의 말씀 카드 (참조 + 미리보기 + 읽기 CTA)
- [x] `H04` ④ 감정/상황 맞춤 추천 (원형 칩 가로 스크롤)
- [x] `H05` ⑤ 구약 추천 카드 (가로 스크롤)
- [x] `H06` ⑥ 신약 추천 카드 (가로 스크롤)
- [x] `H07` ⑦ 최근 읽은 장 (가로 스크롤 카드)
- [x] `H08` ⑧ 오늘의 한 줄 기도 카드

---

## 6. 프론트엔드 (Flutter) — 장 읽기 화면

- [x] `R01` 장 전체 본문 표시 (절 번호 포함, ListView)
- [x] `R02` AI 쉬운 설명 표시 (On-Demand, Shimmer 로딩)
- [x] `R03` 삶 적용 한 줄 표시 ("오늘 이렇게 적용해 보세요:")
- [ ] `R04` 즐겨찾기 버튼 (하트/북마크)
- [x] `R05` 대표 구절 하이라이트 (감정 추천에서 진입 시)

---

## 7. 프론트엔드 (Flutter) — 즐겨찾기 탭

- [ ] `F01` 즐겨찾기 목록 표시 (최신순, ListView)
- [x] `F02` 즐겨찾기 해제(삭제) 기능 (Dismissible 스와이프)
- [ ] `F03` 탭 시 장 읽기 화면 이동
- [ ] `F04` 로컬 저장 (비로그인 — SharedPreferences)

---

## 8. 프론트엔드 (Flutter) — 설정 탭
