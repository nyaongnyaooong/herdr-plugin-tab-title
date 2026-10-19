import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('watch', Path(__file__).with_name('watch-windows.py'))
watch = importlib.util.module_from_spec(spec)
spec.loader.exec_module(watch)


class PlanTests(unittest.TestCase):
    def test_focused_title_truncation_rename_and_restore(self):
        tabs = [{'tab_id': 't1', 'label': 'work'}]
        agents = [{'tab_id': 't1', 'agent': 'claude', 'focused': False, 'terminal_title_stripped': 'other'},
                  {'tab_id': 't1', 'agent': 'claude', 'focused': True, 'terminal_title_stripped': '긴 제목을 붙인다'}]
        saved = watch.plan(tabs, agents, {}, 5)
        self.assertEqual(saved['t1']['applied'], 'work-긴 제목을…')
        tabs[0]['label'] = saved['t1']['applied']
        self.assertEqual(watch.plan(tabs, [], saved)['t1']['applied'], 'work')
        tabs[0]['label'] = 'renamed'
        self.assertEqual(watch.plan(tabs, agents, saved)['t1']['base'], 'renamed')

    def test_placeholder_and_closed_tabs(self):
        self.assertEqual(watch.plan([], [], {'closed': {'base': 'old'}}), {})
        result = watch.plan([{'tab_id': 't1', 'label': 'work'}], [{'tab_id': 't1', 'agent': 'claude', 'terminal_title_stripped': 'Claude Code'}], {})
        self.assertEqual(result['t1']['applied'], 'work')


if __name__ == '__main__':
    unittest.main()
