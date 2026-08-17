#!/usr/bin/env bash
# waybar custom/media module — playerctl backend
# Outputs JSON: {"text": "...", "class": "playing|paused", "alt": "playing|paused", "tooltip": "..."}

set -euo pipefail

MAX_LEN=40

# Bail out cleanly (empty text) if playerctl isn't installed or no player is active
if ! command -v playerctl >/dev/null 2>&1; then
    echo '{"text": "", "class": "stopped"}'
    exit 0
fi

STATUS="$(playerctl status 2>/dev/null || true)"

if [[ -z "$STATUS" ]]; then
    echo '{"text": "", "class": "stopped"}'
    exit 0
fi

ARTIST="$(playerctl metadata artist 2>/dev/null || true)"
TITLE="$(playerctl metadata title 2>/dev/null || true)"

if [[ -z "$TITLE" ]]; then
    echo '{"text": "", "class": "stopped"}'
    exit 0
fi

if [[ -n "$ARTIST" ]]; then
    RAW_TEXT="$ARTIST - $TITLE"
else
    RAW_TEXT="$TITLE"
fi

# Truncate long titles
if (( ${#RAW_TEXT} > MAX_LEN )); then
    RAW_TEXT="${RAW_TEXT:0:MAX_LEN}…"
fi

case "$STATUS" in
    Playing) CLASS="playing" ;;
    Paused)  CLASS="paused" ;;
    *)       CLASS="stopped" ;;
esac

# JSON-escape any quotes/backslashes in the text
escape_json() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

TEXT_ESCAPED="$(escape_json "$RAW_TEXT")"

printf '{"text": "%s", "class": "%s", "alt": "%s", "tooltip": "%s"}\n' \
    "$TEXT_ESCAPED" "$CLASS" "$CLASS" "$TEXT_ESCAPED"
