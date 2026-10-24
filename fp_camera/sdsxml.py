"""Reads and patches the binary XML resources inside a Mafia III .sds archive.

Only zlib and the standard library are used. The archive is not parsed: its
zlib blocks are inflated in order, which gives the resource stream, and XML
resources are found in it by their name ("/config/game_camera/player").

XML resource (Gibbed.Illusion XmlResource, version >= 3):
    U32 len + tag, U8 unk1, U32 len + name, U8 unk3, content
content when unk3 == 0 (XmlResource0):
    U8 4, U32 node count, U32 value table size, value table, node records
value table entry at an offset (offsets are relative to the table start):
    U32 type, then 1 special / 4 string: U32 0 + UTF-8 + NUL, 2 bool: U32 0 + U8,
    3 float: U32 0 + F32, 5 int: U32 0 + S32, 8: 3 x U32 + F32
node record:
    U32 name offset, U32 value offset, U32 id, U32 child count, child ids,
    U32 attribute count, (U32 name offset, U32 value offset) per attribute
The root is the node with id 0 and has exactly one child.

Paths name an element by its "name" attribute when it has one
("camera:Player/modes[0]/mode:exterior/param:FovApply.FOV@value"; also "Name",
"Id" or "cameramodefrom": "blendinproperty:E_GCM_MAFIA_AIM@time"), otherwise
by tag and index among the unnamed siblings with that tag ("point[2]").
"""
from __future__ import annotations

import itertools
import json
import re
import struct
import zlib
from dataclasses import dataclass, field
from pathlib import Path

TYPE_LETTER = {1: "x", 2: "b", 3: "f", 4: "s", 5: "i", 8: "u"}


# ------------------------------------------------------------------ streams

@dataclass
class Stream:
    sds_off: int     # where the compressed bytes start in the .sds
    comp_len: int    # compressed length, kept when patching
    blob_start: int  # where its inflated bytes start in the joined blob
    dec_len: int


def inflate_streams(sds: bytes, window: int = 0x200000) -> tuple[bytes, list[Stream]]:
    """Inflates every complete zlib stream in file order and joins them."""
    out = bytearray()
    streams: list[Stream] = []
    i, n = 0, len(sds)
    while i < n - 2:
        if sds[i] == 0x78 and sds[i + 1] in (0x01, 0x5E, 0x9C, 0xDA):
            d = zlib.decompressobj()
            chunk = sds[i:i + window]
            try:
                dec = d.decompress(chunk)
                if d.eof:
                    consumed = len(chunk) - len(d.unused_data)
                    streams.append(Stream(i, consumed, len(out), len(dec)))
                    out += dec
                    i += consumed
                    continue
            except zlib.error:
                pass
        i += 1
    return bytes(out), streams


# ------------------------------------------------------------------ values

@dataclass
class Value:
    off: int          # offset inside the value table
    type: int
    value: object
    payload_abs: int  # absolute blob offset of the payload bytes
    payload_len: int  # bytes that may be rewritten in place (strings: without NUL)


def read_value(blob: bytes, vt_start: int, off: int) -> Value:
    p = vt_start + off
    t = struct.unpack_from("<I", blob, p)[0]
    if t in (1, 4):
        end = blob.index(b"\x00", p + 8)
        s = blob[p + 8:end].decode("utf-8", "replace")
        return Value(off, t, s, p + 8, end - (p + 8))
    if t == 2:
        return Value(off, t, blob[p + 8] != 0, p + 8, 1)
    if t == 3:
        return Value(off, t, struct.unpack_from("<f", blob, p + 8)[0], p + 8, 4)
    if t == 5:
        return Value(off, t, struct.unpack_from("<i", blob, p + 8)[0], p + 8, 4)
    if t == 8:
        return Value(off, t, struct.unpack_from("<f", blob, p + 16)[0], p + 16, 4)
    raise ValueError(f"unknown value type {t} at table offset {off}")


# ------------------------------------------------------------------ nodes

@dataclass
class Node:
    id: int
    name_off: int
    value_off: int
    children: list[int]
    attrs: list[tuple[int, int]]
    record_abs: int  # absolute blob offset of the record (value offset at +4)


