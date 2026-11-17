"""Tests for counting accuracy and Git-history edge cases; no RTL is modified."""

from datetime import date
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET


SCRIPT = Path(__file__).resolve().parents[1] / "sv_stats.py"
SPEC = importlib.util.spec_from_file_location("sv_stats", SCRIPT)
stats = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(stats)
CONFIG = json.loads(SCRIPT.with_name("sv_stats_config.json").read_text())


class CountingTests(unittest.TestCase):
    def test_comments_strings_and_escaped_identifiers(self):
        source = '''// no code
/* comment
   still comment */ module example;
  string url = "https://host/*literal*/"; // trailing comment
  logic \\name//identifier ;
  /* middle */ logic a; /* tail */

endmodule
'''
        self.assertEqual(stats.count_lines(source), {"physical_lines": 8, "code_lines": 5})

    def test_multiline_comments_and_escaped_quotes(self):
        source = '/*\n comment\n*/\nstring s = "say \\"hi\\" //";\n// end\n'
        self.assertEqual(stats.count_lines(source)["code_lines"], 1)
        self.assertEqual(stats.count_lines("")["physical_lines"], 0)

    def test_scope(self):
        self.assertTrue(stats.included("IP/fifo/async_fifo.v", CONFIG))
        for path in ["IP/a/tb_dut.sv", "IP/a/dut_golden.sv", "IP/a/reference/dut.sv",
                     "UVM/rtl/dut.sv", "IP/a/question.md", "IP/a/.svlangserver/probe.sv"]:
            self.assertFalse(stats.included(path, CONFIG), path)

    def test_readme_changes_only_marker_contents(self):
        original = "user intro\n" + stats.START + "\nold\n" + stats.END + "\nuser footer\n"
        replacement = stats.START + "\nnew\n" + stats.END
        self.assertEqual(stats.update_readme(original, replacement),
                         "user intro\n" + replacement + "\nuser footer\n")
        with self.assertRaises(ValueError):
            stats.update_readme("no markers", replacement)

    def test_empty_chart_is_valid_svg(self):
        chart = stats.chart_svg({"timezone": "America/Los_Angeles", "recent": [
            {"date": "2026-11-15", "added": 0, "deleted": 0, "commits": 0},
            {"date": "2026-11-16", "added": 0, "deleted": 0, "commits": 0},
        ]})
        root = ET.fromstring(chart)
        self.assertEqual(root.attrib["viewBox"], "0 0 1040 350")
        self.assertNotIn("nan", chart.lower())


class HistoryTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="sv-stats-test-")
        self.addCleanup(self.temporary.cleanup)
        self.repo = Path(self.temporary.name)
        self.git("init", "-b", "main")
        self.git("config", "user.name", "Stats Test")
        self.git("config", "user.email", "stats@example.invalid")

    def git(self, *args, env=None):
        return subprocess.check_output(
            ["git", "-c", "commit.gpgsign=false", "-C", str(self.repo), *args],
            env=env, stderr=subprocess.PIPE,
        )

    def write(self, path, content):
        target = self.repo / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content)

    def commit(self, message, day):
        self.git("add", "--all")
        env = dict(os.environ, GIT_AUTHOR_DATE=f"2026-11-{day:02d}T12:00:00-08:00",
                   GIT_COMMITTER_DATE=f"2026-11-{day:02d}T12:00:00-08:00")
        self.git("commit", "-m", message, env=env)

    def collect(self):
        return stats.collect(self.repo, CONFIG, date(2026, 11, 16))

    def test_root_edit_rename_delete_and_ignored_files(self):
        self.write("IP/demo/dut.sv", "module demo;\n// comment\nlogic a;\n\nendmodule\n")
        self.write("IP/demo/tb_demo.sv", "ignored\n" * 40)
        self.write("IP/demo/demo_golden.sv", "ignored\n" * 42)
        self.write("UVM/demo.sv", "ignored\n" * 10)
        self.commit("root", 10)
        self.write("IP/demo/dut.sv", "module demo;\n// comment\nlogic a;\nlogic b;\n\nendmodule\n")
        self.commit("edit", 11)
        self.git("mv", "IP/demo/dut.sv", "IP/demo/renamed dut.sv")
        self.commit("rename", 12)
        # Uncommitted and untracked files must not alter the HEAD snapshot.
        self.write("IP/demo/renamed dut.sv", "working tree only\n")
        self.write("IP/demo/untracked.sv", "not committed\n")
        result = self.collect()
        self.assertEqual(result["current"], {"files": 1, "code_lines": 4, "physical_lines": 6})
        self.assertEqual((result["history"]["added"], result["history"]["deleted"]), (6, 0))
        self.assertEqual(result["history"]["daily"][-1]["added"], 0)
        (self.repo / "IP/demo/untracked.sv").unlink()
        self.git("rm", "-f", "IP/demo/renamed dut.sv")
        self.commit("delete", 13)
        result = self.collect()
        self.assertEqual(result["current"]["files"], 0)
        self.assertEqual((result["history"]["added"], result["history"]["deleted"]), (6, 6))

    def test_rename_across_scope_boundary_and_unusual_filename(self):
        self.write("IP/demo/tb_original.sv", "module demo;\nlogic a;\nendmodule\n")
        self.commit("excluded", 10)
        self.git("mv", "IP/demo/tb_original.sv", "IP/demo/name with\ttab.sv")
        self.commit("enter scope", 11)
        result = self.collect()
        self.assertEqual(result["history"]["added"], 3)
        self.assertEqual(result["current"]["files"], 1)
        self.git("mv", "IP/demo/name with\ttab.sv", "IP/demo/tb_again.sv")
        self.commit("leave scope", 12)
        result = self.collect()
        self.assertEqual((result["history"]["added"], result["history"]["deleted"]), (3, 3))

    def test_first_parent_merge_does_not_double_count(self):
        self.write("IP/demo/base.sv", "module base;\nendmodule\n")
        self.commit("root", 10)
        self.git("checkout", "-b", "feature")
        self.write("IP/demo/extra.sv", "module extra;\nendmodule\n")
        self.commit("feature", 11)
        self.git("checkout", "main")
        self.write("IP/demo/base.sv", "module base;\nlogic b;\nendmodule\n")
        self.commit("main edit", 12)
        env = dict(os.environ, GIT_AUTHOR_DATE="2026-11-13T12:00:00-08:00",
                   GIT_COMMITTER_DATE="2026-11-13T12:00:00-08:00")
        self.git("merge", "--no-ff", "feature", "-m", "merge feature", env=env)
        result = self.collect()
        self.assertEqual(result["history"]["added"], 5)
        self.assertEqual(result["history"]["commits"], 3)
        daily = {day["date"]: day for day in result["history"]["daily"]}
        self.assertNotIn("2026-11-11", daily)
        self.assertEqual(daily["2026-11-13"]["added"], 2)


if __name__ == "__main__":
    unittest.main()
