# Decide each tab's label from the tab list, the agent list and the saved state.
# state[tab_id] = {base, applied}: base is the name the user gave, applied is the label we last set.
# A label that differs from applied was changed by the user (or the tab is new), so it becomes the base.
# Output: {tab_id: {base, applied, current}} where applied is the label the tab should have now.
def short($n): if length > $n then (.[0:$n] | sub(" +$"; "")) + "…" else . end;

($agents
  | map(select(.agent == "claude"
      and (.terminal_title_stripped // "") != ""
      and .terminal_title_stripped != "Claude Code"))
  | sort_by(.focused | not)
  | group_by(.tab_id) | map({key: .[0].tab_id, value: .[0].terminal_title_stripped}) | from_entries
) as $titles
| $tabs
| map(
    .tab_id as $id
    | ($state[$id]) as $s
    | (if $s != null and $s.applied == .label then $s.base else .label end) as $base
    | {key: $id, value: {
        base: $base,
        current: .label,
        applied: (if $titles[$id] then "\($base)-\($titles[$id] | short($max))" else $base end)
      }})
| from_entries
