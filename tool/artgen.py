#!/usr/bin/env python3
"""Generate every awaited image for a zone, then review it before it ships.

    python3 tool/artgen.py --zone whispering_woods --dry-run
    python3 tool/artgen.py --zone glimmerbrook --kind icons
    python3 tool/artgen.py --review --zone glimmerbrook
    python3 tool/artgen.py --status

One zone is 20 to 30 pictures — 11 creatures, one arena backdrop, and between 8
and 18 item icons. This walks all of them: assembles each prompt from the art docs, calls
the image API, saves the raw source where `tool/pixelate.py` expects it, runs
pixelate, checks the file landed on its contract path, and records what
happened in `art/state.json`.

⭐ **The docs are the prompt database, and nothing is copied out of them.**
`docs/BESTIARY_ART.md` and `docs/ITEM_ART.md` are parsed on every run. A second
copy of a description inside this file would be one more thing to drift, and
the whole reason `art/prompts/` was retired.

⚠️ **The anchor formats in those two docs are load-bearing.** An entry is
`**Name** — *meta*` on its own line followed by a blockquote; an item and a
backdrop also carry a `` `assets/...` `` filename line. Break that shape and
this tool silently finds fewer assets — which is why `tool/test_artgen.py`
pins the counts at 55 creatures / 52 icons / 5 backdrops in both directions,
exactly as the Dart coverage tests do.

⭐ **Nothing is generated twice by accident.** The ledger remembers status per
asset, and a `--zone` run only touches what is `pending` or `rejected`.
Approved art and art waiting for review are skipped, because both already cost
money once.

Why each seam is where it is
----------------------------
⭐ **Four parts, deliberately separable**: `PromptSource` (docs -> prompts),
`ImageGenerator` (prompt -> bytes), `PostProcessor` (bytes -> game asset),
`Ledger` (what happened). Only the generator knows a vendor exists; swapping in
a `GeminiGenerator` is one class and no other edits. See `ImageGenerator` for
the interface that promise rests on.

⚠️ **The key is never printed, logged, committed or put in an exception.**
`OPENAI_API_KEY` from the environment, else a gitignored `.env` at the repo
root. Errors quote the HTTP status and the API's own message, never the
request headers.

⚠️ **Raw sources are not committed.** `art/source/` is gitignored: the ledger
holds the prompt and its hash, and a raw costs cents to make again. The
pixelated results in `assets/` are the artefacts that ship.

📝 **Review is local and dependency-free.** `--review` serves a contact sheet
off `http.server` bound to 127.0.0.1, showing each new picture beside its
in-game result at game scale — because a creature that reads fine at 1024px
can be mud at 128, and that is the only question worth asking.
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import html
import http.server
import json
import mimetypes
import os
import pathlib
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import webbrowser
from dataclasses import dataclass, field
from datetime import datetime, timezone

ROOT = pathlib.Path(__file__).resolve().parent.parent
BESTIARY_DOC = ROOT / "docs" / "BESTIARY_ART.md"
ITEM_DOC = ROOT / "docs" / "ITEM_ART.md"
PIXELATE = ROOT / "tool" / "pixelate.py"
SOURCE_DIR = ROOT / "art" / "source"
STATE_FILE = ROOT / "art" / "state.json"
ENV_FILE = ROOT / ".env"

# ⚠️ Written out rather than derived, for the same reason
# `test/creature_art_test.dart` writes them out: a zone that vanishes from a
# doc should fail loudly here, not quietly shrink every loop below to four.
ZONES = [
    "whispering_woods",
    "glimmerbrook",
    "cinderpeak_foothills",
    "thornmire",
    "ashfall_vale",
]

# ⭐ The palette a zone's creatures are locked to by `pixelate.py`. Hybrid
# zones use their LEAD element, so the generated art and the silhouette
# fallback agree about what you are fighting (IMPLEMENTATION_PLAN, Art row).
ZONE_ELEMENT = {
    "whispering_woods": "flora",
    "glimmerbrook": "aqua",
    "cinderpeak_foothills": "pyro",
    "thornmire": "flora",
    "ashfall_vale": "pyro",
}

KINDS = ("creature", "icon", "backdrop")

# What each kind asks the generator for.
#
# ⭐ **Backdrops are the only kind that is not square and not transparent.** A
# creature and an icon are one object that has to sit on the game's own panels,
# so they come back cut out; a backdrop is a whole scene and alpha in it would
# be a hole in the arena.
#
# ⚠️ **1536x1024 is 3:2, and the arena is 16:9.** That is fine and deliberate:
# `pixelate.py` cover-crops to 384x216, so the extra height is trimmed off the
# top and bottom rather than letterboxed. It does mean the very top and bottom
# of what the generator paints will not be in the game, which is why the
# backdrop briefs put nothing important there.
GEN_SIZE = {
    "creature": "1024x1024",
    "icon": "1024x1024",
    "backdrop": "1536x1024",
}
GEN_TRANSPARENT = {"creature": True, "icon": True, "backdrop": False}

MODEL = "gpt-image-1"
GENERATIONS_URL = "https://api.openai.com/v1/images/generations"
EDITS_URL = "https://api.openai.com/v1/images/edits"

# ⚠️ **Estimates, and stale the moment a price list changes.** Printed by
# `--dry-run` so a run of 30 pictures is a decision rather than a surprise;
# every number this tool prints from here is labelled as an estimate and points
# at the real price list. gpt-image-1 is priced per image by size and quality.
PRICE_URL = "https://openai.com/api/pricing/"
PRICE_NOTED = "2026-08"
PRICE_USD = {
    ("1024x1024", "low"): 0.011,
    ("1024x1024", "medium"): 0.042,
    ("1024x1024", "high"): 0.167,
    ("1536x1024", "low"): 0.016,
    ("1536x1024", "medium"): 0.063,
    ("1536x1024", "high"): 0.250,
}

# ⚠️ Retries exist for the two failures that are not the caller's fault: a rate
# limit and a server error. Everything else — a bad key, a rejected prompt — is
# reported once and immediately, because retrying it just wastes the operator's
# afternoon.
RETRY_STATUSES = {429, 500, 502, 503, 504}
MAX_ATTEMPTS = 4
BACKOFF_BASE = 2.0

LEDGER_VERSION = 1
STATUSES = ("pending", "generated", "approved", "rejected")


def now_iso() -> str:
    """The one clock in the tool.

    ⭐ Called at the CLI and server edges and passed *in* to everything else,
    so every record written during one run carries the same timestamp and the
    ledger is testable without freezing time.
    """
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


# ---- the prompt source ---------------------------------------------------


@dataclass(frozen=True)
class Asset:
    """One awaited picture, and everything needed to make it."""

    asset_id: str
    kind: str  # creature | icon | backdrop
    zone: str
    meta: str  # the doc's own `*rank · archetype · element*` line
    name: str
    target: str  # assets/... — the path the game asks for
    source: str  # art/source/... — where pixelate.py looks
    prompt: str

    @property
    def prompt_hash(self) -> str:
        return "sha256:" + hashlib.sha256(self.prompt.encode("utf-8")).hexdigest()[:16]

    @property
    def target_path(self) -> pathlib.Path:
        return ROOT / self.target

    @property
    def source_path(self) -> pathlib.Path:
        return ROOT / self.source

    @property
    def size(self) -> str:
        return GEN_SIZE[self.kind]

    @property
    def transparent(self) -> bool:
        return GEN_TRANSPARENT[self.kind]


_ENTRY_RE = re.compile(r"^\*\*([^*]+)\*\* — \*(.+?)\*\s*$")
_ENTRY_OPEN_RE = re.compile(r"^\*\*([^*]+)\*\* — \*")
_ZONE_HEAD_RE = re.compile(r"^## (.+)$")
_SUB_HEAD_RE = re.compile(r"^### (.+)$")
_ITEM_FILE_RE = re.compile(r"^`assets/items/([a-z_]+)/([a-z0-9_]+)\.png`")
_BACKDROP_FILE_RE = re.compile(r"^`assets/backgrounds/([a-z_]+)\.png`")
_PALETTE_RE = re.compile(r"^\*\*Palette:\*\*\s*(.+)$")

# Sentences that describe the *pipeline* rather than the picture. ⚠️ A prompt
# containing `python3 tool/pixelate.py --mode background` would be handed
# straight to a painter, so preamble prose is filtered before it is used.
_PIPELINE_MARKERS = ("python3 ", "tool/", "assets/", ".md", ".dart", "pubspec")


def slugify(name: str) -> str:
    """`The Standing Green` -> `the_standing_green`.

    ⚠️ Only used for creatures, whose doc entries carry no filename line. It is
    checked against the real `EnemyDef` ids parsed out of `lib/game/enemies/`,
    so a name that stops slugifying to its own id fails the run rather than
    generating art onto a path nothing loads.
    """
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")


def strip_markdown(text: str) -> str:
    """Blockquote and emphasis out, prose left.

    ⭐ The doc's ⭐/⚠️/📝 markers are addressed to the maintainer, not to a
    painter, and go too — as does the emphasis, since a generator reading
    `**pale grey-brown**` is reading two asterisk pairs it has to guess about.
    """
    out = []
    for line in text.splitlines():
        line = re.sub(r"^\s*>\s?", "", line)
        out.append(line)
    text = " ".join(out)
    text = text.replace("⭐", "").replace("⚠️", "").replace("📝", "")
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)
    text = re.sub(r"\*(.+?)\*", r"\1", text)
    text = re.sub(r"`([^`]*)`", r"\1", text)
    return re.sub(r"\s+", " ", text).strip()


def drop_pipeline_sentences(prose: str) -> str:
    """Keeps the art direction, drops the build instructions.

    The style sections of both docs mix the two in one paragraph — "generate at
    1920x1080, then run pixelate, so paint these muted". Only the last clause is
    a prompt.
    """
    kept = [
        s
        for s in re.split(r"(?<=[.!?])\s+", prose)
        if s and not any(m in s for m in _PIPELINE_MARKERS)
    ]
    return " ".join(kept).strip()


def unwrap_entries(text: str) -> str:
    """Rejoins the two anchor lines the docs are allowed to wrap.

    ⚠️ **Found the hard way**: the Heartwood Staff's stat line and every zone's
    `**Palette:**` line are longer than the docs' wrap column, and a strict
    one-line anchor silently found 51 icons instead of 52 and truncated five
    palettes mid-colour — exactly the "the coverage check quietly compares two
    empty sets" failure `test/item_icon_test.dart` warns about. Markdown treats
    the wrapped lines as one paragraph, so honouring the wrap is the correct
    read of the document rather than a workaround.

    ⭐ An entry stops at its closing `*`; a palette runs to the blank line,
    because it has no closing mark and the whole paragraph is the colour list.
    """
    lines = text.splitlines()
    out: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if _ENTRY_OPEN_RE.match(line) and not _ENTRY_RE.match(line):
            while i + 1 < len(lines) and lines[i + 1].strip():
                i += 1
                line = line.rstrip() + " " + lines[i].strip()
                if _ENTRY_RE.match(line):
                    break
        elif _PALETTE_RE.match(line):
            while i + 1 < len(lines) and lines[i + 1].strip():
                i += 1
                line = line.rstrip() + " " + lines[i].strip()
        out.append(line)
        i += 1
    return "\n".join(out)


def _paragraphs(text: str) -> list[str]:
    return [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]


def _paragraph_anchored_on(text: str, anchor: str) -> str:
    """The one paragraph containing [anchor], cleaned for a generator."""
    for para in _paragraphs(text):
        if anchor in para:
            return drop_pipeline_sentences(strip_markdown(para))
    raise LookupError(
        f"could not find the paragraph anchored on {anchor!r}. The style "
        f"guidance in the art doc moved or was reworded — artgen assembles "
        f"every prompt from it, so fix the anchor rather than the doc."
    )


def zone_of_heading(heading: str) -> str | None:
    """`## Whispering Woods · Lv 1–5 · Flora` -> `whispering_woods`."""
    zone = slugify(heading.split("·")[0])
    return zone if zone in ZONES else None


def enemy_ids() -> dict[str, str]:
    """Creature display name -> `EnemyDef.id`, read out of the Dart bestiary.

    ⭐ **Parsed rather than slugified-and-hoped**, for the same reason
    `pixelate.py` parses `element_style.dart` for its colours: the id is what
    `creatureAssetFor` builds a path from, and a tool that guessed it would
    generate perfectly good art into a filename the game never asks for. The
    slug is still checked against it below, so a divergence is loud.
    """
    out: dict[str, str] = {}
    for zone in ZONES:
        src = ROOT / "lib" / "game" / "enemies" / f"{zone}.dart"
        text = src.read_text(encoding="utf-8")
        for eid, name in re.findall(
            r"EnemyDef\(\s*id:\s*'([^']+)',\s*name:\s*'([^']+)'", text
        ):
            out[name] = eid
    if not out:
        raise LookupError(
            "parsed no EnemyDef ids out of lib/game/enemies/ — the definition "
            "shape changed and every creature path artgen builds would be a "
            "guess"
        )
    return out


class PromptSource:
    """The art docs, read as a database of awaited pictures.

    ⭐ **The only thing in this tool that knows what a prompt says.** Everything
    downstream sees an [Asset] — an id, a target path and a block of text — so
    the docs can be rewritten freely without touching the generator, the
    post-processor or the ledger.
    """

    def __init__(
        self,
        bestiary_doc: pathlib.Path | None = None,
        item_doc: pathlib.Path | None = None,
        names_to_ids: dict[str, str] | None = None,
    ) -> None:
        self._bestiary = unwrap_entries(
            (bestiary_doc or BESTIARY_DOC).read_text(encoding="utf-8")
        )
        self._items = unwrap_entries(
            (item_doc or ITEM_DOC).read_text(encoding="utf-8")
        )
        self._ids = names_to_ids if names_to_ids is not None else enemy_ids()
        self._cache: list[Asset] | None = None

    # -- the three style preambles, quoted out of the docs themselves --

    @property
    def creature_preamble(self) -> str:
        """The bestiary's house style: a naturalist's field plate."""
        return _paragraph_anchored_on(
            self._bestiary, "A house style, so the set looks like one bestiary"
        )

    @property
    def backdrop_preamble(self) -> str:
        """The duel screen's composition, which every backdrop has to survive."""
        parts = [
            _paragraph_anchored_on(
                self._bestiary,
                "The duel screen is the composition the description has to survive",
            ),
            _paragraph_anchored_on(self._bestiary, "Generate at 1920×1080"),
        ]
        return " ".join(p for p in parts if p)

    @property
    def icon_preamble(self) -> str:
        """ITEM_ART's shared preamble — the doc says prepend it to every prompt."""
        head = "### ⭐ The shared style preamble"
        idx = self._items.find(head)
        if idx < 0:
            raise LookupError(
                f"{head!r} is gone from docs/ITEM_ART.md — it is the first half "
                f"of all 52 icon prompts"
            )
        block: list[str] = []
        for line in self._items[idx:].splitlines()[1:]:
            if line.startswith(">"):
                block.append(line)
            elif block:
                break
        if not block:
            raise LookupError(
                "the shared style preamble heading has no blockquote under it"
            )
        return strip_markdown("\n".join(block))

    # -- the walk --

    def assets(self, zone: str | None = None, kind: str | None = None) -> list[Asset]:
        if self._cache is None:
            self._cache = self._parse_creatures() + self._parse_icons()
        out = self._cache
        if zone:
            out = [a for a in out if a.zone == zone]
        if kind:
            out = [a for a in out if a.kind == kind]
        return out

    def by_id(self, asset_id: str) -> Asset | None:
        for a in self.assets():
            if a.asset_id == asset_id:
                return a
        return None

    def _parse_creatures(self) -> list[Asset]:
        """Creatures and arena backdrops, both out of BESTIARY_ART.md."""
        preamble = self.creature_preamble
        backdrop_preamble = self.backdrop_preamble
        out: list[Asset] = []

        zone: str | None = None
        zone_note = ""
        section = ""
        section_note = ""
        pending: tuple[str, str] | None = None  # (name, meta)
        quote: list[str] = []
        backdrop_file: str | None = None

        def flush() -> None:
            nonlocal pending, quote, zone_note, section_note, backdrop_file
            body = strip_markdown("\n".join(quote))
            if pending and zone and body:
                name, meta = pending
                eid = self._ids.get(name) or slugify(name)
                if slugify(name) != eid:
                    raise LookupError(
                        f"{name!r} has EnemyDef id {eid!r}, which is not its own "
                        f"slug — artgen names the source file after the id, so "
                        f"check `creatureAssetFor` before generating"
                    )
                out.append(
                    Asset(
                        asset_id=eid,
                        kind="creature",
                        zone=zone,
                        meta=strip_markdown(meta),
                        name=name,
                        target=f"assets/creatures/{zone}/{eid}.png",
                        source=f"art/source/{zone}/{eid}.png",
                        prompt="\n\n".join(
                            p
                            for p in (preamble, zone_note, section_note, body)
                            if p
                        ),
                    )
                )
            elif backdrop_file and zone and body:
                if backdrop_file != zone:
                    raise LookupError(
                        f"the {zone} section's backdrop names "
                        f"assets/backgrounds/{backdrop_file}.png — one of the "
                        f"two is a typo, and `backdropFor` only ever asks for "
                        f"the zone's own id"
                    )
                out.append(
                    Asset(
                        asset_id=zone,
                        kind="backdrop",
                        zone=zone,
                        meta="arena backdrop",
                        name=f"{zone} arena",
                        target=f"assets/backgrounds/{zone}.png",
                        source=f"art/source/backgrounds/{zone}.png",
                        prompt="\n\n".join(
                            p for p in (backdrop_preamble, zone_note, body) if p
                        ),
                    )
                )
            elif quote and zone and not pending and not backdrop_file:
                # A blockquote with no entry above it is art direction for
                # whatever scope it sits in.
                if section:
                    section_note = body
                else:
                    zone_note = body
            pending = None
            backdrop_file = None
            quote = []

        for line in self._bestiary.splitlines():
            if _ZONE_HEAD_RE.match(line):
                flush()
                zone = zone_of_heading(_ZONE_HEAD_RE.match(line).group(1))
                zone_note = ""
                section = ""
                section_note = ""
                continue
            if _SUB_HEAD_RE.match(line):
                flush()
                section = _SUB_HEAD_RE.match(line).group(1)
                section_note = ""
                continue
            m = _ENTRY_RE.match(line)
            if m:
                flush()
                pending = (m.group(1), m.group(2))
                continue
            m = _BACKDROP_FILE_RE.match(line)
            if m:
                flush()
                backdrop_file = m.group(1)
                continue
            if line.startswith(">"):
                quote.append(line)
                continue
            if not line.strip():
                if quote:
                    flush()
                continue
            # Any other prose ends whatever was being collected.
            flush()
        flush()
        return out

    def _parse_icons(self) -> list[Asset]:
        """One icon per entry in ITEM_ART.md, keyed by its own filename line."""
        preamble = self.icon_preamble
        out: list[Asset] = []

        zone: str | None = None
        zone_note = ""
        palette = ""
        section = ""
        section_note = ""
        pending: tuple[str, str] | None = None
        filed: tuple[str, str] | None = None
        quote: list[str] = []

        def flush() -> None:
            nonlocal pending, filed, quote, zone_note, section_note
            body = strip_markdown("\n".join(quote))
            if pending and filed and body:
                name, meta = pending
                file_zone, item_id = filed
                out.append(
                    Asset(
                        asset_id=item_id,
                        kind="icon",
                        zone=file_zone,
                        meta=strip_markdown(meta),
                        name=name,
                        target=f"assets/items/{file_zone}/{item_id}.png",
                        source=f"art/source/items/{file_zone}/{item_id}.png",
                        prompt="\n\n".join(
                            p
                            for p in (
                                preamble,
                                zone_note,
                                f"Palette: {palette}" if palette else "",
                                section_note,
                                body,
                            )
                            if p
                        ),
                    )
                )
            elif quote and zone and not pending:
                if section:
                    section_note = body
                else:
                    zone_note = body
            pending = None
            filed = None
            quote = []

        for line in self._items.splitlines():
            if _ZONE_HEAD_RE.match(line):
                flush()
                zone = zone_of_heading(_ZONE_HEAD_RE.match(line).group(1))
                zone_note = ""
                palette = ""
                section = ""
                section_note = ""
                continue
            if _SUB_HEAD_RE.match(line):
                flush()
                section = _SUB_HEAD_RE.match(line).group(1)
                section_note = ""
                continue
            m = _PALETTE_RE.match(line)
            if m and zone:
                palette = strip_markdown(m.group(1))
                continue
            m = _ENTRY_RE.match(line)
            if m:
                flush()
                pending = (m.group(1), m.group(2))
                continue
            m = _ITEM_FILE_RE.match(line)
            if m and pending:
                filed = (m.group(1), m.group(2))
                continue
            if line.startswith(">"):
                quote.append(line)
                continue
            if not line.strip():
                if quote:
                    flush()
                continue
            flush()
        flush()
        return out


