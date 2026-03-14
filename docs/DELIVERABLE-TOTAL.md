# BibleSsam 전체 산출물 리포트

> 자동 생성됨 — 2026-03-13 20:22

---

## 프로젝트 진행률

**체크리스트: 7 / 64 (10%)**

---

## 파일 통계

| 구분 | 수량 |
|------|------|
| TypeScript 전체 (.ts + .tsx) | 2개 |
| API Route 파일 | 0개 |
| React 컴포넌트 | 0개 |
| 페이지 | 1개 |
| 라이브러리 (lib/) | 0개 |
| 커스텀 훅 (hooks/) | 0개 |
| 타입 정의 (types/) | 0개 |
| 정적 데이터 (data/) | 0개 |

---

## 에이전트별 산출물 요약

### backend-api
- API Routes: 0개
- 라이브러리: 0개
- 상세: [DELIVERABLE-backend-api.md](./DELIVERABLE-backend-api.md)

### frontend-web
- 페이지: 1개
- 컴포넌트: 0개
- 상세: [DELIVERABLE-frontend-web.md](./DELIVERABLE-frontend-web.md)

### bible-data
- 데이터 파일: 0개
- 타입 정의: 0개
- 상세: [DELIVERABLE-bible-data.md](./DELIVERABLE-bible-data.md)

### auth
- 인증 API: 0개
- 상세: [DELIVERABLE-auth.md](./DELIVERABLE-auth.md)

### flutter-app
- 상태: Phase 2 (미생성)
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

```
web/src/app/layout.tsx
web/src/app/page.tsx
```

---

## Docker 환경

| 서비스 | 이미지 | 포트 |
|--------|--------|------|
| web | Next.js (standalone) | 3000 |
| db | postgres:16-alpine | 5432 |
| redis | redis:7-alpine | 6379 |

---

*리포트 생성 시각: 2026-03-13 20:22:53*
