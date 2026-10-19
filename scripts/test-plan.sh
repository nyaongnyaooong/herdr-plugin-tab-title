#!/bin/sh
# Self-check for plan.jq: run with `sh scripts/test-plan.sh`.
set -eu
cd "$(dirname "$0")"

plan() { jq -cn --argjson max 5 --argjson tabs "$1" --argjson agents "$2" --argjson state "$3" -f plan.jq; }
check() { [ "$1" = "$2" ] || { echo "FAIL: $3"; echo "  got:  $1"; echo "  want: $2"; exit 1; }; }

tabs='[{"tab_id":"t1","label":"duty"},{"tab_id":"t2","label":"main"}]'
agents='[{"tab_id":"t1","agent":"claude","focused":false,"terminal_title_stripped":"Slack 메시지 확인"},
         {"tab_id":"t2","agent":"claude","focused":false,"terminal_title_stripped":"Claude Code"}]'

out=$(plan "$tabs" "$agents" '{}')
check "$(echo "$out" | jq -r '.t1.applied')" "duty-Slack…" "new tab gets base + truncated title"
check "$(echo "$out" | jq -r '.t2.applied')" "main" "placeholder title is ignored"

# Our own label is not mistaken for a user rename.
state='{"t1":{"base":"duty","applied":"duty-Slack…"}}'
tabs='[{"tab_id":"t1","label":"duty-Slack…"}]'
agents='[{"tab_id":"t1","agent":"claude","focused":false,"terminal_title_stripped":"새 제목"}]'
check "$(plan "$tabs" "$agents" "$state" | jq -r '.t1.applied')" "duty-새 제목" "title change keeps base"

# A hand rename becomes the new base.
tabs='[{"tab_id":"t1","label":"hermod"}]'
check "$(plan "$tabs" "$agents" "$state" | jq -r '.t1.applied')" "hermod-새 제목" "user rename becomes base"

# Claude gone: back to the bare name.
check "$(plan '[{"tab_id":"t1","label":"duty-Slack…"}]' '[]' "$state" | jq -r '.t1.applied')" "duty" "no claude restores base"

# Focused claude pane wins inside a tab.
tabs='[{"tab_id":"t1","label":"x"}]'
agents='[{"tab_id":"t1","agent":"claude","focused":false,"terminal_title_stripped":"aaa"},
         {"tab_id":"t1","agent":"claude","focused":true,"terminal_title_stripped":"bbb"}]'
check "$(plan "$tabs" "$agents" '{}' | jq -r '.t1.applied')" "x-bbb" "focused pane wins"

echo ok
