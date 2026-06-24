# blackcow-codex-swap

⚡ Switch between multiple OpenAI Codex accounts — same sessions, skills, config. Separate quotas.

> 🪟 **Windows** (`win/profile.ps1`) · 🍎 **macOS/Linux** (`mac/codex-swap.sh`)  
> [한국어 / Korean →](README_KR.md)

---

## Commands

| Command | What it does |
|---------|-------------|
| `codex-pick` | Interactive menu — pick an account for Desktop |
| `codex-add` | Add a new account (opens browser for login) |
| `codex-who` | Show current account + plan + days left |
| `codex2` ~ `codex4` | Launch CLI with a specific account |

## Quick Install

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

To make it permanent, add the `source` line to your `~/.zshrc` or `~/.bashrc`.

---

## Setup (first time)

1. **Backup your current account:**
   ```powershell
   mkdir ~/.codex1
   cp ~/.codex/auth.json ~/.codex1/auth.json
   ```

2. **Add a second account:**
   ```powershell
   codex-add     # Windows
   # or create folder manually:
   mkdir ~/.codex2
   CODEX_HOME="$HOME/.codex2" codex   # login → creates auth.json
   ```

3. **Share sessions & skills (optional, Windows requires Admin):**
   See `codex-add` which does this automatically.

---

## How it works

```
~/.codex/auth.json    ← active account (Desktop reads this)
~/.codex1/auth.json   ← account #1 backup
~/.codex2/auth.json   ← account #2 backup
~/.codex3/auth.json   ← account #3
~/.codex4/auth.json   ← account #4
```

`codex-pick` copies the chosen `auth.json` into `~/.codex/`.  
Other files (sessions, skills) are symlinked — every account shares the same environment.

---

## Example

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

## Safety

- **Do not run two instances at once** — SQLite can corrupt.
- Swap *before* launching Desktop.

## License

MIT