@dataclass
class XmlRes:
    tag: str
    name: str
    content_abs: int
    vt_start: int
    vt_size: int
    end_abs: int
    nodes: dict[int, Node] = field(default_factory=dict)
    blob: bytes = b""

    def val(self, off: int):
        return read_value(self.blob, self.vt_start, off)

    def text(self, off: int):
        v = self.val(off)
        if v.type in (1, 4) and v.value == "":
            return None
        return v.value

    def refcount(self) -> dict[int, int]:
        """How many node values and attribute values point at each table offset."""
        rc: dict[int, int] = {}
        for nd in self.nodes.values():
            rc[nd.value_off] = rc.get(nd.value_off, 0) + 1
            for _, av in nd.attrs:
                rc[av] = rc.get(av, 0) + 1
        return rc

    def name_attr(self, nd: Node):
        found = {str(self.text(an)): av for an, av in nd.attrs}
        for key in LABEL_ATTRS:
            if key in found:
                return str(self.val(found[key]).value)
        return None

    def walk(self):
        """Yields (path, node) depth first; path like 'Camera[0]/Behaviors[0]/param:Fov'."""
        root = next(nd for nd in self.nodes.values() if nd.id == 0)

        def rec(nid: int, path: str):
            nd = self.nodes[nid]
            yield path, nd
            seen: dict = {}
            for cid in nd.children:
                c = self.nodes[cid]
                yield from rec(cid, f"{path}/{label(str(self.text(c.name_off)), self.name_attr(c), seen)}")

        for cid in root.children:
            c = self.nodes[cid]
            yield from rec(cid, label(str(self.text(c.name_off)), self.name_attr(c), {}))


# Attributes that name an element in a path, first found wins.
LABEL_ATTRS = ("name", "Name", "Id", "cameramodefrom")


def label(tag: str, name, seen: dict) -> str:
    """Path step: 'param:FovApply.FOV' (a repeated name gets '#1', '#2'), or 'tag[k]'."""
    k = seen.get((tag, name), 0)
    seen[(tag, name)] = k + 1
    if name is None:
        return f"{tag}[{k}]"
    return f"{tag}:{name}" + (f"#{k}" if k else "")


def parse_xml0(blob: bytes, pos: int) -> tuple[int, int, int, dict[int, Node]]:
    if blob[pos] != 4:
        raise ValueError("not an XmlResource0 block")
    count, size = struct.unpack_from("<II", blob, pos + 1)
    if count > 200000 or size > 0x500000:
        raise ValueError("implausible header")
    vt_start = pos + 9
    p = vt_start + size
    nodes: dict[int, Node] = {}
    for _ in range(count):
        rec = p
        name_off, value_off, nid, nchild = struct.unpack_from("<IIII", blob, p)
        p += 16
        children = list(struct.unpack_from(f"<{nchild}I", blob, p))
        p += 4 * nchild
        nattr = struct.unpack_from("<I", blob, p)[0]
        p += 4
        attrs = [struct.unpack_from("<II", blob, p + 8 * j) for j in range(nattr)]
        p += 8 * nattr
        if name_off >= size or value_off >= size:
            raise ValueError("offset outside the value table")
        nodes[nid] = Node(nid, name_off, value_off, children, attrs, rec)
    if 0 not in nodes or len(nodes[0].children) != 1:
        raise ValueError("no root node")
    return vt_start, size, p, nodes


# ------------------------------------------------------------------ BX form

@dataclass
class BxNode:
    kind: str                 # "elem", "text" or "attr"
    name: str = ""
    children: list = field(default_factory=list)
    attrs: list = field(default_factory=list)
    value: str = ""           # text / attribute value
    payload_abs: int = -1     # where the value bytes start
    payload_len: int = 0


@dataclass
class XmlResBX:
    """XmlResource1: U16 'BX' 0x5842, U16 version 0/1, then nested entries
    (U16 size, U8 type): 1 element (U8 name len, U16 children, U8 attributes,
    name + NUL, children, attributes), 4 value (U8 kind 0, U16 len, UTF-8 + NUL),
    5 attribute (U8 name len, name + NUL, then a value entry)."""
    tag: str
    name: str
    content_abs: int
    root: BxNode
    end_abs: int
    blob: bytes = b""


