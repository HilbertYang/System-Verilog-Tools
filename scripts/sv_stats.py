#!/usr/bin/env python3
"""Generate README statistics from committed RTL and first-parent Git history.

Uses only Python's standard library. Does not stage, commit, or push anything.
"""

from __future__ import annotations

import argparse
from collections import defaultdict
from datetime import date, datetime, timedelta
from fnmatch import fnmatchcase
from html import escape
import json
import math
from pathlib import Path, PurePosixPath
import subprocess
from zoneinfo import ZoneInfo


ROOT = Path(__file__).resolve().parents[1]
START = "<!-- SV-STATS:START -->"
END = "<!-- SV-STATS:END -->"


def git(repo: Path, *args: str) -> bytes:
    return subprocess.check_output(["git", "-C", str(repo), *args])


def included(path: str, config: dict) -> bool:
    p = PurePosixPath(path)
    return (
        p.suffix.lower() in config["extensions"]
        and any(path.startswith(root.rstrip("/") + "/") for root in config["roots"])
        and not any(fnmatchcase(path.lower(), pat.lower()) for pat in config["exclude"])
    )


def count_lines(source: str) -> dict[str, int]:
    """Count physical lines containing code, preserving strings/escaped identifiers.

    Code lines include mixed code/comment lines and preprocessor directives.
    This is a lexical line count, not a count of statements or synthesized gates.
    """
    block = string = False
    code_lines = 0
    for line in source.splitlines():
        i, has_code = 0, False
        while i < len(line):
            if block:
                end = line.find("*/", i)
                if end < 0:
                    break
                block, i = False, end + 2
            elif string:
                has_code = True
                if line[i] == "\\":
                    i += 2
                elif line[i] == '"':
                    string, i = False, i + 1
                else:
                    i += 1
            elif line.startswith("//", i):
                break
            elif line.startswith("/*", i):
                block, i = True, i + 2
            elif line[i] == '"':
                string, has_code, i = True, True, i + 1
            elif line[i] == "\\":
                # A Verilog escaped identifier ends at whitespace, not at //.
                has_code = True
                i += 1
                while i < len(line) and not line[i].isspace():
                    i += 1
            else:
                has_code |= not line[i].isspace()
                i += 1
        code_lines += int(has_code)
    return {"physical_lines": len(source.splitlines()), "code_lines": code_lines}


def numstat_records(raw: bytes):
    """Parse --numstat -z, including the three-field encoding of renames."""
    fields = iter(raw.split(b"\0"))
    for field in fields:
        if not field:
            continue
        added, deleted, name = field.split(b"\t", 2)
        if name:
            old = new = name.decode("utf-8", errors="surrogateescape")
        else:
            old = next(fields).decode("utf-8", errors="surrogateescape")
            new = next(fields).decode("utf-8", errors="surrogateescape")
        if added != b"-" and deleted != b"-":
            yield int(added), int(deleted), old, new


def blob(repo: Path, revision: str, path: str) -> str:
    return git(repo, "show", f"{revision}:{path}").decode("utf-8", errors="replace")


