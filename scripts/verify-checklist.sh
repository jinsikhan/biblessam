#!/bin/zsh
#
# BibleSsam 체크리스트 자동 검증 스크립트
# 구현 상태를 확인하고 CHECKLIST.md를 자동 업데이트합니다.
#
# 사용법: ./scripts/verify-checklist.sh
#

set -uo pipefail

ROOT="${0:a:h:h}"
WEB="$ROOT/web"
SRC="$WEB/src"
FLUTTER="$ROOT/flutter_app"
CHECKLIST="$ROOT/CHECKLIST.md"

# 색상
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 카운터
typeset -A CAT_TOTAL CAT_DONE RESULTS ID_TO_CAT
TOTAL=0
DONE=0

# ── 검증 함수들 ──

file_exists() { [[ -f "$1" ]]; }
dir_exists() { [[ -d "$1" ]]; }

file_contains() {
  local file="$1" pattern="$2"
  [[ -f "$file" ]] && grep -qE "$pattern" "$file" 2>/dev/null
}

any_file_contains() {
  local dir="$1" glob="$2" pattern="$3"
  [[ -d "$dir" ]] && find "$dir" -name "$glob" -exec grep -lE "$pattern" {} + 2>/dev/null | head -1 | grep -q .
}

glob_exists() {
  local pattern="$1"
  local files=( ${~pattern}(N) )
  (( ${#files} > 0 ))
}

# ── 각 체크 항목 정의 ──

# === 1. 프로젝트 초기 설정 ===
check_P01() { file_exists "$WEB/package.json" && file_contains "$WEB/package.json" "next"; }
check_P02() { file_exists "$WEB/tsconfig.json" && file_contains "$WEB/tsconfig.json" '"strict"'; }
check_P03() {
  (file_exists "$WEB/tailwind.config.ts" || file_exists "$WEB/tailwind.config.js" || file_exists "$WEB/postcss.config.mjs") \
  && file_exists "$WEB/package.json" && file_contains "$WEB/package.json" "tailwindcss"
}
check_P04() { file_exists "$SRC/app/layout.tsx"; }
check_P05() { file_exists "$WEB/.env.local.example" || file_exists "$WEB/.env.example" || file_exists "$WEB/.env.local"; }
check_P06() { dir_exists "$SRC/types" && glob_exists "$SRC/types/*.ts"; }
check_P07() { file_exists "$FLUTTER/pubspec.yaml"; }

# === 2. 정적 데이터 ===
check_D01() { file_exists "$SRC/data/bible-books.json" || file_exists "$SRC/data/bible-books.ts"; }
check_D02() { file_exists "$SRC/data/emotion-themes.json" || file_exists "$SRC/data/emotion-themes.ts"; }
check_D03() {
  any_file_contains "$SRC" "*.ts" "nameKo|name_ko|korean" 2>/dev/null || \
  any_file_contains "$SRC" "*.json" "nameKo|name_ko" 2>/dev/null || \
  any_file_contains "$SRC/data" "*.ts" "Genesis.*창세기|창세기.*Genesis" 2>/dev/null
}

# === 3. 백엔드 API ===
check_B01() { glob_exists "$SRC/app/api/bible/chapter/route.ts*"; }
check_B02() { glob_exists "$SRC/app/api/bible/books/route.ts*"; }
check_B03() { glob_exists "$SRC/app/api/bible/search/route.ts*"; }
check_B04() { file_exists "$SRC/lib/bible-api.ts"; }
check_B05() { file_exists "$SRC/lib/daily-chapter.ts"; }
check_B06() { glob_exists "$SRC/app/api/daily/route.ts*"; }
check_B07() {
  file_exists "$SRC/lib/ai-api.ts" \
  && any_file_contains "$SRC/lib" "ai-api.*" "gemini|generativelanguage|GEMINI" 2>/dev/null
}
check_B08() {
  file_exists "$SRC/lib/ai-api.ts" \
  && any_file_contains "$SRC/lib" "ai-api.*" "openrouter|groq|fallback" 2>/dev/null
}
check_B09() { glob_exists "$SRC/app/api/ai/explanation/route.ts*"; }
check_B10() { glob_exists "$SRC/app/api/ai/prayer/route.ts*"; }
check_B11() {
  any_file_contains "$SRC/lib" "*.ts" "cache|Cache" 2>/dev/null || \
  any_file_contains "$SRC/app/api" "*.ts" "cache|Cache" 2>/dev/null
}
check_B12() {
  glob_exists "$SRC/app/api/recommendations/*/route.ts*" || \
  glob_exists "$SRC/app/api/emotion*/route.ts*"
}
check_B13() { glob_exists "$SRC/app/api/favorites*/route.ts*" || glob_exists "$SRC/app/api/favorites/route.ts*"; }
check_B14() { glob_exists "$SRC/app/api/history*/route.ts*" || glob_exists "$SRC/app/api/history/route.ts*"; }
check_B15() { glob_exists "$SRC/app/api/streak*/route.ts*" || glob_exists "$SRC/app/api/streak/route.ts*"; }

# === 4. 레이아웃 (Flutter) ===
check_L01() {
  any_file_contains "$FLUTTER/lib" "*.dart" "BottomNavigationBar|NavigationBar|bottomNavigationBar" 2>/dev/null
}
check_L02() {
  any_file_contains "$FLUTTER/lib" "*.dart" "MediaQuery|LayoutBuilder|Responsive|maxWidth" 2>/dev/null
}
check_L03() {
  any_file_contains "$FLUTTER/lib" "*.dart" "ThemeData\.dark|darkTheme|ThemeMode" 2>/dev/null
}

# === 5. 홈 탭 (Flutter) ===
check_H01() { any_file_contains "$FLUTTER/lib" "*.dart" "SearchBar|search_bar|TextField.*검색" 2>/dev/null; }
check_H02() { any_file_contains "$FLUTTER/lib" "*.dart" "StreakBanner|streak_banner|LinearProgressIndicator.*streak" 2>/dev/null; }
check_H03() { any_file_contains "$FLUTTER/lib" "*.dart" "DailyChapter|daily_chapter|오늘의.*말씀" 2>/dev/null; }
check_H04() { any_file_contains "$FLUTTER/lib" "*.dart" "EmotionChip|emotion_chip|감정" 2>/dev/null; }
check_H05() { any_file_contains "$FLUTTER/lib" "*.dart" "OldTestament|구약.*추천" 2>/dev/null; }
check_H06() { any_file_contains "$FLUTTER/lib" "*.dart" "NewTestament|신약.*추천" 2>/dev/null; }
check_H07() { any_file_contains "$FLUTTER/lib" "*.dart" "RecentlyRead|recently_read|최근.*읽" 2>/dev/null; }
check_H08() { any_file_contains "$FLUTTER/lib" "*.dart" "DailyPrayer|daily_prayer|한.*줄.*기도" 2>/dev/null; }

# === 6. 장 읽기 (Flutter) ===
check_R01() { any_file_contains "$FLUTTER/lib" "*.dart" "ChapterReader|chapter_reader" 2>/dev/null; }
check_R02() { any_file_contains "$FLUTTER/lib" "*.dart" "AiExplanation|ai_explanation" 2>/dev/null; }
check_R03() { any_file_contains "$FLUTTER/lib" "*.dart" "LifeApplication|life_application|적용해.*보세요" 2>/dev/null; }
check_R04() { any_file_contains "$FLUTTER/lib" "*.dart" "FavoriteButton|favorite.*button|IconButton.*favorite" 2>/dev/null; }
check_R05() { any_file_contains "$FLUTTER/lib" "*.dart" "highlight|하이라이트|highlightVerse" 2>/dev/null; }

# === 7. 즐겨찾기 (Flutter) ===
check_F01() { any_file_contains "$FLUTTER/lib" "*.dart" "FavoriteList|favorite_list" 2>/dev/null; }
check_F02() { any_file_contains "$FLUTTER/lib" "*.dart" "removeFavorite|deleteFavorite|Dismissible.*favorite" 2>/dev/null; }
check_F03() { any_file_contains "$FLUTTER/lib" "*.dart" "favorite.*onTap|favorite.*Navigator|favorite.*router" 2>/dev/null; }
check_F04() { any_file_contains "$FLUTTER/lib" "*.dart" "SharedPreferences.*favorite|favorite.*SharedPreferences|FAVORITES_KEY" 2>/dev/null; }

# === 8. 설정 (Flutter) ===
check_S01() { any_file_contains "$FLUTTER/lib" "*.dart" "login|Login|logout|Logout|signIn|signOut|로그인|로그아웃" 2>/dev/null; }
check_S02() { any_file_contains "$FLUTTER/lib" "*.dart" "StreakCalendar|streak.*calendar|TableCalendar|달력" 2>/dev/null; }
check_S03() { any_file_contains "$FLUTTER/lib" "*.dart" "translation|번역본|bible.*version" 2>/dev/null; }
check_S04() { any_file_contains "$FLUTTER/lib" "*.dart" "language|언어.*설정|ai.*lang" 2>/dev/null; }
check_S05() { any_file_contains "$FLUTTER/lib" "*.dart" "darkMode|dark_mode|다크.*모드|ThemeMode" 2>/dev/null; }
check_S06() { any_file_contains "$FLUTTER/lib" "*.dart" "app.*info|version|버전|앱.*정보|packageInfo" 2>/dev/null; }

# === 9. 검색/리스트 (Flutter) ===
check_X01() { any_file_contains "$FLUTTER/lib" "*.dart" "parseReference|parse.*book.*chapter|searchBible" 2>/dev/null; }
check_X02() { any_file_contains "$FLUTTER/lib" "*.dart" "BookList|book_list|책.*목록" 2>/dev/null; }
check_X03() { any_file_contains "$FLUTTER/lib" "*.dart" "ChapterList|chapter_list|장.*목록" 2>/dev/null; }
check_X04() {
  any_file_contains "$FLUTTER/lib" "*.dart" "BookList|book_list" 2>/dev/null && \
  any_file_contains "$FLUTTER/lib" "*.dart" "ChapterReader|chapter_reader" 2>/dev/null
}

# === 10. 스트릭 (Flutter) ===
check_K01() {
  any_file_contains "$FLUTTER/lib" "*.dart" "Timer\.|timer|elapsed|duration|readingTime" 2>/dev/null
}
check_K02() { any_file_contains "$FLUTTER/lib" "*.dart" "10.*min|600|markAsRead|streak.*complete" 2>/dev/null; }
check_K03() { any_file_contains "$FLUTTER/lib" "*.dart" "consecutive|streak.*count|currentStreak|연속" 2>/dev/null; }
check_K04() { any_file_contains "$FLUTTER/lib" "*.dart" "LinearProgressIndicator|ProgressBar|프로그레스" 2>/dev/null; }
check_K05() { any_file_contains "$FLUTTER/lib" "*.dart" "SharedPreferences.*streak|streak.*SharedPreferences|STREAK_KEY" 2>/dev/null; }

# === 11. 인증 (Flutter + 백엔드) ===
check_A01() { any_file_contains "$FLUTTER/lib" "*.dart" "google.*auth|google.*login|google.*sign|GoogleSignIn" 2>/dev/null; }
check_A02() { any_file_contains "$FLUTTER/lib" "*.dart" "kakao.*auth|kakao.*login|kakao.*sign|KakaoAuth" 2>/dev/null; }
check_A03() {
  any_file_contains "$FLUTTER/lib" "*.dart" "jwt|JWT|accessToken|refreshToken" 2>/dev/null || \
  any_file_contains "$SRC" "*.ts" "jwt|JWT|jsonwebtoken|accessToken|refreshToken" 2>/dev/null
}
check_A04() { any_file_contains "$FLUTTER/lib" "*.dart" "syncData|sync.*favorites|sync.*server|merge.*local" 2>/dev/null; }
check_A05() {
  any_file_contains "$FLUTTER/lib" "*.dart" "authGuard|withAuth|requireAuth|AuthMiddleware" 2>/dev/null || \
  any_file_contains "$SRC" "*.ts" "middleware|authGuard|withAuth|requireAuth" 2>/dev/null
}


# === 12. QA ===
check_Q01() { file_exists "$WEB/jest.config.ts" || file_exists "$WEB/jest.config.js"; }
check_Q02() { file_exists "$WEB/playwright.config.ts" || file_exists "$WEB/playwright.config.js"; }
check_Q03() {
  glob_exists "$SRC/__tests__/unit/sanitize*" && \
  glob_exists "$SRC/__tests__/unit/rate-limit*" && \
  glob_exists "$SRC/__tests__/unit/headers*"
}
check_Q04() { glob_exists "$SRC/__tests__/security/xss*" && glob_exists "$SRC/__tests__/security/injection*"; }
check_Q05() { glob_exists "$SRC/__tests__/e2e/home*" && glob_exists "$SRC/__tests__/e2e/reader*"; }
check_Q06() { glob_exists "$SRC/__tests__/integration/api*"; }
check_Q07() { file_exists "$ROOT/scripts/qa.sh" && [[ -x "$ROOT/scripts/qa.sh" ]]; }
check_Q08() {
  # 커버리지 리포트가 존재하고 60% 이상인지 확인
  [[ -d "$WEB/coverage" ]] && any_file_contains "$WEB/coverage" "*.json" '"pct":[6-9][0-9]|"pct":100' 2>/dev/null
}

# === 13. 보안 ===
check_SEC01() { file_exists "$SRC/lib/security/sanitize.ts" && file_contains "$SRC/lib/security/sanitize.ts" "escapeHtml"; }
check_SEC02() { file_exists "$SRC/lib/security/rate-limit.ts" && file_contains "$SRC/lib/security/rate-limit.ts" "AI_RATE_LIMIT"; }
check_SEC03() { file_exists "$SRC/lib/security/headers.ts" && file_contains "$SRC/lib/security/headers.ts" "Content-Security-Policy"; }
check_SEC04() { file_exists "$SRC/lib/security/env.ts" && file_contains "$SRC/lib/security/env.ts" "NEXT_PUBLIC_"; }
check_SEC05() { file_exists "$SRC/lib/security/cors.ts" && file_contains "$SRC/lib/security/cors.ts" "ALLOWED_ORIGINS"; }
check_SEC06() { file_exists "$ROOT/scripts/security-audit.sh" && [[ -x "$ROOT/scripts/security-audit.sh" ]]; }
check_SEC07() {
  file_exists "$SRC/middleware.ts" && \
  any_file_contains "$SRC" "middleware.ts" "applySecurityHeaders|SECURITY_HEADERS" 2>/dev/null
}
check_SEC08() {
  any_file_contains "$SRC/app/api" "*.ts" "checkRateLimit|rateLimit" 2>/dev/null
}

# ── 카테고리 매핑 ──

for id in P01 P02 P03 P04 P05 P06 P07; do ID_TO_CAT[$id]="프로젝트 설정"; done
for id in D01 D02 D03; do ID_TO_CAT[$id]="정적 데이터"; done
for id in B01 B02 B03 B04 B05 B06 B07 B08 B09 B10 B11 B12 B13 B14 B15; do ID_TO_CAT[$id]="백엔드 API"; done
for id in L01 L02 L03; do ID_TO_CAT[$id]="레이아웃"; done
for id in H01 H02 H03 H04 H05 H06 H07 H08; do ID_TO_CAT[$id]="홈 탭"; done
for id in R01 R02 R03 R04 R05; do ID_TO_CAT[$id]="장 읽기"; done
for id in F01 F02 F03 F04; do ID_TO_CAT[$id]="즐겨찾기"; done
for id in S01 S02 S03 S04 S05 S06; do ID_TO_CAT[$id]="설정"; done
for id in X01 X02 X03 X04; do ID_TO_CAT[$id]="검색/리스트"; done
for id in K01 K02 K03 K04 K05; do ID_TO_CAT[$id]="스트릭"; done
for id in A01 A02 A03 A04 A05; do ID_TO_CAT[$id]="인증"; done
for id in Q01 Q02 Q03 Q04 Q05 Q06 Q07 Q08; do ID_TO_CAT[$id]="QA"; done
for id in SEC01 SEC02 SEC03 SEC04 SEC05 SEC06 SEC07 SEC08; do ID_TO_CAT[$id]="보안"; done

ALL_IDS=(
  P01 P02 P03 P04 P05 P06 P07
  D01 D02 D03
  B01 B02 B03 B04 B05 B06 B07 B08 B09 B10 B11 B12 B13 B14 B15
  L01 L02 L03
  H01 H02 H03 H04 H05 H06 H07 H08
  R01 R02 R03 R04 R05
  F01 F02 F03 F04
  S01 S02 S03 S04 S05 S06
  X01 X02 X03 X04
  K01 K02 K03 K04 K05
  A01 A02 A03 A04 A05
  Q01 Q02 Q03 Q04 Q05 Q06 Q07 Q08
  SEC01 SEC02 SEC03 SEC04 SEC05 SEC06 SEC07 SEC08
)

# 카테고리 카운터 초기화
for cat in "프로젝트 설정" "정적 데이터" "백엔드 API" "레이아웃" "홈 탭" "장 읽기" "즐겨찾기" "설정" "검색/리스트" "스트릭" "인증" "QA" "보안"; do
  CAT_TOTAL[$cat]=0
  CAT_DONE[$cat]=0
done


# ── 검증 실행 ──

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  BibleSsam 체크리스트 자동 검증"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for id in "${ALL_IDS[@]}"; do
  cat="${ID_TO_CAT[$id]}"
  CAT_TOTAL[$cat]=$(( ${CAT_TOTAL[$cat]} + 1 ))
  TOTAL=$((TOTAL + 1))

  if "check_$id" 2>/dev/null; then
    RESULTS[$id]=1
    CAT_DONE[$cat]=$(( ${CAT_DONE[$cat]} + 1 ))
    DONE=$((DONE + 1))
    echo -e "  ${GREEN}[x]${NC} $id"
  else
    RESULTS[$id]=0
    echo -e "  ${RED}[ ]${NC} $id"
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


# ── CHECKLIST.md 업데이트 ──

TMPFILE=$(mktemp)

while IFS= read -r line; do
  updated=false
  for id in "${ALL_IDS[@]}"; do
    if echo "$line" | grep -q "\`$id\`"; then
      if [[ ${RESULTS[$id]} -eq 1 ]]; then
        echo "$line" | sed 's/^- \[ \]/- [x]/' >> "$TMPFILE"
      else
        echo "$line" | sed 's/^- \[x\]/- [ ]/' >> "$TMPFILE"
      fi
      updated=true
      break
    fi
  done

  if ! $updated; then
    echo "$line" >> "$TMPFILE"
  fi
done < "$CHECKLIST"

# 진행 요약 테이블 업데이트
SUMMARY_TMPFILE=$(mktemp)

while IFS= read -r line; do
  matched=false
  for cat in "프로젝트 설정" "정적 데이터" "백엔드 API" "레이아웃" "홈 탭" "장 읽기" "즐겨찾기" "설정" "검색/리스트" "스트릭" "인증" "QA" "보안"; do
    if echo "$line" | grep -q "^| $cat |"; then
      t=${CAT_TOTAL[$cat]}
      d=${CAT_DONE[$cat]}
      if [[ $t -gt 0 ]]; then
        pct=$(( d * 100 / t ))
      else
        pct=0
      fi
      echo "| $cat | $t | $d | ${pct}% |" >> "$SUMMARY_TMPFILE"
      matched=true
      break
    fi
  done

  if echo "$line" | grep -q "^| \*\*합계\*\*"; then
    if [[ $TOTAL -gt 0 ]]; then
      total_pct=$(( DONE * 100 / TOTAL ))
    else
      total_pct=0
    fi
    echo "| **합계** | **$TOTAL** | **$DONE** | **${total_pct}%** |" >> "$SUMMARY_TMPFILE"
    matched=true
  fi

  if ! $matched; then
    echo "$line" >> "$SUMMARY_TMPFILE"
  fi
done < "$TMPFILE"

# 타임스탬프 업데이트
sed -i '' "s|^\*마지막 검증:.*|*마지막 검증: $(date '+%Y-%m-%d %H:%M:%S')*|" "$SUMMARY_TMPFILE"

cp "$SUMMARY_TMPFILE" "$CHECKLIST"
rm -f "$TMPFILE" "$SUMMARY_TMPFILE"


# ── 결과 출력 ──

echo ""
echo "  카테고리별 진행률:"
echo ""
for cat in "프로젝트 설정" "정적 데이터" "백엔드 API" "레이아웃" "홈 탭" "장 읽기" "즐겨찾기" "설정" "검색/리스트" "스트릭" "인증" "QA" "보안"; do
  t=${CAT_TOTAL[$cat]}
  d=${CAT_DONE[$cat]}
  if [[ $t -gt 0 ]]; then
    pct=$(( d * 100 / t ))
  else
    pct=0
  fi

  # 프로그레스 바
  filled=$(( pct / 5 ))
  empty=$(( 20 - filled ))
  bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done

  if [[ $pct -eq 100 ]]; then
    color=$GREEN
  elif [[ $pct -gt 0 ]]; then
    color=$YELLOW
  else
    color=$RED
  fi
  printf "  %-14s ${color}%s %3d%%${NC}  (%d/%d)\n" "$cat" "$bar" "$pct" "$d" "$t"
done

echo ""
if [[ $TOTAL -gt 0 ]]; then
  total_pct=$(( DONE * 100 / TOTAL ))
else
  total_pct=0
fi
echo -e "  ${YELLOW}전체 진행률: $DONE / $TOTAL (${total_pct}%)${NC}"
echo ""
echo "  CHECKLIST.md 업데이트 완료!"

# ── 100% 달성 시 산출물 자동 생성 ──
if [[ $total_pct -eq 100 ]]; then
  echo ""
  echo -e "  ${GREEN}🎉 100% 달성! 산출물 자동 생성 중...${NC}"
  zsh "$ROOT/scripts/generate-deliverables.sh" --force 2>/dev/null
fi
echo ""