def parse_bx(blob, pos: int) -> tuple[BxNode, int]:
    magic, ver = struct.unpack_from("<HH", blob, pos)
    if magic != 0x5842 or ver > 1:
        raise ValueError("not a BX block")
    depth = [0]

    def entry(p: int) -> tuple[BxNode, int]:
        depth[0] += 1
        if depth[0] > 64:
            raise ValueError("BX nesting too deep")
        _, typ = struct.unpack_from("<HB", blob, p)
        q = p + 3
        if typ == 1:
            nlen, nchild, nattr = struct.unpack_from("<BHB", blob, q)
            q += 4
            node = BxNode("elem", bytes(blob[q:q + nlen]).decode("utf-8", "replace"))
            q += nlen + 1
            for _ in range(nchild):
                c, q = entry(q)
                node.children.append(c)
            for _ in range(nattr):
                a, q = entry(q)
                if a.kind != "attr":
                    raise ValueError("BX attribute expected")
                node.attrs.append(a)
        elif typ == 4:
            kind, ln = struct.unpack_from("<BH", blob, q)
            q += 3
            if kind != 0:
                raise ValueError(f"BX value kind {kind}")
            node = BxNode("text", value=bytes(blob[q:q + ln]).decode("utf-8", "replace"), payload_abs=q, payload_len=ln)
            q += ln + 1
        elif typ == 5:
            nlen = blob[q]
            q += 1
            name = bytes(blob[q:q + nlen]).decode("utf-8", "replace")
            q += nlen + 1
            v, q = entry(q)
            if v.kind != "text":
                raise ValueError("BX attribute value expected")
            node = BxNode("attr", name, value=v.value, payload_abs=v.payload_abs, payload_len=v.payload_len)
        else:
            raise ValueError(f"BX entry type {typ}")
        depth[0] -= 1
        return node, q

    root, end = entry(pos + 4)
    return root, end


def bx_name(nd: BxNode):
    found = {a.name: a.value for a in nd.attrs}
    return next((found[key] for key in LABEL_ATTRS if key in found), None)


def bx_walk(res: XmlResBX):
    def rec(nd: BxNode, path: str):
        yield path, nd
        seen: dict = {}
        for c in nd.children:
            if c.kind != "elem":
                continue
            yield from rec(c, f"{path}/{label(c.name, bx_name(c), seen)}")

    yield from rec(res.root, label(res.root.name, bx_name(res.root), {}))


def bx_text(nd: BxNode) -> BxNode | None:
    texts = [c for c in nd.children if c.kind == "text"]
    return texts[0] if len(texts) == 1 and len(nd.children) == 1 else None


NAME_RE = re.compile(rb"(?<![A-Za-z0-9_])/?(?:config|tables)/[A-Za-z0-9_./\-]{2,200}")


def find_xml_resources(blob: bytes) -> list[XmlRes | tuple[str, str]]:
    """Every XML resource whose name starts with /config/ or /tables/.
    Returns parsed resources, or (name, error) for the ones that did not parse."""
    found: list = []
    seen = set()
    for m in NAME_RE.finditer(blob):
        n = m.start()
        if n < 9:
            continue
        ln = struct.unpack_from("<I", blob, n - 4)[0]
        if not 3 < ln < 260 or n + ln >= len(blob):
            continue
        raw = blob[n:n + ln]
        if not NAME_RE.fullmatch(raw):
            continue
        name = raw.decode("ascii")
        if n in seen:
            continue
        unk1 = blob[n - 5]
        if unk1 not in (0, 1):
            continue
        tag = "?"
        for tl in range(1, 64):
            ts = n - 5 - tl
            if ts - 4 < 0:
                break
            if struct.unpack_from("<I", blob, ts - 4)[0] == tl and all(32 <= c < 127 for c in blob[ts:ts + tl]):
                tag = blob[ts:ts + tl].decode("ascii")
                break
        seen.add(n)
        unk3 = blob[n + ln]
        content = n + ln + 1
        if unk3 != 0:
            try:
                root, end = parse_bx(blob, content)
            except (ValueError, struct.error, IndexError) as e:
                found.append((name, f"BX parse failed: {e}"))
                continue
            found.append(XmlResBX(tag, name, content, root, end, blob))
            continue
        try:
            vt_start, size, end, nodes = parse_xml0(blob, content)
        except (ValueError, struct.error, IndexError) as e:
            found.append((name, f"parse failed: {e}"))
            continue
        found.append(XmlRes(tag, name, content, vt_start, size, end, nodes, blob))
    return found


