"""Exercise label correction, review progress, backups, and the Colab callback."""
import csv
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from PIL import Image

SOURCE = Path(__file__).resolve().parents[1] / "notebook_sources/label_review.py"
spec = importlib.util.spec_from_file_location("label_review", SOURCE)
review = importlib.util.module_from_spec(spec)
spec.loader.exec_module(review)


class LabelReviewTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.crops = Path(self.temporary.name)
        (self.crops / "halves").mkdir()
        self.tiles = [{"tile_id": f"tile-{i}", "image": f"photo-{i}.jpeg", "box_index": "0",
                       "a_path": f"halves/{i}_a.png", "b_path": f"halves/{i}_b.png"} for i in range(3)]
        for tile in self.tiles:
            for side in ("a", "b"):
                Image.new("RGB", (128, 128), "white").save(self.crops / tile[f"{side}_path"])
        self.write_csv("tiles.csv", self.tiles)
        self.labels = [{"tile_id": tile["tile_id"], "a": "7", "b": "3", "status": "labeled"} for tile in self.tiles]
        self.write_csv("pip_labels.csv", self.labels)
        self.metadata = {"dataset_fingerprint": "test-only", "crop_version": "test-crops"}
        (self.crops / "metadata.json").write_text(json.dumps(self.metadata))
        flags = [{"tile_id": f"tile-{i}", "side": "a", "current": 7, "proposed": 8} for i in (1, 2)]
        (self.crops / "pip_review_flags.json").write_text(json.dumps(dict(self.metadata, flags=flags)))
        self.before = (self.crops / "pip_labels.csv").read_bytes()

    def tearDown(self):
        self.temporary.cleanup()

    def write_csv(self, name, rows):
        with (self.crops / name).open("w", newline="") as target:
            writer = csv.DictWriter(target, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)

    def test_open_and_navigation_never_apply_suggestions(self):
        session = review.PipLabelReview(self.crops)
        state = session.state()
        self.assertEqual((state["mode"], state["number"], state["a"]), ("flagged", 2, "7"))
        self.assertEqual(state["flags"][0]["proposed"], 8)
        html = review.review_html(state)
        self.assertIn('data-value="7" aria-pressed="true"', html)
        self.assertIn('data-value="8" aria-pressed="false"', html)
        self.assertEqual(session.act("skip", 2, mode="flagged")["number"], 3)
        self.assertEqual(session.act("previous", 3, mode="flagged")["number"], 2)
        self.assertEqual(session.act("go", 1, mode="flagged")["mode"], "all")
        self.assertEqual((self.crops / "pip_labels.csv").read_bytes(), self.before)
        self.assertFalse(session.progress_path.exists())

    def test_correction_preserves_other_rows_and_saves_backups_and_progress(self):
        session = review.PipLabelReview(self.crops)
        state = session.state()
        next_state = session.act("save", 2, "8", "3", state["token"], "flagged")
        rows, labels = session.load_labels()
        self.assertEqual(labels["tile-1"]["a"], "8")
        self.assertEqual(rows[0], self.labels[0])
        self.assertEqual(rows[2], self.labels[2])
        self.assertEqual(session.backup_path.read_bytes(), self.before)
        self.assertEqual(self.crops.joinpath("pip_labels.previous.csv").read_bytes(), self.before)
        self.assertEqual(next_state["number"], 3)
        resumed = review.PipLabelReview(self.crops)
        self.assertEqual((resumed.state()["number"], resumed.state()["reviewed"]), (3, 1))
        last = resumed.state()
        done = resumed.act("save", 3, "7", "3", last["token"], "flagged")
        self.assertTrue(done["complete"])
        self.assertEqual(done["remaining"], 0)

    def test_confirming_correct_values_keeps_label_bytes_and_contract_hash(self):
        session = review.PipLabelReview(self.crops)
        state = session.state(1, "all")
        session.act("save", 1, "7", "3", state["token"], "all")
        self.assertEqual(session.labels_path.read_bytes(), self.before)
        self.assertIsNone(session.backup_path)
        self.assertEqual(session.state(1, "all")["reviewed"], 1)

    def test_invalid_and_stale_saves_cannot_overwrite_labels(self):
        first, second = review.PipLabelReview(self.crops), review.PipLabelReview(self.crops)
        state = first.state()
        for a, b in [("16", "3"), ("-1", "3"), ("7", ""), (8, "3")]:
            with self.assertRaisesRegex(ValueError, "0 to 15"):
                first.act("save", 2, a, b, state["token"], "flagged")
        self.assertEqual(first.labels_path.read_bytes(), self.before)
        second.act("save", 2, "8", "3", state["token"], "flagged")
        saved = first.labels_path.read_bytes()
        with self.assertRaisesRegex(ValueError, "another session"):
            first.act("save", 2, "7", "3", state["token"], "flagged")
        self.assertEqual(first.labels_path.read_bytes(), saved)
        self.assertEqual(first.act("reload", 2, mode="flagged")["a"], "8")

    def test_reject_and_later_label_edits_require_another_review(self):
        session = review.PipLabelReview(self.crops)
        state = session.state()
        session.act("reject", 2, expected=state["token"], mode="flagged")
        rows, labels = session.load_labels()
        self.assertEqual((labels["tile-1"]["status"], labels["tile-1"]["a"]), ("rejected", ""))
        labels["tile-1"].update(a="8", b="3", status="labeled")
        self.write_csv("pip_labels.csv", rows)
        self.assertEqual(session.state()["number"], 2)
        self.assertEqual(session.state()["reviewed"], 0)

    def test_flags_and_paths_must_match_the_crop_manifest(self):
        flags = self.crops / "pip_review_flags.json"
        flags.write_text(json.dumps({"dataset_fingerprint": "wrong", "flags": []}))
        with self.assertRaisesRegex(ValueError, "different crops"):
            review.PipLabelReview(self.crops)
        flags.unlink()
        session = review.PipLabelReview(self.crops)
        self.assertEqual(session.state()["mode"], "all")
        self.tiles[0]["a_path"] = "../outside.png"
        self.write_csv("tiles.csv", self.tiles)
        with self.assertRaisesRegex(ValueError, "outside"):
            review.PipLabelReview(self.crops)

    def test_colab_callback_renders_and_saves_without_clearing_output(self):
        callbacks = {}
        colab = SimpleNamespace(output=SimpleNamespace(register_callback=callbacks.__setitem__))
        with patch.dict(sys.modules, {"google.colab": colab}), patch("IPython.display.display") as display, \
                patch("IPython.display.clear_output", side_effect=AssertionError("Keep the review controls visible")):
            session = review.open_pip_label_review(self.crops)
        callback_id, update = next(iter(callbacks.items()))
        html = display.call_args.args[0].data
        self.assertIn(callback_id, html)
        self.assertIn("google.colab.kernel.invokeFunction", html)
        self.assertIn("Discard unsaved selections", html)
        self.assertIn("data:image/png;base64,", html)
        self.assertNotIn("#PANEL", html)
        state = session.state()
        saved = update("save", 2, "8", "3", state["token"], "flagged").data
        self.assertIn("Saved tile 2", saved["html"])
        self.assertEqual(session.load_labels()[1]["tile-1"]["a"], "8")
        self.assertIn("error", update("save", 2, "7", "3", state["token"], "flagged").data)


if __name__ == "__main__":
    unittest.main()