# ---- the ledger ----------------------------------------------------------


class Ledger:
    """What has been generated, what it cost, and what the reviewer said.

    ⭐ **Committed**, unlike the raws it points at. A record is the receipt for
    a picture: the prompt hash it was made from, the model that made it, how
    many attempts it took and every word of rejection feedback. That is enough
    to reproduce a run without keeping a megabyte of PNG in git.

    ⚠️ **Prompt drift is flagged, never acted on.** If a doc paragraph is
    rewritten after its art was approved, the record's hash stops matching and
    listings say `stale` — but nothing regenerates, because a reworded sentence
    is usually a typo fix and art is not free.
    """

    def __init__(self, path: pathlib.Path | None = None) -> None:
        self.path = path or STATE_FILE
        if self.path.exists():
            data = json.loads(self.path.read_text(encoding="utf-8"))
        else:
            data = {"version": LEDGER_VERSION, "assets": {}}
        self.version = data.get("version", LEDGER_VERSION)
        self.assets: dict[str, dict] = data.get("assets", {})

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text(
            json.dumps(
                {"version": self.version, "assets": dict(sorted(self.assets.items()))},
                indent=2,
                ensure_ascii=False,
            )
            + "\n",
            encoding="utf-8",
        )

    def get(self, asset_id: str) -> dict | None:
        return self.assets.get(asset_id)

    def status(self, asset: Asset) -> str:
        rec = self.assets.get(asset.asset_id)
        return rec["status"] if rec else "pending"

    def is_stale(self, asset: Asset) -> bool:
        """The doc changed after this record was written."""
        rec = self.assets.get(asset.asset_id)
        if not rec or rec["status"] == "pending":
            return False
        return rec.get("prompt_hash") != asset.prompt_hash

    def feedback(self, asset_id: str) -> list[str]:
        rec = self.assets.get(asset_id)
        return [f["text"] for f in rec.get("feedback", [])] if rec else []

    def record_generated(
        self, asset: Asset, *, model: str, now: str, processed: bool = False
    ) -> dict:
        rec = self.assets.setdefault(
            asset.asset_id,
            {
                "kind": asset.kind,
                "zone": asset.zone,
                "target": asset.target,
                "source": asset.source,
                "status": "pending",
                "attempts": 0,
                "feedback": [],
            },
        )
        rec.update(
            {
                "kind": asset.kind,
                "zone": asset.zone,
                "target": asset.target,
                "source": asset.source,
                "status": "generated",
                "prompt_hash": asset.prompt_hash,
                "model": model,
                "attempts": rec.get("attempts", 0) + 1,
                "processed": processed,
                "updated": now,
            }
        )
        return rec

    def mark_processed(self, asset_id: str, *, now: str) -> None:
        rec = self.assets[asset_id]
        rec["processed"] = True
        rec["updated"] = now

    def approve(self, asset_id: str, *, now: str) -> None:
        rec = self.assets[asset_id]
        rec["status"] = "approved"
        rec["updated"] = now

    def reject(self, asset_id: str, *, feedback: str, now: str) -> None:
        """⚠️ Feedback is required, because it is the whole next prompt.

        A rejection with no words is a picture that will be regenerated
        identically and rejected again.
        """
        text = feedback.strip()
        if not text:
            raise ValueError(
                "a rejection needs feedback — it becomes the edit instruction "
                "for the next attempt, and without it nothing changes"
            )
        rec = self.assets[asset_id]
        rec["status"] = "rejected"
        rec.setdefault("feedback", []).append({"at": now, "text": text})
        rec["updated"] = now


