# SV Practice Statistics

The README shows current RTL code size, historical line additions/deletions,
and a daily activity chart. Everything is generated locally with Git and
Python 3.9 or newer; there are no Python packages or external badge services
to install. The default chart covers 30 calendar days in
`America/Los_Angeles` time.

## What gets counted

The rules are configurable in
[`scripts/sv_stats_config.json`](../scripts/sv_stats_config.json):

- Include tracked implementation `.sv` and `.v` files under `IP/`.
- Exclude filenames matching `tb_*`, `*_tb.sv`, `*_tb.v`, `*golden*`, and
  `*reference*`, plus `testbench`, `tests`, and `.svlangserver` directories.
- `UVM/` is outside the default scope. Add it to `roots` to count that work.
- Exclusion is based on paths, not proof of authorship. A reference file with
  an ordinary implementation filename will still count. Add a specific
  exclusion pattern if needed.

**Current code lines** count physical lines containing non-comment code in
committed `HEAD`. Blank and comment-only lines are omitted. Mixed code/comment
lines, declarations, and preprocessor directives count. Strings and escaped
identifiers are respected when removing comments. The JSON also records full
physical line counts and a per-file breakdown.

**Historical additions and deletions** come from Git's physical-line diffs.
They include comments and blank lines. Replacing a line counts as a deletion
and an addition; deleting and rewriting code contributes to both totals.
These totals therefore measure change activity rather than current code size.
They do not measure literal keystrokes, saved-but-uncommitted edits, correctness,
or exclusively human-written code. All authors on the current branch's
first-parent history are included.

History starts with the root commit. Merge commits are compared with their
first parent, so work merged from a feature branch is counted once, on the
merge's commit date. Daily buckets use **committer timestamps**, converted to
the configured timezone. Renames recognized by Git within the included scope
do not recount the whole file; renames across a scope boundary count the full
file as entering or leaving scope. Renames Git cannot recognize can appear
as a deletion and addition. Shallow clones are rejected to avoid displaying
incomplete historical totals.

The snapshot always reads committed `HEAD`, even when run locally. Uncommitted
SV changes are intentionally excluded so local and GitHub results agree.
Rewriting Git history or changing exclusions can change past totals.

## Refresh locally

From the repository root:

```sh
python3 scripts/sv_stats.py
```

This updates only the marked statistics block in `README.md` and the generated
files below. It does not stage, commit, or push anything. To include new RTL
work, commit that work first, then refresh. Existing README content outside
the marker pair is preserved.

```text
docs/stats/sv-stats.json    Summary, daily history, and per-file counts
docs/stats/sv-activity.svg Recent daily additions and deletions
```

For a reproducible chart end date:

```sh
python3 scripts/sv_stats.py --as-of 2026-11-16
```

`--as-of` changes the chart window and display date; the current snapshot and
all-time totals still describe `HEAD`. Rerunning with the same inputs and date
produces identical generated files.

Run the counting and Git-history checks with:

```sh
python3 -m unittest discover -s scripts/tests -v
```

## Automatic updates on GitHub

[`sv-stats.yml`](../.github/workflows/sv-stats.yml) runs after relevant pushes
to `main`, once a day at 09:23 UTC, and manually from **Actions → Update SV
practice statistics → Run workflow**. Scheduled execution times are best-effort.
The daily run moves the rolling chart window even on days without new code.

The workflow checks out full history, runs the tests, regenerates statistics,
and commits only the generated JSON/SVG and README if they changed. It uses the
repository's built-in `GITHUB_TOKEN` with `contents: write`; no personal token
or secret is needed. Its bot-generated pushes do not recursively start another
push workflow. Bot commits modify no counted RTL files and do not increase the
practice totals.

After these files are committed and pushed, open Actions to inspect the first
run. If repository or organization policy disables Actions or prevents the
workflow token from writing, enable the required access in repository settings.
Branch protection may require accepting generated updates through a PR instead
of direct pushes; this workflow does not bypass those rules. A non-fast-forward
push fails rather than force-pushing over newer work; rerun the workflow to
regenerate from the latest `main` in that case.

GitHub may disable scheduled workflows in inactive public repositories; manual
and push triggers remain useful when returning to the project.

References: [Git diff statistics](https://git-scm.com/docs/git-log),
[workflow events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows),
and [the workflow token](https://docs.github.com/en/actions/concepts/security/github_token).
