#!/bin/zsh
#
# BibleSsam QA 자동화 스크립트
# 린트, 타입체크, 단위/통합/E2E 테스트, 커버리지 리포트
#
# 사용법:
#   ./scripts/qa.sh              # 전체 실행
#   ./scripts/qa.sh lint         # 린트만
#   ./scripts/qa.sh typecheck    # 타입체크만
#   ./scripts/qa.sh unit         # 단위 테스트만
#   ./scripts/qa.sh security     # 보안 테스트만
#   ./scripts/qa.sh e2e          # E2E 테스트만
#   ./scripts/qa.sh coverage     # 커버리지 리포트
#

set -uo pipefail

ROOT="${0:a:h:h}"
WEB="$ROOT/web"

# 색상
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

PASS=0
FAIL=0
SKIP=0

print_header() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  $1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

run_step() {
  local name="$1"
  shift
  echo -e "  ${YELLOW}▸${NC} $name..."
  if "$@" 2>&1; then
    echo -e "  ${GREEN}✓${NC} $name 완료"
    PASS=$((PASS + 1))
    return 0
  else
    echo -e "  ${RED}✗${NC} $name 실패"
    FAIL=$((FAIL + 1))
    return 1
  fi
}

# ── 린트 ──
do_lint() {
  print_header "1. ESLint 린트 검사"
  cd "$WEB"
  run_step "ESLint" npx eslint src/ --ext .ts,.tsx --max-warnings 10 || true
}

# ── 타입 체크 ──
do_typecheck() {
  print_header "2. TypeScript 타입 검사"
  cd "$WEB"
  run_step "tsc --noEmit" npx tsc --noEmit
}

# ── 단위 테스트 ──
do_unit() {
  print_header "3. 단위 테스트 (Jest)"
  cd "$WEB"
  run_step "Unit Tests" npx jest --testPathPatterns='__tests__/unit' --passWithNoTests
}

# ── 보안 테스트 ──
do_security() {
  print_header "4. 보안 테스트 (Jest)"
  cd "$WEB"
  run_step "Security Tests" npx jest --testPathPatterns='__tests__/security' --passWithNoTests
}

# ── 통합 테스트 ──
do_integration() {
  print_header "5. 통합 테스트 (Jest)"
  cd "$WEB"
  run_step "Integration Tests" npx jest --testPathPatterns='__tests__/integration' --passWithNoTests
}

# ── E2E 테스트 ──
do_e2e() {
  print_header "6. E2E 테스트 (Playwright)"
  cd "$WEB"
  # Playwright 브라우저가 설치되어 있는지 확인
  if ! npx playwright --version > /dev/null 2>&1; then
    echo -e "  ${YELLOW}⚠${NC} Playwright가 설치되지 않았습니다. 설치 중..."
    npx playwright install chromium
  fi
  run_step "E2E Tests" npx playwright test --reporter=list
}

# ── 커버리지 ──
do_coverage() {
  print_header "7. 커버리지 리포트"
  cd "$WEB"
  run_step "Coverage" npx jest --coverage --testPathPatterns='__tests__/(unit|security)' --passWithNoTests
}

# ── 결과 요약 ──
print_summary() {
  print_header "QA 결과 요약"
  echo -e "  ${GREEN}통과: $PASS${NC}"
  echo -e "  ${RED}실패: $FAIL${NC}"
  echo -e "  ${YELLOW}스킵: $SKIP${NC}"
  echo ""
  if [[ $FAIL -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}모든 QA 검사를 통과했습니다!${NC}"
  else
    echo -e "  ${RED}${BOLD}$FAIL개 QA 검사에 실패했습니다.${NC}"
  fi
  echo ""
}

# ── 메인 ──

MODE="${1:-all}"

print_header "BibleSsam QA 자동화"
echo "  대상: $WEB"
echo "  모드: $MODE"

case "$MODE" in
  lint)       do_lint ;;
  typecheck)  do_typecheck ;;
  unit)       do_unit ;;
  security)   do_security ;;
  integration) do_integration ;;
  e2e)        do_e2e ;;
  coverage)   do_coverage ;;
  all)
    do_lint
    do_typecheck
    do_unit
    do_security
    do_integration
    do_coverage
    # E2E는 별도 (서버 필요)
    echo ""
    echo -e "  ${YELLOW}ℹ${NC} E2E 테스트는 서버가 필요합니다: ./scripts/qa.sh e2e"
    ;;
  *)
    echo "사용법: $0 {all|lint|typecheck|unit|security|integration|e2e|coverage}"
    exit 1
    ;;
esac

print_summary
exit $FAIL