# ---- the generator adapter ----------------------------------------------


class GeneratorError(RuntimeError):
    """A generation failed. ⚠️ Never carries the API key; see `_fail`."""


class ImageGenerator:
    """The one seam a different image vendor has to fit through.

    ⭐ **Two methods and one attribute**, and nothing above this class knows a
    vendor exists:

        name: str
            Recorded in the ledger as the record's `model`, so a picture can
            always be traced to what drew it.

        generate(prompt: str, *, size: str, transparent: bool) -> bytes
            A fresh picture from nothing but the prompt. `size` is a
            `"<w>x<h>"` string chosen by the caller from [GEN_SIZE];
            `transparent` asks for alpha rather than a painted ground.
            Returns raw image bytes (PNG), never a URL or a file path.

        edit(prompt: str, *, size: str, transparent: bool, image: bytes) -> bytes
            The same, but starting from [image] — the previous raw for this
            asset — with [prompt] carrying the reviewer's feedback. This is
            how a rejection becomes a second attempt that is recognisably the
            same picture rather than a fresh roll of the dice.

    A `GeminiGenerator` implementing exactly those three is a drop-in: the
    orchestrator picks `edit` over `generate` purely on whether the ledger holds
    feedback, and hands back bytes to `PostProcessor` either way. ⚠️ An adapter
    whose vendor has no edit endpoint should implement `edit` by folding the
    feedback into the prompt and calling `generate` — never by raising, because
    the review loop's whole value is that a rejection goes somewhere.
    """

    name = "abstract"

    def generate(self, prompt: str, *, size: str, transparent: bool) -> bytes:
        raise NotImplementedError

    def edit(
        self, prompt: str, *, size: str, transparent: bool, image: bytes
    ) -> bytes:
        raise NotImplementedError