def collect(repo: Path, config: dict, as_of: date) -> dict:
    if git(repo, "rev-parse", "--is-shallow-repository").strip() == b"true":
        raise ValueError("Full Git history is required; fetch with --unshallow first.")
    timezone = ZoneInfo(config["timezone"])
    filenames = git(repo, "ls-tree", "-rz", "--name-only", "HEAD").split(b"\0")
    files = []
    for raw_path in filenames:
        path = raw_path.decode("utf-8", errors="surrogateescape")
        if path and included(path, config):
            files.append({"path": path, **count_lines(blob(repo, "HEAD", path))})

    days = defaultdict(lambda: {"added": 0, "deleted": 0, "commits": 0})
    last_change = None
    commits = git(repo, "log", "--first-parent", "--format=%H %ct %P", "HEAD")
    for row in commits.decode().splitlines():
        sha, timestamp, *parents = row.split()
        if parents:
            diff = git(repo, "diff-tree", "--no-commit-id", "--numstat", "-r", "-z",
                       "-M", parents[0], sha)
        else:
            diff = git(repo, "diff-tree", "--root", "--no-commit-id", "--numstat",
                       "-r", "-z", "-M", sha)
        added_total = deleted_total = 0
        relevant = False
        for added, deleted, old, new in numstat_records(diff):
            old_in, new_in = included(old, config), included(new, config)
            if not (old_in or new_in):
                continue
            relevant = True
            if old_in and new_in:
                added_total += added
                deleted_total += deleted
            elif new_in:
                # Renaming an excluded file into scope brings in its full contents.
                added_total += len(blob(repo, sha, new).splitlines())
            elif parents:
                deleted_total += len(blob(repo, parents[0], old).splitlines())
        if relevant:
            day = datetime.fromtimestamp(int(timestamp), timezone).date().isoformat()
            days[day]["added"] += added_total
            days[day]["deleted"] += deleted_total
            days[day]["commits"] += 1
            if last_change is None:
                last_change = sha

    chart_days = config["chart_days"]
    recent = []
    for offset in range(chart_days - 1, -1, -1):
        day = (as_of - timedelta(days=offset)).isoformat()
        recent.append({"date": day, **days.get(day, {"added": 0, "deleted": 0, "commits": 0})})
    return {
        "schema_version": 1,
        "as_of": as_of.isoformat(),
        "timezone": config["timezone"],
        "last_rtl_commit": last_change,
        "scope": config,
        "current": {
            "files": len(files),
            "code_lines": sum(f["code_lines"] for f in files),
            "physical_lines": sum(f["physical_lines"] for f in files),
        },
        "history": {
            "added": sum(d["added"] for d in days.values()),
            "deleted": sum(d["deleted"] for d in days.values()),
            "commits": sum(d["commits"] for d in days.values()),
            "daily": [{"date": day, **values} for day, values in sorted(days.items())],
        },
        "recent": recent,
        "files": sorted(files, key=lambda f: f["path"]),
    }


def chart_svg(stats: dict) -> str:
    recent = stats["recent"]
    width, height = 1040, 350
    left, right, top, bottom = 64, 1006, 112, 282
    maximum = max((d["added"] + d["deleted"] for d in recent), default=0)
    raw_tick = max(maximum, 4) / 4
    magnitude = 10 ** math.floor(math.log10(raw_tick))
    step = next(n * magnitude for n in (1, 2, 5, 10) if n * magnitude >= raw_tick)
    ceiling = step * 4
    added = sum(d["added"] for d in recent)
    deleted = sum(d["deleted"] for d in recent)
    active = sum(d["commits"] > 0 for d in recent)
    subtitle = f'{recent[0]["date"]} to {recent[-1]["date"]} · {stats["timezone"]}'
    svg = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
        '<title id="title">Daily RTL practice: committed lines added and deleted</title>',
        f'<desc id="desc">{escape(subtitle)}. {added} lines added, {deleted} deleted, {active} active days. Git physical-line changes include comments and blank lines.</desc>',
        '<rect x="1" y="1" width="1038" height="348" rx="18" fill="#101b2d" stroke="#29364d"/>',
        '<g font-family="-apple-system,BlinkMacSystemFont,Segoe UI,sans-serif">',
        '<text x="28" y="39" fill="#f0f5fc" font-size="21" font-weight="650">Daily RTL practice</text>',
        f'<text x="28" y="64" fill="#9dafc7" font-size="12">{escape(subtitle)}</text>',
        f'<text x="28" y="89" fill="#d4deed" font-size="13">{active} active days / {len(recent)} days</text>',
        '<rect x="722" y="29" width="10" height="10" rx="2" fill="#40d6b0"/>',
        f'<text x="740" y="39" fill="#d4deed" font-size="13">Added  +{added:,}</text>',
        '<rect x="872" y="29" width="10" height="10" rx="2" fill="#f38c83"/>',
        f'<text x="890" y="39" fill="#d4deed" font-size="13">Deleted  −{deleted:,}</text>',
    ]
    for index in range(5):
        value = step * index
        y = bottom - (bottom - top) * value / ceiling
        svg += [
            f'<path d="M {left} {y:.1f} H {right}" stroke="#29364d"/>',
            f'<text x="{left - 10}" y="{y + 4:.1f}" text-anchor="end" fill="#9dafc7" font-size="11">{value:g}</text>',
        ]
    slot = (right - left) / len(recent)
    for index, day in enumerate(recent):
        x = left + slot * index + slot * 0.18
        bar_width = slot * 0.64
        add_height = day["added"] * (bottom - top) / ceiling
        del_height = day["deleted"] * (bottom - top) / ceiling
        svg.append(f'<g><title>{day["date"]}: +{day["added"]}, −{day["deleted"]}; {day["commits"]} RTL commits</title>')
        if add_height:
            svg.append(f'<rect x="{x:.2f}" y="{bottom - add_height:.2f}" width="{bar_width:.2f}" height="{add_height:.2f}" fill="#40d6b0"/>')
        if del_height:
            svg.append(f'<rect x="{x:.2f}" y="{bottom - add_height - del_height:.2f}" width="{bar_width:.2f}" height="{del_height:.2f}" fill="#f38c83"/>')
        svg.append('</g>')
        if (index % 7 == 0 and index < len(recent) - 3) or index == len(recent) - 1:
            svg.append(f'<text x="{x + bar_width / 2:.2f}" y="305" text-anchor="middle" fill="#9dafc7" font-size="11">{day["date"][5:]}</text>')
    svg += [
        '<text x="28" y="331" fill="#9dafc7" font-size="11">IP implementation files · Git line changes, including comments and blank lines · no testbenches or reference files</text>',
        '</g></svg>',
    ]
    return "\n".join(svg) + "\n"


