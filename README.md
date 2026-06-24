# blackcow-codex-swap

Effortlessly switch between multiple OpenAI Codex accounts.  
Same sessions, skills, and config. Separate quotas.

## Why?

Codex has daily usage limits tied to your ChatGPT account.  
If you have multiple accounts, you can **double (or triple, or quadruple)**  
your quota without losing sessions, skills, MCP servers, or config.

> Quota ran out? Swap. Keep working.

## How it works

```
~/.codex/          ← Desktop always reads this folder
    auth.json      ← active account

~/.codex1/         ← account #1 backup
~/.codex2/         ← account #2 backup
~/.codex3/         ← account #3 (add anytime)
~/.codex4/         ← account #4 (add anytime)
```

`codex-pick` copies the chosen `auth.json` into `~/.codex/`.  
All other files (sessions, skills, SQLite state) are symlinked,  
so every account shares the same environment.

## Commands

| Command | What it does |
|---------|-------------|
| `codex-pick` | Interactive menu — pick an account for Desktop |
| `codex-add` | Add a new account (opens browser for login) |
| `codex-who` | Show current active account + plan + days left |
| `codex2` ~ `codex4` | Launch CLI with a specific account |

## Install (Windows)

### 1. First-time setup

Create backup folders and add your accounts:

```powershell
mkdir ~/.codex1
mkdir ~/.codex2

# Backup current account
cp ~/.codex/auth.json ~/.codex1/auth.json

# Login with account #2
$env:CODEX_HOME = "$HOME\.codex2"
codex          # browser opens -> login -> creates ~/.codex2/auth.json
```

To share sessions and skills, symlink everything except `auth.json`:

```powershell
# Run as Administrator
$src = "$HOME\.codex"
$dst = "$HOME\.codex2"
Get-ChildItem -Path $src -Exclude auth.json | ForEach-Object {
    $targetPath = Join-Path $dst $_.Name
    Remove-Item $targetPath -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType SymbolicLink -Path $targetPath -Target $_.FullName -Force
}
```

### 2. Install the script

Download `profile.ps1` and source it in your PowerShell profile:

```powershell
# Download
iwr -Uri "https://raw.githubusercontent.com/blackcowmaster/blackcow-codex-swap/main/profile.ps1" -OutFile "$HOME\.codex\profile.ps1"

# Add to your PowerShell profile
Add-Content -Path $PROFILE -Value ". `"`$HOME\.codex\profile.ps1`""
```

### 3. Reload

```powershell
. $PROFILE
codex-pick
```

## Adding more accounts later

```powershell
codex-add     # interactive — finds next free slot, opens browser
```

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

  Enter a number to switch the
  Codex Desktop account.

  Choice (1-2): 2

  Switched -> bob@team.io
```

## Safety

- **Never run two instances simultaneously** — shared SQLite state can corrupt.
- Swap accounts *before* launching Desktop, not while it's running.
- Each `auth.json` belongs to a different ChatGPT account with its own quota.

## License

MIT
