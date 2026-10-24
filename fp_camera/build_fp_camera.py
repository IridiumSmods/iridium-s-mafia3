"""Builds a first-person camera tables.sds from rules (fp_rules.json).

The game's own camera keeps doing everything (mouse look, walking where the
view points, aiming, collision); only its configuration values change. Every
edit keeps sizes:
a value is rewritten in place, a value shared with other nodes is swapped for
an existing table entry that holds the new value, and each touched zlib block
is recompressed into its old length. The result is checked by decoding it
again: the rule targets must hold their new values, every other camera value
must be untouched.

A block that compresses a few bytes longer than its slot gets, in turn: every
zlib setting, zopfli (when installed), other ways to write the same numbers
("0 0 1.78" or "0.0 0 1.8"), and its optional edits put back to the game's value.

fp_rules.json:
  {"rules": [ {"res": "/config/game_camera/player*",          (fnmatch on the resource name)
               "path": "param:FovApply\\.FOV@value$",         (regex on the value path, see vanilla/*.values.txt)
               "value": 70,                                   (number, string, bool, or [x, y, z] for
                                                               a text vector; null keeps that number)
               "tol": 0.051,                                  (optional: how far a number may be rounded
                                                               to fit the old text length)
               "optional": true,                              (optional: may stay as in the game when its
                                                               block cannot fit otherwise)
               "note": "why"} ],
   "tested_sha16": ["7c91aa428ab16ae7"]}                      (optional: tables.sds the rules were tried
                                                               on; another one is named in the report)
A rule that matches nothing, or a value that cannot be written, fails the build.

Run: python build_fp_camera.py [--dry] [--no-zopfli] [rules.json] [source.sds] [out.sds]
Out: tables.sds.FP_CAMERA and tables.sds.FP_CAMERA.report.txt (or the out.sds given)
Exit: 0 written; 1 a rule, a block or the check failed; 3 a block does not fit
      and zopfli is not installed (APPLY_FP_CAMERA.bat then installs it and retries).
"""
from __future__ import annotations

import bisect
import fnmatch
import hashlib
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import sdsxml  # noqa: E402

GAME = HERE.parent.parent
LIVE = GAME / "sds_retail" / "tables" / "tables.sds"
OUT = HERE / "tables.sds.FP_CAMERA"
NEEDS_ZOPFLI = 3


@dataclass
class Spot:
    """Bytes the rules changed at one place of the inflated data."""
    at: int
    orig: bytes
    data: bytes
    alts: list[bytes]                # every acceptable bytes for this place, best first
    keys: list = field(default_factory=list)  # (resource, path) of the value it holds
    optional: bool = False


def index_resources(blob) -> dict:
    return {r.name: r for r in sdsxml.find_xml_resources(blob) if not isinstance(r, tuple)}


def snapshot(index: dict) -> dict[tuple[str, str], object]:
    snap = {}
    for name, res in index.items():
        if "camera" not in name.lower():
            continue
        for row in sdsxml.flat_values(res):
            snap[(name, row["path"])] = row["value"]
    return snap


