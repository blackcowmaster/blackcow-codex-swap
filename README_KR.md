# blackcow-codex-swap

여러 개의 OpenAI Codex 계정을 자유롭게 전환하세요.  
세션, 스킬, 설정은 그대로. 쿼터만 따로.

> Windows: `win/profile.ps1` — macOS/Linux: `mac/codex-swap.sh`  
> [English](README.md)

---

## 설치

**Windows:** `install.bat`을 더블클릭하거나 PowerShell에서 실행.

**macOS / Linux:** `bash install.sh`

그 후 새 터미널을 열고:

```
codex-pick
```

처음이라면 `codex-add`로 계정을 추가하세요.

---

## 명령어

| 명령어 | 설명 |
|--------|------|
| `codex-pick` | 계정 목록을 보고 숫자로 Desktop 전환 |
| `codex-add` | 새 계정 추가 (브라우저 열림) |
| `codex-who` | 현재 계정, 요금제, 남은 일수 확인 |
| `codex2` .. `codex4` | CLI를 특정 계정으로 실행 |

---

## 동작 방식

```
~/.codex/auth.json     <-- Desktop이 읽는 활성 계정
~/.codex1/auth.json    <-- 계정 #1 보관
~/.codex2/auth.json    <-- 계정 #2 보관
~/.codex3/auth.json    <-- 계정 #3
~/.codex4/auth.json    <-- 계정 #4
```

`codex-pick`이 선택한 `auth.json`을 `~/.codex/`로 복사합니다.  
나머지 파일은 심링크로 연결되어 모든 계정이 환경을 공유합니다.

---

## 실행 예시

```
PS> codex-pick

  +----------------------------------+
  |       Codex Account Switch       |
  +----------------------------------+

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

Codex 인스턴스를 동시에 두 개 실행하지 마세요. SQLite 상태 파일이 깨질 수 있습니다.  
Desktop을 켜기 전에 계정을 전환하세요.

## 라이선스

MIT
