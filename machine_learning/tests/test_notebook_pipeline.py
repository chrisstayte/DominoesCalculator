"""Meaningful data/geometry/regression checks; no user labels or trained weights required.

python -m unittest discover -s machine_learning/tests -v
"""
from pathlib import Path
import ast
import importlib.util
import io
import json
import tempfile
import unittest
import zipfile
from unittest.mock import patch
from types import SimpleNamespace

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("helpers", ROOT / "notebook_sources/common.py")
h = importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)


class PipelineTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)

    def tearDown(self):
        self.temporary.cleanup()

    def create_export(self, count=6):
        root = self.root / "export"
        (root / "images").mkdir(parents=True)
        (root / "labels").mkdir()
        (root / "classes.txt").write_text("domino\n")
        for i in range(count):
            image = np.zeros((100, 200, 3), np.uint8)
            image[:, :100] = (230, 20 + i, 20)
            image[:, 100:] = (20, 20, 230 - i)
            Image.fromarray(image).save(root / "images" / f"photo_{i}.jpeg")
            (root / "labels" / f"photo_{i}.txt").write_text("0 0 0 1 0 1 1 0 1\n")
        return root

    def test_jpeg_pairing_and_obb_validation(self):
        root = self.create_export()
        records, _ = h.audit_export(root)
        self.assertEqual(len(records), 6)
        (root / "labels/photo_0.txt").write_text("0 0.5 0.5 1 1\n")
        with self.assertRaisesRegex(ValueError, "eight OBB"):
            h.audit_export(root)

    def test_rotated_tile_preserves_two_separate_halves(self):
        rgb = np.zeros((240, 240, 3), np.uint8)
        tile = np.zeros((60, 120, 3), np.uint8)
        tile[:, :60] = (240, 0, 0)
        tile[:, 60:] = (0, 0, 240)
        source = np.float32([[0, 0], [119, 0], [119, 59], [0, 59]])
        theta = np.deg2rad(37)
        rotation = np.array([[np.cos(theta), -np.sin(theta)], [np.sin(theta), np.cos(theta)]])
        corners = ((source - [60, 30]) @ rotation.T + [120, 120]).astype(np.float32)
        rgb = h.cv2.warpPerspective(tile, h.cv2.getPerspectiveTransform(source, corners), (240, 240))
        for order in [corners, np.roll(corners, 1, axis=0), corners[::-1]]:
            halves = h.tile_halves(h.rectify_tile(rgb, order))
            centers = [half[32:96, 32:96].mean(axis=(0, 1)) for half in halves]
            self.assertEqual(sorted(int(center.argmax()) for center in centers), [0, 2])
            self.assertTrue(all(center.max() > 225 for center in centers))
            self.assertTrue(all(half.shape == (128, 128, 3) for half in halves))

    def test_groups_are_disjoint_frozen_and_duplicates_stay_together(self):
        root = self.create_export()
        records, fingerprint = h.audit_export(root)
        groups, saved = self.root / "groups.csv", self.root / "split.json"
        rows = h.ensure_groups(records, groups)
        rows[1]["group"] = rows[0]["group"]
        h.write_csv(groups, rows, ["image", "group"])
        self.assertIsNone(h.frozen_split(records, fingerprint, groups, saved))
        split = h.frozen_split(records, fingerprint, groups, saved, reviewed=True)
        photo_split = {r["image"]: r["split"] for r in split["photos"]}
        self.assertEqual(photo_split["photo_0.jpeg"], photo_split["photo_1.jpeg"])
        self.assertEqual(set(photo_split.values()), {"train", "val", "test"})
        self.assertEqual(split, h.frozen_split(records, fingerprint, groups, saved))
        rows[2]["group"] = rows[0]["group"]
        h.write_csv(groups, rows, ["image", "group"])
        with self.assertRaisesRegex(ValueError, "changed after"):
            h.frozen_split(records, fingerprint, groups, saved, reviewed=True)

    def test_crops_keep_source_split_and_numeric_values(self):
        root = self.create_export()
        records, fingerprint = h.audit_export(root)
        crops = self.root / "crops"
        tiles = h.make_crops(root, records, crops, fingerprint)
        path = crops / "pip_labels.csv"
        labels = h.load_pip_labels(path, tiles)
        labels[tiles[0]["tile_id"]].update(a="10", b="2", status="labeled")
        h.write_csv(path, list(labels.values()), ["tile_id", "a", "b", "status"])
        groups = self.root / "groups.csv"
        h.ensure_groups(records, groups)
        split = h.frozen_split(records, fingerprint, groups, self.root / "split.json", reviewed=True)
        rows = h.classifier_rows(tiles, h.load_pip_labels(path, tiles), split)
        self.assertEqual([r["value"] for r in rows], [10, 2])
        self.assertEqual(rows[0]["split"], rows[1]["split"])
        before = path.read_bytes()
        h.make_crops(root, records, crops, fingerprint)
        h.load_pip_labels(path, tiles)
        self.assertEqual(path.read_bytes(), before)
        self.assertEqual(len(list((crops / "halves").glob("*.png"))), 12)

    def test_matching_does_not_count_duplicate_detections_twice(self):
        box = [[0, 0], [100, 0], [100, 50], [0, 50]]
        self.assertAlmostEqual(h.polygon_iou(box, box), 1.0)
        matches = h.match_boxes([box], [box, box])
        self.assertEqual(len(matches), 1)

    def test_archive_paths_cannot_escape_extraction(self):
        project, work = self.root / "project", self.root / "work"
        project.mkdir()
        with zipfile.ZipFile(project / "bad.zip", "w") as z:
            z.writestr("../escaped.txt", "bad")
        with self.assertRaisesRegex(ValueError, "unsafe path"):
            h.stage_export(project, work, "bad")
        self.assertFalse((work / "unpacked/escaped.txt").exists())

    def classifier_function(self, name, extra=None):
        tree = ast.parse((ROOT / "notebook_sources/classifier.py").read_text())
        function = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == name)
        namespace = dict(vars(h))
        namespace.update({"display": lambda *_: None, "IN_COLAB": False})
        namespace.update(extra or {})
        exec(compile(ast.Module(body=[function], type_ignores=[]), "classifier function", "exec"), namespace)
        return namespace[name]

    def test_labeling_widget_saves_values_and_resumes(self):
        root = self.create_export()
        records, fingerprint = h.audit_export(root)
        crops = self.root / "crops"
        tiles = h.make_crops(root, records, crops, fingerprint)
        labels_path = crops / "pip_labels.csv"
        station = self.classifier_function("labeling_station")
        def check_display(panel):
            # The first view must include the image already; no output clearing may
            # erase that view when Colab attaches the widget asynchronously.
            preview = panel.children[2]
            image = Image.open(io.BytesIO(bytes(preview.children[1].value)))
            self.assertEqual(image.size, (768, 384))
            expected = np.concatenate([h.read_rgb(crops / tiles[0]["a_path"]),
                                       h.read_rgb(crops / tiles[0]["b_path"])], axis=1)
            np.testing.assert_array_equal(np.asarray(image), np.asarray(
                Image.fromarray(expected).resize((768, 384), Image.Resampling.NEAREST)))
            self.assertIn(tiles[0]["tile_id"], preview.children[0].value)

        with patch("IPython.display.display", side_effect=check_display) as display, \
                patch("IPython.display.clear_output", side_effect=AssertionError("Picker must not clear cell output")) as clear:
            panel = station(tiles, crops, labels_path)
            display.assert_called_once_with(panel)
            first_image = bytes(panel.children[2].children[1].value)
            panel.children[3].children[0].value = "10"
            panel.children[3].children[1].value = "2"
            panel.children[4].children[0].click()
            labels = h.load_pip_labels(labels_path, tiles)
            self.assertEqual(labels[tiles[0]["tile_id"]]["a"], "10")
            self.assertEqual(labels[tiles[0]["tile_id"]]["b"], "2")
            self.assertEqual(labels[tiles[0]["tile_id"]]["status"], "labeled")
            self.assertTrue(labels_path.with_suffix(".previous.csv").exists())
            self.assertIn(tiles[1]["tile_id"], panel.children[2].children[0].value)
            self.assertNotEqual(bytes(panel.children[2].children[1].value), first_image)
            self.assertEqual(display.call_count, 1)
            panel.children[4].children[1].click()
            self.assertEqual(h.load_pip_labels(labels_path, tiles)[tiles[1]["tile_id"]]["status"], "rejected")
            resumed = station(tiles, crops, labels_path)
            self.assertEqual(resumed.children[3].children[0].value, "10")
            clear.assert_not_called()

    def test_equal_total_does_not_hide_wrong_tile_pairs(self):
        raw = self.root / "raw"
        (raw / "images").mkdir(parents=True)
        Image.fromarray(np.full((64, 256, 3), 100, np.uint8)).save(raw / "images/photo.png")
        corners = np.float32([[[0, 0], [127, 0], [127, 63], [0, 63]], [[128, 0], [255, 0], [255, 63], [128, 63]]])
        normalized = (corners / [256, 64]).tolist()
        tile_records = [{"tile_id": "first", "image": "photo.png"}, {"tile_id": "second", "image": "photo.png"}]
        labels = {"first": {"status": "labeled", "a": "1", "b": "3"}, "second": {"status": "labeled", "a": "2", "b": "4"}}
        fake_tensor = SimpleNamespace(cpu=lambda: SimpleNamespace(numpy=lambda: corners))
        detector = SimpleNamespace(predict=lambda *a, **kw: [SimpleNamespace(obb=SimpleNamespace(xyxyxyxy=fake_tensor))])
        function = self.classifier_function("evaluate_photos", {
            "split": {"photos": [{"image": "photo.png", "split": "test"}]}, "tiles": tile_records,
            "records": [{"image": "photo.png", "width": 256, "height": 64, "boxes": normalized}],
            "pip_labels": labels, "RAW": raw, "DETECTION_CONFIDENCE": 0.25, "PIP_CONFIDENCE": 0.8, "BLANK_SCORE": 50})
        values = iter([2, 2, 3, 3])  # Same total (10) as truth, but neither pair is correct.
        predictor = lambda half: np.eye(16)[next(values)]
        with patch.object(h.plt, "show"):
            function(detector, predictor, "test", self.root / "evaluation")
        summary = json.loads((self.root / "evaluation/summary.json").read_text())
        self.assertEqual(summary["exact_score_accuracy"], 1.0)
        self.assertEqual(summary["all_tiles_correct_accuracy"], 0.0)
        h.plt.close("all")

    def test_blank_values_are_scored_without_changing_pip_labels(self):
        pairs = [(0, 0), (2, 0), (3, 4)]
        self.assertEqual(h.score_pairs(pairs), 9)
        self.assertEqual(h.score_pairs(pairs, 25), 84)
        self.assertEqual(h.score_pairs(pairs, 50), 159)


if __name__ == "__main__":
    unittest.main()
