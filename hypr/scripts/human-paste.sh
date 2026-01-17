#!/bin/bash
# human-like paste script for wayland (hyprland)
# pastes clipboard content character by character with random delays
# press the same hotkey again to stop all running instances

PIDFILE="/tmp/human-paste.pid"
MAX_DELAY=0.08

cleanup() {
    # remove our pid from the file
    if [[ -f "$PIDFILE" ]]; then
        grep -v "^$$\$" "$PIDFILE" > "${PIDFILE}.tmp" 2>/dev/null
        mv "${PIDFILE}.tmp" "$PIDFILE" 2>/dev/null
        # if file is empty, remove it
        [[ ! -s "$PIDFILE" ]] && rm -f "$PIDFILE" 2>/dev/null
    fi
}

trap cleanup EXIT

# check if any instances are running
if [[ -f "$PIDFILE" ]]; then
    running_pids=$(cat "$PIDFILE" 2>/dev/null)
    if [[ -n "$running_pids" ]]; then
        # kill all running instances
        while IFS= read -r pid; do
            if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null
            fi
        done <<< "$running_pids"
        rm -f "$PIDFILE" 2>/dev/null
        notify-send "Human Paste" "Stopped" -t 1000
        exit 0
    fi
fi

# register our pid
echo "$$" >> "$PIDFILE"

# get clipboard content and strip trailing newlines
CLIPBOARD=$(wl-paste 2>/dev/null | sed 's/[[:space:]]*$//')

if [[ -z "$CLIPBOARD" ]]; then
    notify-send "Clipboard Empty" "Nothing to paste" -t 2000
    exit 1
fi

# type each character with a random delay
printf '%s' "$CLIPBOARD" | while IFS= read -r -n1 char; do
    if [[ -n "$char" ]]; then
        # handle special characters for wtype
        case "$char" in
            $'\t') wtype -k Tab ;;
            ' ') wtype -k space ;;
            *) wtype -- "$char" ;;
        esac
    elif [[ -z "$char" ]]; then
        # handle newline
        wtype -k Return
    fi
    
    # random delay between 0 and MAX_DELAY seconds
    delay=$(awk -v max="$MAX_DELAY" 'BEGIN{srand(); printf "%.3f", rand()*max}')
    sleep "$delay"
done

# press enter after finishing
# wtype -k Return
