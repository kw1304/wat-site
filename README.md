# WAT 소개·설명서 사이트

웅계사의 감사 자동화 도구(WAT)를 소개하고, 도구별 사용설명서를 비전공자도 쉽게 읽도록 만든 정적 사이트입니다.

## 구성

```
WAT_SITE/
├─ index.html          ← 랜딩(도구 소개)
├─ styles.css          ← 공통 디자인(토스 느낌 + WAT 토큰)
├─ render.yaml         ← Render 배포 설정
└─ guide/
   ├─ rcps.html        ← RCPS·DCF 평가 설명서
   ├─ irs.html         ← IRS 평가 설명서
   ├─ jet.html         ← JET 분개테스트 설명서
   ├─ cc.html          ← CC 채권채무조회서 설명서
   ├─ bc.html          ← BC 금융기관조회서 설명서
   └─ accounting.html  ← 회계기준 AI 설명서
```

빌드 과정이 없습니다. 순수 HTML/CSS라 그대로 호스팅하면 됩니다.

## 로컬에서 미리 보기

```powershell
cd WAT_SITE
python -m http.server 8080
# 브라우저에서 http://localhost:8080
```

## Render.com 배포 (가장 쉬운 방법: 대시보드)

1. 이 폴더(`WAT_SITE`)를 GitHub 저장소에 올립니다.
2. Render → **New** → **Static Site** 선택.
3. 저장소 연결 후 설정:
   - **Build Command**: 비워 둠
   - **Publish Directory**: `WAT_SITE` (저장소 루트가 이 폴더면 `.`)
4. **Create Static Site** → 몇 초 뒤 `https://<이름>.onrender.com` 으로 공개됩니다.

### Blueprint(render.yaml)로 배포

저장소 루트에 `render.yaml`이 있으면 Render가 자동 인식합니다.
이 폴더를 저장소 루트로 쓰면 포함된 `render.yaml`이 그대로 동작합니다.

## 커스텀 도메인 연결

1. Render 사이트 → **Settings** → **Custom Domains** → 도메인 입력.
2. 안내되는 CNAME(또는 A) 레코드를 도메인 등록기관 DNS에 추가.
3. 검증되면 HTTPS 인증서가 자동 발급됩니다.

## 도구 실행 링크에 대해

각 "도구 열기" 버튼은 현재 `https://wat.taild5874c.ts.net/` (Tailscale 사설망)을 가리킵니다.
- 이 사이트는 **누구나 볼 수 있는 소개·설명서**입니다.
- 실제 도구 실행은 사설망 접근 권한이 있어야 동작합니다.
- 도구를 공개로 열려면, 공개 URL로 바꾼 뒤 각 HTML의 `wat.taild5874c.ts.net` 주소만 교체하면 됩니다.

## 내용 수정

- 문구·설명: 각 `*.html`의 본문 텍스트만 고치면 됩니다.
- 색·여백·카드 모양: `styles.css`의 `:root` 변수와 컴포넌트 규칙.

## 새 도구 추가 (자동)

새 툴이 생기면 **스펙 JSON 하나**만 채워 스크립트를 돌리면, 랜딩 카드 + 설명서 + 상호 링크가 한 번에 추가되고 푸시됩니다.

```powershell
cd c:\wat-site
# 1) 예시를 복사해 내용 채우기
Copy-Item _tool-spec.example.json mytool.json   # → 편집
# 2) 생성 + (선택)배포
powershell -ExecutionPolicy Bypass -File .\add-tool.ps1 -Spec .\mytool.json          # 미리보기
powershell -ExecutionPolicy Bypass -File .\add-tool.ps1 -Spec .\mytool.json -Push     # 생성+커밋+푸시
```

스크립트가 하는 일:
1. `guide/_template.html` → `guide/<slug>.html` 생성 (스펙 치환)
2. `index.html`의 `<!-- CARD-INSERT:분류 -->` 위치에 카드 삽입 (분류=valuation·audit·reference)
3. 모든 가이드의 `more-tools`(상호 링크) 재동기화
4. `-Push` 시 git commit + push → Render 자동 재배포

스펙 필드 설명은 `_tool-spec.example.json` 참고. 아이콘은 분류 머리글자(V·A·R)로 자동 통일됩니다.

> 참고: `add-tool.ps1`은 한글 때문에 **UTF-8 BOM**으로 저장돼 있어야 Windows PowerShell 5.1에서 깨지지 않습니다.

© 2026 Woongcpa