def http_post(url: str, *, data: bytes, headers: dict[str, str]) -> tuple[int, bytes]:
    """The default transport: one POST, status and body, no exceptions for 4xx.

    ⭐ Injectable so `tool/test_artgen.py` can assert the exact shape of every
    request without a network, which is the only way the transparent-background
    and edits-endpoint rules stay true.
    """
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=300) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as exc:  # 4xx/5xx carry a useful body
        return exc.code, exc.read()
    except urllib.error.URLError as exc:
        raise GeneratorError(f"could not reach {url}: {exc.reason}") from None


class OpenAIGenerator(ImageGenerator):
    """gpt-image-1, over `urllib`.

    ⚠️ **The key exists in exactly one place** — `self._key`, read once — and
    is never formatted into a message. `_fail` below builds every error this
    class raises, from the status code and the API's own `error.message`.
    """

    name = MODEL

    def __init__(
        self,
        api_key: str,
        *,
        model: str = MODEL,
        quality: str = "medium",
        transport=http_post,
        sleep=time.sleep,
    ) -> None:
        if not api_key:
            raise GeneratorError(
                "no API key. Set OPENAI_API_KEY, or put OPENAI_API_KEY=sk-... "
                "in a .env at the repo root (it is gitignored)."
            )
        self._key = api_key
        self.name = model
        self.model = model
        self.quality = quality
        self._transport = transport
        self._sleep = sleep

    # -- requests --

    def generate(self, prompt: str, *, size: str, transparent: bool) -> bytes:
        body = {
            "model": self.model,
            "prompt": prompt,
            "n": 1,
            "size": size,
            "quality": self.quality,
            "output_format": "png",
        }
        # ⚠️ Sent only when it is wanted. `background: opaque` on a backdrop
        # would be harmless, but the absence is what the test asserts on and
        # what makes the rule visible: only cut-out kinds ask for alpha.
        if transparent:
            body["background"] = "transparent"
        return self._post_json(GENERATIONS_URL, body)

    def edit(
        self, prompt: str, *, size: str, transparent: bool, image: bytes
    ) -> bytes:
        fields = {
            "model": self.model,
            "prompt": prompt,
            "n": "1",
            "size": size,
            "quality": self.quality,
        }
        if transparent:
            fields["background"] = "transparent"
        data, content_type = _multipart(fields, [("image", "source.png", image)])
        return self._send(EDITS_URL, data, {"Content-Type": content_type})

    # -- plumbing --

    def _post_json(self, url: str, body: dict) -> bytes:
        return self._send(
            url,
            json.dumps(body).encode("utf-8"),
            {"Content-Type": "application/json"},
        )

    def _send(self, url: str, data: bytes, headers: dict[str, str]) -> bytes:
        headers = dict(headers)
        headers["Authorization"] = f"Bearer {self._key}"
        for attempt in range(1, MAX_ATTEMPTS + 1):
            status, raw = self._transport(url, data=data, headers=headers)
            if status == 200:
                return self._decode(raw)
            if status in RETRY_STATUSES and attempt < MAX_ATTEMPTS:
                wait = BACKOFF_BASE ** attempt
                print(
                    f"    HTTP {status} — retrying in {wait:.0f}s "
                    f"({attempt}/{MAX_ATTEMPTS - 1})"
                )
                self._sleep(wait)
                continue
            self._fail(status, raw)
        raise GeneratorError("unreachable")  # pragma: no cover

    def _decode(self, raw: bytes) -> bytes:
        payload = json.loads(raw)
        data = payload.get("data") or []
        if not data or "b64_json" not in data[0]:
            raise GeneratorError(
                "the API returned no image data — the response had keys "
                f"{sorted(payload)} and {len(data)} item(s)"
            )
        return base64.b64decode(data[0]["b64_json"])

    def _fail(self, status: int, raw: bytes) -> None:
        """⚠️ **The only place an error is built**, and it never sees the key.

        Everything here comes from the status line and the API's own message,
        so no traceback, log line or CI transcript can ever leak a credential.
        """
        try:
            message = json.loads(raw).get("error", {}).get("message", "")
        except (ValueError, AttributeError):
            message = ""
        message = re.sub(r"sk-[A-Za-z0-9_\-]{8,}", "<redacted>", message)
        if status == 401:
            raise GeneratorError(
                "HTTP 401 — the image API rejected the credential. Check "
                "OPENAI_API_KEY (or the .env at the repo root); the key itself "
                "is deliberately never printed."
            )
        if status == 400:
            raise GeneratorError(
                f"HTTP 400 — the request or the prompt was rejected: "
                f"{message or 'no message'}"
            )
        raise GeneratorError(f"HTTP {status}: {message or 'no message'}")


