# Claude 실무자 가이드 (CLI · 스킬 · 플러그인 · SDK · Cowork)

> 작성일: 2026-09-22 / 기준: 공식 문서(code.claude.com/docs, platform.claude.com/docs, support.claude.com)
>
> Claude Code는 릴리스 주기가 빠릅니다. 이 문서는 스냅샷이며, 플래그·설정 키가 동작하지 않으면 `claude --help`, `/help`, `claude doctor`로 현재 버전 기준을 먼저 확인하세요.

## 목차

1. [설치와 진단](#1-설치와-진단)
2. [실행 모드와 CLI 플래그](#2-실행-모드와-cli-플래그)
3. [슬래시 명령어](#3-슬래시-명령어)
4. [키보드 단축키 / TUI](#4-키보드-단축키--tui)
5. [CLAUDE.md 메모리 시스템](#5-claudemd-메모리-시스템)
6. [settings.json](#6-settingsjson)
7. [권한 시스템](#7-권한-시스템)
8. [커스텀 슬래시 명령어](#8-커스텀-슬래시-명령어)
9. [서브에이전트](#9-서브에이전트)
10. [훅(Hooks)](#10-훅hooks)
11. [MCP](#11-mcp-model-context-protocol)
12. [스킬(Agent Skills)](#12-스킬agent-skills)
13. [플러그인과 마켓플레이스](#13-플러그인과-마켓플레이스)
14. [IDE · CI/CD 통합](#14-ide--cicd-통합)
15. [Claude Agent SDK](#15-claude-agent-sdk)
16. [Claude API 실무 팁](#16-claude-api-실무-팁)
17. [Cowork · 데스크톱 앱](#17-cowork--데스크톱-앱)
18. [컨텍스트·비용 최적화 플레이북](#18-컨텍스트비용-최적화-플레이북)
19. [트러블슈팅 체크리스트](#19-트러블슈팅-체크리스트)
20. [참고 링크](#20-참고-링크)

---

## 1. 설치와 진단

### 네이티브 인스톨러 (권장)

```bash
# macOS / Linux / WSL
curl -fsSL https://claude.ai/install.sh | bash

# Windows PowerShell
irm https://claude.ai/install.ps1 | iex
```

### 패키지 관리자

```bash
brew install --cask claude-code        # macOS
winget install Anthropic.ClaudeCode    # Windows
sudo apt install claude-code           # Debian/Ubuntu
sudo dnf install claude-code           # Fedora/RHEL
npm install -g @anthropic-ai/claude-code   # Node.js 22+ 필요
```

### 지원 플랫폼

| OS | 최소 버전 | 아키텍처 |
|---|---|---|
| macOS | 13.0+ | x64, ARM64 |
| Windows | 10 1809+, Server 2019+ | x64, ARM64 |
| Ubuntu | 20.04+ | x64, ARM64 |
| Debian | 10+ | x64, ARM64 |
| Alpine | 3.19+ | x64, ARM64 |

### 검증 · 업데이트 · 마이그레이션

```bash
claude --version
claude doctor                # 설치/설정/성능 진단 — 문제 생기면 제일 먼저
claude update                # 수동 업데이트
claude migrate-installer     # npm/Homebrew 설치 → 네이티브로 이전
```

자동 업데이트 제어 (`~/.claude/settings.json`):

```json
{
  "autoUpdatesChannel": "stable",
  "env": { "DISABLE_AUTOUPDATER": "1" }
}
```

> **팁** — 팀 단위로 버전을 고정하려면 관리 설정(managed settings)에서 최소 버전을 강제하는 편이 개별 `DISABLE_AUTOUPDATER`보다 안전합니다.

---

## 2. 실행 모드와 CLI 플래그

### 기본 실행

```bash
claude                          # 대화형 세션
claude "리팩터링 계획 세워줘"    # 초기 프롬프트와 함께 시작
claude -p "이 로그 요약해"       # print(headless) 모드: 응답 출력 후 종료
claude -c                       # 최근 대화 이어가기
claude -r <session-id> "계속"   # 특정 세션 재개
```

### 파이프 입력 (스크립트 조합의 핵심)

```bash
cat error.log | claude -p "이 로그에서 근본 원인 3개 뽑아"
git diff | claude -p "이 diff의 리스크를 표로 정리"
claude -p "커밋 메시지 초안" --output-format json | jq -r '.result'
```

### 주요 플래그

**모델/추론**

| 플래그 | 설명 |
|---|---|
| `--model <name>` | 모델 지정 (`opus`, `sonnet`, `haiku` 또는 전체 ID) |
| `--effort <level>` | 추론 강도: `low`/`medium`/`high`/`xhigh`/`max` |
| `--fallback-model a,b` | 폴백 체인 |

**권한/보안**

| 플래그 | 설명 |
|---|---|
| `--permission-mode <mode>` | `default` / `acceptEdits` / `plan` / `bypassPermissions` |
| `--allowedTools "Bash,Read,Edit"` | 허용 도구 화이트리스트 |
| `--disallowedTools "WebFetch"` | 거부 도구 |
| `--dangerously-skip-permissions` | 모든 확인 생략 — **격리된 컨테이너/CI에서만** |

**파일/설정**

| 플래그 | 설명 |
|---|---|
| `--add-dir ../lib ../shared` | 작업 디렉터리 추가 (모노레포 필수) |
| `--settings ./ci-settings.json` | 이 세션용 설정 파일 |
| `--mcp-config ./mcp.json` | MCP 구성 파일 지정 |
| `--plugin-dir ./my-plugin` | 로컬 플러그인 로드 (개발 중 테스트) |

**출력/자동화**

| 플래그 | 설명 |
|---|---|
| `--output-format text\|json\|stream-json` | 출력 형식 |
| `--verbose` | 상세 로그 |
| `--max-turns N` | 에이전트 턴 상한 |
| `--append-system-prompt "..."` | 시스템 프롬프트 끝에 추가 |
| `--debug[=mcp,startup,hooks]` | 디버그 카테고리 필터 |

**인증**

```bash
claude setup-token      # CI/스크립트용 장기 OAuth 토큰 발급
```

> **실전 패턴** — CI에서는 `claude -p`, `--max-turns`, `--allowedTools`, `--output-format json`을 항상 함께 씁니다. 턴 상한과 도구 화이트리스트가 없으면 예산과 사이드이펙트가 통제 불가능해집니다.

---

## 3. 슬래시 명령어

### 세션 제어

| 명령 | 용도 |
|---|---|
| `/help` | 도움말 |
| `/clear` | 컨텍스트 초기화(새 세션) |
| `/compact` | 대화 요약 압축 |
| `/context` | 현재 컨텍스트 구성/점유량 확인 |
| `/resume` | 이전 세션 재개 |
| `/rewind` | 체크포인트로 되돌리기 |
| `/memory` | CLAUDE.md 등 메모리 파일 열기/편집 |

### 설정

| 명령 | 용도 |
|---|---|
| `/config` | 설정 패널 |
| `/model` | 모델 전환 |
| `/permissions` | 권한 규칙 관리 |
| `/hooks` | 등록된 훅 확인 |

### 도구/확장

| 명령 | 용도 |
|---|---|
| `/mcp` | MCP 서버 상태·인증 |
| `/plugin` | 플러그인·마켓플레이스 관리 |
| `/agents` | 서브에이전트 관리 |

### 정보

| 명령 | 용도 |
|---|---|
| `/cost` | 이번 세션 토큰·비용 |
| `/usage` | 사용량 통계 |
| `/status` | 세션 상태 |

### 유틸리티

| 명령 | 용도 |
|---|---|
| `/init` | 저장소 분석 후 CLAUDE.md 생성 |
| `/export` | 대화 내보내기 |
| `/doctor` | 진단 |
| `/vim` | Vim 편집 모드 토글 |
| `/terminal-setup` | 터미널 키 바인딩 설정 |
| `/install-github-app` | GitHub Actions 연동 설치 |

### 네임스페이스

```
/my-command                 # .claude/commands/my-command.md
/plugin-name:skill-name     # 플러그인이 제공하는 스킬
/mcp-server:prompt-name     # MCP 서버가 노출한 프롬프트
```

---

## 4. 키보드 단축키 / TUI

### 필수 6개

| 키 | 동작 |
|---|---|
| `Esc` | Claude 작업 중단 |
| `Esc` `Esc` | 이전 메시지로 되감기(체크포인트 메뉴) |
| `Shift+Tab` | 권한 모드 순환 (default → acceptEdits → plan → …) |
| `Ctrl+O` | 트랜스크립트 뷰어(도구 호출 상세) 토글 |
| `Ctrl+R` | 명령 히스토리 역방향 검색 |
| `Ctrl+C` ×2 / `Ctrl+D` | 종료 |

### 입력 프리픽스

| 입력 | 의미 |
|---|---|
| `/` | 슬래시 명령·스킬 |
| `!` | 셸 모드 — 명령을 직접 실행하고 결과를 컨텍스트에 넣음 |
| `@` | 파일 경로 자동완성·참조 |
| `#` | 메모리에 바로 추가 (CLAUDE.md 갱신) |

### 텍스트 편집 (readline)

`Ctrl+A/E` 줄 시작·끝, `Ctrl+K/U` 뒤·앞 삭제, `Ctrl+W` 단어 삭제, `Alt+B/F` 단어 이동.

### 멀티라인 입력

| 방법 | 환경 |
|---|---|
| `\` + `Enter` | 모든 터미널 |
| `Shift+Enter` | iTerm2, WezTerm, Kitty, Warp (`/terminal-setup` 후) |
| `Ctrl+J` | 모든 터미널 |

### 이미지

`Ctrl+V` / `Cmd+V`로 클립보드 이미지를 그대로 붙여넣기 — 스크린샷 기반 디버깅에 유용.

---

## 5. CLAUDE.md 메모리 시스템

### 계층과 경로

| 범위 | 경로 | 공유 대상 |
|---|---|---|
| 관리 정책 | macOS `/Library/Application Support/ClaudeCode/CLAUDE.md`<br>Linux `/etc/claude-code/CLAUDE.md`<br>Windows `C:\Program Files\ClaudeCode\CLAUDE.md` | 조직 전체 |
| 사용자 | `~/.claude/CLAUDE.md` | 내 모든 프로젝트 |
| 프로젝트 | `./CLAUDE.md` 또는 `./.claude/CLAUDE.md` | 팀 (git 커밋) |
| 로컬 | `./CLAUDE.local.md` | 나만 (.gitignore) |

상위 디렉터리부터 현재 디렉터리까지 순차 로드되며, 하위 디렉터리의 CLAUDE.md는 해당 경로 작업 시 추가 로드됩니다.

### @import

```markdown
## 빌드 절차
@docs/build.md

## API 규약
@docs/api-design.md
```

- 상대 경로 기준, 재귀 임포트 최대 4단계
- 코드 블록·백틱 안의 `@`는 무시됨

### 경로별 규칙 (`.claude/rules/`)

```markdown
---
paths:
  - "src/**/*.{ts,tsx}"
---

# 프론트엔드 규칙
- 클래스 컴포넌트 금지, 함수형 + hooks
- 스타일은 CSS Modules
```

해당 글롭에 매칭되는 파일을 다룰 때만 로드되므로, 큰 저장소에서 CLAUDE.md를 가볍게 유지하는 핵심 수단입니다.

### 작성 베스트 프랙티스

- **200줄 이하**를 목표로. 매 요청마다 전부 로드됩니다.
- 추상적 미덕("깨끗한 코드") ❌ → 검증 가능한 명령("커밋 전 `npm run lint && npm test`") ✅
- **명령어**를 최우선으로 적으세요. Claude가 가장 자주 틀리는 건 빌드/테스트/실행 방법입니다.
- 금지 사항은 명시적으로: "main 직접 push 금지, PR 필수"
- `/init`으로 초안을 만든 뒤 사람이 잘라내는 방식이 가장 빠릅니다.
- 세션 중 `#`로 즉시 추가 → 나중에 정리.

**좋은 CLAUDE.md 골격**

```markdown
# <프로젝트명>

## 명령어
- 설치: `pnpm i`
- 개발: `pnpm dev` (http://localhost:3000)
- 테스트: `pnpm test` / 단일: `pnpm test -- path/to/spec`
- 빌드: `pnpm build`
- 린트: `pnpm lint --fix`

## 구조
- `src/api/` 라우트 핸들러 / `src/lib/` 순수 유틸 / `src/db/` Drizzle 스키마

## 규칙
- TypeScript strict. `any` 금지 (`unknown` + 좁히기)
- DB 변경은 반드시 마이그레이션 파일 동반
- 커밋 전 `pnpm lint && pnpm test`

## 하지 말 것
- `package-lock.json` 수동 수정
- `.env` 커밋
```

---

## 6. settings.json

### 파일 계층 (뒤가 우선, 단 관리 정책은 덮어쓸 수 없음)

| 계층 | 경로 |
|---|---|
| 관리 정책 | 조직 관리 경로 (`managed-settings.json`) |
| 사용자 | `~/.claude/settings.json` |
| 프로젝트 | `.claude/settings.json` (git 공유) |
| 로컬 | `.claude/settings.local.json` (gitignore) |
| CLI | `--settings file.json` |

### 자주 쓰는 키

```json
{
  "model": "claude-opus-4-8",
  "includeCoAuthoredBy": false,
  "cleanupPeriodDays": 30,

  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Bash(npm run *)",
      "Bash(git status)",
      "Bash(git diff *)",
      "Read(src/**)"
    ],
    "ask": ["Bash(git push *)"],
    "deny": ["Bash(rm -rf *)", "Read(.env)"],
    "additionalDirectories": ["../shared-lib"]
  },

  "env": {
    "NODE_ENV": "development",
    "MCP_TIMEOUT": "10000"
  },

  "hooks": { },

  "enableAllProjectMcpServers": false,
  "apiKeyHelper": "/opt/bin/get-api-key.sh"
}
```

### 팀 운영 패턴

- `.claude/settings.json` → **팀 공통 규칙**(allow/deny, 훅, 플러그인)을 커밋
- `.claude/settings.local.json` → **개인 편의**(모델 선호, 추가 allow)를 gitignore
- `managed-settings.json` → **조직 강제**(deny 목록, bypassPermissions 금지). 하위 계층이 덮어쓸 수 없음

---

## 7. 권한 시스템

### 권한 모드

| 모드 | 동작 | 언제 |
|---|---|---|
| `default` | 도구 첫 사용마다 확인 | 기본, 낯선 저장소 |
| `acceptEdits` | 파일 편집은 자동 승인, 나머지는 확인 | 익숙한 저장소에서 일상 작업 |
| `plan` | 읽기/탐색만, 편집 불가 | 조사·설계 단계 (비용도 절약) |
| `bypassPermissions` | 모든 확인 생략 | **격리 컨테이너/CI 전용** |

`Shift+Tab`으로 순환, `/permissions`로 세부 규칙 편집.

### 규칙 문법

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run *)",          // npm run build, npm run test ...
      "Bash(git log *)",
      "Read(src/**/*.ts)",
      "Edit(src/**)",
      "WebFetch(domain:github.com)",
      "mcp__github__*"            // 특정 MCP 서버 전체 도구
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(curl *)",
      "Edit(.git/**)",
      "Read(**/.env)"
    ]
  }
}
```

### 평가 우선순위

```
deny  >  ask  >  allow
```

`allow: ["Bash(npm *)"]`가 있어도 `deny: ["Bash(npm publish *)"]`가 이깁니다.

### 알아둘 동작

- **복합 명령 분해**: `a && b | c`는 각 서브명령이 개별 검사됩니다.
- **리다이렉션 검사**: `npm test > out.log`의 `out.log`는 Edit 규칙으로 검사됩니다.
- **읽기 전용 명령 자동 허용**: `ls`, `cat`, `grep`, `git status`, `git log` 등.
- **보호 경로**: `.git/**`, `.claude/settings*` 등은 모드와 무관하게 보호됩니다.

> **권장 시작점** — 처음 며칠은 `default`로 두고, 반복해서 승인하게 되는 명령만 `allow`에 하나씩 추가하세요. 처음부터 넓은 `allow`를 쓰면 무엇이 실행되는지 감을 잃습니다. `deny`에는 `rm -rf`, `git push --force`, 시크릿 파일 읽기를 먼저 넣어두세요.

---

## 8. 커스텀 슬래시 명령어

### 구조

```
.claude/commands/
├── review.md          →  /review
├── deploy.md          →  /deploy
└── db/
    └── migrate.md     →  /db:migrate
```

### Frontmatter

```markdown
---
description: "변경분 코드 리뷰"
argument-hint: "[파일 경로]"
allowed-tools: Read, Grep, Glob, Bash(git diff *)
model: sonnet
---
```

| 필드 | 용도 |
|---|---|
| `description` | `/help`에 표시 + Claude의 자동 호출 판단 근거 |
| `argument-hint` | 입력 힌트 |
| `allowed-tools` | 이 명령 실행 중 허용 도구 |
| `model` | 명령 전용 모델 |
| `disable-model-invocation` | `true`면 사용자 입력으로만 실행 |

### 본문 문법

| 문법 | 의미 |
|---|---|
| `$ARGUMENTS` | 인수 전체 |
| `$1`, `$2` | 개별 인수 |
| `!`명령 | 셸 실행 후 결과를 컨텍스트에 삽입 |
| `@경로` | 파일 내용 삽입 |

### 실전 예시

```markdown
---
description: "현재 브랜치 변경분을 리뷰"
allowed-tools: Read, Grep, Bash(git diff *), Bash(git log *)
---

## 변경 내역

!`git diff origin/main...HEAD`

## 프로젝트 규약

@.claude/CLAUDE.md

위 diff를 다음 기준으로 리뷰하세요. 추측성 지적은 제외하고,
재현 시나리오를 쓸 수 있는 문제만 보고하세요.

1. 정확성 버그 (경계값, null, 동시성)
2. 프로젝트 규약 위반
3. 테스트 누락

각 항목은 `파일:줄 — 문제 — 재현 조건` 형식으로.
```

> **팁** — 좋은 커스텀 명령의 핵심은 프롬프트가 아니라 **`!`로 주입하는 컨텍스트**입니다. diff, 테스트 출력, 로그를 자동으로 끌어오면 매번 붙여넣을 필요가 없어집니다.

---

## 9. 서브에이전트

별도 컨텍스트에서 실행되는 전문 에이전트. 메인 대화의 컨텍스트를 오염시키지 않고 탐색·검증을 위임할 때 씁니다.

### 정의 파일

`.claude/agents/<name>.md` (프로젝트) 또는 `~/.claude/agents/` (개인)

```markdown
---
name: test-verifier
description: 변경 후 테스트를 실행하고 실패 원인을 정리한다. 코드 수정이 끝난 뒤 검증이 필요할 때 사용.
tools: Read, Grep, Glob, Bash
model: sonnet
---

당신은 테스트 검증 담당입니다.

1. 변경된 파일과 관련된 테스트를 찾습니다.
2. 테스트를 실행합니다.
3. 실패가 있으면 실패 메시지, 원인 가설, 최소 수정안을 보고합니다.
4. 코드를 직접 수정하지 마세요. 보고만 합니다.
```

| 필드 | 설명 |
|---|---|
| `name` | 소문자-하이픈 |
| `description` | **Claude가 위임 여부를 판단하는 근거** — 가장 중요 |
| `tools` | 허용 도구 (생략 시 상속) |
| `model` | `opus` / `sonnet` / `haiku` |

### 호출

```
test-verifier 에이전트로 지금 변경분 검증해줘
```

또는 `/agents`에서 생성·관리.

### 언제 쓸 만한가

- **탐색**: "이 기능이 어디에 구현돼 있나" — 파일 수십 개를 읽어도 메인 컨텍스트에는 결론만 남음
- **검증**: 구현과 리뷰를 분리해 자기검증 편향을 줄임
- **병렬화**: 독립적인 조사 3건을 한 번에 던짐

> 서브에이전트는 대화 히스토리를 물려받지 않습니다. 필요한 맥락은 프롬프트에 명시적으로 전달해야 합니다.

---

## 10. 훅(Hooks)

Claude의 생명주기 특정 시점에 **결정론적으로** 셸 명령을 실행합니다. "매번 프롬프트로 부탁하는 규칙"을 코드로 강제할 때 씁니다.

### 이벤트

| 이벤트 | 시점 | 차단 가능 |
|---|---|---|
| `SessionStart` | 세션 시작/재개 | ✗ |
| `UserPromptSubmit` | 프롬프트 제출 직전 | ✓ |
| `PreToolUse` | 도구 실행 직전 | ✓ |
| `PostToolUse` | 도구 성공 직후 | ✗ |
| `Notification` | 알림 발생 | ✗ |
| `Stop` | 응답 완료 | ✗ |
| `SubagentStop` | 서브에이전트 완료 | ✗ |
| `PreCompact` | 컨텍스트 압축 직전 | ✗ |
| `SessionEnd` | 세션 종료 | ✗ |

### 설정

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/format.sh", "timeout": 30 }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/guard.sh" }
        ]
      }
    ]
  }
}
```

`matcher`는 도구 이름 정규식: `Bash`, `Edit|Write`, `mcp__github__.*`, `*`(전체).

### 훅 스크립트 규약

stdin으로 JSON을 받습니다:

```json
{
  "session_id": "abc123",
  "cwd": "/home/user/project",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": { "command": "rm -rf build" }
}
```

**Exit code**

| 코드 | 의미 |
|---|---|
| `0` | 정상. stdout의 JSON이 있으면 해석 |
| `2` | 차단 — stderr 내용이 Claude에게 전달됨 |
| 기타 | 오류(비차단), stderr는 사용자에게 표시 |

**차단 예시**

```bash
#!/usr/bin/env bash
cmd=$(jq -r '.tool_input.command // ""')
if grep -qE 'rm -rf|git push --force' <<<"$cmd"; then
  echo "정책 위반: 파괴적 명령은 금지" >&2
  exit 2
fi
exit 0
```

**포맷터 예시 (PostToolUse)**

```bash
#!/usr/bin/env bash
file=$(jq -r '.tool_input.file_path // ""')
case "$file" in
  *.ts|*.tsx|*.js) npx prettier --write "$file" >/dev/null 2>&1 ;;
  *.py) ruff format "$file" >/dev/null 2>&1 ;;
esac
exit 0
```

### 경로 변수

`${CLAUDE_PROJECT_DIR}`, `${CLAUDE_PLUGIN_ROOT}`

> **경고** — 훅은 사용자 권한으로 임의 명령을 실행합니다. 저장소에서 받은 훅 설정은 반드시 읽고 실행하세요. `/hooks`로 현재 등록된 훅을 전부 확인할 수 있습니다.

---

## 11. MCP (Model Context Protocol)

외부 도구·데이터 소스를 Claude에 연결하는 표준.

### 서버 추가

```bash
# HTTP (원격 SaaS)
claude mcp add --transport http notion https://mcp.notion.com/mcp

# 헤더 인증
claude mcp add --transport http github https://api.githubcopilot.com/mcp/ \
  --header "Authorization: Bearer $GITHUB_PAT"

# stdio (로컬 프로세스)
claude mcp add --transport stdio filesystem -- npx -y @modelcontextprotocol/server-filesystem ~/docs

# 프로젝트 스코프 (.mcp.json에 기록 → git 공유)
claude mcp add --scope project --transport http shared https://example.com/mcp
```

### 스코프

| 스코프 | 저장 위치 | 공유 |
|---|---|---|
| `local` (기본) | 사용자 설정, 해당 프로젝트 한정 | 나만 |
| `project` | `.mcp.json` | 팀 (git) |
| `user` | 사용자 설정 | 내 모든 프로젝트 |

### 관리

```bash
claude mcp list            # 목록 + 연결 상태
claude mcp get <name>      # 상세
claude mcp remove <name>
claude mcp serve           # Claude Code 자체를 MCP 서버로 노출
```

세션 안에서는 `/mcp`로 상태 확인과 OAuth 로그인을 합니다.

### .mcp.json 예시

```json
{
  "mcpServers": {
    "postgres": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": { "DATABASE_URL": "${DATABASE_URL}" }
    },
    "sentry": {
      "type": "http",
      "url": "https://mcp.sentry.dev/mcp"
    }
  }
}
```

환경변수 확장 `${VAR}`, 기본값 `${VAR:-default}`를 지원하므로 **시크릿을 파일에 직접 쓰지 마세요.**

### 리소스·프롬프트 사용

```
@server-name:resource-uri     # MCP 리소스를 컨텍스트에 첨부
/server-name:prompt-name      # MCP 서버가 제공하는 프롬프트 실행
```

### 튜닝

```bash
MCP_TIMEOUT=10000 claude
MAX_MCP_OUTPUT_TOKENS=50000 claude
```

> **비용 주의** — MCP 서버를 붙이면 도구 정의가 매 요청 컨텍스트에 들어갑니다. 서버 10개를 항상 켜두면 시작 컨텍스트만으로 수만 토큰이 소모됩니다. `/context`로 점유량을 확인하고, 쓰지 않는 서버는 프로젝트 스코프에서 빼세요.

---

## 12. 스킬(Agent Skills)

### 개념

스킬은 **절차적 지식을 담은 폴더**입니다. 핵심은 점진적 공개(progressive disclosure):

1. 세션 시작 시 모든 스킬의 `name` + `description`만 로드 (스킬당 수십~백 토큰)
2. 요청과 매칭되면 해당 `SKILL.md` 본문을 로드
3. `references/`, `scripts/`는 Claude가 필요할 때만 읽음

덕분에 스킬 50개를 설치해도 평소 컨텍스트 비용은 거의 없습니다.

### 디렉터리 구조

```
my-skill/
├── SKILL.md            # 필수. 핵심 절차
├── references/         # 상세 문서 (필요 시 로드)
│   └── patterns.md
├── scripts/            # 실행 가능한 도구
│   └── validate.sh
└── assets/             # 템플릿, 데이터 (컨텍스트 미로드)
```

### 설치 위치

| 위치 | 범위 |
|---|---|
| `~/.claude/skills/<name>/` | 내 모든 프로젝트 |
| `.claude/skills/<name>/` | 이 저장소 |
| 플러그인의 `skills/` | 플러그인 활성화 시 |

### SKILL.md

```markdown
---
name: api-contract-review
description: OpenAPI/GraphQL 스키마 변경의 하위호환성을 검토할 때 사용. "API 스펙 리뷰", "breaking change 확인", "스키마 변경 검토" 요청에 트리거.
allowed-tools: Read, Grep, Glob, Bash(git diff *)
---

# API 계약 리뷰

## 절차

1. `git diff`로 스키마 변경분을 수집한다.
2. 아래 breaking change 목록과 대조한다.
3. 각 위반에 대해 마이그레이션 경로를 제시한다.

## Breaking change 판정 기준

- 필수 필드 추가 (요청 스키마)
- 필드 삭제 또는 타입 변경
- enum 값 삭제
- 기본값 변경으로 동작이 달라지는 경우

상세 판정표는 `references/breaking-changes.md` 참조.

## 출력 형식

| 변경 | 호환성 | 영향 | 마이그레이션 |
```

### description 작성법 — 스킬 품질의 90%

`description`은 Claude가 **이 스킬을 쓸지 말지 판단하는 유일한 근거**입니다.

❌ `"API 관련 도움을 제공합니다"` — 언제 써야 할지 알 수 없음
❌ `"스키마 검토 스킬"` — 트리거 표현 없음
✅ `"OpenAPI/GraphQL 스키마 변경의 하위호환성을 검토할 때 사용. 'API 스펙 리뷰', 'breaking change 확인' 요청에 트리거."`

공식: **[무엇을 하는가] + [언제 쓰는가] + [사용자가 실제로 쓸 법한 표현들]**

### 본문 작성 원칙

- **명령형으로**: "~할 수 있습니다" ❌ → "~한다" / "~하세요" ✅
- **SKILL.md는 1,500~2,000단어 이내**. 넘치면 `references/`로 분리
- **판정 기준을 표로**. 산문보다 표가 훨씬 안정적으로 지켜집니다
- **출력 형식을 명시**. 형식을 안 정하면 매번 다르게 나옵니다
- 결정론적으로 처리할 수 있는 건 산문 대신 `scripts/`의 스크립트로

### 안티패턴

- 하나의 스킬에 서로 다른 작업 5가지를 욱여넣기 → 트리거 정확도 붕괴
- 모델이 이미 아는 일반 지식을 장황하게 재설명 → 토큰만 소모
- 특정 경로/환경 하드코딩 → 다른 저장소에서 깨짐
- `description`을 나중에 대충 쓰기 → 스킬이 아예 호출되지 않음

### 품질 도구

```bash
claude plugin eval ./my-plugin           # 스킬 포함 플러그인 평가 실행
claude plugin validate ./my-plugin       # 구조 검증
```

세션에서는 `/skill-doctor`로 스킬별 컨텍스트 비용·사용 빈도를, `skill-creator` 스킬로 생성·개선을 진행할 수 있습니다.

---

## 13. 플러그인과 마켓플레이스

플러그인 = 스킬 + 슬래시 명령 + 서브에이전트 + 훅 + MCP 서버를 한 번에 묶은 배포 단위.

### 구조

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json       # 필수
├── skills/
├── commands/
├── agents/
├── hooks/
│   └── hooks.json
└── .mcp.json
```

### plugin.json

```json
{
  "name": "team-standards",
  "description": "우리 팀 코딩 표준과 리뷰 자동화",
  "version": "1.2.0",
  "author": { "name": "Platform Team", "email": "platform@example.com" },
  "license": "MIT",
  "homepage": "https://github.com/acme/claude-plugins",
  "keywords": ["review", "standards"]
}
```

`skills/`, `commands/`, `agents/` 등 관례 디렉터리는 자동 탐색됩니다.

### 마켓플레이스

`.claude-plugin/marketplace.json`:

```json
{
  "name": "acme-tools",
  "owner": { "name": "Platform Team" },
  "plugins": [
    { "name": "team-standards", "source": "./plugins/team-standards" },
    { "name": "deploy-kit", "source": { "source": "github", "repo": "acme/deploy-kit" } }
  ]
}
```

### 사용

```
/plugin marketplace add acme/claude-plugins
/plugin install team-standards@acme-tools
/plugin list
```

로컬 개발 중에는:

```bash
claude --plugin-dir ./my-plugin
```

### 팀 배포

`.claude/settings.json`에 커밋해두면 팀원이 저장소를 열 때 함께 적용됩니다:

```json
{
  "extraKnownMarketplaces": {
    "acme-tools": { "source": { "source": "github", "repo": "acme/claude-plugins" } }
  },
  "enabledPlugins": { "team-standards@acme-tools": true }
}
```

> **보안** — 플러그인은 훅과 로컬 MCP 서버를 포함할 수 있고, 이는 임의 코드 실행을 의미합니다. 신뢰하는 출처만 설치하고, 설치 전 `hooks/`와 `.mcp.json`을 직접 확인하세요.

---

## 14. IDE · CI/CD 통합

### VS Code / JetBrains

마켓플레이스에서 Claude 확장 설치. 터미널의 Claude Code 세션과 연동되어 diff 뷰, 선택 영역 컨텍스트 전달이 가능합니다.

### GitHub Actions

세션에서 `/install-github-app` 실행 → App 설치, 시크릿 등록, 워크플로 PR 생성까지 자동.

수동 설정:

```yaml
name: Claude
on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]

jobs:
  claude:
    if: contains(github.event.comment.body, '@claude')
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
      issues: write
      id-token: write
    steps:
      - uses: actions/checkout@v4
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

이후 이슈·PR 코멘트에서 `@claude 이 버그 원인 찾아줘`로 호출합니다.

### 임의의 CI (GitLab, Jenkins 등)

```bash
claude setup-token   # 로컬에서 1회, 결과를 CI 시크릿에 저장
```

```yaml
review:
  script:
    - claude -p "$(git diff origin/main...HEAD) 위 diff를 리뷰해"
        --max-turns 5
        --allowedTools "Read,Grep,Glob"
        --output-format json > review.json
```

> **CI 원칙** — `--max-turns`, `--allowedTools`(읽기 전용), 그리고 예산 상한을 항상 함께 지정하세요. 쓰기 권한이 필요한 작업은 별도 잡으로 분리합니다.

---

## 15. Claude Agent SDK

Claude Code의 에이전트 루프를 내 애플리케이션에 내장할 때 사용합니다.

### 설치

```bash
npm install @anthropic-ai/claude-agent-sdk    # TypeScript
pip install claude-agent-sdk                  # Python 3.10+
export ANTHROPIC_API_KEY=sk-ant-...
```

### TypeScript 최소 예제

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const message of query({
  prompt: "이 저장소의 테스트 커버리지 공백을 찾아줘",
  options: {
    allowedTools: ["Read", "Grep", "Glob", "Bash"],
    permissionMode: "plan",
    maxTurns: 10,
    cwd: "/path/to/repo",
  },
})) {
  if (message.type === "result") console.log(message.result);
}
```

### Python 최소 예제

```python
import asyncio
from claude_agent_sdk import query, ClaudeAgentOptions

async def main():
    async for message in query(
        prompt="이 저장소의 테스트 커버리지 공백을 찾아줘",
        options=ClaudeAgentOptions(
            allowed_tools=["Read", "Grep", "Glob", "Bash"],
            permission_mode="plan",
            max_turns=10,
            cwd="/path/to/repo",
        ),
    ):
        if hasattr(message, "result"):
            print(message.result)

asyncio.run(main())
```

### 주요 옵션

| 옵션 (TS / Py) | 용도 |
|---|---|
| `systemPrompt` / `system_prompt` | 시스템 프롬프트 |
| `allowedTools` / `allowed_tools` | 도구 화이트리스트 |
| `permissionMode` / `permission_mode` | 권한 모드 |
| `maxTurns` / `max_turns` | 턴 상한 |
| `mcpServers` / `mcp_servers` | MCP 서버 연결 |
| `hooks` | 생명주기 훅 |
| `cwd` | 작업 디렉터리 |

### 커스텀 도구 (인프로세스 MCP)

```typescript
import { tool, createSdkMcpServer } from "@anthropic-ai/claude-agent-sdk";
import { z } from "zod";

const lookupOrder = tool(
  "lookup_order",
  "주문 ID로 주문 상태를 조회한다",
  { orderId: z.string().describe("주문 ID") },
  async ({ orderId }) => ({
    content: [{ type: "text", text: await db.getOrder(orderId) }],
  })
);

const myTools = createSdkMcpServer({ name: "orders", tools: [lookupOrder] });
```

```python
from claude_agent_sdk import tool, create_sdk_mcp_server

@tool("lookup_order", "주문 ID로 주문 상태를 조회한다", {"order_id": "주문 ID"})
async def lookup_order(args):
    result = await db.get_order(args["order_id"])
    return {"content": [{"type": "text", "text": result}]}

my_tools = create_sdk_mcp_server(name="orders", tools=[lookup_order])
```

---

## 16. Claude API 실무 팁

### 기본 호출

```python
from anthropic import Anthropic
client = Anthropic()

resp = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    system="당신은 간결한 기술 리뷰어입니다.",
    messages=[{"role": "user", "content": "이 설계의 실패 지점은?"}],
)
print(resp.content[0].text)
```

Messages API는 **상태가 없습니다.** 멀티턴은 매 요청마다 전체 이력을 다시 보냅니다.

### 프롬프트 캐싱 — 가장 큰 비용 레버

```python
resp = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    system=[
        {
            "type": "text",
            "text": LONG_STATIC_CONTEXT,           # 긴 문서, 스키마, 가이드라인
            "cache_control": {"type": "ephemeral"} # 캐시 브레이크포인트
        },
        {"type": "text", "text": f"오늘 날짜: {today}"}  # 자주 바뀌는 부분은 뒤에
    ],
    messages=[...],
)
print(resp.usage.cache_creation_input_tokens, resp.usage.cache_read_input_tokens)
```

핵심 규칙:

- **정적인 것을 앞에, 변하는 것을 뒤에.** 캐시는 접두사(prefix) 단위로 매칭됩니다.
- 캐시 적중에는 **최소 토큰 수**가 있습니다(모델별 상이, 대개 1,024 또는 4,096).
- 브레이크포인트는 최대 4개까지 지정 가능.
- 기본 TTL은 5분, `{"type": "ephemeral", "ttl": "1h"}`로 1시간 캐시 사용 가능(쓰기 비용 증가).

### Tool use 루프

```python
while True:
    resp = client.messages.create(model=M, max_tokens=2048, tools=TOOLS, messages=messages)
    if resp.stop_reason != "tool_use":
        break
    messages.append({"role": "assistant", "content": resp.content})
    results = [
        {"type": "tool_result", "tool_use_id": b.id, "content": run_tool(b.name, b.input)}
        for b in resp.content if b.type == "tool_use"
    ]
    messages.append({"role": "user", "content": results})
```

`client.beta.messages.tool_runner(...)`를 쓰면 이 루프를 SDK가 대신 돌려줍니다.

### 배치 API

지연에 민감하지 않은 대량 작업은 Message Batches API로 **약 50% 저렴하게** 처리합니다. 스트리밍은 불가하며 결과는 일정 기간 후 만료됩니다.

### 토큰 카운팅

```python
client.messages.count_tokens(model=M, system=S, messages=MSGS).input_tokens
```

요청 전에 비용을 예측하거나 컨텍스트 한계를 체크할 때 사용합니다.

---

## 17. Cowork · 데스크톱 앱

### Cowork란

코딩을 넘어선 다단계 지식 작업(문서 작성, 파일 정리, 리서치, 스프레드시트)을 에이전트에게 위임하는 모드. 유료 플랜(Pro/Max/Team/Enterprise) 전용이며 데스크톱 앱, 웹, 모바일에서 사용합니다.

Claude Code와의 차이: Cowork는 프로젝트(Projects) 단위 워크스페이스와 병렬 워크스트림 조율을 제공하고, 대상이 코드에 한정되지 않습니다.

### 폴더 연결과 샌드박스

- 로컬 파일 접근은 **사용자가 명시적으로 연결한 폴더**로 한정됩니다.
- 클라우드 세션은 격리된 임시 샌드박스에서 실행되고 종료 시 파기됩니다. 외부 네트워크는 허용목록 프록시를 통해서만 나갑니다.
- 로컬 세션의 코드 실행은 격리 VM(macOS: Apple Virtualization, Windows: Hyper-V)에서 이루어집니다.

**승인 모드 3가지**

| 모드 | 동작 |
|---|---|
| Manually approve | 모든 동작 전 확인 |
| Automatically approve | 안전성 검토 후 자동 진행, 위험 동작은 차단 |
| Skip all approvals | 안전 검사 없음 (파일 **삭제**는 어떤 모드에서도 별도 승인 필요) |

> **프롬프트 인젝션 주의** — 위험은 ①신뢰 경계 밖 콘텐츠를 읽고 ②위험한 행동 권한을 가질 때 성립합니다. 외부 문서·웹페이지를 다루는 세션에는 쓰기/삭제 권한을 넓게 주지 마세요.

### 아티팩트

대화 옆 패널에 뜨는 자기완결적 산출물(문서, 코드, HTML, 다이어그램, 슬라이드, 디자인). 업데이트마다 버전이 생기고 공유·복원이 가능합니다. **Settings > Capabilities에서 "Code execution and file creation"이 켜져 있어야 합니다.**

공유 시 수신자는 Claude 계정이 필요하며, 공유된 아티팩트는 **열람자 본인의 데이터 접근 권한**으로 동작합니다.

### 커넥터 / MCP

| 대상 | 방식 | 사용 범위 |
|---|---|---|
| SaaS (Slack, Notion, GitHub 등) | 원격 커넥터 | 웹·모바일·데스크톱·Claude Code |
| 로컬 도구(로컬 DB, 데스크톱 앱) | 데스크톱 확장 | 데스크톱·Claude Code |

데스크톱에서 MCP 추가: **Settings > Extensions > Browse extensions**에서 원클릭 설치. 커스텀은 Advanced settings > Extension Developer에서 `.mcpb` 파일 설치. 민감 필드는 manifest에서 `"sensitive": true`로 지정하면 OS 키체인에 암호화 저장됩니다.

### 스킬·플러그인 (앱)

사이드바 **Customize** → Skills / Connectors / Plugins 탭에서 브라우즈·설치. 커스텀 스킬은 폴더를 ZIP으로 묶어 업로드합니다. 앱에서는 스킬이 상황에 맞게 **자동 활성화**되므로 명시 호출이 필요 없습니다.

훅과 서브에이전트는 **Cowork에서만** 동작하고 일반 채팅에서는 비활성입니다.

### 예약 작업

사이드바 "Scheduled"에서 관리. 빈도는 hourly / daily / weekly / weekdays / manual. **원격에서 실행되므로 내 컴퓨터가 꺼져 있어도 동작**하지만, 그렇기 때문에 로컬 폴더가 아닌 클라우드 파일을 대상으로 해야 합니다. 각 실행은 독립 세션입니다.

### 브라우저 · Excel

- **Cowork 내장 브라우저**: 사이드 패널에서 실행. Settings > Cowork > Preferred browser에서 내장 브라우저 / Claude in Chrome 선택.
- **Claude in Chrome**: 실제 Chrome을 제어하는 확장. 클릭·입력·스크린샷이 가능해 권한 범위가 넓습니다.
- **Claude for Excel**: 워크북 질의(셀 인용), 수식 관계 유지 시나리오 변경, 오류 추적. Excel 웹/Windows(M365)/Mac 지원. 데이터 테이블과 VBA는 미지원.

> 공식 권고: 금융 계좌, 의료 정보, 타인의 개인정보처럼 민감한 대상에 브라우저 자동화를 사용하지 마세요.

### 프로젝트와 메모리

- **Projects**: 관련 태스크를 묶는 워크스페이스. 프로젝트별 지침·파일·메모리를 가지며, **메모리는 프로젝트 경계를 넘지 않습니다.**
- **Memory**: 대화 중 토픽 단위로 저장. 기본값은 Free/Pro/Max on, Team/Enterprise off. Settings > Memory에서 Pause(신규 중단) / Reset(전체 삭제) / Topics(개별 편집).
- **Incognito**: 유령 아이콘. 메모리·검색 대상에서 제외됩니다.

### 단축키 (macOS)

| 기능 | 기본 키 |
|---|---|
| Quick entry | `Option` 더블탭 (또는 `Option+Space`) |
| 음성 받아쓰기 | `Caps Lock` (활성화 시) |

Settings > General에서 변경. Quick entry는 Mac 전용입니다.

---

## 18. 컨텍스트·비용 최적화 플레이북

### 원칙 1 — 컨텍스트는 예산이다

`/context`를 습관적으로 확인하세요. 세션 시작 시점의 점유가 이미 30%를 넘는다면, 문제는 대화가 아니라 **설정**입니다. 주범은 대개 비대한 CLAUDE.md, 상시 연결된 MCP 서버, 과도한 스킬입니다.

### 원칙 2 — `/clear`를 아끼지 마세요

작업이 바뀌면 `/clear`. 컨텍스트를 이어갈 이유가 없는데 남겨두면 매 요청마다 그 비용을 다시 냅니다. `/compact`는 맥락이 필요하지만 길어졌을 때, `/clear`는 맥락이 필요 없을 때입니다.

### 원칙 3 — 탐색은 plan 모드 또는 서브에이전트로

구현 전 조사 단계는 `Shift+Tab`으로 plan 모드에 두세요. 실수로 파일을 고칠 위험도, 비용도 줄어듭니다. 파일을 수십 개 읽어야 하는 조사는 서브에이전트에 위임하면 메인 컨텍스트에는 결론만 남습니다.

### 원칙 4 — 작업 크기에 모델을 맞추세요

| 작업 | 권장 |
|---|---|
| 포맷 변경, 단순 반복 수정, 파일 탐색 | Haiku |
| 일상적 기능 구현, 리뷰 | Sonnet |
| 아키텍처 설계, 난해한 버그, 대규모 리팩터링 | Opus |

`/model`로 세션 중에도 바꿀 수 있습니다. 어려운 설계를 Opus로 잡고, 반복 적용은 Sonnet으로 내리는 식이 효율적입니다.

### 원칙 5 — 프롬프트 캐싱이 동작하게 두세요

Claude Code는 CLAUDE.md와 대화 접두사를 자동 캐싱합니다. 세션 중간에 CLAUDE.md를 계속 수정하면 캐시가 매번 무효화됩니다. **메모리 수정은 몰아서 하고, 작업 중에는 건드리지 마세요.** `/cost`로 캐시 적중을 확인할 수 있습니다.

### 원칙 6 — 병렬 작업은 git worktree로

```bash
git worktree add ../proj-featB feature/b
cd ../proj-featB && claude
```

한 세션에서 두 기능을 오가는 것보다, 디렉터리를 분리해 세션을 나누는 편이 컨텍스트 오염과 충돌을 모두 막습니다.

### 원칙 7 — 반복되는 요청은 즉시 자산화

같은 지시를 세 번 이상 반복했다면 그건 프롬프트가 아니라 설정입니다.

| 반복 유형 | 자산화 대상 |
|---|---|
| "빌드 명령은 pnpm이야" | CLAUDE.md |
| "변경분 리뷰해줘" | 커스텀 슬래시 명령 |
| "저장할 때 포맷 맞춰" | PostToolUse 훅 |
| "우리 API 설계 규칙대로" | 스킬 |
| "팀 전체가 이걸 쓰게 해줘" | 플러그인 |

### 원칙 8 — 계획을 먼저 보고 받으세요

복잡한 작업은 "구현하기 전에 계획부터 보여줘"라고 요청하세요. 잘못된 방향으로 진행된 300줄을 되돌리는 비용보다, 계획 한 페이지를 읽는 비용이 훨씬 쌉니다.

### 원칙 9 — 검증을 분리하세요

구현한 주체에게 검증을 맡기면 자기 코드를 관대하게 봅니다. 별도 서브에이전트나 새 세션에서 "이 변경의 실패 시나리오를 찾아라"라고 시키는 편이 훨씬 잘 잡아냅니다.

---

## 19. 트러블슈팅 체크리스트

| 증상 | 확인 순서 |
|---|---|
| 설치/실행 이상 | `claude doctor` → `claude --version` → `claude update` |
| 세션 시작이 느리고 무겁다 | `/context` → MCP 서버 수, CLAUDE.md 크기, 스킬 수 |
| 스킬이 호출되지 않는다 | `description`에 사용자가 쓸 표현이 들어 있는지 → 스킬이 설치 경로에 있는지 |
| MCP 서버 연결 실패 | `/mcp` 상태 → `claude mcp get <name>` → `--debug=mcp` → 환경변수 확장 확인 |
| 훅이 동작하지 않는다 | `/hooks`로 등록 확인 → 스크립트 실행 권한(`chmod +x`) → `--debug=hooks` |
| 권한 프롬프트가 계속 뜬다 | `/permissions`에서 해당 패턴 추가 → 와일드카드 범위 확인 |
| 비용이 예상보다 높다 | `/cost`로 캐시 적중률 → CLAUDE.md 잦은 수정 여부 → 모델·effort 하향 |
| 모노레포에서 파일을 못 찾는다 | `--add-dir` 또는 `permissions.additionalDirectories` |
| CI에서 무한정 도는 것 같다 | `--max-turns` 누락 여부 |

---

## 20. 참고 링크

### Claude Code

- [문서 홈](https://code.claude.com/docs)
- [설치·고급 설정](https://code.claude.com/docs/en/setup)
- [CLI 레퍼런스](https://code.claude.com/docs/en/cli-reference)
- [대화형 모드·단축키](https://code.claude.com/docs/en/interactive-mode)
- [메모리(CLAUDE.md)](https://code.claude.com/docs/en/memory)
- [설정 레퍼런스](https://code.claude.com/docs/en/settings-reference)
- [권한](https://code.claude.com/docs/en/permissions)
- [훅](https://code.claude.com/docs/en/hooks)
- [MCP](https://code.claude.com/docs/en/mcp)
- [서브에이전트](https://code.claude.com/docs/en/sub-agents)
- [스킬](https://code.claude.com/docs/en/skills)
- [플러그인 마켓플레이스](https://code.claude.com/docs/en/plugin-marketplaces)
- [GitHub Actions](https://code.claude.com/docs/en/github-actions)
- [프롬프트 캐싱](https://code.claude.com/docs/en/prompt-caching)

### Agent SDK / API

- [Agent SDK 개요](https://code.claude.com/docs/en/agent-sdk/overview)
- [Messages API](https://platform.claude.com/docs/en/build-with-claude/working-with-messages)
- [프롬프트 캐싱](https://platform.claude.com/docs/en/build-with-claude/prompt-caching)
- [Message Batches](https://platform.claude.com/docs/en/build-with-claude/batch-processing)
- [Tool Runner](https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-runner)
- [claude-agent-sdk-typescript](https://github.com/anthropics/claude-agent-sdk-typescript)
- [claude-agent-sdk-python](https://github.com/anthropics/claude-agent-sdk-python)

### Cowork / 데스크톱

- [Cowork 시작하기](https://support.claude.com/en/articles/13345190-get-started-with-claude-cowork)
- [Cowork 아키텍처](https://support.claude.com/en/articles/14479288-claude-cowork-architecture-overview)
- [Cowork 안전하게 사용하기](https://support.claude.com/en/articles/13364135-use-claude-cowork-safely)
- [아티팩트](https://support.claude.com/en/articles/9487310-what-are-artifacts-and-how-do-i-use-them)
- [로컬 MCP 서버](https://support.claude.com/en/articles/10949351-getting-started-with-local-mcp-servers-on-claude-desktop)
- [스킬 사용](https://support.claude.com/en/articles/12512180-use-skills-in-claude)
- [플러그인 사용](https://support.claude.com/en/articles/13837440-use-plugins-in-claude)
- [예약 작업](https://support.claude.com/en/articles/13854387-schedule-recurring-tasks-in-claude-cowork)
- [Projects](https://support.claude.com/en/articles/14116274-organize-your-tasks-with-projects-in-claude-cowork)
- [Claude in Chrome](https://support.claude.com/en/articles/12012173-get-started-with-claude-in-chrome)
- [Claude for Excel](https://claude.com/docs/office-agents/excel)
