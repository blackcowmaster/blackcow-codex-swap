#!/usr/bin/env bash
# === blackcow-codex-swap (macOS/Linux) ===
# Multi-account switcher for OpenAI Codex
# Source this in your ~/.bashrc or ~/.zshrc:
#   source /path/to/codex-swap.sh
# https://github.com/blackcowmaster/blackcow-codex-swap

_codex_cli() {
    local external_codex

    if [ -n "${CODEX_CLI_PATH:-}" ] && [ -x "$CODEX_CLI_PATH" ]; then
        "$CODEX_CLI_PATH" "$@"
        return
    fi

    if [ "$(uname -s 2>/dev/null)" = "Darwin" ] && [ -x "/Applications/Codex.app/Contents/Resources/codex" ]; then
        "/Applications/Codex.app/Contents/Resources/codex" "$@"
        return
    fi

    if [ -n "${BASH_VERSION:-}" ]; then
        external_codex=$(type -P codex 2>/dev/null || true)
    elif [ -n "${ZSH_VERSION:-}" ]; then
        external_codex=$(whence -p codex 2>/dev/null || true)
    else
        external_codex=$(command -v codex 2>/dev/null || true)
    fi

    if [ -n "$external_codex" ] && [ -x "$external_codex" ]; then
        "$external_codex" "$@"
        return
    fi

    echo "codex CLI not found. Install Codex or set CODEX_CLI_PATH." >&2
    return 127
}

codex() { CODEX_HOME="${CODEX_HOME:-$HOME/.codex}" _codex_cli "$@"; }
codex2() { CODEX_HOME="$HOME/.codex2" _codex_cli "$@"; }
codex3() { CODEX_HOME="$HOME/.codex3" _codex_cli "$@"; }
codex4() { CODEX_HOME="$HOME/.codex4" _codex_cli "$@"; }

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
    print(str(auth.get('chatgpt_plan_type', '?')) + '\t' + str(auth.get('chatgpt_subscription_active_until', '')))
except:
    print('?\t')
" 2>/dev/null
}

_upper() {
    printf "%s" "$1" | tr '[:lower:]' '[:upper:]'
}

_auth_hash() {
    [ -f "$1" ] || return 1
    shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1
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
    echo "${email} · $(_upper "$plan") · D-${days}"
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
    local current_hash=""
    [ -f "$current" ] && current_hash=$(_auth_hash "$current")
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

    local idx=1
    for n in 1 2 3 4; do
        local f="$HOME/.codex${n}/auth.json"
        [ -f "$f" ] || continue
        local slot_hash
        slot_hash=$(_auth_hash "$f")
        if [ -n "$current_hash" ] && [ "$slot_hash" = "$current_hash" ]; then
            continue
        fi
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
        if [ -n "$current_hash" ] && [ "$slot_hash" = "$current_hash" ]; then
            marker="  ${GREEN}<-- active${RESET}"
        fi

        local expire_color="$GRAY"
        [ -n "$days" ] && {
            [ "$days" -le 3 ] && expire_color="$RED"
            [ "$days" -gt 3 ] && [ "$days" -le 7 ] && expire_color="$YELLOW"
        }

        echo -e "  [${idx}] ${email}${marker}"
        echo -e "      $(_upper "$plan")${expire_color} / expires D-${days} (${datestr})${RESET}"

        eval "path_${idx}=\$f"
        eval "email_${idx}=\$email"
        idx=$((idx + 1))
    done

    if [ "$idx" -eq 1 ]; then
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
    printf "  Choice (1-%d): " $((idx - 1))
    read -r choice

    case "$choice" in
        1|2|3|4) ;;
        *)
            echo ""
            echo -e "  ${RED}Invalid choice. Canceled.${RESET}"
            echo ""
            return 1
            ;;
    esac

    local target_path="" target_email=""
    eval "target_path=\${path_${choice}:-}"
    eval "target_email=\${email_${choice}:-}"
    if [ -z "$target_path" ]; then
        echo ""
        echo -e "  ${RED}Invalid choice. Canceled.${RESET}"
        echo ""
        return 1
    fi

    cp "$target_path" "$current"
    echo ""
    echo -e "  ${GREEN}Switched -> ${target_email}${RESET}"
    echo ""
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

    local found="" num=2
    for n in 2 3 4; do
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

    CODEX_HOME="$found" _codex_cli
    local codex_status=$?

    if [ ! -f "$found/auth.json" ]; then
        echo ""
        echo -e "  ${RED}Login was not completed.${RESET}"
        [ "$codex_status" -ne 0 ] && echo -e "  ${GRAY}Codex CLI exited with status ${codex_status}.${RESET}"
        echo ""
        return "$codex_status"
    fi

    echo ""
    echo -e "  ${GRAY}Setting up session/skill sharing...${RESET}"
    local src="$HOME/.codex" linked=0 failed=0
    for item in "$src"/*; do
        [ -e "$item" ] || continue
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

codex-clear() {
    local slot="$1"
    case "$slot" in
        1|2|3|4) ;;
        *)
            echo "Usage: codex-clear <1|2|3|4>"
            return 2
            ;;
    esac

    local authfile="$HOME/.codex${slot}/auth.json"
    if [ ! -f "$authfile" ]; then
        echo "codex${slot} is already empty."
        return 0
    fi

    local email
    email=$(_jwt_email "$authfile")
    printf "Clear codex%s (%s)? This removes only %s [y/N]: " "$slot" "$email" "$authfile"
    local answer
    read -r answer
    case "$answer" in
        y|Y|yes|YES)
            rm -f "$authfile"
            echo "Cleared codex${slot}."
            ;;
        *)
            echo "Canceled."
            return 1
            ;;
    esac
}
