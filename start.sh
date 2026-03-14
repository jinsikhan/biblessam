#!/bin/zsh
#
# ============================================
#  BibleSsam - 원클릭 시작
# ============================================
#
#  사용법:
#    ./start.sh         # 개발 모드 (기본)
#    ./start.sh dev     # 개발 모드
#    ./start.sh prod    # 프로덕션 모드
#    ./start.sh stop    # 중지
#    ./start.sh status  # 상태 확인
#
# ============================================

set -uo pipefail

ROOT="${0:a:h}"
cd "$ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

MODE="${1:-dev}"

banner() {
  echo ""
  echo -e "${CYAN}${BOLD}"
  echo "  ╔══════════════════════════════════════╗"
  echo "  ║                                      ║"
  echo "  ║     📖  BibleSsam (바이블쌤)         ║"
  echo "  ║                                      ║"
  echo "  ║   지금 내 상황에 맞는 말씀 + AI 설명  ║"
  echo "  ║                                      ║"
  echo "  ╚══════════════════════════════════════╝"
  echo -e "${NC}"
}

check_prerequisites() {
  local missing=0

  # Docker 확인
  if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker가 설치되어 있지 않습니다.${NC}"
    echo "  https://docs.docker.com/get-docker/"
    missing=1
  elif ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Docker가 실행되고 있지 않습니다.${NC}"
    echo "  Docker Desktop을 먼저 시작해주세요."
    missing=1
  fi

  # docker compose 확인
  if ! docker compose version > /dev/null 2>&1; then
    echo -e "${RED}Docker Compose가 설치되어 있지 않습니다.${NC}"
    missing=1
  fi

  if [[ $missing -eq 1 ]]; then
    exit 1
  fi

  echo -e "  Docker:          ${GREEN}OK${NC}"
  echo -e "  Docker Compose:  ${GREEN}OK${NC}"
}

setup_env() {
  if [[ ! -f "$ROOT/.env" ]]; then
    echo -e "${YELLOW}  .env 파일 생성 중...${NC}"
    cat > "$ROOT/.env" << 'ENVEOF'
POSTGRES_DB=biblessam
POSTGRES_USER=biblessam
POSTGRES_PASSWORD=biblessam_dev_2026
DB_PORT=5432
REDIS_PORT=6379
WEB_PORT=3000
GEMINI_API_KEY=
OPENROUTER_API_KEY=
GROQ_API_KEY=
ENVEOF
    echo -e "  .env:            ${GREEN}Created${NC}"
  else
    echo -e "  .env:            ${GREEN}OK${NC}"
  fi
}

