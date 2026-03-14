#!/bin/zsh
#
# BibleSsam 보안 감사 스크립트
# 의존성 취약점, 비밀 노출, 환경 변수, OWASP 규칙 검증
#
# 사용법: ./scripts/security-audit.sh
#

set -uo pipefail

ROOT="${0:a:h:h}"
WEB="$ROOT/web"
SRC="$WEB/src"

# 색상
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

WARNINGS=0
ERRORS=0

print_header() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  $1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

pass() { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; WARNINGS=$((WARNINGS + 1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; ERRORS=$((ERRORS + 1)); }

# ── 1. 비밀 노출 검사 ──
check_secrets() {
  print_header "1. 비밀 노출 검사"

  # .env 파일이 git에 추가되지 않았는지 확인
  if [[ -d "$ROOT/.git" ]]; then
    if git -C "$ROOT" ls-files --cached | grep -qE '\.env$|\.env\.local$|\.env\.production$'; then
      fail ".env 파일이 git에 커밋되어 있습니다!"
    else
      pass ".env 파일이 git에 추적되지 않음"
    fi
  fi

  # .gitignore에 .env가 포함되어 있는지 확인
  if [[ -f "$WEB/.gitignore" ]] && grep -q '\.env' "$WEB/.gitignore"; then
    pass ".gitignore에 .env 패턴 포함"
  elif [[ -f "$ROOT/.gitignore" ]] && grep -q '\.env' "$ROOT/.gitignore"; then
    pass ".gitignore에 .env 패턴 포함"
  else
    warn ".gitignore에 .env 패턴이 없습니다"
  fi

  # 소스 코드에 하드코딩된 비밀 검색
  local patterns=(
    "GEMINI_API_KEY\s*=\s*['\"][^'\"]*['\"]"
    "OPENROUTER_API_KEY\s*=\s*['\"][^'\"]*['\"]"
    "GROQ_API_KEY\s*=\s*['\"][^'\"]*['\"]"
    "JWT_SECRET\s*=\s*['\"][^'\"]*['\"]"
    "DATABASE_URL\s*=\s*['\"]postgres"
    "password\s*=\s*['\"][^'\"]{8,}['\"]"
  )

  local found_secrets=false
  for pattern in "${patterns[@]}"; do
    if find "$SRC" -name '*.ts' -o -name '*.tsx' | xargs grep -lE "$pattern" 2>/dev/null | head -1 | grep -q .; then
      fail "소스 코드에 하드코딩된 비밀 발견: $pattern"
      found_secrets=true
    fi
  done

  if ! $found_secrets; then
    pass "소스 코드에 하드코딩된 비밀 없음"
  fi
}

# ── 2. 의존성 취약점 검사 ──
check_dependencies() {
  print_header "2. 의존성 취약점 검사"

  cd "$WEB"
  if command -v npm > /dev/null; then
    echo "  npm audit 실행 중..."
    local audit_output
    audit_output=$(npm audit --json 2>/dev/null || true)

    local high_count
    high_count=$(echo "$audit_output" | grep -o '"high":[0-9]*' | head -1 | cut -d: -f2)
    local critical_count
    critical_count=$(echo "$audit_output" | grep -o '"critical":[0-9]*' | head -1 | cut -d: -f2)

    if [[ "${critical_count:-0}" -gt 0 ]]; then
      fail "Critical 취약점 ${critical_count}개 발견!"
    elif [[ "${high_count:-0}" -gt 0 ]]; then
      warn "High 취약점 ${high_count}개 발견"
    else
      pass "Critical/High 취약점 없음"
    fi
  else
    warn "npm을 찾을 수 없습니다"
  fi
}

# ── 3. 보안 유틸리티 존재 확인 ──
check_security_utils() {
  print_header "3. 보안 유틸리티 파일 검사"

  local files=(
    "$SRC/lib/security/sanitize.ts:입력값 살균"
    "$SRC/lib/security/rate-limit.ts:Rate Limiting"
    "$SRC/lib/security/headers.ts:보안 헤더"
    "$SRC/lib/security/env.ts:환경 변수 검증"
    "$SRC/lib/security/cors.ts:CORS 설정"
  )

  for entry in "${files[@]}"; do
    local file="${entry%%:*}"
    local desc="${entry##*:}"
    if [[ -f "$file" ]]; then
      pass "$desc ($file)"
    else
      fail "$desc 파일 없음: $file"
    fi
  done
}

# ── 4. 보안 헤더 설정 확인 ──
check_headers_config() {
  print_header "4. 보안 헤더 설정 검사"

  if [[ -f "$SRC/lib/security/headers.ts" ]]; then
    local required_headers=(
      "X-XSS-Protection"
      "X-Content-Type-Options"
      "X-Frame-Options"
      "Strict-Transport-Security"
      "Content-Security-Policy"
      "Permissions-Policy"
      "Referrer-Policy"
    )

    for header in "${required_headers[@]}"; do
      if grep -q "$header" "$SRC/lib/security/headers.ts"; then
        pass "$header 설정됨"
      else
        fail "$header 미설정"
      fi
    done
  else
    fail "headers.ts 파일이 없습니다"
  fi
}

# ── 5. CORS 설정 확인 ──
check_cors() {
  print_header "5. CORS 설정 검사"

  if [[ -f "$SRC/lib/security/cors.ts" ]]; then
    if grep -q 'ALLOWED_ORIGINS' "$SRC/lib/security/cors.ts"; then
      pass "CORS 화이트리스트 설정됨"
    else
      warn "CORS 화이트리스트가 보이지 않습니다"
    fi

    if grep -q '\*' "$SRC/lib/security/cors.ts" | grep -v "//"; then
      warn "CORS에 와일드카드(*) 사용 가능성 — 확인 필요"
    else
      pass "CORS 와일드카드 미사용"
    fi
  fi
}

# ── 6. Rate Limiting 설정 확인 ──
check_rate_limit() {
  print_header "6. Rate Limiting 설정 검사"

  if [[ -f "$SRC/lib/security/rate-limit.ts" ]]; then
    if grep -q 'AI_RATE_LIMIT' "$SRC/lib/security/rate-limit.ts"; then
      pass "AI 엔드포인트 Rate Limit 설정됨"
    else
      warn "AI 엔드포인트 Rate Limit 미설정"
    fi

    if grep -q 'AUTH_RATE_LIMIT' "$SRC/lib/security/rate-limit.ts"; then
      pass "인증 엔드포인트 Rate Limit 설정됨"
    else
      warn "인증 엔드포인트 Rate Limit 미설정"
    fi
  fi
}

# ── 7. 환경 변수 검증 ──
check_env_validation() {
  print_header "7. 환경 변수 보안 검사"

  if [[ -f "$SRC/lib/security/env.ts" ]]; then
    if grep -q 'NEXT_PUBLIC_' "$SRC/lib/security/env.ts"; then
      pass "NEXT_PUBLIC_ 민감 변수 노출 감지 로직 있음"
    else
      warn "NEXT_PUBLIC_ 노출 감지 로직 없음"
    fi

    if grep -q "typeof window" "$SRC/lib/security/env.ts"; then
      pass "서버 전용 변수 클라이언트 접근 차단 로직 있음"
    else
      warn "서버 전용 변수 보호 로직 없음"
    fi
  fi
}

# ── 8. 보안 테스트 존재 확인 ──
check_security_tests() {
  print_header "8. 보안 테스트 검사"

  local test_files=( "$SRC/__tests__/security/"*.test.ts(N) )
  if (( ${#test_files} > 0 )); then
    pass "보안 테스트 파일 ${#test_files}개 존재"
    for f in "${test_files[@]}"; do
      echo "    - $(basename $f)"
    done
  else
    fail "보안 테스트 파일이 없습니다"
  fi
}


# ── 메인 ──

print_header "BibleSsam 보안 감사"
echo "  대상: $ROOT"
echo "  시간: $(date '+%Y-%m-%d %H:%M:%S')"

check_secrets
check_dependencies
check_security_utils
check_headers_config
check_cors
check_rate_limit
check_env_validation
check_security_tests

# ── 결과 요약 ──
print_header "보안 감사 결과"
echo -e "  ${GREEN}통과 항목: $((WARNINGS + ERRORS == 0 ? 1 : 0)) (에러/경고 없는 섹션)${NC}"
echo -e "  ${YELLOW}경고: $WARNINGS${NC}"
echo -e "  ${RED}에러: $ERRORS${NC}"
echo ""

if [[ $ERRORS -gt 0 ]]; then
  echo -e "  ${RED}${BOLD}보안 에러가 발견되었습니다. 즉시 수정이 필요합니다!${NC}"
  exit 1
elif [[ $WARNINGS -gt 0 ]]; then
  echo -e "  ${YELLOW}${BOLD}경고가 있습니다. 검토를 권장합니다.${NC}"
  exit 0
else
  echo -e "  ${GREEN}${BOLD}모든 보안 검사를 통과했습니다!${NC}"
  exit 0
fi
