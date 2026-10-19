# herdr-plugin-tab-title

herdr 탭 이름 뒤에 그 탭에서 돌고 있는 Claude 세션 제목 앞부분을 붙인다: `duty-Slack 확인 요청…`

- 탭 이름을 직접 바꾸면 그 이름이 새 기본 이름이 된다.
- Claude 가 끝나면 기본 이름으로 돌아간다.
- 탭에 Claude pane 이 여럿이면 포커스된 pane 의 제목을 쓴다.

## 설치

```sh
herdr plugin link .
herdr plugin action invoke watch-start --plugin tab-title   # 이후엔 서버 시작 시 자동 실행
```

## Windows

Windows에서는 Python 3.9+와 PowerShell만 사용하며 Bash나 jq는 필요하지 않다. `HERDR_PYTHON`으로 Python 경로를 지정할 수 있다. 플러그인 시작 시 자동 실행되며, 수동으로 시작하려면 `herdr plugin action invoke watch-start-windows --plugin tab-title`을 실행한다. Windows 상태 파일은 Herdr가 제공하는 플러그인 상태 경로(기본 `%LOCALAPPDATA%\herdr\plugins\tab-title`)에 저장된다.

`python scripts/test_windows.py`로 제목 단축, 포커스 우선순위, 사용자 이름 변경 및 기본 이름 복원을 검증한다.

## 설정 (환경 변수)

- `TAB_TITLE_MAX` — 붙일 제목 글자 수 (기본 12)
- `TAB_TITLE_INTERVAL` — 확인 주기 초 (기본 3)

상태는 `~/.local/state/herdr/plugins/tab-title/tabs.json` 에 탭별 `{base, applied}` 로 저장된다.

## 테스트

```sh
sh scripts/test-plan.sh
```
