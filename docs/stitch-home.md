# Stitch 홈 디자인 연동

## Stitch 프로젝트 정보
- **프로젝트 제목**: Bible
- **프로젝트 ID**: `10112272476937199624`
- **Home Screen ID**: `f1e71fdd78b041339281201309fdf4f2`

## MCP 연결 (Cursor)

`~/.cursor/mcp.json`에 Stitch MCP가 추가되어 있습니다.

```json
"stitch": {
  "command": "npx",
  "args": ["-y", "@_davideast/stitch-mcp", "proxy"]
}
```

### 최초 1회 인증
Stitch API 접근을 위해 터미널에서 실행:

```bash
npx @_davideast/stitch-mcp init
```

또는 Stitch 설정에서 발급한 API 키 사용 시:
```bash
export STITCH_API_KEY="your-api-key"
```

### 연결 확인
```bash
npx @_davideast/stitch-mcp doctor --verbose
```

## 스크린/코드 가져오기

MCP 연결 후 Cursor에서 Stitch 도구 사용 가능:
- **get_screen_code** — Home Screen HTML/CSS 코드 다운로드 (projectId, screenId 필요)
- **get_screen_image** — 스크린샷 이미지(base64) 다운로드

호스트 URL이 있으면 로컬 저장:
```bash
curl -L -o home-screen.png "<image-url>"
curl -L -o home-screen.html "<code-url>"
```

## 다음 단계
1. Cursor 재시작 또는 MCP 새로고침 후 Stitch 서버 연결 확인
2. `get_screen_code` / `get_screen_image`로 Home Screen 데이터 획득
3. `flutter_app` 또는 `web` 홈 화면을 Stitch 디자인에 맞게 수정
