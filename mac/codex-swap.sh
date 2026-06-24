#!/usr/bin/env bash
# === blackcow-codex-swap (macOS/Linux) ===
# Multi-account switcher for OpenAI Codex
# Source this in your ~/.bashrc or ~/.zshrc:
#   source /path/to/codex-swap.sh
# https://github.com/blackcowmaster/blackcow-codex-swap

alias codex2='CODEX_HOME="$HOME/.codex2" codex'
alias codex3='CODEX_HOME="$HOME/.codex3" codex'
alias codex4='CODEX_HOME="$HOME/.codex4" codex'

# ── helpers -----------------------------------────────────

_jwt_email() {
    local authfile="$1"
    local payload
    payload=$(python3 -c "
import json, base64, sys
try:
    raw = json.load(open('$authfile'))
    tok = raw['tokens']['id_token']
    body = tok.split('.')[1]
    body += '=' * (4 - len(body) % 4) if len(body) % 4 else ''
    dec = base64.urlsafe_b64decode(body).decode()
    obj = json.loads(dec)
    print(obj.get('email', '?'))
except:
    print('?')
" 2>/dev/null)
    echo "$payload"
}

_jwt_plan() {
    local authfile="$1"
    python3 -c "
import json, base64, sys
try:
    raw = json.load(open('$authfile'))
    tok = raw['tokens']['id_token']
    body = tok.split('.')[1]
    body += '=' * (4 - len(body) % 4) if len(body) % 4 else ''
    dec = base64.urlsafe_b64decode(body).decode()
    obj = json.loads(dec)
    auth = obj.get('https://api.openai.com/auth', {})
    print(auth.get('chatgpt_plan_type', '?'))
    print(auth.get('chatgpt_subscription_active_until', ''))
except:
    print('?')
    print('')
" 2>/dev/null
}

# ── codex-who -----------------------------------──────────

codex-who() {
    local a1="$HOME/.codex/auth.json"
    [ -f "$a1" ] || { echo "auth.json not found"; return; }
    local email plan until days
    email=$(_jwt_email "$a1")
    read -r plan until < <(_jwt_plan "$a1")
    if [ -n "$until" ]; then
        local ts now
        ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${until:0:19}" +%s 2>/dev/null || date -d "${until:0:19}" +%s 2>/dev/null)
        now=$(date +%s)
        days=$(( (ts - now) / 86400 + 1 ))
    fi
    echo "${email} · ${plan^^} · D-${days}"
}

# ── codex-pick -----------------------------------──────────

codex-pick() {
    clear
    local GREEN CYAN YELLOW RED GRAY RESET
    GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[0;33m'
    RED='\033[0;31m'; GRAY='\033[0;90m'; RESET='\033[0m'

    echo ""
    echo -e "  ${CYAN}+----------------------------------+${RESET}"
    echo -e "  ${CYAN}|       Codex Account Switch       |${RESET}"
    echo -e "  ${CYAN}+----------------------------------+${RESET}"
    echo ""

    local current="$HOME/.codex/auth.json"
    if [ -f "$current" ]; then
        local cemail cplan cuntil cdays
        cemail=$(_jwt_email "$current")
        read -r cplan cuntil < <(_jwt_plan "$current")
        if [ -n "$cuntil" ]; then
            local cts now
            cts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${cuntil:0:19}" +%s 2>/dev/null || date -d "${cuntil:0:19}" +%s 2>/dev/null)
            now=$(date +%s)
            cdays=$(( (cts - now) / 86400 + 1 ))
        fi
        echo -e "  Active: ${GREEN}${cemail}${RESET}  ${GRAY}(D-${cdays})${RESET}"
        echo ""
    fi

    local accounts=() paths=() emails=()
    local idx=1
    for n in 1 2 3 4; do
        local f="$HOME/.codex${n}/auth.json"
        [ -f "$f" ] || continue
        local email plan until days
        email=$(_jwt_email "$f")
        read -r plan until < <(_jwt_plan "$f")
        if [ -n "$until" ]; then
            local ts now
            ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${until:0:19}" +%s 2>/dev/null || date -d "${until:0:19}" +%s 2>/dev/null)
            now=$(date +%s)
            days=$(( (ts - now) / 86400 + 1 ))
        fi
        local datestr=""
        [ -n "$until" ] && datestr=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${until:0:19}" "+%m/%d" 2>/dev/null || date -d "${until:0:19}" "+%m/%d" 2>/dev/null)

        local marker=""
        if [ "$(shasum -a 256 "$f" 2>/dev/null | cut -d' ' -f1)" = "$(shasum -a 256 "$current" 2>/dev/null | cut -d' ' -f1)" ]; then
            marker="  ${GREEN}<-- active${RESET}"
        fi

        local expire_color="$GRAY"
        [ -n "$days" ] && {
            [ "$days" -le 3 ] && expire_color="$RED"
            [ "$days" -gt 3 ] && [ "$days" -le 7 ] && expire_color="$YELLOW"
        }

        echo -e "  [${idx}] ${email}${marker}"
        echo -e "      ${plan^^}${expire_color} / expires D-${days} (${datestr})${RESET}"

        accounts+=("$idx"); paths+=("$f"); emails+=("$email")
        ((idx++))
    done

    if [ ${#accounts[@]} -eq 0 ]; then
        echo ""
        echo -e "  ${RED}No accounts found.${RESET}"
        echo -e "  ${GRAY}Run codex2 to add an account, or codex-add.${RESET}"
        echo ""
        return
    fi

    echo ""
    echo -e "  ${GRAY}-----------------------------------${RESET}"
    echo -e "  ${GRAY}Enter a number to switch the${RESET}"
    echo -e "  ${GRAY}Codex Desktop account.${RESET}"
    echo ""
    printf "  Choice (1-%d): " ${#accounts[@]}
    read -r choice

    local found=0
    for i in "${!accounts[@]}"; do
        if [ "${accounts[$i]}" = "$choice" ]; then
            cp "${paths[$i]}" "$current"
            echo ""
            echo -e "  ${GREEN}Switched -> ${emails[$i]}${RESET}"
            echo ""
            found=1
            break
        fi
    done
    [ "$found" -eq 0 ] && { echo ""; echo -e "  ${RED}Invalid choice. Canceled.${RESET}"; echo ""; }
}

# ── codex-add -----------------------------------──────────

codex-add() {
    clear
    local GREEN CYAN YELLOW RED GRAY RESET
    GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[0;33m'
    RED='\033[0;31m'; GRAY='\033[0;90m'; RESET='\033[0m'

    echo ""
    echo -e "  ${CYAN}+----------------------------------+${RESET}"
    echo -e "  ${CYAN}|       Codex Add Account          |${RESET}"
    echo -e "  ${CYAN}+----------------------------------+${RESET}"
    echo ""

    local found="" num=3
    for n in 3 4; do
        if [ ! -f "$HOME/.codex${n}/auth.json" ]; then
            found="$HOME/.codex${n}"
            num=$n
            break
        fi
    done

    if [ -z "$found" ]; then
        echo -e "  ${RED}All 4 slots are full.${RESET}"
        echo -e "  ${GRAY}Delete an existing account folder first.${RESET}"
        echo ""
        return
    fi

    echo -e "  Free slot: ${YELLOW}codex${num}${RESET}"
    echo ""
    mkdir -p "$found"

    echo -e "  ${GRAY}-----------------------------------${RESET}"
    echo -e "  A browser will open."
    echo -e "  Login with your new account."
    echo ""
    echo -e "  ${GRAY}When Codex CLI appears,${RESET}"
    echo -e "  ${GRAY}type /exit or Ctrl+C to close it.${RESET}"
    echo -e "  ${GRAY}-----------------------------------${RESET}"
    echo ""
    printf "  Press Enter to continue..."
    read -r

    CODEX_HOME="$found" codex

    if [ ! -f "$found/auth.json" ]; then
        echo ""
        echo -e "  ${RED}Login was not completed.${RESET}"
        echo ""
        return
    fi

    echo ""
    echo -e "  ${GRAY}Setting up session/skill sharing...${RESET}"
    local src="$HOME/.codex" linked=0 failed=0
    for item in "$src"/*; do
        local name
        name=$(basename "$item")
        [ "$name" = "auth.json" ] && continue
        [ -e "$found/$name" ] && rm -rf "$found/$name"
        ln -s "$item" "$found/$name" 2>/dev/null && ((linked++)) || ((failed++))
    done

    local email
    email=$(_jwt_email "$found/auth.json")
    echo ""
    echo -e "  ${GREEN}Added!${RESET} ${email}"
    [ "$linked" -gt 0 ] && echo -e "  ${GRAY}($linked items shared)${RESET}"
    [ "$failed" -gt 0 ] && echo -e "  ${GRAY}($failed items skipped)${RESET}"
    echo ""
    echo -e "  ${CYAN}Use codex-pick to switch!${RESET}"
    echo ""
}