def bx_to_xml(res: XmlResBX) -> str:
    from xml.sax.saxutils import escape, quoteattr

    lines: list[str] = []

    def rec(nd: BxNode, depth: int):
        pad = "  " * depth
        attrs = "".join(f" {a.name}={quoteattr(a.value)}" for a in nd.attrs)
        t = bx_text(nd)
        if t is not None:
            lines.append(f"{pad}<{nd.name}{attrs}>{escape(t.value)}</{nd.name}>")
            return
        elems = [c for c in nd.children if c.kind == "elem"]
        if not elems:
            lines.append(f"{pad}<{nd.name}{attrs} />")
            return
        lines.append(f"{pad}<{nd.name}{attrs}>")
        for c in elems:
            rec(c, depth + 1)
        lines.append(f"{pad}</{nd.name}>")

    rec(res.root, 0)
    return "\n".join(lines) + "\n"


def to_xml(res) -> str:
    """Readable XML; non-string values carry __type like the Mafia Toolkit."""
    from xml.sax.saxutils import escape, quoteattr

    if isinstance(res, XmlResBX):
        return bx_to_xml(res)
    lines: list[str] = []

    def fmt(v: Value) -> str:
        if v.type == 3 or v.type == 8:
            return repr(round(v.value, 6))
        if v.type == 2:
            return "true" if v.value else "false"
        return str(v.value)

    def rec(nid: int, depth: int):
        nd = res.nodes[nid]
        name = str(res.text(nd.name_off))
        attrs = ""
        for an, av in nd.attrs:
            attrs += f" {res.text(an)}={quoteattr(fmt(res.val(av)))}"
        v = res.val(nd.value_off)
        has_text = not (v.type in (1, 4) and v.value == "")
        if has_text and v.type not in (1, 4):
            attrs += f' __type="{TYPE_LETTER.get(v.type, "?")}"'
        pad = "  " * depth
        if not nd.children:
            if has_text:
                lines.append(f"{pad}<{name}{attrs}>{escape(fmt(v))}</{name}>")
            else:
                lines.append(f"{pad}<{name}{attrs} />")
            return
        lines.append(f"{pad}<{name}{attrs}>" + (escape(fmt(v)) if has_text else ""))
        for cid in nd.children:
            rec(cid, depth + 1)
        lines.append(f"{pad}</{name}>")

    for cid in res.nodes[0].children:
        rec(cid, 0)
    return "\n".join(lines) + "\n"


def flat_values(res) -> list[dict]:
    """One row per node with a value: its path, type, value and where the bytes live."""
    if isinstance(res, XmlResBX):
        rows = []
        for path, nd in bx_walk(res):
            t = bx_text(nd)
            if t is not None:
                rows.append({"path": path, "type": "s", "value": t.value, "value_off": None, "shared": 1,
                             "record_abs": None, "payload_abs": t.payload_abs, "payload_len": t.payload_len})
            for a in nd.attrs:
                rows.append({"path": f"{path}@{a.name}", "type": "s", "value": a.value, "value_off": None, "shared": 1,
                             "record_abs": None, "payload_abs": a.payload_abs, "payload_len": a.payload_len})
        return rows
    rc = res.refcount()
    rows = []
    for path, nd in res.walk():
        v = res.val(nd.value_off)
        if not (v.type in (1, 4) and v.value == "" and nd.children):
            rows.append({
                "path": path, "type": TYPE_LETTER.get(v.type, "?"), "value": v.value,
                "value_off": nd.value_off, "shared": rc.get(nd.value_off, 0),
                "record_abs": nd.record_abs, "payload_abs": v.payload_abs, "payload_len": v.payload_len,
            })
        for an, av in nd.attrs:
            a = res.val(av)
            rows.append({
                "path": f"{path}@{res.text(an)}", "type": TYPE_LETTER.get(a.type, "?"), "value": a.value,
                "value_off": av, "shared": rc.get(av, 0), "record_abs": None,
                "payload_abs": a.payload_abs, "payload_len": a.payload_len,
            })
    return rows


# ------------------------------------------------------------------ patching

TOL = 0.051  # how far a number may be rounded to fit its text field


def num_texts(value: float, tol: float = TOL) -> list[str]:
    """Ways to write `value` within `tol`, least rounding first: "0.2", "0.20" ...,
    and roundings padded with zeros ("1.8", "1.80" for 1.78 when the tolerance allows)."""
    found: dict[str, float] = {}
    for keep in range(0, 7):
        r = round(value, keep)
        if abs(r - value) > tol:
            continue
        for shown in range(keep, 7):
            s = f"{r:.{shown}f}"
            if float(s) == 0:
                s = s.lstrip("-")  # never "-0.0"
            err = abs(float(s) - value)
            if err <= tol and s not in found:
                found[s] = err
    return sorted(found, key=lambda s: (found[s], len(s)))