def readme_block(stats: dict) -> str:
    current, history = stats["current"], stats["history"]
    recent = stats["recent"]
    additions = sum(d["added"] for d in recent)
    deletions = sum(d["deleted"] for d in recent)
    return f'''{START}
| RTL implementation files | Current code lines | All-time added / deleted | Last {len(recent)} days added / deleted |
| ---: | ---: | ---: | ---: |
| {current["files"]:,} | {current["code_lines"]:,} | +{history["added"]:,} / −{history["deleted"]:,} | +{additions:,} / −{deletions:,} |

![Daily RTL practice](docs/stats/sv-activity.svg)

As of **{stats["as_of"]}** ({stats["timezone"]}). Counts use committed `HEAD`,
with implementation `.sv` / `.v` files under `IP/`; testbenches, golden files,
and reference files are excluded by filename. Current code lines exclude blank
and comment-only lines. Historical changes include all physical lines and use
first-parent commit dates. These measure repository activity, not literal
keystrokes or verified human-only authorship.

[Counting rules and local refresh](docs/sv-stats.md) · [Detailed data](docs/stats/sv-stats.json)
{END}'''


def update_readme(text: str, block: str) -> str:
    if text.count(START) != 1 or text.count(END) != 1:
        raise ValueError("README must contain exactly one SV-STATS marker pair.")
    before, rest = text.split(START, 1)
    _, after = rest.split(END, 1)
    if text.index(START) > text.index(END):
        raise ValueError("README statistics markers are reversed.")
    return before + block + after


def write_if_changed(path: Path, content: str) -> None:
    if not path.exists() or path.read_text(encoding="utf-8") != content:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--as-of", type=date.fromisoformat, help="Chart end date, YYYY-MM-DD")
    args = parser.parse_args()
    config = json.loads((ROOT / "scripts/sv_stats_config.json").read_text())
    if not 2 <= config["chart_days"] <= 90:
        raise ValueError("chart_days must be between 2 and 90.")
    as_of = args.as_of or datetime.now(ZoneInfo(config["timezone"])).date()
    stats = collect(ROOT, config, as_of)
    # Validate markers before writing any generated files.
    readme = update_readme((ROOT / "README.md").read_text(), readme_block(stats))
    write_if_changed(ROOT / "docs/stats/sv-stats.json", json.dumps(stats, indent=2) + "\n")
    write_if_changed(ROOT / "docs/stats/sv-activity.svg", chart_svg(stats))
    write_if_changed(ROOT / "README.md", readme)
    print(f'RTL: {stats["current"]["files"]} files, {stats["current"]["code_lines"]} code lines; '
          f'history: +{stats["history"]["added"]}/-{stats["history"]["deleted"]}; as of {as_of}')


if __name__ == "__main__":
    main()
