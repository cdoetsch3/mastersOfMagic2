#!/usr/bin/env python3
"""Tests for `tool/artgen.py`.

    python3 tool/test_artgen.py            # or
    python3 -m unittest discover -s tool -p 'test_*.py' -v

⭐ **Stdlib only, and no network anywhere.** The generator adapter takes its
transport as a constructor argument precisely so the request shape can be
asserted byte for byte without an API key, a bill or an internet connection —
which is the only way the rules that matter (transparent background on cut-out
kinds but never on a backdrop, the edits endpoint once feedback exists, the key
never reaching an exception) can be held true over time.

⚠️ **The parse counts are pinned in both directions**, the same trap
`test/creature_art_test.dart` documents: a regex that silently stopped matching
would otherwise make every coverage assertion here pass by comparing two empty
sets.
"""

from __future__ import annotations

import base64
import io
import json
import pathlib
import re
import sys
import tempfile
import unittest
from contextlib import redirect_stdout

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

import artgen  # noqa: E402

ROOT = artgen.ROOT

# The whole Primal quarter, and the numbers every other check hangs off.
EXPECTED_CREATURES = 55
EXPECTED_ICONS = 52
EXPECTED_BACKDROPS = 5
ICONS_PER_ZONE = {
    "whispering_woods": 18,
    "glimmerbrook": 9,
    "cinderpeak_foothills": 8,
    "thornmire": 9,
    "ashfall_vale": 8,
}

ONE_PIXEL_PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
)

# A fake key with the shape of a real one, so the redaction test is meaningful.
FAKE_KEY = "sk-testkeyDEADBEEFdeadbeef0123456789"


def ok_response(blob: bytes = ONE_PIXEL_PNG) -> tuple[int, bytes]:
    payload = {"data": [{"b64_json": base64.b64encode(blob).decode()}]}
    return 200, json.dumps(payload).encode()


def error_response(status: int, message: str) -> tuple[int, bytes]:
    return status, json.dumps({"error": {"message": message}}).encode()


class FakeTransport:
    """Records every request and answers from a scripted queue."""

    def __init__(self, *responses):
        self.responses = list(responses)
        self.calls: list[dict] = []

    def __call__(self, url, *, data, headers):
        self.calls.append({"url": url, "data": data, "headers": headers})
        return self.responses.pop(0) if self.responses else ok_response()

    @property
    def last_json(self) -> dict:
        return json.loads(self.calls[-1]["data"])


class ExplodingTransport:
    """⚠️ Any network at all is a test failure, not a slow test."""

    def __call__(self, *a, **k):  # pragma: no cover - the point is not calling it
        raise AssertionError("a test touched the network")


def source() -> artgen.PromptSource:
    return artgen.PromptSource()


def temp_ledger() -> tuple[artgen.Ledger, tempfile.TemporaryDirectory]:
    tmp = tempfile.TemporaryDirectory()
    return artgen.Ledger(pathlib.Path(tmp.name) / "state.json"), tmp


# ---- the docs, parsed ----------------------------------------------------