dev_mode() {
  banner
  echo -e "  ${YELLOW}[ 개발 모드 ]${NC}"
  echo ""

  echo -e "${CYAN}[1/4]${NC} 환경 확인..."
  check_prerequisites
  setup_env
  echo ""

  echo -e "${CYAN}[2/4]${NC} DB + Redis 시작..."
  docker compose up -d db redis
  echo ""

  # 서비스 준비 대기
  echo -e "${CYAN}[3/4]${NC} 서비스 준비 대기..."
  local retries=0
  while ! docker compose exec db pg_isready -U biblessam > /dev/null 2>&1; do
    retries=$((retries + 1))
    if [[ $retries -gt 30 ]]; then
      echo -e "  ${RED}DB 시작 실패${NC}"
      echo "  docker compose logs db 로 확인하세요."
      exit 1
    fi
    printf "."
    sleep 1
  done
  echo -e "\n  PostgreSQL: ${GREEN}Ready${NC}"

  retries=0
  while ! docker compose exec redis redis-cli ping > /dev/null 2>&1; do
    retries=$((retries + 1))
    if [[ $retries -gt 30 ]]; then
      echo -e "  ${RED}Redis 시작 실패${NC}"
      exit 1
    fi
    printf "."
    sleep 1
  done
  echo -e "  Redis:      ${GREEN}Ready${NC}"
  echo ""

  echo -e "${CYAN}[4/4]${NC} Next.js 개발 서버 시작..."
  docker compose --profile dev up -d dev
  echo ""

  # 웹 서버 준비 대기
  retries=0
  while ! curl -s -o /dev/null -w "%{http_code}" http://localhost:${WEB_PORT:-3000} 2>/dev/null | grep -q "200\|304"; do
    retries=$((retries + 1))
    if [[ $retries -gt 60 ]]; then
      break  # 타임아웃이어도 서버는 시작 중일 수 있음
    fi
    printf "."
    sleep 2
  done
  echo ""

  echo -e "${GREEN}${BOLD}"
  echo "  ╔══════════════════════════════════════╗"
  echo "  ║  개발 서버가 준비되었습니다!          ║"
  echo "  ╚══════════════════════════════════════╝"
  echo -e "${NC}"
  echo -e "  ${CYAN}Web:${NC}     http://localhost:${WEB_PORT:-3000}"
  echo -e "  ${CYAN}DB:${NC}      postgresql://biblessam@localhost:${DB_PORT:-5432}/biblessam"
  echo -e "  ${CYAN}Redis:${NC}   redis://localhost:${REDIS_PORT:-6379}"
  echo ""
  echo -e "  명령어:"
  echo -e "    로그 보기:    ${YELLOW}docker compose --profile dev logs -f${NC}"
  echo -e "    서버 중지:    ${YELLOW}./start.sh stop${NC}"
  echo -e "    상태 확인:    ${YELLOW}./start.sh status${NC}"
  echo ""
}

prod_mode() {
  banner
  echo -e "  ${GREEN}[ 프로덕션 모드 ]${NC}"
  echo ""

  echo -e "${CYAN}[1/4]${NC} 환경 확인..."
  check_prerequisites
  setup_env
  echo ""

  echo -e "${CYAN}[2/4]${NC} 프로덕션 이미지 빌드..."
  docker compose --profile prod build web
  echo ""

  echo -e "${CYAN}[3/4]${NC} DB + Redis 시작..."
  docker compose up -d db redis

  local retries=0
  while ! docker compose exec db pg_isready -U biblessam > /dev/null 2>&1; do
    retries=$((retries + 1))
    [[ $retries -gt 30 ]] && { echo -e "${RED}DB 시작 실패${NC}"; exit 1; }
    sleep 1
  done
  echo ""

  echo -e "${CYAN}[4/4]${NC} 프로덕션 서버 시작..."
  docker compose --profile prod up -d web
  echo ""

  echo -e "${GREEN}${BOLD}"
  echo "  ╔══════════════════════════════════════╗"
  echo "  ║  프로덕션 서버가 시작되었습니다!      ║"
  echo "  ╚══════════════════════════════════════╝"
  echo -e "${NC}"
  echo -e "  ${CYAN}Web:${NC}  http://localhost:${WEB_PORT:-3000}"
  echo ""
}

stop_all() {
  banner
  echo -e "  ${YELLOW}서비스 중지 중...${NC}"
  echo ""
  docker compose --profile dev --profile prod down
  echo ""
  echo -e "  ${GREEN}모든 서비스가 중지되었습니다.${NC}"
  echo ""
}

show_status() {
  banner
  echo -e "  ${CYAN}서비스 상태:${NC}"
  echo ""
  docker compose --profile dev --profile prod ps
  echo ""
}

case "$MODE" in
  dev)     dev_mode ;;
  prod)    prod_mode ;;
  stop)    stop_all ;;
  status)  show_status ;;
  *)
    echo "사용법: $0 {dev|prod|stop|status}"
    echo ""
    echo "  dev    - 개발 모드 (hot-reload, 기본값)"
    echo "  prod   - 프로덕션 모드 (최적화 빌드)"
    echo "  stop   - 모든 서비스 중지"
    echo "  status - 서비스 상태 확인"
    exit 1
    ;;
esac
