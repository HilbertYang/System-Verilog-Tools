"""Render the reproduction's actual VCD transitions with Python's standard library."""

from html import escape
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parent
source = (ROOT / "moving_sum4_continuous.vcd").read_text()
header, body = source.split("$enddefinitions $end", 1)
scale = re.search(r"\$timescale\s+(\d+)\s*(\w+)\s+\$end", header)
unit_ns = int(scale[1]) * {"s": 1e9, "ms": 1e6, "us": 1e3,
                          "ns": 1, "ps": 1e-3, "fs": 1e-6}[scale[2]]
scope = []
ids = {}
for line in header.splitlines():
    fields = line.split()
    if not fields:
        continue
    if fields[0] == "$scope":
        scope.append(fields[2])
    elif fields[0] == "$upscope":
        scope.pop()
    elif fields[0] == "$var" and scope == ["tb_moving_sum4_continuous"]:
        ids[fields[4]] = fields[3]

events = {identifier: [] for identifier in ids.values()}
now = 0.0
for line in body.splitlines():
    line = line.strip()
    if not line or line.startswith("$"):
        continue
    if line.startswith("#"):
        now = int(line[1:]) * unit_ns
        continue
    if line[0] in "bB":
        bits, identifier = line[1:].split()
    elif line[0] in "01xXzZ":
        bits, identifier = line[0], line[1:]
    else:
        continue
    if identifier not in events:
        continue
    value = "X" if re.search("[xz]", bits, re.I) else str(int(bits, 2))
    trace = events[identifier]
    if trace and trace[-1][0] == now:
        trace[-1] = (now, value)
    elif not trace or trace[-1][1] != value:
        trace.append((now, value))


def value_at(name, time):
    result = "X"
    for timestamp, value in events[ids[name]]:
        if timestamp > time:
            break
        result = value
    return result


lanes = [
    ("clk", "clk", True, "#546477"),
    ("rst_n", "rst_n", True, "#546477"),
    ("in_valid", "in_valid", True, "#158052"),
    ("in_data", "in_data (decimal)", False, "#158052"),
    ("buff0", "buff[0] (newest)", False, "#2366b1"),
    ("buff1", "buff[1]", False, "#2366b1"),
    ("buff2", "buff[2] (oldest)", False, "#2366b1"),
    ("cnt", "cnt", False, "#546477"),
    ("held_sum", "hold", False, "#2366b1"),
    ("out_sum", "out_sum: ACTUAL", False, "#c23936"),
    ("expected_sum", "out_sum: EXPECTED", False, "#a66b00"),
    ("out_valid", "out_valid: ACTUAL", True, "#c23936"),
    ("expected_valid", "out_valid: EXPECTED", True, "#a66b00"),
]
start, end = 10.0, 80.0
left, right, top, row = 245, 1745, 150, 53
bottom = top + row * len(lanes)
height = bottom + 160


def x(time):
    return left + (time - start) / (end - start) * (right - left)


svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="1800" height="{height}" viewBox="0 0 1800 {height}">',
       '<rect width="100%" height="100%" fill="#ffffff"/>',
       '<style>text{font-family:Menlo,Consolas,monospace;fill:#243344} .small{font-size:14px} .label{font-size:17px}</style>',
       '<text x="30" y="39" font-size="25" font-weight="bold">moving_sum4: continuous-input reproduction</text>',
       '<text x="30" y="68" font-size="16">Inputs change on falling edges; register updates occur at rising edges. All bus values are decimal.</text>',
       '<text x="30" y="93" font-size="16">Actual traces come from Icarus VCD. Expected outputs are checked 1 ps after each rising edge.</text>']
svg.append(f'<rect x="{x(54)}" y="{top-24}" width="{x(56)-x(54)}" height="{bottom-top+24}" fill="#fff0cf"/>')
for tick in range(10, 81, 5):
    xx = x(tick)
    svg += [f'<line x1="{xx}" y1="{top-20}" x2="{xx}" y2="{bottom}" stroke="#dde3eb"/>',
            f'<text x="{xx}" y="{top-31}" text-anchor="middle" class="small">{tick}</text>']
svg.append(f'<text x="{right+13}" y="{top-31}" class="small">ns</text>')

for sample, timestamp in enumerate((25, 35, 45, 55, 65), 1):
    xx = x(timestamp)
    svg += [f'<line x1="{xx}" y1="{top-20}" x2="{xx}" y2="{bottom}" stroke="#bd9254" stroke-dasharray="3 5"/>',
            f'<text x="{xx}" y="{top-51}" text-anchor="middle" class="small">sample {sample}</text>']

for index, (name, label, digital, color) in enumerate(lanes):
    yy = top + index * row
    if index % 2 == 0:
        svg.append(f'<rect x="12" y="{yy-4}" width="1760" height="{row}" fill="#f3f6fa" fill-opacity="0.6"/>')
    svg.append(f'<text x="20" y="{yy+23}" class="label">{escape(label)}</text>')
    transitions = [(start, value_at(name, start))]
    transitions += [(time, value) for time, value in events[ids[name]] if start < time < end]
    segments = [(a, transitions[i+1][0] if i+1 < len(transitions) else end, value)
                for i, (a, value) in enumerate(transitions)]
    if digital:
        points = []
        for a, b, value in segments:
            level = yy + (6 if value == "1" else 33)
            points.extend((f"{x(a)},{level}", f"{x(b)},{level}"))
        svg.append(f'<polyline points="{" ".join(points)}" stroke="{color}" stroke-width="2.2" fill="none"/>')
    else:
        for a, b, value in segments:
            xa, xb = x(a), x(b)
            if xb-xa < 0.1:
                continue
            cap = min(4, (xb-xa)/3)
            points = f"{xa},{yy+20} {xa+cap},{yy+5} {xb-cap},{yy+5} {xb},{yy+20} {xb-cap},{yy+35} {xa+cap},{yy+35}"
            svg.append(f'<polygon points="{points}" fill="white" stroke="{color}" stroke-width="1.7"><title>{escape(name)}: {value}, {a:g} to {b:g} ns</title></polygon>')
            if xb-xa > 19:
                svg.append(f'<text x="{(xa+xb)/2}" y="{yy+25}" text-anchor="middle" font-size="16">{value}</text>')

note_y = bottom + 32
svg += [f'<rect x="25" y="{note_y-19}" width="1740" height="112" rx="8" fill="#fff6e5" stroke="#e5c28b"/>',
        f'<text x="42" y="{note_y+6}" font-size="18" font-weight="bold">At 55.001 ns, after accepting sample 4 (40):</text>',
        f'<text x="42" y="{note_y+34}" font-size="17">in_valid=1, in_data=40, buff[0]=40, buff[1]=30, buff[2]=20, hold=100</text>',
        f'<text x="42" y="{note_y+62}" font-size="17">Actual out_sum=130 (20+30+40+40); required out_sum=100. Inputs stay unchanged until 60 ns.</text>',
        '</svg>']
destination = ROOT / "moving_sum4_continuous.svg"
destination.write_text("\n".join(svg))
print(destination)
print("VCD snapshot at 55.001 ns:", {name: value_at(name, 55.001) for name in
      ("in_valid", "in_data", "buff0", "buff1", "buff2", "held_sum", "out_sum", "expected_sum")})