class ParseTest(unittest.TestCase):
    def setUp(self):
        self.src = source()
        self.assets = self.src.assets()

    def test_the_quarter_is_fifty_five_creatures(self):
        creatures = [a for a in self.assets if a.kind == "creature"]
        self.assertEqual(
            len(creatures),
            EXPECTED_CREATURES,
            "docs/BESTIARY_ART.md must yield 5 zones x 11 creatures — a lower "
            "number means the `**Name** — *meta*` anchor moved and artgen is "
            "silently skipping art nobody will notice is missing",
        )

    def test_the_quarter_is_fifty_two_icons(self):
        icons = [a for a in self.assets if a.kind == "icon"]
        self.assertEqual(len(icons), EXPECTED_ICONS)
        per_zone: dict[str, int] = {}
        for a in icons:
            per_zone[a.zone] = per_zone.get(a.zone, 0) + 1
        self.assertEqual(
            per_zone,
            ICONS_PER_ZONE,
            "the per-zone split must match ItemCatalogue.byZone exactly — a "
            "zone short of an icon is an item that can never get a picture",
        )

    def test_every_zone_has_one_backdrop(self):
        backdrops = [a for a in self.assets if a.kind == "backdrop"]
        self.assertEqual(len(backdrops), EXPECTED_BACKDROPS)
        self.assertEqual({a.zone for a in backdrops}, set(artgen.ZONES))
        self.assertEqual(
            {a.asset_id for a in backdrops},
            set(artgen.ZONES),
            "a backdrop is identified by its zone id, because that is the "
            "filename backdropFor asks for",
        )

    def test_the_anchors_still_match_in_both_directions(self):
        # ⚠️ The falsifiability check. Counted straight off the raw documents,
        # so a parser that stopped finding anything fails here rather than
        # passing every coverage assertion above by finding nothing.
        bestiary = artgen.unwrap_entries(artgen.BESTIARY_DOC.read_text())
        items = artgen.unwrap_entries(artgen.ITEM_DOC.read_text())
        self.assertEqual(
            len(re.findall(r"^\*\*([^*]+)\*\* — \*", bestiary, re.M)),
            EXPECTED_CREATURES,
        )
        self.assertEqual(
            len(re.findall(r"^\*\*([^*]+)\*\* — \*", items, re.M)),
            EXPECTED_ICONS,
        )
        self.assertEqual(
            len(re.findall(r"^`assets/backgrounds/", bestiary, re.M)),
            EXPECTED_BACKDROPS,
        )

    def test_creature_targets_are_the_contract_paths(self):
        ids = artgen.enemy_ids()
        for a in (x for x in self.assets if x.kind == "creature"):
            self.assertEqual(
                a.target,
                f"assets/creatures/{a.zone}/{a.asset_id}.png",
                "creatureAssetFor builds exactly this path; anything else is "
                "art generated into a filename the game never asks for",
            )
            self.assertEqual(
                a.source,
                f"art/source/{a.zone}/{a.asset_id}.png",
                "pixelate.py reads creature sources from art/source/<zone>/",
            )
            self.assertIn(a.name, ids)
            self.assertEqual(ids[a.name], a.asset_id)

    def test_icon_targets_come_from_the_doc_filename_lines(self):
        doc = artgen.ITEM_DOC.read_text()
        declared = set(
            re.findall(r"^`(assets/items/[a-z_]+/[a-z0-9_]+\.png)`", doc, re.M)
        )
        self.assertEqual(
            {a.target for a in self.assets if a.kind == "icon"},
            declared,
            "every icon target is quoted verbatim out of ITEM_ART.md — the "
            "tool must never invent one",
        )
        for a in (x for x in self.assets if x.kind == "icon"):
            self.assertEqual(a.source, f"art/source/items/{a.zone}/{a.asset_id}.png")

    def test_backdrop_targets_and_sources(self):
        for a in (x for x in self.assets if x.kind == "backdrop"):
            self.assertEqual(a.target, f"assets/backgrounds/{a.zone}.png")
            self.assertEqual(a.source, f"art/source/backgrounds/{a.zone}.png")

    def test_asset_ids_are_unique_across_all_three_kinds(self):
        ids = [a.asset_id for a in self.assets]
        self.assertEqual(
            len(set(ids)),
            len(ids),
            "--only takes a bare id, so two assets sharing one would make it "
            "ambiguous which picture the operator meant",
        )

    def test_every_zone_maps_to_a_pixelate_element(self):
        self.assertEqual(set(artgen.ZONE_ELEMENT), set(artgen.ZONES))
        self.assertEqual(
            artgen.ZONE_ELEMENT["thornmire"],
            "flora",
            "hybrid zones lock to their LEAD element so the generated sprite "
            "and the silhouette fallback agree",
        )


# ---- prompt assembly -----------------------------------------------------


