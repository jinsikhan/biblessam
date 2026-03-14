# API 배포 후 GitHub Pages에서 데이터 보이게 하기

GitHub Pages 앱(`https://jinsikhan.github.io/biblessam/`)에서 **데이터가 안 나오는** 이유는, 앱이 호출하는 백엔드 API가 없기 때문입니다. 아래 순서대로 하면 됩니다.

## 1. Next.js API 배포 (Vercel 권장)

1. [Vercel](https://vercel.com) 로그인 후 **Add New Project**.
2. GitHub 저장소 `jinsikhan/biblessam` 연결.
3. **Root Directory**를 `web` 으로 지정.
4. **Environment Variables**에 필요한 값 설정 (예: `GEMINI_API_KEY` 등, 루트 `.env` 참고).
5. 배포 후 나온 URL 복사 (예: `https://biblessam-xxxx.vercel.app`).

## 2. GitHub에 API 주소 알려주기

1. 저장소 **Settings** → **Secrets and variables** → **Actions**.
2. **New repository secret** 클릭.
3. Name: `API_BASE_URL`  
   Value: 배포한 API URL (끝에 슬래시 없이, 예: `https://biblessam-xxxx.vercel.app`).

## 3. GitHub Pages 다시 배포

- **Actions** 탭 → **Deploy to GitHub Pages** 워크플로 선택 → **Run workflow** (또는 아무 커밋 푸시).

이후 빌드가 성공하면 `https://jinsikhan.github.io/biblessam/` 에서 같은 API를 쓰므로 데이터가 나와야 합니다.

---

**참고:** Secret을 설정하지 않으면 워크플로 기본값 `https://biblessam-api.vercel.app` 를 사용합니다. Vercel에서 프로젝트 이름을 `biblessam-api` 로 만들어 두면 Secret 없이도 그 주소로 동작합니다.
