"""Native Windows tab-title watcher; no jq or POSIX shell required."""
import json
import os
from pathlib import Path
import subprocess
import sys
import time


def plan(tabs, agents, state, maximum=12):
    titles = {}
    for agent in sorted(agents, key=lambda a: not a.get('focused', False)):
        title = agent.get('terminal_title_stripped') or ''
        if agent.get('agent') == 'claude' and title and title != 'Claude Code':
            titles.setdefault(agent['tab_id'], title)
    result = {}
    for tab in tabs:
        key, current = tab['tab_id'], tab['label']
        saved = state.get(key, {})
        base = saved.get('base', current) if saved.get('applied') == current else current
        title = titles.get(key, '')
        if len(title) > maximum:
            title = title[:maximum].rstrip(' ') + '…'
        result[key] = {'base': base, 'current': current, 'applied': base + '-' + title if title else base}
    return result


def rpc(*args):
    output = subprocess.check_output([os.environ.get('HERDR_BIN_PATH', 'herdr'), *args],
                                     encoding='utf-8', errors='replace', creationflags=subprocess.CREATE_NO_WINDOW)
    return json.loads(output)['result']


def main():
    state = Path(os.environ.get('HERDR_PLUGIN_STATE_DIR') or Path(os.environ['LOCALAPPDATA']) / 'herdr/plugins/tab-title')
    state.mkdir(parents=True, exist_ok=True)
    path = state / 'tabs.json'
    maximum = max(1, int(os.environ.get('TAB_TITLE_MAX', '12')))
    interval = max(1, float(os.environ.get('TAB_TITLE_INTERVAL', '3')))
    failures = 0
    while True:
        try:
            saved = json.loads(path.read_text(encoding='utf-8')) if path.exists() else {}
            result = plan(rpc('tab', 'list')['tabs'], rpc('agent', 'list')['agents'], saved, maximum)
            for key, row in result.items():
                if row['current'] != row['applied']:
                    rpc('tab', 'rename', key, row['applied'])
            temporary = path.with_suffix('.tmp')
            temporary.write_text(json.dumps({k: {'base': v['base'], 'applied': v['applied']} for k, v in result.items()}, ensure_ascii=False), encoding='utf-8')
            temporary.replace(path)
            failures = 0
        except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
            print(str(error), file=sys.stderr, flush=True)
            failures += 1
            if failures >= 10:
                return 1
        time.sleep(interval)


def start():
    state = Path(os.environ['HERDR_PLUGIN_STATE_DIR'])
    with (state / 'watch.log').open('a', encoding='utf-8') as output, (state / 'watch.err').open('a', encoding='utf-8') as errors:
        process = subprocess.Popen([sys.executable, str(Path(__file__).resolve())], stdin=subprocess.DEVNULL,
                                   stdout=output, stderr=errors, close_fds=True,
                                   creationflags=subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP)
    (state / 'watch.pid').write_text(str(process.pid), encoding='ascii')
    return 0


if __name__ == '__main__':
    raise SystemExit(start() if '--watch-start' in sys.argv else main())