class PromptTest(unittest.TestCase):
    def setUp(self):
        self.src = source()

    def test_creature_prompt_is_preamble_then_zone_then_entry(self):
        fawn = self.src.by_id("listening_fawn")
        self.assertIn("a naturalist's field plate", fawn.prompt)
        self.assertIn("The wood is one creature", fawn.prompt)
        self.assertIn("no eyes and no mouth", fawn.prompt)
        self.assertLess(
            fawn.prompt.index("naturalist"),
            fawn.prompt.index("no eyes and no mouth"),
            "the shared style has to come first, or the entry's own framing "
            "wins the argument with it",
        )

    def test_every_creature_carries_the_house_style(self):
        preamble = self.src.creature_preamble
        for a in self.src.assets(kind="creature"):
            self.assertTrue(a.prompt.startswith(preamble))

    def test_every_icon_carries_the_shared_preamble_and_its_palette(self):
        preamble = self.src.icon_preamble
        self.assertIn("A single game item icon", preamble)
        for a in self.src.assets(kind="icon"):
            self.assertTrue(
                a.prompt.startswith(preamble),
                f"{a.asset_id} lost the preamble ITEM_ART says to prepend to "
                f"every prompt",
            )
            self.assertIn("Palette:", a.prompt)
        log = self.src.by_id("oak_log")
        self.assertIn("one dull amber", log.prompt, "the palette line wraps in "
                      "the doc and must be rejoined, not truncated")

    def test_backdrop_prompt_carries_the_duel_composition(self):
        b = self.src.by_id("whispering_woods")
        self.assertEqual(b.kind, "backdrop")
        self.assertIn("24% and 76% of the width", b.prompt)
        self.assertIn("muted and low-contrast", b.prompt)
        self.assertIn("well-walked earth path", b.prompt)

    def test_no_prompt_carries_build_instructions(self):
        # ⚠️ Both docs mix art direction and shell commands in one paragraph.
        for a in self.src.assets():
            for forbidden in ("python3 ", "pixelate.py", "assets/", "pubspec"):
                self.assertNotIn(
                    forbidden,
                    a.prompt,
                    f"{a.asset_id}'s prompt would hand a painter a build step",
                )

    def test_no_prompt_carries_markdown(self):
        for a in self.src.assets():
            self.assertNotIn("**", a.prompt)
            self.assertNotIn("⭐", a.prompt)
            self.assertNotIn("⚠️", a.prompt)

    def test_prompt_hashes_are_stable_and_distinct(self):
        a = self.src.by_id("listening_fawn")
        b = self.src.by_id("thornback_sprite")
        self.assertEqual(a.prompt_hash, source().by_id("listening_fawn").prompt_hash)
        self.assertNotEqual(a.prompt_hash, b.prompt_hash)
        self.assertTrue(a.prompt_hash.startswith("sha256:"))

    def test_sizes_and_transparency_by_kind(self):
        for a in self.src.assets():
            if a.kind == "backdrop":
                self.assertEqual(a.size, "1536x1024")
                self.assertFalse(a.transparent)
            else:
                self.assertEqual(a.size, "1024x1024")
                self.assertTrue(a.transparent)

    def test_edit_instruction_keeps_the_brief_and_every_note(self):
        prompt = "A deer made of roots."
        text = artgen.edit_instruction(prompt, ["ears too small", "too tall"])
        self.assertTrue(text.startswith(prompt))
        self.assertIn("- ears too small", text)
        self.assertIn("- too tall", text)
        self.assertLess(
            text.index("ears too small"),
            text.index("too tall"),
            "oldest note first, so a later pass does not un-fix an earlier one",
        )


# ---- the ledger ----------------------------------------------------------


class LedgerTest(unittest.TestCase):
    def setUp(self):
        self.ledger, self._tmp = temp_ledger()
        self.asset = source().by_id("listening_fawn")

    def tearDown(self):
        self._tmp.cleanup()

    def test_an_unknown_asset_is_pending(self):
        self.assertEqual(self.ledger.status(self.asset), "pending")
        self.assertFalse(self.ledger.is_stale(self.asset))

    def test_round_trip_through_disk(self):
        self.ledger.record_generated(self.asset, model="gpt-image-1", now="T0")
        self.ledger.save()
        reloaded = artgen.Ledger(self.ledger.path)
        rec = reloaded.get("listening_fawn")
        self.assertEqual(rec["status"], "generated")
        self.assertEqual(rec["model"], "gpt-image-1")
        self.assertEqual(rec["attempts"], 1)
        self.assertEqual(rec["prompt_hash"], self.asset.prompt_hash)
        self.assertEqual(rec["target"], "assets/creatures/whispering_woods/listening_fawn.png")
        self.assertEqual(rec["updated"], "T0")
        self.assertEqual(reloaded.version, artgen.LEDGER_VERSION)

    def test_the_full_status_walk(self):
        self.ledger.record_generated(self.asset, model="m", now="T0")
        self.assertEqual(self.ledger.status(self.asset), "generated")
        self.ledger.reject("listening_fawn", feedback="no antlers, please", now="T1")
        self.assertEqual(self.ledger.status(self.asset), "rejected")
        self.assertEqual(self.ledger.feedback("listening_fawn"), ["no antlers, please"])
        self.ledger.record_generated(self.asset, model="m", now="T2")
        self.assertEqual(self.ledger.get("listening_fawn")["attempts"], 2)
        self.assertEqual(
            self.ledger.feedback("listening_fawn"),
            ["no antlers, please"],
            "a regeneration must not forget why the last one was rejected",
        )
        self.ledger.approve("listening_fawn", now="T3")
        self.assertEqual(self.ledger.status(self.asset), "approved")

    def test_a_rejection_without_feedback_is_refused(self):
        self.ledger.record_generated(self.asset, model="m", now="T0")
        with self.assertRaises(ValueError):
            self.ledger.reject("listening_fawn", feedback="   ", now="T1")
        self.assertEqual(
            self.ledger.status(self.asset),
            "generated",
            "a refused rejection must leave the record alone, or the picture "
            "silently leaves the review queue with nothing said about it",
        )

    def test_feedback_accumulates_with_its_timestamps(self):
        self.ledger.record_generated(self.asset, model="m", now="T0")
        self.ledger.reject("listening_fawn", feedback="one", now="T1")
        self.ledger.record_generated(self.asset, model="m", now="T2")
        self.ledger.reject("listening_fawn", feedback="two", now="T3")
        rec = self.ledger.get("listening_fawn")
        self.assertEqual([f["text"] for f in rec["feedback"]], ["one", "two"])
        self.assertEqual([f["at"] for f in rec["feedback"]], ["T1", "T3"])

    def test_drift_is_flagged_and_nothing_else(self):
        self.ledger.record_generated(self.asset, model="m", now="T0")
        self.ledger.approve("listening_fawn", now="T1")
        self.assertFalse(self.ledger.is_stale(self.asset))
        self.ledger.get("listening_fawn")["prompt_hash"] = "sha256:0000000000000000"
        self.assertTrue(
            self.ledger.is_stale(self.asset),
            "a doc rewritten after approval must show as stale in listings",
        )
        self.assertEqual(
            self.ledger.status(self.asset),
            "approved",
            "⚠️ drift is a flag, never an automatic regeneration — art is not "
            "free and a reworded sentence is usually a typo fix",
        )


