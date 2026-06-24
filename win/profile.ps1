# === blackcow-codex-swap ===
# Multi-account switcher for OpenAI Codex
# https://github.com/blackcowmaster/blackcow-codex-swap

function codex1 { $env:CODEX_HOME = "$HOME\.codex1"; & codex @args }
function codex2 { $env:CODEX_HOME = "$HOME\.codex2"; & codex @args }
function codex3 { $env:CODEX_HOME = "$HOME\.codex3"; & codex @args }
function codex4 { $env:CODEX_HOME = "$HOME\.codex4"; & codex @args }

function _jwt-decode($authFile) {
    try {
        $raw = Get-Content $authFile -Raw | ConvertFrom-Json
        $payload = $raw.tokens.id_token.Split('.')[1]
        $payload = $payload.Replace('-', '+').Replace('_', '/')
        switch ($payload.Length % 4) {
            2 { $payload += '==' }
            3 { $payload += '=' }
        }
        $json = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($payload))
        $obj = $json | ConvertFrom-Json
        $auth = $obj.'https://api.openai.com/auth'
        return @{
            Email = $obj.email
            Plan = $auth.chatgpt_plan_type
            Until = [datetime]::Parse($auth.chatgpt_subscription_active_until)
        }
    } catch { return @{ Email = '?'; Plan = '?'; Until = $null } }
}

function _info-line($info) {
    $remain = ''
    if ($info.Until) {
        $days = [math]::Ceiling(($info.Until - (Get-Date)).TotalDays)
        $dateStr = $info.Until.ToString('M/d')
        $color = if ($days -le 3) { 'Red' } elseif ($days -le 7) { 'Yellow' } else { 'DarkGray' }
        $remain = " / expires D-$days ($dateStr)"
    }
    $planColor = if ($info.Plan -eq 'pro') { 'Cyan' } else { 'White' }
    Write-Host "      " -NoNewline
    Write-Host $info.Plan.ToUpper() -ForegroundColor $planColor -NoNewline
    Write-Host $remain -ForegroundColor $color
}

