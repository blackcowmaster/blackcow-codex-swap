# blackcow-codex-swap

⚡ 여러 개의 OpenAI Codex 계정을 자유롭게 전환하세요.  
세션, 스킬, 설정은 그대로. 쿼터만 따로.

*Effortlessly switch between multiple OpenAI Codex accounts — same sessions, skills, and config. Separate quotas.*

---

## 왜 필요한가? / Why?

Codex는 ChatGPT 계정마다 일일 사용량 제한이 있습니다.  
여러 계정이 있다면 **2배, 3배, 4배** 쿼터를 쓸 수 있어요.  
세션, 스킬, MCP 서버, 설정은 전혀 건드리지 않고요.

> 쿼터 떨어졌다고? 전환하고 계속 작업해.

---

*Codex has daily usage limits tied to your ChatGPT account. If you have multiple accounts, you can double (or triple, or quadruple) your quota without losing sessions, skills, MCP servers, or config.*

## 동작 방식 / How it works

```
~/.codex/          ← Desktop이 항상 이 폴더를 바라봄
    auth.json      ← 현재 활성 계정

~/.codex1/         ← 계정 #1 보관
~/.codex2/         ← 계정 #2 보관
~/.codex3/         ← 계정 #3 (언제든 추가 가능)
~/.codex4/         ← 계정 #4 (언제든 추가 가능)
```

`codex-pick`이 선택한 `auth.json`을 `~/.codex/`로 복사합니다.  
나머지 파일들(세션, 스킬, SQLite)은 심링크로 연결되어 모든 계정이 공유합니다.

---

*`codex-pick` copies the chosen `auth.json` into `~/.codex/`. All other files are symlinked so every account shares the same environment.*

## 명령어 / Commands

| 명령어 | 설명 |
|--------|------|
| `codex-pick` | 계정 목록 보고 숫자로 Desktop 전환 |
| `codex-add` | 새 계정 추가 (브라우저 열림) |
| `codex-who` | 현재 계정 + 요금제 + 남은 일수 확인 |
| `codex2` ~ `codex4` | CLI를 특정 계정으로 실행 |

---

## 설치 (Windows) / Install

### 1. 최초 설정

```powershell
mkdir ~/.codex1
mkdir ~/.codex2

# 현재 계정 백업
cp ~/.codex/auth.json ~/.codex1/auth.json

# 두 번째 계정 로그인
$env:CODEX_HOME = "$HOME\.codex2"
codex          # 브라우저 열림 → 로그인 → ~/.codex2/auth.json 생성
```

세션과 스킬을 공유하려면 `auth.json`을 제외한 모든 파일을 심링크:

```powershell
# 관리자 권한으로 실행
$src = "$HOME\.codex"
$dst = "$HOME\.codex2"
Get-ChildItem -Path $src -Exclude auth.json | ForEach-Object {
    $targetPath = Join-Path $dst $_.Name
    Remove-Item $targetPath -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType SymbolicLink -Path $targetPath -Target $_.FullName -Force
}
```

### 2. 스크립트 설치

```powershell
# 다운로드
iwr -Uri "https://raw.githubusercontent.com/blackcowmaster/blackcow-codex-swap/main/profile.ps1" -OutFile "$HOME\.codex\profile.ps1"

# PowerShell 프로필에 추가
Add-Content -Path $PROFILE -Value ". `"`$HOME\.codex\profile.ps1`""
```

### 3. 적용

```powershell
. $PROFILE
codex-pick
```

---

## 계정 추가 / Add more accounts

```powershell
codex-add     # 빈 슬롯 자동 감지 → 브라우저 열림
```

---

## 실행 예시 / Example

```
PS> codex-pick

  ╔══════════════════════════════════╗
  ║       Codex Account Switch       ║
  ╚══════════════════════════════════╝

  Active: alice@company.com  (D-12)

  [1] alice@company.com  <-- active
      PRO / expires D-12 (7/12)
  [2] bob@team.io
      PRO / expires D-28 (7/24)

  ──────────────────────────────────
  Enter a number to switch the
  Codex Desktop account.

  Choice (1-2): 2

  Switched -> bob@team.io
```

---

## 주의사항 / Safety

- **절대 두 개를 동시에 실행하지 마세요** — SQLite 상태 파일이 깨질 수 있습니다.
- Desktop을 켜기 **전에** 계정을 전환하세요. 실행 중에는 바꾸지 마세요.
- 각 `auth.json`은 서로 다른 ChatGPT 계정의 인증 정보이며, 쿼터도 별도입니다.

---

*Never run two instances simultaneously — shared SQLite state can corrupt. Swap before launching Desktop. Each auth.json belongs to a different ChatGPT account.*

## 라이선스 / License

MIT
