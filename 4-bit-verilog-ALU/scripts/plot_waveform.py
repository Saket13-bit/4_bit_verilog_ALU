"""Replot the archived demonstration VCD; requires matplotlib."""
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

root = Path(__file__).resolve().parents[1]
vcd = root / "results" / "alu4_demo.vcd"
lines = vcd.read_text(encoding="utf-8").splitlines()
scopes, codes, widths = [], {}, {}
definitions, values, snapshots, time = True, {}, {}, None
for raw in lines:
    line = raw.strip()
    if definitions:
        parts = line.split()
        if line.startswith("$scope"):
            scopes.append(parts[2])
        elif line.startswith("$upscope"):
            scopes.pop()
        elif line.startswith("$var") and scopes == ["tb_alu4"]:
            codes[parts[3]] = parts[4]
            widths[parts[4]] = int(parts[2])
        elif line.startswith("$enddefinitions"):
            definitions = False
    elif line.startswith("#"):
        if time is not None:
            snapshots[time] = values.copy()
        time = int(line[1:])
    elif line.startswith("b"):
        bits, code = line[1:].split()
        if code in codes:
            values[codes[code]] = bits
    elif line and line[0] in "01xz" and line[1:] in codes:
        values[codes[line[1:]]] = line[0]
if time is not None:
    snapshots[time] = values.copy()
times = sorted(snapshots)
signals = ["a", "b", "op", "y", "zero", "carry", "overflow"]
labels = ["A [3:0]", "B [3:0]", "Opcode [2:0]", "Y [3:0]", "Zero", "Carry / borrow", "Overflow"]
fig, ax = plt.subplots(figsize=(12.5, 5.2))
for index, (name, label) in enumerate(zip(signals, labels)):
    center = 6 - index
    ax.text(-.15, center, label, ha="right", va="center", fontsize=10)
    color = "#136f63" if name == "y" else "#345d89"
    if widths[name] > 1:
        for start, end in zip(times[:-1], times[1:]):
            bits = snapshots[start][name].zfill(widths[name])
            x, w = start/1000, (end-start)/1000
            ax.add_patch(Rectangle((x, center-.25), w, .5, facecolor=color, alpha=.1, edgecolor=color, lw=.8))
            ax.text(x+w/2, center, bits, ha="center", va="center", family="monospace", fontsize=9)
    else:
        xs = [t/1000 for t in times]
        ys = [center-.2+.4*int(snapshots[t][name]) for t in times]
        ax.step(xs, ys, where="post", lw=1.8, color=color)
        for start, end in zip(times[:-1], times[1:]):
            ax.text((start+end)/2000, center+.27, snapshots[start][name], ha="center", fontsize=8, color=color)
ax.set_xlim(0, 12); ax.set_ylim(-.55, 6.6)
ax.set_xticks(range(13)); ax.set_yticks([])
ax.grid(axis="x", alpha=.15); ax.set_xlabel("Testbench stimulus time (ns)")
ax.spines["left"].set_visible(False)
fig.suptitle("4-bit ALU: archived testbench waveform", fontsize=15, weight="bold")
fig.text(.5, .025, "Parsed from saved VCD · 12 demo vectors · 1 ns stimulus spacing is not measured propagation delay", ha="center", fontsize=8.5)
fig.tight_layout(rect=(.02, .05, 1, .94))
target = root / "results" / "waveform.png"
fig.savefig(target, dpi=170)
plt.close(fig)
print("Saved", target)
