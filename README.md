# blackcow-codex-swap

Switch between multiple OpenAI Codex accounts.  
Same sessions, skills, and config. Separate quotas.

> Windows: `win/profile.ps1` — macOS/Linux: `mac/codex-swap.sh`  
> [한국어 / Korean](README_KR.md)

---

## Install

**Windows:** Double-click `install.bat`, or run it from PowerShell.

**macOS / Linux:** `bash install.sh`

Then open a new terminal and run:

```
codex-pick
```

First-time setup: if you don't have a second account yet, run `codex-add`.

---

## Commands

| Command | Description |
|---------|-------------|
| `codex` | Launch CLI with the active account |
| `codex-pick` | Interactive menu — switch the Desktop account |
| `codex-add` | Add a new account (opens browser for login) |
| `codex-clear <slot>` | Empty a saved account slot, for example `codex-clear 2` |
| `codex-who` | Show current account, plan, days remaining |
| `codex2` .. `codex4` | Launch CLI with a specific account |

---

## How it works

```
~/.codex/auth.json     <-- active account (Desktop reads this)
~/.codex2/auth.json    <-- account #2 backup
~/.codex3/auth.json    <-- account #3
~/.codex4/auth.json    <-- account #4
```

`codex-pick` copies the chosen `auth.json` into `~/.codex/`.  
Other files (sessions, skills) are symlinked so all accounts share the same environment.

On macOS, the shell helper prefers the Codex Desktop bundled CLI at
`/Applications/Codex.app/Contents/Resources/codex` before falling back to a
global `codex` on `PATH`. That avoids stale npm-installed CLI binaries.

---

## Example

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

## Safety

Do not run two Codex instances at the same time — shared SQLite state can corrupt.  
Switch accounts before launching Desktop.

## License

MIT