# ---- the generator adapter ----------------------------------------------


class GeneratorTest(unittest.TestCase):
    def setUp(self):
        self.src = source()

    def _gen(self, *responses, quality="medium"):
        transport = FakeTransport(*responses)
        gen = artgen.OpenAIGenerator(
            FAKE_KEY, transport=transport, quality=quality, sleep=lambda _s: None
        )
        return gen, transport

    def test_a_creature_asks_for_a_transparent_square(self):
        gen, t = self._gen(ok_response())
        a = self.src.by_id("listening_fawn")
        blob = gen.generate(a.prompt, size=a.size, transparent=a.transparent)
        self.assertEqual(blob, ONE_PIXEL_PNG)
        self.assertEqual(t.calls[-1]["url"], artgen.GENERATIONS_URL)
        body = t.last_json
        self.assertEqual(body["model"], "gpt-image-1")
        self.assertEqual(body["size"], "1024x1024")
        self.assertEqual(body["n"], 1)
        self.assertEqual(body["quality"], "medium")
        self.assertEqual(body["output_format"], "png")
        self.assertEqual(body["background"], "transparent")
        self.assertEqual(body["prompt"], a.prompt)

    def test_an_icon_asks_for_a_transparent_square_too(self):
        gen, t = self._gen(ok_response())
        a = self.src.by_id("oak_log")
        gen.generate(a.prompt, size=a.size, transparent=a.transparent)
        self.assertEqual(t.last_json["background"], "transparent")
        self.assertEqual(t.last_json["size"], "1024x1024")

    def test_a_backdrop_never_asks_for_transparency(self):
        gen, t = self._gen(ok_response())
        a = self.src.by_id("thornmire")
        gen.generate(a.prompt, size=a.size, transparent=a.transparent)
        body = t.last_json
        self.assertNotIn(
            "background",
            body,
            "alpha in a backdrop is a hole in the arena — only cut-out kinds "
            "ask for it",
        )
        self.assertEqual(body["size"], "1536x1024")

    def test_the_authorization_header_carries_the_key_and_nothing_else_does(self):
        gen, t = self._gen(ok_response())
        gen.generate("x", size="1024x1024", transparent=True)
        self.assertEqual(t.calls[-1]["headers"]["Authorization"], f"Bearer {FAKE_KEY}")
        self.assertNotIn(FAKE_KEY, t.calls[-1]["data"].decode())

    def test_an_edit_is_multipart_against_the_edits_endpoint(self):
        gen, t = self._gen(ok_response())
        a = self.src.by_id("listening_fawn")
        instruction = artgen.edit_instruction(a.prompt, ["the ears are too short"])
        gen.edit(
            instruction, size=a.size, transparent=True, image=ONE_PIXEL_PNG
        )
        call = t.calls[-1]
        self.assertEqual(call["url"], artgen.EDITS_URL)
        self.assertTrue(call["headers"]["Content-Type"].startswith("multipart/form-data"))
        body = call["data"]
        self.assertIn(b'name="image"; filename="source.png"', body)
        self.assertIn(ONE_PIXEL_PNG, body)
        self.assertIn(b"the ears are too short", body)
        self.assertIn(b'name="background"', body)
        self.assertIn(b"1024x1024", body)

    def test_a_backdrop_edit_still_asks_for_no_transparency(self):
        gen, t = self._gen(ok_response())
        gen.edit("fix it", size="1536x1024", transparent=False, image=ONE_PIXEL_PNG)
        self.assertNotIn(b'name="background"', t.calls[-1]["data"])

    def test_a_rate_limit_is_retried_and_then_succeeds(self):
        gen, t = self._gen(
            error_response(429, "slow down"),
            error_response(503, "upstream"),
            ok_response(),
        )
        blob = gen.generate("x", size="1024x1024", transparent=True)
        self.assertEqual(blob, ONE_PIXEL_PNG)
        self.assertEqual(len(t.calls), 3)

    def test_a_bad_key_fails_once_and_says_nothing_about_the_key(self):
        gen, t = self._gen(error_response(401, f"Incorrect API key provided: {FAKE_KEY}"))
        with self.assertRaises(artgen.GeneratorError) as ctx:
            gen.generate("x", size="1024x1024", transparent=True)
        text = str(ctx.exception)
        self.assertIn("401", text)
        self.assertNotIn(
            FAKE_KEY,
            text,
            "⚠️ a key in an exception reaches a log, a CI transcript and a "
            "bug report — this is the assertion that stops it",
        )
        self.assertEqual(len(t.calls), 1, "a bad key must not be retried")

    def test_a_server_error_redacts_a_key_the_api_echoes_back(self):
        gen, _ = self._gen(*[error_response(500, f"boom {FAKE_KEY}")] * artgen.MAX_ATTEMPTS)
        with self.assertRaises(artgen.GeneratorError) as ctx:
            gen.generate("x", size="1024x1024", transparent=True)
        self.assertNotIn(FAKE_KEY, str(ctx.exception))
        self.assertIn("<redacted>", str(ctx.exception))

    def test_an_empty_response_is_an_error_not_an_empty_file(self):
        gen, _ = self._gen((200, json.dumps({"data": []}).encode()))
        with self.assertRaises(artgen.GeneratorError):
            gen.generate("x", size="1024x1024", transparent=True)

    def test_no_key_at_all_is_refused_before_any_request(self):
        with self.assertRaises(artgen.GeneratorError):
            artgen.OpenAIGenerator("", transport=ExplodingTransport())

    def test_the_interface_a_gemini_adapter_would_implement(self):
        # ⭐ The seam, asserted rather than only documented.
        self.assertTrue(issubclass(artgen.OpenAIGenerator, artgen.ImageGenerator))
        for method in ("generate", "edit"):
            self.assertTrue(callable(getattr(artgen.ImageGenerator, method)))
        self.assertEqual(artgen.OpenAIGenerator(FAKE_KEY, transport=FakeTransport()).name,
                         "gpt-image-1")


