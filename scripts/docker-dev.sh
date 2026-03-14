#!/bin/zsh
#
# BibleSsam - 개발 환경 Docker 실행
#
# 사용법:
#   ./scripts/docker-dev.sh          # 시작
#   ./scripts/docker-dev.sh stop     # 중지
#   ./scripts/docker-dev.sh restart  # 재시작
#   ./scripts/docker-dev.sh logs     # 로그 보기
#   ./scripts/docker-dev.sh status   # 상태 확인
#   ./scripts/docker-dev.sh clean    # 완전 정리 (볼륨 포함)
#

set -uo pipefail

ROOT="${0:a:h:h}"
cd "$ROOT"

# 색상
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ACTION="${1:-start}"

header() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  BibleSsam Docker - $1${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# Docker 실행 확인
check_docker() {
  if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Docker가 실행되고 있지 않습니다.${NC}"
    echo "Docker Desktop을 먼저 시작해주세요."
    exit 1
  fi
}

# .env 파일 확인
check_env() {
  if [[ ! -f "$ROOT/.env" ]]; then
    echo -e "${YELLOW}.env 파일이 없습니다. 기본값으로 생성합니다...${NC}"
    cp "$ROOT/.env.example" "$ROOT/.env" 2>/dev/null || true
  fi
}

# 개발 모드 시작
start() {
  header "개발 모드 시작"
  check_docker
  check_env

  echo -e "${GREEN}[1/3]${NC} DB + Redis 시작..."
  docker compose up -d db redis

  echo ""
  echo -e "${GREEN}[2/3]${NC} 서비스 준비 대기..."
  # DB healthy 대기
  local retries=0
  while ! docker compose exec db pg_isready -U biblessam > /dev/null 2>&1; do
    retries=$((retries + 1))
    if [[ $retries -gt 30 ]]; then
      echo -e "${RED}DB 시작 실패. 로그를 확인하세요: docker compose logs db${NC}"
      exit 1
    fi
    sleep 1
  done
  echo -e "  DB: ${GREEN}Ready${NC}"

  # Redis healthy 대기
  retries=0
  while ! docker compose exec redis redis-cli ping > /dev/null 2>&1; do
    retries=$((retries + 1))
    if [[ $retries -gt 30 ]]; then
      echo -e "${RED}Redis 시작 실패.${NC}"
      exit 1
    fi
    sleep 1
  done
  echo -e "  Redis: ${GREEN}Ready${NC}"

  echo ""
  echo -e "${GREEN}[3/3]${NC} Next.js 개발 서버 시작..."
  docker compose --profile dev up -d dev

  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "  ${GREEN}개발 서버가 시작되었습니다!${NC}"
  echo ""
  echo -e "  Web:      ${CYAN}http://localhost:${WEB_PORT:-3000}${NC}"
  echo -e "  DB:       ${CYAN}localhost:${DB_PORT:-5432}${NC}"
  echo -e "  Redis:    ${CYAN}localhost:${REDIS_PORT:-6379}${NC}"
  echo ""
  echo -e "  로그 보기:  ${YELLOW}./scripts/docker-dev.sh logs${NC}"
  echo -e "  중지:      ${YELLOW}./scripts/docker-dev.sh stop${NC}"
  echo ""
}

# 중지
stop() {
  header "중지"
  docker compose --profile dev down
  echo -e "${GREEN}모든 서비스가 중지되었습니다.${NC}"
  echo ""
}

# 재시작
restart() {
  stop
  start
}

# 로그
logs() {
  docker compose --profile dev logs -f
}

# 상태
status() {
  header "상태"
  docker compose --profile dev ps
  echo ""
}

# 완전 정리
clean() {
  header "완전 정리"
  echo -e "${YELLOW}모든 컨테이너, 볼륨, 이미지를 삭제합니다.${NC}"
  echo -n "계속하시겠습니까? (y/N): "
  read answer
  if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    docker compose --profile dev --profile prod down -v --rmi local
    echo -e "${GREEN}정리 완료!${NC}"
  else
    echo "취소되었습니다."
  fi
  echo ""
}

# 액션 실행
case "$ACTION" in
  start)   start ;;
  stop)    stop ;;
  restart) restart ;;
  logs)    logs ;;
  status)  status ;;
  clean)   clean ;;
  *)
    echo "사용법: $0 {start|stop|restart|logs|status|clean}"
    exit 1
    ;;
esac