def number_alternatives(value: float, length: int, tol: float = TOL) -> list[bytes]:
    """Every text of exactly `length` characters for the number, least rounding first."""
    return [s.encode("ascii") for s in num_texts(float(value), tol) if len(s) == length]


def fit_number(value: float, length: int, tol: float = TOL) -> bytes | None:
    """The number as text of exactly `length` characters ("0.0", "0.15"), or None."""
    alts = number_alternatives(value, length, tol)
    return alts[0] if alts else None


def as_vector(new):
    """[x, y, z] for a vector rule value ([...] or {"vec": [...]}), else None."""
    if isinstance(new, dict):
        new = new.get("vec", new.get("point"))
    return list(new) if isinstance(new, (list, tuple)) else None


def bare(s: str) -> str | None:
    """'0.25' -> '.25', '-0.2' -> '-.2': the same number for C's strtod, one character
    shorter. The game parses its configs that way (its own data has "0.5f")."""
    if s.startswith("0.") and len(s) > 2:
        return s[1:]
    if s.startswith("-0.") and len(s) > 3:
        return "-" + s[2:]
    return None


def fit_vector_all(old: str, want: list, tol: float = TOL) -> list[bytes]:
    """Every way to write `want` like `old` ("0.6 0 0" -> "0 0.2 0"): space separated,
    exactly as long, each number rounded by at most `tol`; None keeps that number's
    old text. Best first: no bare ".25" unless nothing else fits ("0.6 0 0" can hold
    y = -0.2 only as "0 -.2 0"), then least rounding, then the evenest look
    ("0.0 0.2 0.0" over "0 0.2 0.000"). Empty when nothing fits."""
    toks = old.split()
    if len(toks) != len(want) or " ".join(toks) != old:
        raise ValueError(f"'{old}' holds {len(toks)} numbers, the rule gives {len(want)}")
    # every other number takes at least one character and a space
    longest = len(old) - 2 * (len(toks) - 1)
    choices = []
    for tok, w in zip(toks, want):
        if w is None:
            choices.append([(tok, 0.0, 0)])
            continue
        texts = num_texts(float(w), tol)
        if not texts:
            raise ValueError(f"{w} cannot be written")
        cands = []
        for s in texts:
            err = abs(float(s) - float(w))
            b = bare(s)
            cands += [(t, err, k) for t, k in ((s, 0), (b, 1)) if t is not None and len(t) <= longest]
        choices.append(cands)
    scored = {}
    for combo in itertools.product(*choices):
        text = " ".join(s for s, _, _ in combo)
        if len(text) != len(old) or text in scored:
            continue
        decs = [len(s.partition(".")[2]) for s, _, _ in combo]
        scored[text] = (sum(b for _, _, b in combo), max(e for _, e, _ in combo), sum(e for _, e, _ in combo),
                        max(decs), sum(decs), text)
    return [t.encode("ascii") for t in sorted(scored, key=scored.get)]


def fit_vector(old: str, want: list, tol: float = TOL) -> bytes:
    """The best of fit_vector_all; ValueError when nothing fits."""
    alts = fit_vector_all(old, want, tol)
    if not alts:
        raise ValueError(f"{want} does not fit the {len(old)}-character '{old}'")
    return alts[0]


def vector_close(old: str, want: list, tol: float) -> bool:
    try:
        nums = [float(t) for t in str(old).split()]
    except ValueError:
        return False
    return len(nums) == len(want) and all(w is None or abs(n - float(w)) <= tol for n, w in zip(nums, want))