def _num(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return None


def matches(new, want, tol: float) -> bool:
    vec = sdsxml.as_vector(want)
    if vec is not None:
        return sdsxml.vector_close(new, vec, tol + 1e-6)
    if new == want:
        return True
    a, b = _num(new), _num(want)
    return a is not None and b is not None and abs(a - b) <= tol + 1e-6


def show(data: bytes) -> str:
    return repr(data.decode("utf-8", "replace"))


def plan_rules(rules, blob, index, report) -> tuple[bytearray, dict[int, Spot], dict, int]:
    """Applies the rules to a copy of the inflated data, in order."""
    patched = bytearray(blob)
    spots: dict[int, Spot] = {}
    expected: dict[tuple[str, str], tuple[object, float]] = {}
    fails = 0
    for rule in rules:
        path_re = re.compile(rule["path"])
        tol = float(rule.get("tol", sdsxml.TOL))
        optional = bool(rule.get("optional", False))
        hits = 0
        for name in sorted(n for n in index if fnmatch.fnmatch(n, rule["res"])):
            paths = [r.path for r in sdsxml.refs(sdsxml.reparse(patched, index[name])) if path_re.search(r.path)]
            for path in paths:
                # Read again before every write: shared-value counts change after a repoint.
                ref = next((r for r in sdsxml.refs(sdsxml.reparse(patched, index[name])) if r.path == path), None)
                if ref is None:
                    continue
                try:
                    edits = ref.plan(rule["value"], tol)
                except ValueError as e:
                    report.append(f"FAIL {name} {path}: {e}")
                    fails += 1
                    continue
                for at, data, note, alts in edits:
                    sp = spots.get(at)
                    if sp is None:
                        sp = spots[at] = Spot(at, bytes(blob[at:at + len(data)]), data, alts, optional=optional)
                    else:
                        # optional only while every rule that wrote here is
                        sp.data, sp.alts, sp.optional = data, alts, sp.optional and optional
                    if (name, path) not in sp.keys:
                        sp.keys.append((name, path))
                    patched[at:at + len(data)] = data
                    if sp.data == sp.orig:
                        del spots[at]
                    report.append(f"edit {name} {path}: {note}")
                if not edits:
                    report.append(f"same {name} {path}: already {ref.value!r}")
                expected[(name, path)] = (rule["value"], tol)
                hits += 1
        if hits == 0:
            report.append(f"NONE res={rule['res']} path={rule['path']}  {rule.get('note', '')}")
            fails += 1
    return patched, spots, expected, fails


def build_streams(sds, blob, streams, patched, spots, expected, report, use_zopfli, shrink):
    """Recompresses every block the spots touch into its slot. Returns the new
    archive bytes (None when a block cannot fit) and the number of such blocks."""
    starts = [st.blob_start for st in streams]

    def blocks_of(sp: Spot) -> list[int]:
        first = bisect.bisect_right(starts, sp.at) - 1
        last = bisect.bisect_right(starts, sp.at + len(sp.data) - 1) - 1
        return list(range(first, last + 1))

    by_block: dict[int, list[Spot]] = {}
    for sp in spots.values():
        for k in blocks_of(sp):
            by_block.setdefault(k, []).append(sp)
    out = bytearray(sds)
    stuck = 0
    for k in sorted(by_block):
        st = streams[k]
        orig_comp = sds[st.sds_off:st.sds_off + st.comp_len]
        room = st.comp_len - shrink
        lo, hi = st.blob_start, st.blob_start + st.dec_len
        dec = bytearray(patched[lo:hi])
        new, best = sdsxml.fit_stream(orig_comp, bytes(dec), room, use_zopfli)
        if new is None:
            # Spots that cross into the next block stay as they are.
            inner = [sp for sp in by_block[k] if lo <= sp.at and sp.at + len(sp.data) <= hi]
            choices = [(sp.at - lo, sp.alts) for sp in inner if len(sp.alts) > 1]
            report.append(f"block at {st.sds_off}: {best} bytes for a {room}-byte slot, "
                          f"trying other ways to write {len(choices)} values")
            sdsxml.rephrase(dec, choices, room)
            new, best = sdsxml.fit_stream(orig_comp, bytes(dec), room, use_zopfli)
            if new is None:
                optional = [sp for sp in inner if sp.optional]
                back = sdsxml.put_back(dec, [(sp.at - lo, sp.orig) for sp in optional], room)
                for i in back:
                    report.append(f"kept as in the game (optional, block too tight): {optional[i].keys}")
                    for key in optional[i].keys:
                        expected.pop(key, None)
                if back:
                    new, best = sdsxml.fit_stream(orig_comp, bytes(dec), room, use_zopfli)
            for sp in inner:
                now = bytes(dec[sp.at - lo:sp.at - lo + len(sp.data)])
                if now != sp.data:
                    if now != sp.orig:
                        report.append(f"rewritten to fit the block: {sp.keys[0][0]} {sp.keys[0][1]}: "
                                      f"{show(sp.data)} -> {show(now)}")
                    sp.data = now
                    patched[sp.at:sp.at + len(now)] = now
        if new is None:
            stuck += 1
            untouched = sdsxml.quick_size(bytes(blob[lo:hi]))
            names = sorted({key[0] for sp in by_block[k] for key in sp.keys})
            report.append(f"BLOCK at {st.sds_off} does not fit: best {best} bytes for a {room}-byte slot "
                          f"(the game's own data recompresses to {untouched}); it holds {', '.join(names)}")
            continue
        out[st.sds_off:st.sds_off + st.comp_len] = new
    return (bytes(out) if stuck == 0 else None), stuck


def version_note(sha16: str, tested: list) -> str:
    """Whether this tables.sds is one the rules were tried on. Another game version
    (or other mods in the file) is not refused: every value is found by name and
    checked after writing, and a rule that finds nothing fails the build anyway."""
    if sha16 in tested:
        return f"version: tables.sds {sha16} is one the rules were tested on"
    return (f"version: tables.sds {sha16} is not one the rules were tested on (another game version, or other "
            "mods in the file): the camera values were found by name and are checked after writing; if the "
            "camera behaves oddly, UNINSTALL_FP_CAMERA.bat puts the original back")


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry" in sys.argv
    use_zopfli = "--no-zopfli" not in sys.argv
    # --slot-shrink=N makes every slot N bytes tighter: only for testing the fallbacks.
    shrink = next((int(a.split("=", 1)[1]) for a in sys.argv[1:] if a.startswith("--slot-shrink=")), 0)
    rules_path = Path(args[0]) if args else HERE / "fp_rules.json"
    source = Path(args[1]) if len(args) > 1 else LIVE
    out_path = Path(args[2]) if len(args) > 2 else OUT
    data = json.loads(rules_path.read_text(encoding="utf-8"))
    rules = data["rules"]
    sds = source.read_bytes()
    sha16 = hashlib.sha256(sds).hexdigest()[:16]
    report = [f"source {source} sha16 {sha16}, rules {rules_path.name}", version_note(sha16, data.get("tested_sha16", []))]
    blob, streams = sdsxml.inflate_streams(sds)
    index = index_resources(blob)
    patched, spots, expected, fails = plan_rules(rules, blob, index, report)
    if dry:
        print("\n".join(report))
        print(f"dry run: {len(spots)} values to write, {fails} problems")
        return 1 if fails else 0

    if out_path.exists():
        out_path.unlink()  # never leave an older build next to a failed one
    report_path = out_path.with_name(out_path.name + ".report.txt")
    zopfli_on = use_zopfli and sdsxml.has_zopfli()
    new_sds, stuck = build_streams(sds, blob, streams, patched, spots, expected, report, zopfli_on, shrink)
    bad = 0
    if new_sds is not None:
        if len(new_sds) != len(sds):
            raise RuntimeError("size changed")
        # The game finds blocks through the archive's block table: read them the same way.
        new_blob = sdsxml.inflate_slots(new_sds, streams)
        if len(new_blob) != len(blob) or new_blob != bytes(patched):
            raise RuntimeError("the rebuilt blocks do not inflate to the edited data")
        before, after = snapshot(index), snapshot(index_resources(new_blob))
        for key, old in before.items():
            new = after.get(key)
            if key in expected:
                want, tol = expected[key]
                if not matches(new, want, tol):
                    report.append(f"VERIFY target {key}: {new!r}, want {want!r}")
                    bad += 1
            elif new != old:
                report.append(f"VERIFY changed by accident {key}: {old!r} -> {new!r}")
                bad += 1
    if new_sds is not None and bad == 0 and fails == 0:
        out_path.write_bytes(new_sds)
        report.append(f"written {out_path}, {len(spots)} values changed")
    else:
        report.append(f"NOT written: {fails} rule problems, {stuck} blocks that do not fit, {bad} verify problems")
        if stuck and not zopfli_on:
            report.append("a stronger compressor would help: python -m pip install zopfli (APPLY_FP_CAMERA.bat does it)")
    report_path.write_text("\n".join(report) + "\n", encoding="utf-8")
    print("\n".join(line for line in report if not line.startswith(("edit ", "same "))))
    print(f"{sum(1 for line in report if line.startswith('edit '))} values edited (full list: {report_path.name})")
    if stuck and not fails and not bad and not zopfli_on:
        return NEEDS_ZOPFLI
    return 1 if (fails or bad or stuck) else 0


if __name__ == "__main__":
    sys.exit(main())