def _multipart(
    fields: dict[str, str], files: list[tuple[str, str, bytes]]
) -> tuple[bytes, str]:
    """A minimal `multipart/form-data` body. Stdlib has no builder for one."""
    boundary = "----artgen" + hashlib.sha256(os.urandom(16)).hexdigest()[:24]
    out = bytearray()
    for key, value in fields.items():
        out += f"--{boundary}\r\n".encode()
        out += f'Content-Disposition: form-data; name="{key}"\r\n\r\n'.encode()
        out += f"{value}\r\n".encode()
    for key, filename, blob in files:
        ctype = mimetypes.guess_type(filename)[0] or "application/octet-stream"
        out += f"--{boundary}\r\n".encode()
        out += (
            f'Content-Disposition: form-data; name="{key}"; '
            f'filename="{filename}"\r\n'
        ).encode()
        out += f"Content-Type: {ctype}\r\n\r\n".encode()
        out += blob + b"\r\n"
    out += f"--{boundary}--\r\n".encode()
    return bytes(out), f"multipart/form-data; boundary={boundary}"


def edit_instruction(prompt: str, feedback: list[str]) -> str:
    """The prompt a rejected picture gets on its next attempt.

    ⭐ **The brief, then every note, oldest first.** The original description is
    still the target — feedback is a correction to it, not a replacement — and
    all of it is carried rather than only the newest note, because a second
    reviewer pass that fixes the eyes must not un-fix the scale.
    """
    notes = "\n".join(f"- {f}" for f in feedback)
    return (
        f"{prompt}\n\n"
        f"Revise the attached image to match the description above, keeping "
        f"its composition and subject, and applying these corrections:\n{notes}"
    )


def read_api_key(env: dict[str, str] | None = None, env_file: pathlib.Path | None = None) -> str:
    """`OPENAI_API_KEY` from the environment, else from a gitignored `.env`.

    ⚠️ The `.env` parse is deliberately minimal — `KEY=value`, one per line,
    `#` comments, optional surrounding quotes. It is not a dotenv
    implementation and should never grow into one; anything more elaborate
    belongs in the shell.
    """
    env = os.environ if env is None else env
    key = (env.get("OPENAI_API_KEY") or "").strip()
    if key:
        return key
    path = env_file or ENV_FILE
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            name, _, value = line.partition("=")
            if name.strip() == "OPENAI_API_KEY":
                return value.strip().strip("'\"")
    return ""


# ---- the post-processor --------------------------------------------------


class PostProcessor:
    """`tool/pixelate.py`, invoked with the right flags for the kind.

    ⭐ **Shelled out to, never reimplemented.** Every finding in that file — 128
    not 64, area-average downsampling, alpha lifted out before quantising, an
    icon getting none of a creature's treatment — is one this tool would have
    to rediscover, and a second copy would drift the first time one of them is
    revised.

    ⚠️ **pixelate works per zone, not per file.** One run re-processes every
    source in the zone directory, which is idempotent and cheap next to a
    generation, so a single regenerated creature costs a re-pixelate of its ten
    neighbours. Worth knowing before wondering why `--only` prints eleven lines.
    """

    def __init__(self, runner=subprocess.run, cutout: bool = False) -> None:
        self._run = runner
        self.cutout = cutout

    def argv(self, kind: str, zone: str) -> list[str]:
        base = [sys.executable, str(PIXELATE), "--zone", zone]
        if kind == "backdrop":
            return base + ["--mode", "background"]
        if kind == "icon":
            return base + ["--mode", "icon"]
        argv = base + ["--element", ZONE_ELEMENT[zone]]
        # ⚠️ **Off by default, unlike a hand-run pixelate.** The generator is
        # asked for `background: transparent`, so a creature arrives already cut
        # out and `rembg` would be a heavyweight no-op — and an install this
        # tool would otherwise force on everyone. `--cutout` puts it back for
        # sources that came from somewhere else.
        if self.cutout:
            argv.append("--cutout")
        return argv

    def run(self, kind: str, zone: str) -> None:
        argv = self.argv(kind, zone)
        result = self._run(argv, cwd=str(ROOT))
        if getattr(result, "returncode", 0) != 0:
            raise RuntimeError(
                f"pixelate failed for {zone} {kind}s (exit "
                f"{result.returncode}): {' '.join(argv[1:])}"
            )