function codex-pick {
    Clear-Host
    
    Write-Host ""
    Write-Host "  +----------------------------------+" -ForegroundColor Cyan
    Write-Host "  |       Codex Account Switch       |" -ForegroundColor Cyan
    Write-Host "  +----------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    $current = "$HOME\.codex\auth.json"
    if (Test-Path $current) {
        $curInfo = _jwt-decode $current
        Write-Host "  Active: " -NoNewline
        Write-Host $curInfo.Email -ForegroundColor Green -NoNewline
        $remain = ''
        if ($curInfo.Until) {
            $days = [math]::Ceiling(($curInfo.Until - (Get-Date)).TotalDays)
            $remain = "  (D-$days)"
        }
        Write-Host "  $remain" -ForegroundColor DarkGray
        Write-Host ""
    }

    $accounts = @()
    $folders = @("$HOME\.codex1", "$HOME\.codex2", "$HOME\.codex3", "$HOME\.codex4")
    $idx = 1

    foreach ($folder in $folders) {
        $authFile = Join-Path $folder "auth.json"
        if (-not (Test-Path $authFile)) { continue }
        $info = _jwt-decode $authFile
        $isCurrent = (Get-FileHash $authFile).Hash -eq (Get-FileHash $current).Hash
        
        Write-Host "  [$idx] " -NoNewline
        Write-Host $info.Email -NoNewline
        if ($isCurrent) {
            Write-Host "  <-- active" -ForegroundColor Green
        } else {
            Write-Host ""
        }
        _info-line $info
        $accounts += @{Index=$idx; Path=$authFile; Email=$info.Email}
        $idx++
    }

    if ($accounts.Count -eq 0) {
        Write-Host ""
        Write-Host "  No accounts found." -ForegroundColor Red
        Write-Host "  Run codex-add to add one." -ForegroundColor DarkGray
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Host "  ------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Enter a number to switch the" -ForegroundColor DarkGray
    Write-Host "  Codex Desktop account." -ForegroundColor DarkGray
    Write-Host ""
    $choice = Read-Host "  Choice (1-$($accounts.Count))"
    $num = [int]$choice
    $target = $accounts | Where-Object { $_.Index -eq $num }

    if ($target) {
        Copy-Item $target.Path $current -Force
        Write-Host ""
        Write-Host "  Switched -> " -NoNewline -ForegroundColor Green
        Write-Host "$($target.Email)" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "  Invalid choice. Canceled." -ForegroundColor Red
        Write-Host ""
    }
}

function codex-add {
    Clear-Host
    Write-Host ""
    Write-Host "  +----------------------------------+" -ForegroundColor Cyan
    Write-Host "  |       Codex Add Account          |" -ForegroundColor Cyan
    Write-Host "  +----------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    $slots = @("$HOME\.codex3", "$HOME\.codex4")
    $num = 3
    $found = $null
    foreach ($slot in $slots) {
        if (-not (Test-Path (Join-Path $slot "auth.json"))) {
            $found = $slot
            break
        }
        $num++
    }

    if (-not $found) {
        Write-Host "  All 4 slots are full." -ForegroundColor Red
        Write-Host "  Delete an existing account folder first." -ForegroundColor DarkGray
        Write-Host ""
        return
    }

    Write-Host "  Free slot: codex$num" -ForegroundColor Yellow
    Write-Host ""
    New-Item -ItemType Directory -Path $found -Force | Out-Null

    Write-Host "  ------------------------------------" -ForegroundColor DarkGray
    Write-Host "  A browser will open." -ForegroundColor White
    Write-Host "  Login with your new account." -ForegroundColor White
    Write-Host ""
    Write-Host "  When Codex CLI appears," -ForegroundColor DarkGray
    Write-Host "  type /exit or Ctrl+C to close it." -ForegroundColor DarkGray
    Write-Host "  ------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "  Press Enter to continue"

    $env:CODEX_HOME = $found
    & codex
    $env:CODEX_HOME = $null

    if (-not (Test-Path (Join-Path $found "auth.json"))) {
        Write-Host ""
        Write-Host "  Login was not completed." -ForegroundColor Red
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Host "  Setting up session/skill sharing..." -ForegroundColor DarkGray
    $src = "$HOME\.codex"
    $linked = 0
    $failed = 0
    Get-ChildItem -Path $src -Exclude auth.json | ForEach-Object {
        $targetPath = Join-Path $found $_.Name
        if (Test-Path $targetPath) { Remove-Item $targetPath -Recurse -Force -ErrorAction SilentlyContinue }
        try {
            New-Item -ItemType SymbolicLink -Path $targetPath -Target $_.FullName -Force -ErrorAction Stop | Out-Null
            $linked++
        } catch {
            $failed++
        }
    }

    $info = _jwt-decode (Join-Path $found "auth.json")
    Write-Host ""
    Write-Host "  Added! " -NoNewline -ForegroundColor Green
    Write-Host "$($info.Email)" -ForegroundColor Green
    if ($linked -gt 0) {
        Write-Host "  ($linked items shared)" -ForegroundColor DarkGray
    }
    if ($failed -gt 0) {
        Write-Host "  ($failed items skipped - admin needed for symlinks)" -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "  Use codex-pick to switch!" -ForegroundColor Cyan
    Write-Host ""
}

function codex-who {
    $a1 = "$HOME\.codex\auth.json"
    if (-not (Test-Path $a1)) { Write-Host "auth.json not found"; return }
    $info = _jwt-decode $a1
    $remain = ''
    if ($info.Until) {
        $days = [math]::Ceiling(($info.Until - (Get-Date)).TotalDays)
        $remain = " - D-$days"
    }
    Write-Host "$($info.Email) | $($info.Plan.ToUpper()) | $remain"
}
