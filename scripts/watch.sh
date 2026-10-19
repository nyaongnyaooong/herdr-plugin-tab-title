#!/bin/sh
# Poll herdr and keep every tab labelled "name-<Claude session title>…".
# The user's own name is remembered in state so renaming a tab by hand still works.
set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
herdr=${HERDR_BIN_PATH:-herdr}
state_file=${HERDR_PLUGIN_STATE_DIR:?}/tabs.json
max=${TAB_TITLE_MAX:-12}
interval=${TAB_TITLE_INTERVAL:-3}
tab=$(printf '\t')

[ -s "$state_file" ] || echo '{}' >"$state_file"
fails=0

while :; do
    # shortcut: polls every few seconds; switch to an event hook if herdr adds a title-changed event.
    if tabs=$("$herdr" tab list 2>/dev/null) && agents=$("$herdr" agent list 2>/dev/null); then
        fails=0
        if plan=$(jq -n --argjson max "$max" \
            --argjson tabs "$(printf '%s' "$tabs" | jq -c '.result.tabs')" \
            --argjson agents "$(printf '%s' "$agents" | jq -c '.result.agents')" \
            --argjson state "$(cat "$state_file")" \
            -f "$script_dir/plan.jq"); then
            renames=$(printf '%s' "$plan" | jq -r 'to_entries[] | select(.value.applied != .value.current) | "\(.key)\t\(.value.applied)"')
            failed=0
            while IFS=$tab read -r id label; do
                [ -n "$id" ] || continue
                "$herdr" tab rename "$id" "$label" >/dev/null 2>&1 || { echo "rename failed: $id" >&2; failed=1; }
            done <<EOF
$renames
EOF
            # A failed rename leaves the old label, which the next round would mistake for a user rename.
            if [ "$failed" -eq 0 ]; then
                printf '%s' "$plan" | jq 'map_values({base, applied})' >"$state_file.tmp" && mv "$state_file.tmp" "$state_file"
            fi
        fi
    else
        # The server is gone; the next startup hook launches a fresh loop.
        fails=$((fails + 1))
        [ "$fails" -lt 10 ] || exit 0
    fi
    sleep "$interval"
done