class KeyReadingTest(unittest.TestCase):
    def test_the_environment_wins(self):
        self.assertEqual(read_key({"OPENAI_API_KEY": "sk-env"}), "sk-env")

    def test_a_dotenv_is_the_fallback(self):
        with tempfile.TemporaryDirectory() as tmp:
            env = pathlib.Path(tmp) / ".env"
            env.write_text("# a comment\nOTHER=1\nOPENAI_API_KEY='sk-file'\n")
            self.assertEqual(artgen.read_api_key({}, env), "sk-file")

    def test_no_key_anywhere_is_an_empty_string_not_a_crash(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(
                artgen.read_api_key({}, pathlib.Path(tmp) / "nope.env"), ""
            )


def read_key(env):
    with tempfile.TemporaryDirectory() as tmp:
        return artgen.read_api_key(env, pathlib.Path(tmp) / "absent.env")


# ---- the post-processor --------------------------------------------------


class PostProcessorTest(unittest.TestCase):
    def test_a_creature_gets_its_zone_element(self):
        argv = artgen.PostProcessor().argv("creature", "glimmerbrook")
        self.assertEqual(argv[1], str(artgen.PIXELATE))
        self.assertEqual(argv[2:], ["--zone", "glimmerbrook", "--element", "aqua"])

    def test_a_hybrid_zone_uses_its_lead_element(self):
        self.assertIn("flora", artgen.PostProcessor().argv("creature", "thornmire"))
        self.assertIn("pyro", artgen.PostProcessor().argv("creature", "ashfall_vale"))

    def test_cutout_is_opt_in(self):
        self.assertNotIn(
            "--cutout",
            artgen.PostProcessor().argv("creature", "thornmire"),
            "the generator is asked for a transparent background, so rembg "
            "would be a heavyweight no-op forced on every user",
        )
        self.assertIn(
            "--cutout", artgen.PostProcessor(cutout=True).argv("creature", "thornmire")
        )

    def test_an_icon_gets_icon_mode_and_nothing_else(self):
        argv = artgen.PostProcessor(cutout=True).argv("icon", "whispering_woods")
        self.assertEqual(argv[2:], ["--zone", "whispering_woods", "--mode", "icon"])
        self.assertNotIn("--element", argv)
        self.assertNotIn("--cutout", argv)

    def test_a_backdrop_gets_background_mode(self):
        argv = artgen.PostProcessor().argv("backdrop", "ashfall_vale")
        self.assertEqual(argv[2:], ["--zone", "ashfall_vale", "--mode", "background"])

    def test_a_failing_pixelate_is_raised_not_swallowed(self):
        class Failed:
            returncode = 1

        post = artgen.PostProcessor(runner=lambda *a, **k: Failed())
        with self.assertRaises(RuntimeError):
            post.run("icon", "thornmire")

    def test_alpha_detection_reads_the_png_header(self):
        self.assertTrue(artgen.has_alpha(ONE_PIXEL_PNG))
        self.assertFalse(artgen.has_alpha(b"not a png at all"))


# ---- planning, and the dry run ------------------------------------------


class PlanTest(unittest.TestCase):
    def setUp(self):
        self.src = source()
        self.ledger, self._tmp = temp_ledger()

    def tearDown(self):
        self._tmp.cleanup()

    def plan(self, **kw):
        args = {"zone": "glimmerbrook", "kind": None, "only": None, "force": False}
        args.update(kw)
        return artgen.build_plan(self.src, self.ledger, **args)

    def test_a_fresh_zone_is_all_work(self):
        plan = self.plan()
        self.assertEqual(len(plan.make), 21)  # 11 creatures + 9 icons + 1 backdrop
        self.assertEqual(plan.skipped, [])

    def test_kind_narrows_the_run(self):
        self.assertEqual(len(self.plan(kind="creature").make), 11)
        self.assertEqual(len(self.plan(kind="icon").make), 9)
        self.assertEqual(len(self.plan(kind="backdrop").make), 1)

    def test_approved_and_awaiting_review_are_both_left_alone(self):
        naiad = self.src.by_id("brook_naiad")
        eel = self.src.by_id("chill_eel")
        self.ledger.record_generated(naiad, model="m", now="T0", processed=True)
        self.ledger.approve("brook_naiad", now="T1")
        self.ledger.record_generated(eel, model="m", now="T0", processed=True)
        plan = self.plan()
        made = {a.asset_id for a in plan.make}
        self.assertNotIn("brook_naiad", made)
        self.assertNotIn("chill_eel", made)
        self.assertEqual(
            dict((a.asset_id, why) for a, why in plan.skipped),
            {"brook_naiad": "approved", "chill_eel": "generated"},
        )

    def test_a_rejection_puts_an_asset_back_in_the_queue(self):
        eel = self.src.by_id("chill_eel")
        self.ledger.record_generated(eel, model="m", now="T0", processed=True)
        self.ledger.reject("chill_eel", feedback="too warm", now="T1")
        self.assertIn("chill_eel", {a.asset_id for a in self.plan().make})

    def test_a_paid_for_raw_that_never_pixelated_is_reprocessed_not_repaid(self):
        eel = self.src.by_id("chill_eel")
        self.ledger.record_generated(eel, model="m", now="T0", processed=False)
        plan = self.plan()
        self.assertNotIn("chill_eel", {a.asset_id for a in plan.make})
        self.assertEqual([a.asset_id for a in plan.reprocess], ["chill_eel"])

    def test_force_overrides_every_skip(self):
        naiad = self.src.by_id("brook_naiad")
        self.ledger.record_generated(naiad, model="m", now="T0", processed=True)
        self.ledger.approve("brook_naiad", now="T1")
        self.assertIn("brook_naiad", {a.asset_id for a in self.plan(force=True).make})

    def test_only_selects_one_asset_by_id(self):
        plan = self.plan(zone=None, only="stillwater")
        self.assertEqual([a.asset_id for a in plan.make], ["stillwater"])

    def test_an_unknown_only_is_a_clear_exit_not_a_silent_no_op(self):
        with self.assertRaises(SystemExit):
            self.plan(zone=None, only="no_such_creature")

    def test_the_cost_estimate_is_per_size_and_quality(self):
        assets = self.src.assets(zone="glimmerbrook")
        total, notes = artgen.estimate_cost(assets, "medium")
        self.assertAlmostEqual(total, 20 * 0.042 + 0.063, places=4)
        self.assertTrue(any("ESTIMATE ONLY" in n for n in notes))
        self.assertTrue(any(artgen.PRICE_URL in n for n in notes))
        cheap, _ = artgen.estimate_cost(assets, "low")
        self.assertLess(cheap, total)


class DryRunTest(unittest.TestCase):
    """⚠️ The whole point of `--dry-run` is that it cannot spend money."""

    def test_a_dry_run_prints_a_plan_and_touches_no_network(self):
        original_post, original_key = artgen.http_post, artgen.read_api_key
        with tempfile.TemporaryDirectory() as tmp:
            original_state = artgen.STATE_FILE
            artgen.STATE_FILE = pathlib.Path(tmp) / "state.json"
            artgen.http_post = ExplodingTransport()
            artgen.read_api_key = lambda *a, **k: (_ for _ in ()).throw(
                AssertionError("a dry run read the API key")
            )
            out = io.StringIO()
            try:
                with redirect_stdout(out):
                    code = artgen.main(["--zone", "ashfall_vale", "--dry-run"])
            finally:
                artgen.http_post, artgen.read_api_key = original_post, original_key
                artgen.STATE_FILE = original_state
            self.assertFalse(
                (pathlib.Path(tmp) / "state.json").exists(),
                "a dry run must not write the ledger either",
            )
        text = out.getvalue()
        self.assertEqual(code, 0)
        self.assertIn("cinderbloom_husk", text)
        self.assertIn("assets/backgrounds/ashfall_vale.png", text)
        self.assertIn("estimated cost:", text)
        self.assertIn("ESTIMATE ONLY", text)

    def test_status_is_read_only_and_lists_every_asset(self):
        out = io.StringIO()
        with tempfile.TemporaryDirectory() as tmp:
            original_state = artgen.STATE_FILE
            artgen.STATE_FILE = pathlib.Path(tmp) / "state.json"
            try:
                with redirect_stdout(out):
                    artgen.main(["--status"])
            finally:
                artgen.STATE_FILE = original_state
        text = out.getvalue()
        self.assertIn(f"{EXPECTED_CREATURES + EXPECTED_ICONS + EXPECTED_BACKDROPS} assets", text)
        self.assertIn("listening_fawn", text)


# ---- generation orchestration -------------------------------------------


class GenerateOneTest(unittest.TestCase):
    """Which endpoint a picture goes to is a fact about the ledger."""

    def setUp(self):
        self.src = source()
        self.ledger, self._tmp = temp_ledger()

    def tearDown(self):
        self._tmp.cleanup()

    def test_a_first_attempt_is_a_plain_generation(self):
        gen = Recorder()
        artgen.generate_one(self.src.by_id("chill_eel"), gen, self.ledger)
        self.assertEqual(gen.mode, "generate")

    def test_a_rejected_asset_with_its_raw_on_disk_goes_to_edits(self):
        asset = self.src.by_id("chill_eel")
        self.ledger.record_generated(asset, model="m", now="T0")
        self.ledger.reject("chill_eel", feedback="too warm", now="T1")
        with tempfile.TemporaryDirectory() as tmp:
            raw = pathlib.Path(tmp) / "chill_eel.png"
            raw.write_bytes(ONE_PIXEL_PNG)
            gen = Recorder()
            artgen.generate_one(_relocated(asset, raw), gen, self.ledger)
        self.assertEqual(gen.mode, "edit")
        self.assertEqual(gen.image, ONE_PIXEL_PNG)
        self.assertIn("too warm", gen.prompt)

    def test_a_rejected_asset_whose_raw_is_gone_keeps_the_feedback(self):
        # ⚠️ art/source/ is gitignored, so a fresh clone has no raw to edit.
        asset = self.src.by_id("chill_eel")
        self.ledger.record_generated(asset, model="m", now="T0")
        self.ledger.reject("chill_eel", feedback="too warm", now="T1")
        gen = Recorder()
        artgen.generate_one(asset, gen, self.ledger)
        self.assertEqual(gen.mode, "generate")
        self.assertIn("too warm", gen.prompt)
        self.assertNotIn("Revise the attached image", gen.prompt)


# ---- the review sheet ----------------------------------------------------


class ReviewSheetTest(unittest.TestCase):
    """The local contact sheet, driven over a real socket on 127.0.0.1.

    ⭐ Uses Whispering Woods, the one zone whose raws and pixelated results are
    both really on disk — so the two <img> tags are checked against actual
    bytes rather than a fixture that would pass with the paths swapped.
    """

    def setUp(self):
        import http.server
        import threading

        self.src = source()
        self.ledger, self._tmp = temp_ledger()
        self.asset = self.src.by_id("listening_fawn")
        self.ledger.record_generated(
            self.asset, model="gpt-image-1", now="T0", processed=True
        )
        handler = type(
            "T", (artgen.ReviewHandler,),
            {"source": self.src, "ledger": self.ledger, "zone_filter": "whispering_woods"},
        )
        self.server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
        self.url = f"http://127.0.0.1:{self.server.server_port}"
        threading.Thread(target=self.server.serve_forever, daemon=True).start()

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self._tmp.cleanup()

    def get(self, path):
        import urllib.request

        with urllib.request.urlopen(self.url + path) as r:
            return r.status, r.read()

    def post(self, fields):
        import urllib.parse
        import urllib.request

        req = urllib.request.Request(
            self.url + "/decide",
            data=urllib.parse.urlencode(fields).encode(),
            method="POST",
        )
        with urllib.request.urlopen(req) as r:
            return r.status

    def test_the_sheet_shows_what_is_awaiting_review(self):
        _, body = self.get("/")
        text = body.decode()
        self.assertIn("listening_fawn", text)
        self.assertIn("/img/raw/listening_fawn.png", text)
        self.assertIn("/img/out/listening_fawn.png", text)
        self.assertIn("128px sprite at 2x", text)
        self.assertNotIn(
            "thornback_sprite",
            text,
            "only generated-awaiting-review assets belong on the sheet",
        )

    def test_both_images_are_served_and_are_different_files(self):
        _, raw = self.get("/img/raw/listening_fawn.png")
        _, out = self.get("/img/out/listening_fawn.png")
        self.assertTrue(raw.startswith(b"\x89PNG"))
        self.assertTrue(out.startswith(b"\x89PNG"))
        self.assertNotEqual(
            raw, out, "the point of the sheet is the source beside the result"
        )

    def test_approving_writes_the_ledger(self):
        self.assertEqual(self.post({"asset_id": "listening_fawn",
                                    "decision": "approve", "feedback": ""}), 200)
        self.assertEqual(
            artgen.Ledger(self.ledger.path).get("listening_fawn")["status"],
            "approved",
        )
        _, body = self.get("/")
        self.assertIn("Nothing waiting for review", body.decode())

    def test_rejecting_stores_the_feedback_for_the_next_attempt(self):
        self.post({"asset_id": "listening_fawn", "decision": "reject",
                   "feedback": "the ears read as leaves, make them longer"})
        rec = artgen.Ledger(self.ledger.path).get("listening_fawn")
        self.assertEqual(rec["status"], "rejected")
        self.assertEqual(rec["feedback"][0]["text"],
                         "the ears read as leaves, make them longer")

    def test_a_rejection_with_no_words_is_refused_and_changes_nothing(self):
        self.post({"asset_id": "listening_fawn", "decision": "reject", "feedback": " "})
        self.assertEqual(self.ledger.get("listening_fawn")["status"], "generated")

    def test_an_unknown_asset_is_a_404_not_a_traceback(self):
        import urllib.error

        with self.assertRaises(urllib.error.HTTPError) as ctx:
            self.get("/img/raw/not_a_creature.png")
        self.assertEqual(ctx.exception.code, 404)

    def test_feedback_is_escaped_rather_than_rendered(self):
        self.post({"asset_id": "listening_fawn", "decision": "reject",
                   "feedback": "<script>alert(1)</script>"})
        self.ledger.record_generated(self.asset, model="m", now="T2", processed=True)
        _, body = self.get("/")
        self.assertNotIn(b"<script>alert(1)</script>", body)
        self.assertIn(b"&lt;script&gt;", body)


class Recorder(artgen.ImageGenerator):
    name = "recorder"

    def generate(self, prompt, *, size, transparent):
        self.mode, self.prompt, self.size = "generate", prompt, size
        return ONE_PIXEL_PNG

    def edit(self, prompt, *, size, transparent, image):
        self.mode, self.prompt, self.size, self.image = "edit", prompt, size, image
        return ONE_PIXEL_PNG


def _relocated(asset: artgen.Asset, raw: pathlib.Path) -> artgen.Asset:
    """The same asset with its raw somewhere a test can write.

    ⚠️ `art/source/` is gitignored and may hold a real picture, so no test in
    this file ever writes into it.
    """
    import dataclasses
    import os.path

    return dataclasses.replace(asset, source=os.path.relpath(raw, ROOT))


if __name__ == "__main__":
    unittest.main(verbosity=2)
