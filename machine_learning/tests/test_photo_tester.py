"""Photo inference checks with synthetic inputs; no saved user models are required."""
from pathlib import Path
from types import SimpleNamespace
import ast
from contextlib import nullcontext
import importlib.util
import json
import os
import sys
import tempfile
import unittest
from unittest.mock import patch

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("photo_common", ROOT / "notebook_sources/common.py")
common = importlib.util.module_from_spec(spec)
spec.loader.exec_module(common)


class PhotoTesterTests(unittest.TestCase):
    def setUp(self):
        source = ast.parse((ROOT / "notebook_sources/photo_tester.py").read_text())
        functions = [node for node in source.body if isinstance(node, ast.FunctionDef)
                     and node.name in {"predict_photo", "show_photo_result"}]
        namespace = dict(vars(common))
        exec(compile(ast.Module(body=functions, type_ignores=[]), "photo tester", "exec"), namespace)
        self.predict = namespace["predict_photo"]
        self.show = namespace["show_photo_result"]
        self.rgb = np.zeros((64, 128, 3), np.uint8)
        self.rgb[:, :64] = (240, 10, 20)
        self.rgb[:, 64:] = (30, 40, 230)
        self.box = [[0, 0], [127, 0], [127, 63], [0, 63]]

    def tearDown(self):
        common.plt.close("all")

    def detector(self, boxes):
        def tensor(value):
            return SimpleNamespace(cpu=lambda: SimpleNamespace(numpy=lambda: np.asarray(value, np.float32)))
        obb = SimpleNamespace(xyxyxyxy=tensor(np.asarray(boxes).reshape(-1, 4, 2)),
                              conf=tensor([0.9] * len(boxes)))
        self.calls = []

        def predict(image, **kwargs):
            self.calls.append((image, kwargs))
            return [SimpleNamespace(obb=obb)]
        return SimpleNamespace(predict=predict)

    def test_rgb_geometry_and_blank_scoring_match_training(self):
        halves = []

        def classify(half):
            halves.append(half)
            return np.eye(16)[0 if len(halves) == 1 else 12]

        report, crops = self.predict(self.rgb, self.detector([self.box]), classify,
                                     detector_image_size=320, detection_confidence=0.4, blank_score=50)
        np.testing.assert_array_equal(self.calls[0][0], self.rgb[:, :, ::-1])
        self.assertEqual(self.calls[0][1]["imgsz"], 320)
        self.assertEqual(self.calls[0][1]["conf"], 0.4)
        self.assertEqual(self.calls[0][1]["device"], "cpu")
        self.assertEqual([half.shape for half in halves], [(128, 128, 3)] * 2)
        self.assertGreater(halves[0][:, :, 0].mean(), 220)
        self.assertGreater(halves[1][:, :, 2].mean(), 220)
        self.assertEqual(crops[0].shape, (128, 256, 3))
        self.assertEqual(report["predicted_total"], 62)
        self.assertEqual(report["raw_pips"], 12)
        self.assertFalse(report["needs_review"])
        self.assertEqual((report["tiles"][0]["a"], report["tiles"][0]["b"]), (0, 12))

    def test_overlapping_detections_are_flagged_and_not_silently_removed(self):
        report, _ = self.predict(self.rgb, self.detector([self.box, self.box]), lambda half: np.eye(16)[3])
        self.assertEqual(report["detected_tiles"], 2)
        self.assertEqual(report["predicted_total"], 12)
        self.assertTrue(all(row["needs_review"] for row in report["tiles"]))
        self.assertIn("Possible duplicate of tile 2", report["tiles"][0]["review_reasons"])

    def test_no_detections_do_not_claim_a_zero_score(self):
        report, crops = self.predict(self.rgb, self.detector([]), lambda half: self.fail("No crops expected"))
        self.assertIsNone(report["predicted_total"])
        self.assertIsNone(report["raw_pips"])
        self.assertEqual(crops, [])
        self.assertTrue(report["needs_review"])

    def test_unreadable_crop_preserves_detection_and_marks_subtotal(self):
        report, crops = self.predict(self.rgb, self.detector([self.box, [[0, 0]] * 4]),
                                     lambda half: np.eye(16)[5])
        self.assertEqual(report["detected_tiles"], 2)
        self.assertIsNone(report["predicted_total"])
        self.assertEqual(report["readable_subtotal"], 10)
        self.assertIsNone(crops[1])
        self.assertTrue(report["tiles"][1]["needs_review"])

    def test_low_confidence_values_stay_in_total(self):
        probabilities = np.full(16, 0.04)
        probabilities[9] = 0.4
        report, _ = self.predict(self.rgb, self.detector([self.box]), lambda half: probabilities)
        self.assertEqual(report["predicted_total"], 18)
        self.assertIn("Low pip confidence", report["tiles"][0]["review_reasons"])

    def test_invalid_model_output_cannot_be_reported_as_complete(self):
        for bad in [np.full(16, np.nan), np.ones(15)]:
            with self.subTest(shape=bad.shape):
                report, _ = self.predict(self.rgb, self.detector([self.box]), lambda half: bad)
                self.assertIsNone(report["predicted_total"])
                self.assertTrue(report["needs_review"])

    def test_overlay_and_json_preserve_the_predictions(self):
        report, crops = self.predict(self.rgb, self.detector([self.box]), lambda half: np.eye(16)[7])
        with patch.object(common.plt, "show"), tempfile.TemporaryDirectory() as temporary:
            figure = self.show(self.rgb, report, crops, "Synthetic test photo")
            figure.savefig(Path(temporary) / "overlay.png")
            common.write_json(Path(temporary) / "predictions.json", report)
            self.assertIn("Predicted total: 14", figure.axes[0].get_title())
            self.assertEqual(figure.axes[0].texts[0].get_text(), "#1  7 | 7")

    def test_standalone_notebook_runs_without_training_data_or_labels(self):
        import nbformat
        with tempfile.TemporaryDirectory() as temporary:
            project = Path(temporary)
            detector_run = project / "models/detector/domino-v1-01"
            classifier_run = project / "models/classifier/pips-v1-02"
            (detector_run / "weights").mkdir(parents=True)
            classifier_run.mkdir(parents=True)
            (detector_run / "weights/best.pt").touch()
            (classifier_run / "best.keras").touch()
            common.write_json(detector_run / "dataset_contract.json", {"split_signature": "synthetic", "image_size": 640})
            common.write_json(classifier_run / "dataset_contract.json", {
                "split_signature": "synthetic", "image_size": 128,
                "crop_version": common.CROP_VERSION, "class_names": common.CLASS_NAMES})
            photo = Image.fromarray(self.rgb)
            exif = photo.getexif()
            exif[274] = 6  # Rotated phone capture; the saved input must follow display orientation.
            photo_path = project / "synthetic.jpeg"
            photo.save(photo_path, exif=exif)
            with Image.open(photo_path) as original:
                self.assertEqual(original.size, (128, 64))
            detector = self.detector([[[0, 0], [63, 0], [63, 127], [0, 127]]])

            class Classifier:
                input_shape = (None, 128, 128, 3)
                output_shape = (None, 16)
                inputs = [SimpleNamespace(name="rgb_pixels")]

                def __call__(self, inputs, training):
                    self_input = inputs["rgb_pixels"]
                    if self_input.shape != (1, 128, 128, 3) or self_input.dtype != np.float32:
                        raise AssertionError("Wrong classifier input")
                    return SimpleNamespace(numpy=lambda: np.eye(16)[[4]])

            tensorflow = SimpleNamespace(device=lambda *_: nullcontext(),
                                         keras=SimpleNamespace(models=SimpleNamespace(load_model=lambda *a, **k: Classifier())))
            notebook = nbformat.read(ROOT / "notebooks/04_test_photo.ipynb", as_version=4)
            nbformat.validate(notebook)
            namespace = {}
            with patch.dict(os.environ, {"DOMINO_ML_ROOT": str(project), "DOMINO_SKIP_INSTALL": "1",
                                          "DOMINO_WORK_DIR": str(project / "work")}), \
                 patch.dict(sys.modules, {"tensorflow": tensorflow, "ultralytics": SimpleNamespace(YOLO=lambda *_: detector)}), \
                 patch("IPython.display.display"), patch.object(common.plt, "show"):
                for cell in notebook.cells:
                    if cell.cell_type == "code":
                        source = cell.source.replace('PHOTO_PATH = ""', f"PHOTO_PATH = {str(photo_path)!r}")
                        exec(compile(source, "standalone photo notebook", "exec"), namespace)
            results = list((project / "photo_tests").iterdir())
            self.assertEqual(len(results), 1)
            saved = json.loads((results[0] / "predictions.json").read_text())
            self.assertEqual(saved["predicted_total"], 8)
            self.assertEqual(saved["classifier_run"], "pips-v1-02")
            with Image.open(results[0] / "photo.png") as oriented:
                self.assertEqual(oriented.size, (64, 128))
            self.assertTrue((results[0] / "overlay.png").is_file())
            self.assertTrue((results[0] / "tiles.csv").is_file())
            self.assertFalse((project / "data").exists())


if __name__ == "__main__":
    unittest.main()