def has_alpha(png: bytes) -> bool:
    """Whether a PNG's IHDR declares an alpha channel.

    ⭐ Stdlib rather than Pillow, so the check costs nothing and works before
    pixelate's dependencies are installed. Colour type 4 is grey+alpha, 6 is
    RGBA. ⚠️ A heuristic on purpose: an RGBA image whose alpha is entirely
    opaque still passes, and only a real look at the picture would catch that.
    """
    return len(png) > 26 and png[:8] == b"\x89PNG\r\n\x1a\n" and png[25] in (4, 6)


# ---- the run -------------------------------------------------------------


@dataclass
class Plan:
    """What a `--zone` run would do, before it does any of it."""

    make: list[Asset] = field(default_factory=list)
    reprocess: list[Asset] = field(default_factory=list)
    skipped: list[tuple[Asset, str]] = field(default_factory=list)


def estimate_cost(assets: list[Asset], quality: str) -> tuple[float, list[str]]:
    """A labelled guess at what a run costs, and the assumptions behind it."""
    total = 0.0
    unknown = []
    for a in assets:
        price = PRICE_USD.get((a.size, quality))
        if price is None:
            unknown.append(f"{a.size}/{quality}")
        else:
            total += price
    notes = [
        f"⚠️  ESTIMATE ONLY — list prices noted {PRICE_NOTED}, quality "
        f"'{quality}':",
    ]
    for (size, qual), price in sorted(PRICE_USD.items()):
        if qual == quality:
            notes.append(f"      {size}  ${price:.3f} per image")
    notes.append(f"      verify at {PRICE_URL} — this tool does not check.")
    if unknown:
        notes.append(f"      no price on record for {sorted(set(unknown))}")
    return total, notes


def build_plan(
    source: PromptSource,
    ledger: Ledger,
    *,
    zone: str | None,
    kind: str | None,
    only: str | None,
    force: bool,
) -> Plan:
    """Which assets a run touches, and why it leaves the rest alone.

    ⭐ **`pending` and `rejected` are the work.** `approved` is finished and
    `generated` is waiting on a human — regenerating either spends money to
    throw away the thing that was about to be looked at.
    """
    plan = Plan()
    assets = source.assets(zone=zone, kind=kind)
    if only:
        assets = [a for a in assets if a.asset_id == only]
        if not assets:
            raise SystemExit(
                f"no asset called {only!r}. `--status` lists every id."
            )
    for asset in assets:
        status = ledger.status(asset)
        rec = ledger.get(asset.asset_id)
        if force or status in ("pending", "rejected"):
            plan.make.append(asset)
        elif status == "generated" and rec and not rec.get("processed", False):
            # A raw that was paid for but never made it through pixelate.
            plan.reprocess.append(asset)
        else:
            plan.skipped.append((asset, status))
    return plan


def generate_one(
    asset: Asset,
    generator: ImageGenerator,
    ledger: Ledger,
) -> bytes:
    """One picture. `edit` if the reviewer said something, `generate` if not."""
    feedback = ledger.feedback(asset.asset_id)
    previous = asset.source_path
    if feedback and previous.exists():
        return generator.edit(
            edit_instruction(asset.prompt, feedback),
            size=asset.size,
            transparent=asset.transparent,
            image=previous.read_bytes(),
        )
    if feedback:
        # ⚠️ Rejected but the raw is gone (art/source/ is not committed, so a
        # fresh clone has none). Fold the notes into a plain generation rather
        # than losing them.
        return generator.generate(
            edit_instruction(asset.prompt, feedback).replace(
                "Revise the attached image to", "Paint this so as to"
            ),
            size=asset.size,
            transparent=asset.transparent,
        )
    return generator.generate(
        asset.prompt, size=asset.size, transparent=asset.transparent
    )


def run_zone(
    source: PromptSource,
    ledger: Ledger,
    generator: ImageGenerator | None,
    post: PostProcessor,
    plan: Plan,
    *,
    now: str,
) -> list[str]:
    """Generate, place, verify. Returns the ids that landed on their path."""
    landed: list[str] = []
    touched: set[tuple[str, str]] = set()

    for asset in plan.make:
        print(f"  {asset.kind:9} {asset.asset_id}")
        blob = generate_one(asset, generator, ledger)
        asset.source_path.parent.mkdir(parents=True, exist_ok=True)
        asset.source_path.write_bytes(blob)
        if asset.transparent and not has_alpha(blob):
            print(
                "    ⚠️  the raw has no alpha channel — pass --cutout so "
                "pixelate strips the background"
            )
        ledger.record_generated(asset, model=generator.name, now=now)
        ledger.save()
        touched.add((asset.kind, asset.zone))

    for asset in plan.reprocess:
        print(f"  {asset.kind:9} {asset.asset_id}  (raw already on disk)")
        touched.add((asset.kind, asset.zone))

    for kind, zone in sorted(touched):
        print(f"\npixelate: {zone} {kind}s")
        post.run(kind, zone)

    for asset in plan.make + plan.reprocess:
        if asset.target_path.exists():
            ledger.mark_processed(asset.asset_id, now=now)
            landed.append(asset.asset_id)
        else:
            print(
                f"⚠️  {asset.asset_id}: pixelate ran but {asset.target} is not "
                f"there — the game will keep drawing its fallback"
            )
    ledger.save()
    return landed


# ---- verification --------------------------------------------------------

CONTRACT_TESTS = [
    "test/creature_art_test.dart",
    "test/arena_backdrop_test.dart",
    "test/item_icon_test.dart",
]


def verify(runner=subprocess.run) -> bool:
    """The three Dart suites that decide whether a PNG is loadable art.

    ⭐ Run *here*, right after placement, because every one of their failures
    is invisible in game: a stem that is not a real id, a file in the wrong
    zone, a directory nobody declared in pubspec — the art ships and the screen
    does not change.
    """
    print("\nflutter test " + " ".join(CONTRACT_TESTS))
    result = runner(["flutter", "test", *CONTRACT_TESTS], cwd=str(ROOT))
    ok = getattr(result, "returncode", 0) == 0
    print("contract tests: " + ("PASS" if ok else "FAIL"))
    return ok


# ---- the review sheet ----------------------------------------------------