def encode_alternatives(v: Value, new, tol: float = TOL) -> list[bytes]:
    """Every byte string that gives the value at `v` the value `new` in place, best
    first. Text values have several ("0 0.20 0" or "0.0 0.2 0"): a block that has to
    shrink can pick the one that compresses best."""
    if v.type == 3 or v.type == 8:
        return [struct.pack("<f", float(new))]
    if v.type == 5:
        return [struct.pack("<i", int(new))]
    if v.type == 2:
        return [b"\x01" if new else b"\x00"]
    if v.type in (1, 4):
        vec = as_vector(new)
        if vec is not None:
            alts = fit_vector_all(str(v.value), vec, tol)
            if not alts:
                raise ValueError(f"{vec} does not fit the {v.payload_len}-character '{v.value}'")
            return alts
        if isinstance(new, (int, float)):
            alts = number_alternatives(float(new), v.payload_len, tol)
        else:
            b = str(new).encode("utf-8")
            alts = [b] if len(b) == v.payload_len else []
        if not alts:
            raise ValueError(f"'{new}' does not fit the {v.payload_len}-byte string '{v.value}'")
        return alts
    raise ValueError(f"type {v.type} cannot be patched")


def encode_like(v: Value, new, tol: float = TOL) -> bytes:
    """Bytes for `new` that fit exactly where `v` lives."""
    return encode_alternatives(v, new, tol)[0]


def same_value(a: Value, new, tol: float = 1e-6) -> bool:
    if a.type in (3, 8, 5):
        return isinstance(new, (int, float)) and abs(float(a.value) - float(new)) <= tol
    if a.type in (1, 4):
        vec = as_vector(new)
        if vec is not None:
            return vector_close(a.value, vec, tol)
        if isinstance(new, (int, float)):
            try:
                return abs(float(a.value) - float(new)) <= tol
            except ValueError:
                return False
        return a.value == str(new)
    return a.value == new


def entry_size(v: Value) -> int:
    """Bytes the entry takes in the value table (entries are packed back to back)."""
    if v.type in (1, 4):
        return 8 + v.payload_len + 1
    if v.type == 2:
        return 9
    if v.type in (3, 5):
        return 12
    return 20  # type 8: U32 type, 3 x U32, F32


def iter_table(res: XmlRes):
    off = 0
    while off < res.vt_size:
        v = res.val(off)
        yield v
        off += entry_size(v)


def in_place(blob, v: Value, new, tol: float) -> list[tuple[int, bytes, str, list[bytes]]]:
    alts = encode_alternatives(v, new, tol)
    if bytes(blob[v.payload_abs:v.payload_abs + len(alts[0])]) in alts:
        return []  # what is there already is one way to write the new value
    shown = alts[0].decode("utf-8", "replace") if v.type in (1, 4) else new
    return [(v.payload_abs, alts[0], f"in place {v.value!r} -> {shown!r}", alts)]


def plan_edit(res: XmlRes, nd: Node, new, tol: float = TOL) -> list[tuple[int, bytes, str, list[bytes]]]:
    """Byte writes (absolute blob offset, bytes, note, every acceptable bytes for that
    spot) that give node `nd` the value `new`.

    A value used only by this node is rewritten in place. A value shared with
    other nodes is left alone: the node is pointed at another table entry that
    already holds `new` (same type), so nothing changes size."""
    v = res.val(nd.value_off)
    if same_value(v, new):
        return []
    rc = res.refcount()
    if rc.get(nd.value_off, 0) <= 1:
        return in_place(res.blob, v, new, tol)
    for cand in iter_table(res):
        if cand.type == v.type and same_value(cand, new):
            data = struct.pack("<I", cand.off)
            return [(nd.record_abs + 4, data, f"repoint {v.value!r} -> existing {cand.value!r}", [data])]
    raise ValueError(f"value {v.value!r} is shared by {rc[nd.value_off]} nodes and no entry holds {new!r}")


def plan_attr(res: XmlRes, nd: Node, j: int, new, tol: float = TOL) -> list[tuple[int, bytes, str, list[bytes]]]:
    """Like plan_edit, for the j-th attribute value of `nd`."""
    off = nd.attrs[j][1]
    v = res.val(off)
    if same_value(v, new):
        return []
    if res.refcount().get(off, 0) <= 1:
        return in_place(res.blob, v, new, tol)
    at = nd.record_abs + 16 + 4 * len(nd.children) + 4 + 8 * j + 4
    for cand in iter_table(res):
        if cand.type == v.type and same_value(cand, new):
            data = struct.pack("<I", cand.off)
            return [(at, data, f"repoint {v.value!r} -> existing {cand.value!r}", [data])]
    raise ValueError(f"attribute value {v.value!r} is shared and no entry holds {new!r}")


@dataclass
class Ref:
    """One editable value: its path, current value and how to give it a new one."""
    path: str
    value: object
    plan: object  # callable(new, tol=TOL) -> [(blob offset, bytes, note, acceptable bytes)]


