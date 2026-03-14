#!/bin/zsh
#
# BibleSsam - 프로덕션 Docker 실행
#
# 사용법:
#   ./scripts/docker-prod.sh          # 빌드 + 시작
#   ./scripts/docker-prod.sh stop     # 중지
#   ./scripts/docker-prod.sh restart  # 재시작
#   ./scripts/docker-prod.sh logs     # 로그 보기
#   ./scripts/docker-prod.sh status   # 상태 확인
#

set -uo pipefail

ROOT="${0:a:h:h}"
cd "$ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ACTION="${1:-start}"

header() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  BibleSsam Production - $1${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

check_docker() {
  if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Docker가 실행되고 있지 않습니다.${NC}"
    exit 1
  fi
}

start() {
  header "프로덕션 빌드 + 시작"
  check_docker

  echo -e "${GREEN}[1/3]${NC} 프로덕션 이미지 빌드..."
  docker compose --profile prod build web

  echo ""
  echo -e "${GREEN}[2/3]${NC} DB + Redis 시작..."
  docker compose up -d db redis

  # DB 준비 대기
  local retries=0
  while ! docker compose exec db pg_isready -U biblessam > /dev/null 2>&1; do
    retries=$((retries + 1))
    [[ $retries -gt 30 ]] && { echo -e "${RED}DB 시작 실패${NC}"; exit 1; }
    sleep 1
  done

  echo ""
  echo -e "${GREEN}[3/3]${NC} 프로덕션 웹 서버 시작..."
  docker compose --profile prod up -d web

  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "  ${GREEN}프로덕션 서버가 시작되었습니다!${NC}"
  echo ""
  echo -e "  Web:   ${CYAN}http://localhost:${WEB_PORT:-3000}${NC}"
  echo ""
}

stop() {
  header "중지"
  docker compose --profile prod down
  echo -e "${GREEN}중지 완료.${NC}"
  echo ""
}

restart() {
  stop
  start
}

logs() {
  docker compose --profile prod logs -f
}

status() {
  header "상태"
  docker compose --profile prod ps
  echo ""
}

case "$ACTION" in
  start)   start ;;
  stop)    stop ;;
  restart) restart ;;
  logs)    logs ;;
  status)  status ;;
  *)
    echo "사용법: $0 {start|stop|restart|logs|status}"
    exit 1
    ;;
esac
