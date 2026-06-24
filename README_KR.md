# blackcow-codex-swap 🇰🇷

⚡ 여러 개의 OpenAI Codex 계정을 자유롭게 전환하세요.  
세션, 스킬, 설정은 그대로. 쿼터만 따로.

> 🪟 **Windows** (`win/profile.ps1`) · 🍎 **macOS/Linux** (`mac/codex-swap.sh`)  
> [English →](README.md)

---

## 명령어

| 명령어 | 설명 |
|--------|------|
| `codex-pick` | 계정 목록 보고 숫자로 Desktop 전환 |
| `codex-add` | 새 계정 추가 (브라우저 열림) |
| `codex-who` | 현재 계정 + 요금제 + 남은 일수 확인 |
| `codex2` ~ `codex4` | CLI를 특정 계정으로 실행 |

## 빠른 설치

### Windows

```powershell
iwr -Uri "https://raw.githubusercontent.com/blackcowmaster/blackcow-codex-swap/main/win/profile.ps1" -OutFile "$HOME\.codex\profile.ps1"
Add-Content -Path $PROFILE -Value ". `"`$HOME\.codex\profile.ps1`""
. $PROFILE
codex-pick
```

### macOS / Linux

```bash
source <(curl -s https://raw.githubusercontent.com/blackcowmaster/blackcow-codex-swap/main/mac/codex-swap.sh)
codex-pick
```

영구 적용하려면 위 `source` 줄을 `~/.zshrc` 또는 `~/.bashrc`에 추가하세요.

---

## 최초 설정

1. **현재 계정 백업:**
   ```powershell
   mkdir ~/.codex1
   cp ~/.codex/auth.json ~/.codex1/auth.json
   ```

2. **두 번째 계정 추가:**
   ```powershell
   codex-add     # Windows
   # 또는 수동으로:
   mkdir ~/.codex2
   CODEX_HOME="$HOME/.codex2" codex   # 로그인 → auth.json 생성
   ```

3. **세션/스킬 공유:** `codex-add`가 자동 처리합니다.

---

## 동작 방식

```
~/.codex/auth.json    ← Desktop이 읽는 활성 계정
~/.codex1/auth.json   ← 계정 #1 보관
~/.codex2/auth.json   ← 계정 #2 보관
~/.codex3/auth.json   ← 계정 #3
~/.codex4/auth.json   ← 계정 #4
```

`codex-pick`이 선택한 `auth.json`을 `~/.codex/`로 복사합니다.  
나머지 파일들은 심링크로 연결 — 모든 계정이 환경을 공유합니다.

---

## 실행 예시

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

  Choice (1-2): 2

  Switched -> bob@team.io
```

---

## 주의사항

- **두 개를 동시에 실행하지 마세요** — SQLite가 깨집니다.
- Desktop을 켜기 **전에** 전환하세요.

## 라이선스

MIT