def refs(res) -> list[Ref]:
    out: list[Ref] = []
    if isinstance(res, XmlResBX):
        for row in flat_values(res):
            def plan_bx(new, tol=TOL, row=row):
                v = Value(0, 4, row["value"], row["payload_abs"], row["payload_len"])
                if same_value(v, new):
                    return []
                return in_place(res.blob, v, new, tol)
            out.append(Ref(row["path"], row["value"], plan_bx))
        return out
    for path, nd in res.walk():
        v = res.val(nd.value_off)
        if not (nd.children and v.type in (1, 4) and v.value == ""):
            out.append(Ref(path, v.value, lambda new, tol=TOL, nd=nd: plan_edit(res, nd, new, tol)))
        for j, (an, av) in enumerate(nd.attrs):
            out.append(Ref(f"{path}@{res.text(an)}", res.val(av).value,
                           lambda new, tol=TOL, nd=nd, j=j: plan_attr(res, nd, j, new, tol)))
    return out


def node_count(res) -> int:
    if isinstance(res, XmlResBX):
        return sum(1 for _ in bx_walk(res))
    return len(res.nodes)


def reparse(blob, base):
    """The same resource read again from `blob` (sizes never change, so it is where it was)."""
    if isinstance(base, XmlResBX):
        root, end = parse_bx(blob, base.content_abs)
        return XmlResBX(base.tag, base.name, base.content_abs, root, end, blob)
    vt, size, end, nodes = parse_xml0(blob, base.content_abs)
    return XmlRes(base.tag, base.name, base.content_abs, vt, size, end, nodes, blob)


# ------------------------------------------------------------------ recompression
#
# An edited block must compress into its old slot. The new stream goes first and
# the old tail fills the rest; zlib stops at the end marker and ignores it. zlib
# itself reaches the original size only when the edit does not make the text
# less regular, so a block that ends up a few bytes too long gets, in turn:
# every zlib setting, zopfli (a stronger deflate encoder, pip install zopfli),
# other ways to write the same numbers, and the optional edits put back.

ZLIB_GRID = [(level, mem, strategy)
             for level in (9, 8, 7, 6, 5, 4, 3, 2, 1)
             for strategy in (zlib.Z_DEFAULT_STRATEGY, zlib.Z_FILTERED, zlib.Z_HUFFMAN_ONLY, zlib.Z_RLE, zlib.Z_FIXED)
             for mem in (9, 8, 7, 6, 5, 4, 3, 2, 1)]


def deflate(dec: bytes, level: int = 9, mem: int = 9, strategy: int = zlib.Z_DEFAULT_STRATEGY) -> bytes:
    c = zlib.compressobj(level, zlib.DEFLATED, 15, mem, strategy)
    return c.compress(dec) + c.flush()


def quick_size(dec: bytes) -> int:
    """Compressed size with the two strongest zlib settings: the yardstick while searching."""
    return min(len(deflate(dec)), len(deflate(dec, strategy=zlib.Z_FILTERED)))


def has_zopfli() -> bool:
    try:
        import zopfli  # noqa: F401
    except ImportError:
        return False
    return True


def zopfli_stream(dec: bytes, iterations: int = 15) -> bytes | None:
    """A zlib stream made by zopfli, usually 3-8% smaller than zlib -9; None without it."""
    try:
        import zopfli
    except ImportError:
        return None
    try:
        c = zopfli.ZopfliCompressor(zopfli.ZOPFLI_FORMAT_ZLIB, iterations=iterations)
        out = c.compress(dec) + c.flush()
    except (AttributeError, TypeError):
        try:
            import zopfli.zlib
            out = zopfli.zlib.compress(dec, numiterations=iterations)
        except Exception:  # an older or unknown zopfli API: as good as missing
            return None
    try:
        return out if zlib.decompress(out) == dec else None
    except zlib.error:
        return None


def hybrid(orig_comp: bytes, body: bytes, dec: bytes) -> bytes:
    out = body + orig_comp[len(body):]
    if len(out) != len(orig_comp) or zlib.decompress(out) != dec:
        raise RuntimeError("recompressed stream does not round-trip")
    return out


