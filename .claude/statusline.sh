#!/bin/bash
# Statusline: fast + best-effort. Never block on network.

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // empty' 2>/dev/null)
branch=$(git branch --show-current 2>/dev/null || echo "no-git")
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)

status="$model"

if [ "$branch" != "no-git" ] && [ -n "$branch" ]; then
  status="$status | git:$branch"
fi

if [ -n "$used" ] && [ "$used" != "null" ]; then
  status="$status | context:${used}% used"
fi

# --- Claude Max usage indicator (non-blocking; cached; background refresh) ---
# Disable: CLAUDE_STATUSLINE_USAGE=0
if [ "${CLAUDE_STATUSLINE_USAGE:-1}" != "0" ]; then
  CACHE="${HOME}/.claude/.oauth_usage_cache.json"
  LOCKDIR="${HOME}/.claude/.oauth_usage_cache.lock"
  TTL="${CLAUDE_STATUSLINE_USAGE_TTL:-300}"

  now=$(date +%s)
  mtime=0
  if [ -f "$CACHE" ]; then
    # macOS stat; fallback to 0 if unknown
    mtime=$(stat -f %m "$CACHE" 2>/dev/null || echo 0)
  fi

  # If stale, kick off a background refresh, but NEVER wait for it.
  if [ $((now - mtime)) -gt "$TTL" ]; then
    # Break stale locks older than 2x TTL (background subshell may have been killed)
    if [ -d "$LOCKDIR" ]; then
      lock_mtime=$(stat -f %m "$LOCKDIR" 2>/dev/null || echo 0)
      if [ $((now - lock_mtime)) -gt $((TTL * 2)) ]; then
        rmdir "$LOCKDIR" 2>/dev/null || true
      fi
    fi
    # crude lock: mkdir is atomic
    if mkdir "$LOCKDIR" 2>/dev/null; then
      (
        # always release lock
        trap 'rmdir "$LOCKDIR" 2>/dev/null || true' EXIT

        creds_json="$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null || true)"
        token="$(echo "$creds_json" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null || true)"
        [ -n "$token" ] || exit 0

        tmp="${CACHE}.tmp.$$"
        curl -sS --max-time 1.0 \
          -H "Accept: application/json" \
          -H "Authorization: Bearer ${token}" \
          -H "anthropic-beta: oauth-2025-04-20" \
          "https://api.anthropic.com/api/oauth/usage" \
          > "$tmp" 2>/dev/null || { rm -f "$tmp"; exit 0; }

        # Only swap in if valid JSON with actual usage data (not an error response)
        if jq -e '.five_hour and .seven_day' >/dev/null 2>&1 < "$tmp"; then
          mv "$tmp" "$CACHE"
        else
          rm -f "$tmp"
          # Touch cache to reset TTL even on failure — prevents request storms
          touch "$CACHE"
        fi
      ) >/dev/null 2>&1 &
    fi
  fi

  # Render usage *only from cache* (no waiting)
  if [ -f "$CACHE" ]; then
    five_hour="$(jq -r '.five_hour.utilization // empty' "$CACHE" 2>/dev/null || true)"
    five_reset="$(jq -r '.five_hour.resets_at // empty' "$CACHE" 2>/dev/null || true)"
    seven_day="$(jq -r '.seven_day.utilization // empty' "$CACHE" 2>/dev/null || true)"
    seven_reset="$(jq -r '.seven_day.resets_at // empty' "$CACHE" 2>/dev/null || true)"

    fmt_reset() {
      local iso="$1"
      local kind="$2"  # "5h" or "7d"
      [ -n "$iso" ] && [ "$iso" != "null" ] || { echo ""; return; }

      if command -v gdate >/dev/null 2>&1; then
        if [ "$kind" = "7d" ]; then
          gdate -d "$iso" +"%a %H:%M" 2>/dev/null || echo ""
        else
          gdate -d "$iso" +"%H:%M" 2>/dev/null || echo ""
        fi
      else
        # Best-effort: no timezone conversion; extract pieces from ISO
        if [ "$kind" = "7d" ]; then
          local d t
          d="$(echo "$iso" | sed -E 's/^([0-9]{4})-([0-9]{2})-([0-9]{2}).*/\2-\3/')"
          t="$(echo "$iso" | sed -E 's/.*T([0-9]{2}:[0-9]{2}).*/\1/')"
          echo "$d $t" | grep -E '^[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$' || echo ""
        else
          echo "$iso" | sed -E 's/.*T([0-9]{2}:[0-9]{2}).*/\1/' | grep -E '^[0-9]{2}:[0-9]{2}$' || echo ""
        fi
      fi
    }

    usage_bits=()
    if [ -n "$five_hour" ] && [ "$five_hour" != "null" ]; then
      r="$(fmt_reset "$five_reset" "5h")"
      if [ -n "$r" ]; then usage_bits+=("5h ${five_hour}% ↻${r}")
      else usage_bits+=("5h ${five_hour}%")
      fi
    fi
    if [ -n "$seven_day" ] && [ "$seven_day" != "null" ]; then
      r="$(fmt_reset "$seven_reset" "7d")"
      if [ -n "$r" ]; then usage_bits+=("7d ${seven_day}% ↻${r}")
      else usage_bits+=("7d ${seven_day}%")
      fi
    fi

    if [ "${#usage_bits[@]}" -gt 0 ]; then
      status="$status | usage:$(IFS=' | '; echo "${usage_bits[*]}")"
    fi
  fi
fi

echo "$status"