REVIEW_CSS = """
:root { color-scheme: dark; }
* { box-sizing: border-box; }
body { margin: 0; padding: 24px; background: #14121a; color: #e8e4dc;
       font: 15px/1.5 ui-sans-serif, system-ui, -apple-system, sans-serif; }
h1 { font-size: 20px; margin: 0 0 4px; letter-spacing: .02em; }
.sub { color: #9a93a8; margin: 0 0 24px; font-size: 13px; }
.card { border: 1px solid #2e2938; border-radius: 8px; background: #1b1824;
        margin-bottom: 20px; overflow: hidden; }
.head { display: flex; gap: 12px; align-items: baseline; padding: 12px 16px;
        border-bottom: 1px solid #2e2938; background: #201c2b; }
.head b { font-size: 15px; }
.id { color: #7f8fd8; font-family: ui-monospace, monospace; font-size: 12px; }
.meta { color: #9a93a8; font-size: 12px; margin-left: auto; }
.panes { display: flex; flex-wrap: wrap; gap: 24px; padding: 16px; }
.pane { display: flex; flex-direction: column; gap: 8px; }
.label { color: #9a93a8; font-size: 11px; text-transform: uppercase;
         letter-spacing: .08em; }
.raw img { width: 256px; height: auto; border: 1px solid #2e2938;
           border-radius: 4px; background: #0d0b12; }
.game img { image-rendering: pixelated; }
.slot { width: 40px; height: 40px; border: 1px solid #4a4356; border-radius: 4px;
        background: #0d0b12; display: grid; place-items: center; }
.slot img { width: 38px; height: 38px; }
.creature img { width: 256px; height: 256px; }
.backdrop img { width: 384px; height: 216px; border: 1px solid #2e2938; }
.prompt { padding: 0 16px 16px; }
.prompt details { color: #9a93a8; font-size: 12px; }
.prompt pre { white-space: pre-wrap; background: #131019; padding: 12px;
              border-radius: 4px; color: #b9b2c6; font-size: 12px; }
form { display: flex; gap: 10px; align-items: stretch; padding: 0 16px 16px; }
textarea { flex: 1; min-height: 54px; background: #131019; color: #e8e4dc;
           border: 1px solid #3a3448; border-radius: 4px; padding: 8px;
           font: inherit; font-size: 13px; resize: vertical; }
button { border: 0; border-radius: 4px; padding: 10px 18px; font: inherit;
         font-weight: 600; cursor: pointer; }
.ok { background: #2f6b45; color: #eafff1; }
.no { background: #6b2f35; color: #ffeaea; }
.note { color: #c8a24a; font-size: 12px; margin: 0 16px 12px; }
.done { padding: 40px; text-align: center; color: #9a93a8; }
"""