def fit_stream(orig_comp: bytes, dec: bytes, room: int | None = None,
               use_zopfli: bool = True) -> tuple[bytes | None, int]:
    """(a stream for `dec` exactly as long as `orig_comp`, or None; the smallest
    body found). `room`, normally len(orig_comp), is how long the new body may be."""
    room = len(orig_comp) if room is None else room
    best = None
    for level, mem, strategy in ZLIB_GRID:
        body = deflate(dec, level, mem, strategy)
        best = len(body) if best is None else min(best, len(body))
        if len(body) <= room:
            return hybrid(orig_comp, body, dec), best
    if use_zopfli:
        body = zopfli_stream(dec)
        if body is not None:
            best = min(best, len(body))
            if len(body) <= room:
                return hybrid(orig_comp, body, dec), best
    return None, best


def rephrase(dec: bytearray, spots: list[tuple[int, list[bytes]]], room: int, measure=quick_size) -> int:
    """For each edited spot (offset in `dec`, the acceptable texts) picks the text that
    makes `dec` compress smallest, until it fits `room` or no choice helps any more.
    Changes `dec` in place; returns the size reached."""
    size = measure(bytes(dec))
    improved = True
    while size > room and improved:
        improved = False
        for at, alts in spots:
            n = len(alts[0])
            cur = bytes(dec[at:at + n])
            for alt in alts:
                if alt == cur:
                    continue
                dec[at:at + n] = alt
                s = measure(bytes(dec))
                if s < size:
                    size, cur, improved = s, alt, True
                    if size <= room:
                        return size
                else:
                    dec[at:at + n] = cur
    return size


def put_back(dec: bytearray, spots: list[tuple[int, bytes]], room: int, measure=quick_size) -> list[int]:
    """Puts the original bytes back at optional spots (offset in `dec`, original
    bytes), the most helpful first, until `dec` fits `room` or nothing helps.
    Returns the indexes of the spots put back."""
    done: list[int] = []
    size = measure(bytes(dec))
    left = list(range(len(spots)))
    while size > room and left:
        best = None
        for i in left:
            at, orig = spots[i]
            cur = bytes(dec[at:at + len(orig)])
            dec[at:at + len(orig)] = orig
            s = measure(bytes(dec))
            dec[at:at + len(orig)] = cur
            if best is None or s < best[0]:
                best = (s, i)
        s, i = best
        if s >= size:
            break
        at, orig = spots[i]
        dec[at:at + len(orig)] = orig
        done.append(i)
        left.remove(i)
        size = s
    return done


def recompress_same_length(orig_comp: bytes, dec: bytes) -> bytes:
    """A zlib stream for `dec` exactly as long as `orig_comp`: a shorter stream
    followed by the old tail, which zlib ignores after the end marker."""
    out, best = fit_stream(orig_comp, dec)
    if out is None:
        raise RuntimeError(f"cannot recompress into {len(orig_comp)} bytes (best {best})")
    return out


def inflate_slots(sds: bytes, streams: list[Stream]) -> bytes:
    """Inflates every stream from its slot (offset and length), the way the game
    reads blocks through the archive's block table, and joins them."""
    out = bytearray()
    for st in streams:
        d = zlib.decompressobj()
        dec = d.decompress(sds[st.sds_off:st.sds_off + st.comp_len])
        if not d.eof or len(dec) != st.dec_len:
            raise RuntimeError(f"the block at {st.sds_off} no longer inflates to {st.dec_len} bytes")
        out += dec
    return bytes(out)


def apply_writes(sds: bytes, blob: bytes, streams: list[Stream], writes: list[tuple[int, bytes]]) -> bytes:
    """New .sds bytes with the blob writes applied, every stream keeping its size."""
    out = bytearray(sds)
    patched = bytearray(blob)
    touched: set[int] = set()
    for at, data in writes:
        patched[at:at + len(data)] = data
        for k, st in enumerate(streams):
            if st.blob_start < at + len(data) and at < st.blob_start + st.dec_len:
                touched.add(k)
    for k in sorted(touched):
        st = streams[k]
        dec = bytes(patched[st.blob_start:st.blob_start + st.dec_len])
        orig = sds[st.sds_off:st.sds_off + st.comp_len]
        out[st.sds_off:st.sds_off + st.comp_len] = recompress_same_length(orig, dec)
    return bytes(out)


def save_json(path: Path, obj) -> None:
    path.write_text(json.dumps(obj, indent=1, ensure_ascii=False, default=str), encoding="utf-8")
