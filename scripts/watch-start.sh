#!/bin/sh
# Startup hooks are one-shot, so launch the sync loop detached and replace any previous one.
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
state=${HERDR_PLUGIN_STATE_DIR:-${XDG_STATE_HOME:-"$HOME/.local/state"}/herdr/plugins/tab-title}
mkdir -p "$state"
pid_file="$state/watch.pid"

if [ -f "$pid_file" ]; then
    old_pid=$(cat "$pid_file" 2>/dev/null || true)
    case "$(ps -p "$old_pid" -o args= 2>/dev/null || true)" in
        *tab-title/scripts/watch.sh*|*"$script_dir/watch.sh"*) kill "$old_pid" 2>/dev/null || true ;;
    esac
fi

HERDR_PLUGIN_STATE_DIR=$state nohup sh "$script_dir/watch.sh" >>"$state/watch.log" 2>&1 </dev/null &
echo "$!" >"$pid_file"