class ReviewHandler(http.server.BaseHTTPRequestHandler):
    """The contact sheet. ⚠️ Bound to 127.0.0.1 only — see `serve_review`."""

    source: PromptSource
    ledger: Ledger
    zone_filter: str | None = None

    def log_message(self, fmt, *args):  # quieter than the default
        pass

    # -- GET --

    def do_GET(self) -> None:
        path = urllib.parse.urlparse(self.path).path
        if path == "/":
            self._send_html(self._sheet())
            return
        m = re.match(r"^/img/(raw|out)/([a-z0-9_]+)\.png$", path)
        if m:
            self._send_image(m.group(1), m.group(2))
            return
        self.send_error(404)

    def _pending(self) -> list[Asset]:
        return [
            a
            for a in self.source.assets(zone=self.zone_filter)
            if self.ledger.status(a) == "generated"
            and (self.ledger.get(a.asset_id) or {}).get("processed")
        ]

    def _send_html(self, body: str) -> None:
        blob = body.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(blob)))
        self.end_headers()
        self.wfile.write(blob)

    def _send_image(self, which: str, asset_id: str) -> None:
        asset = self.source.by_id(asset_id)
        if asset is None:
            self.send_error(404)
            return
        path = asset.source_path if which == "raw" else asset.target_path
        if not path.exists():
            self.send_error(404)
            return
        blob = path.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", "image/png")
        self.send_header("Content-Length", str(len(blob)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(blob)

    def _sheet(self) -> str:
        waiting = self._pending()
        scope = self.zone_filter or "every zone"
        cards = "".join(self._card(a) for a in waiting)
        if not waiting:
            cards = (
                "<div class='done'>Nothing waiting for review in "
                f"{html.escape(scope)}.<br>Generate some art first: "
                "<code>python3 tool/artgen.py --zone &lt;zone&gt;</code></div>"
            )
        return (
            "<!doctype html><html><head><meta charset='utf-8'>"
            "<title>artgen review</title>"
            f"<style>{REVIEW_CSS}</style></head><body>"
            f"<h1>artgen — review</h1>"
            f"<p class='sub'>{len(waiting)} awaiting review in "
            f"{html.escape(scope)}. Left is what the generator returned; right "
            f"is what the game will draw, at the size the game draws it.</p>"
            f"{cards}</body></html>"
        )

    def _card(self, a: Asset) -> str:
        rec = self.ledger.get(a.asset_id) or {}
        game_class = {"icon": "slot", "creature": "creature", "backdrop": "backdrop"}[
            a.kind
        ]
        scale = {
            "icon": "40px backpack slot",
            "creature": "128px sprite at 2x",
            "backdrop": "384x216, actual size",
        }[a.kind]
        history = "".join(
            f"<p class='note'>⟲ {html.escape(f['text'])}</p>"
            for f in rec.get("feedback", [])
        )
        game_inner = (
            f"<div class='slot'><img src='/img/out/{a.asset_id}.png' alt=''></div>"
            if a.kind == "icon"
            else f"<img src='/img/out/{a.asset_id}.png' alt=''>"
        )
        return f"""
<div class="card">
  <div class="head">
    <b>{html.escape(a.name)}</b>
    <span class="id">{html.escape(a.asset_id)}</span>
    <span class="meta">{html.escape(a.meta)} · attempt
      {rec.get('attempts', 1)} · {html.escape(a.target)}</span>
  </div>
  {history}
  <div class="panes">
    <div class="pane raw">
      <span class="label">generated source · {html.escape(a.size)}</span>
      <img src="/img/raw/{a.asset_id}.png" alt="">
    </div>
    <div class="pane game {game_class}">
      <span class="label">in game · {html.escape(scale)}</span>
      {game_inner}
    </div>
  </div>
  <div class="prompt">
    <details><summary>prompt</summary><pre>{html.escape(a.prompt)}</pre></details>
  </div>
  <form method="post" action="/decide">
    <input type="hidden" name="asset_id" value="{html.escape(a.asset_id)}">
    <textarea name="feedback" placeholder="What is wrong with it? Required on reject &mdash; this text becomes the edit instruction for the next attempt."></textarea>
    <button class="ok" name="decision" value="approve">Approve</button>
    <button class="no" name="decision" value="reject">Reject</button>
  </form>
</div>"""

    # -- POST --

    def do_POST(self) -> None:
        if urllib.parse.urlparse(self.path).path != "/decide":
            self.send_error(404)
            return
        length = int(self.headers.get("Content-Length", 0))
        form = urllib.parse.parse_qs(self.rfile.read(length).decode("utf-8"))
        asset_id = (form.get("asset_id") or [""])[0]
        decision = (form.get("decision") or [""])[0]
        feedback = (form.get("feedback") or [""])[0]
        now = now_iso()
        try:
            if decision == "approve":
                self.ledger.approve(asset_id, now=now)
                print(f"  approved  {asset_id}")
            elif decision == "reject":
                self.ledger.reject(asset_id, feedback=feedback, now=now)
                print(f"  rejected  {asset_id}: {feedback.strip()[:60]}")
            else:
                self.send_error(400, "unknown decision")
                return
            self.ledger.save()
        except (KeyError, ValueError) as exc:
            self._send_html(
                "<!doctype html><html><head><meta charset='utf-8'>"
                f"<style>{REVIEW_CSS}</style></head><body>"
                f"<h1>Not recorded</h1><p class='sub'>{html.escape(str(exc))}</p>"
                "<p><a style='color:#7f8fd8' href='/'>back</a></p></body></html>"
            )
            return
        self.send_response(303)
        self.send_header("Location", "/")
        self.end_headers()


def serve_review(
    source: PromptSource, ledger: Ledger, zone: str | None, port: int, open_browser: bool
) -> None:
    handler = type(
        "BoundReviewHandler",
        (ReviewHandler,),
        {"source": source, "ledger": ledger, "zone_filter": zone},
    )
    # ⚠️ **127.0.0.1, never 0.0.0.0.** The sheet writes the ledger on POST with
    # no authentication of any kind; it is a local tool and must not be
    # reachable from the network.
    server = http.server.ThreadingHTTPServer(("127.0.0.1", port), handler)
    url = f"http://127.0.0.1:{server.server_port}/"
    print(f"review sheet: {url}   (ctrl-c to stop)")
    if open_browser:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nstopped")
    finally:
        server.server_close()


# ---- the CLI -------------------------------------------------------------


def print_status(source: PromptSource, ledger: Ledger, zone: str | None) -> None:
    assets = source.assets(zone=zone)
    print(f"{'asset':28} {'kind':9} {'zone':22} {'status':10} {'att':>3}  note")
    print("-" * 84)
    tally: dict[str, int] = {}
    for a in assets:
        rec = ledger.get(a.asset_id) or {}
        status = ledger.status(a)
        notes = []
        if ledger.is_stale(a):
            notes.append("stale — doc changed since")
        if status == "generated" and not rec.get("processed", False):
            notes.append("raw only, not pixelated")
        if status == "rejected":
            notes.append(f"{len(rec.get('feedback', []))} note(s)")
        tally[status] = tally.get(status, 0) + 1
        print(
            f"{a.asset_id:28} {a.kind:9} {a.zone:22} {status:10} "
            f"{rec.get('attempts', 0):>3}  {'; '.join(notes)}"
        )
    print("-" * 84)
    print(
        f"{len(assets)} assets: "
        + ", ".join(f"{tally.get(s, 0)} {s}" for s in STATUSES)
    )


def print_plan(plan: Plan, ledger: Ledger, quality: str) -> None:
    print(f"plan — {len(plan.make)} to generate, "
          f"{len(plan.reprocess)} to re-pixelate, {len(plan.skipped)} skipped\n")
    for a in plan.make:
        # ⭐ Which endpoint is a fact about the ledger, not the asset: a
        # rejection with feedback is what turns a generation into an edit.
        endpoint = "edits" if ledger.feedback(a.asset_id) else "generations"
        print(
            f"  {endpoint:11} {a.kind:9} {a.asset_id:28} {a.size:10}"
            f"{'transparent' if a.transparent else 'opaque':12} -> {a.target}"
        )
    for a in plan.reprocess:
        print(f"  pixelate    {a.kind:9} {a.asset_id:28} raw already on disk")
    for a, why in plan.skipped:
        print(f"  skip        {a.kind:9} {a.asset_id:28} ({why})")
    total, notes = estimate_cost(plan.make, quality)
    print(f"\nestimated cost: ${total:.2f} for {len(plan.make)} image(s)")
    for line in notes:
        print(line)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("--zone", choices=ZONES, help="generate a zone's pending art")
    ap.add_argument(
        "--kind",
        choices=["creatures", "icons", "backdrop"],
        help="narrow a --zone run to one kind",
    )
    ap.add_argument("--only", help="one asset id (see --status)")
    ap.add_argument(
        "--force",
        action="store_true",
        help="regenerate even approved or already-generated art",
    )
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="print the plan and an estimated cost, touch no network",
    )
    ap.add_argument("--review", action="store_true", help="serve the review sheet")
    ap.add_argument("--port", type=int, default=8765)
    ap.add_argument("--no-open", action="store_true", help="do not open a browser")
    ap.add_argument("--status", action="store_true", help="table of every asset")
    ap.add_argument(
        "--quality",
        choices=["low", "medium", "high"],
        default="medium",
        help="generator quality, which is also what the cost estimate assumes",
    )
    ap.add_argument(
        "--cutout",
        action="store_true",
        help="ask pixelate to strip creature backgrounds (needs rembg); off by "
        "default because generated creatures already come back transparent",
    )
    ap.add_argument(
        "--no-verify",
        action="store_true",
        help="skip the three Dart contract suites after placement",
    )
    args = ap.parse_args(argv)

    source = PromptSource()
    ledger = Ledger()

    if args.status:
        print_status(source, ledger, args.zone)
        return 0

    if args.review:
        serve_review(source, ledger, args.zone, args.port, not args.no_open)
        return 0

    if not args.zone and not args.only:
        ap.error("nothing to do — pass --zone, --only, --status or --review")

    kind = {"creatures": "creature", "icons": "icon", "backdrop": "backdrop"}.get(
        args.kind
    )
    plan = build_plan(
        source,
        ledger,
        zone=args.zone,
        kind=kind,
        only=args.only,
        force=args.force,
    )

    if args.dry_run:
        print_plan(plan, ledger, args.quality)
        return 0

    if not plan.make and not plan.reprocess:
        print("nothing pending.")
        for a, why in plan.skipped:
            print(f"  {a.asset_id}: {why}")
        return 0

    total, _ = estimate_cost(plan.make, args.quality)
    print(
        f"{len(plan.make)} to generate, {len(plan.reprocess)} to re-pixelate "
        f"— estimated ${total:.2f} (--dry-run shows the assumptions)\n"
    )

    generator = None
    if plan.make:
        generator = OpenAIGenerator(read_api_key(), quality=args.quality)

    post = PostProcessor(cutout=args.cutout)
    now = now_iso()
    try:
        landed = run_zone(source, ledger, generator, post, plan, now=now)
    except GeneratorError as exc:
        print(f"\n✖ {exc}", file=sys.stderr)
        return 1

    print(f"\n{len(landed)} asset(s) placed. Review them:")
    print(f"  python3 tool/artgen.py --review"
          + (f" --zone {args.zone}" if args.zone else ""))

    if args.no_verify:
        return 0
    return 0 if verify() else 1


if __name__ == "__main__":
    sys.exit(main())
