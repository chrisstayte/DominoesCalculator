"""Verify recipe isolation, actual augmentation, and portable grayscale inference."""
from pathlib import Path
import importlib.util
import tempfile
import unittest

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("training_common", ROOT / "notebook_sources/common.py")
h = importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)
exec(compile((ROOT / "notebook_sources/training_helpers.py").read_text(), "training helpers", "exec"), vars(h))


class RecipeTests(unittest.TestCase):
    def test_colab_runner_changes_configuration_without_changing_helper_locals(self):
        spec = importlib.util.spec_from_file_location("stage_runner", ROOT / "scripts/run_model_stage.py")
        runner = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(runner)
        source = 'ACTION = "label"\nRUN_NAME = "old"\ndef helper():\n    ACTION = "label"\n    return ACTION\n'
        namespace = {}
        exec(runner.configured_cell(source, {"ACTION": "train", "RUN_NAME": "new"}, "synthetic cell"), namespace)
        self.assertEqual(namespace["ACTION"], "train")
        self.assertEqual(namespace["RUN_NAME"], "new")
        self.assertEqual(namespace["helper"](), "label")

    def test_old_runs_can_be_evaluated_but_not_resumed_under_new_recipe(self):
        data = {"split_signature": "fixed", "labels_sha256": "labels"}
        recipe = {"version": h.CLASSIFIER_RECIPE, "embedded_grayscale": True}
        h.check_run_contract(data, data, recipe, "evaluate")
        with self.assertRaisesRegex(ValueError, "new RUN_NAME"):
            h.check_run_contract(data, data, recipe, "resume")
        h.check_run_contract({**data, "training_recipe": recipe}, data, recipe, "resume")
        with self.assertRaisesRegex(ValueError, "current data"):
            h.check_run_contract({**data, "labels_sha256": "changed"}, data, recipe, "evaluate")

    def test_grayscale_detector_copies_never_enter_holdouts_or_original_cache(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            raw = root / "raw"
            (raw / "images").mkdir(parents=True)
            (raw / "labels").mkdir()
            rows = []
            records = []
            label = "0 0 0 1 0 1 1 0 1\n"
            for split in ["train", "val", "test"]:
                name = split + ".png"
                Image.new("RGB", (60, 30), (230, 30, 90)).save(raw / "images" / name)
                (raw / "labels" / (split + ".txt")).write_text(label)
                rows.append({"image": name, "split": split})
                records.append({"image": name, "stem": split})
            split = {"signature": "unchanged", "photos": rows}
            old = h.prepare_detector(raw, records, split, root / "work")
            new = h.prepare_detector_training(raw, records, split, root / "work")
            self.assertNotEqual(old.parent, new.parent)
            self.assertEqual(len(list((new.parent / "train/images").iterdir())), 2)
            self.assertEqual((new.parent / "train/labels/gray_train.txt").read_text(), label)
            gray = np.asarray(Image.open(new.parent / "train/images/gray_train.png").convert("RGB"))
            np.testing.assert_array_equal(gray[:, :, 0], gray[:, :, 1])
            for holdout in ["val", "test"]:
                self.assertEqual(len(list((new.parent / holdout / "images").iterdir())), 1)
                self.assertEqual((new.parent / holdout / "images" / (holdout + ".png")).read_bytes(),
                                 (raw / "images" / (holdout + ".png")).read_bytes())
            self.assertEqual(len(list((old.parent / "train/images").iterdir())), 1)


@unittest.skipUnless(importlib.util.find_spec("tensorflow"), "TensorFlow needed for model/augmentation checks")
class TensorFlowTrainingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        import tensorflow as tf
        cls.tf = tf

    def test_grayscale_is_embedded_and_survives_safe_model_reload(self):
        tf = self.tf
        model = h.build_classifier(tf)
        conv = next(layer for layer in model.layers if isinstance(layer, tf.keras.layers.Conv2D))
        self.assertEqual(conv.input.shape[-1], 1)
        rgb = np.random.default_rng(2).uniform(0, 255, (2, 128, 128, 3)).astype(np.float32)
        gray = tf.repeat(tf.image.rgb_to_grayscale(rgb), 3, axis=-1).numpy() / 0.9999
        expected = model(rgb, training=False).numpy()
        np.testing.assert_allclose(model(gray, training=False).numpy(), expected, atol=1e-6)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "model.keras"
            model.save(path)
            loaded = tf.keras.models.load_model(path, compile=False, safe_mode=True)
            np.testing.assert_allclose(loaded(rgb, training=False).numpy(), expected, atol=1e-6)

    def test_augmentation_runs_inside_tf_data_without_changing_labels_or_shape(self):
        tf = self.tf
        image = np.full((128, 128, 3), 240, np.uint8)
        image[20:36, 20:36] = (180, 20, 60)
        dataset = tf.data.Dataset.from_tensor_slices((np.stack([image] * 8), [4] * 8))
        dataset = dataset.map(lambda x, y: h.augment_classifier_image(x, y, tf)).batch(8)
        images, labels = next(iter(dataset))
        self.assertEqual(tuple(images.shape), (8, 128, 128, 3))
        self.assertEqual(images.dtype, tf.float32)
        np.testing.assert_array_equal(labels, [4] * 8)
        self.assertTrue(np.isfinite(images.numpy()).all())
        self.assertGreaterEqual(float(tf.reduce_min(images)), 0)
        self.assertLessEqual(float(tf.reduce_max(images)), 255)
        self.assertFalse(np.allclose(images[0], images[1]))

    def test_grayscale_model_converts_to_fp32_and_int8_tflite(self):
        tf = self.tf
        model = h.build_classifier(tf)
        inputs = np.random.default_rng(4).uniform(0, 255, (1, 128, 128, 3)).astype(np.float32)
        expected = model(inputs, training=False).numpy()
        for quantized in [False, True]:
            with self.subTest(quantized=quantized):
                converter = tf.lite.TFLiteConverter.from_keras_model(model)
                if quantized:
                    converter.optimizations = [tf.lite.Optimize.DEFAULT]
                    converter.representative_dataset = lambda: iter([[inputs], [inputs * 0.5]])
                    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
                    converter.inference_input_type = tf.uint8
                    converter.inference_output_type = tf.uint8
                interpreter = tf.lite.Interpreter(model_content=converter.convert())
                interpreter.allocate_tensors()
                info = interpreter.get_input_details()[0]
                array = inputs
                if quantized:
                    scale, zero = info["quantization"]
                    array = np.clip(np.rint(inputs / scale + zero), 0, 255).astype(np.uint8)
                interpreter.set_tensor(info["index"], array)
                interpreter.invoke()
                output_info = interpreter.get_output_details()[0]
                actual = interpreter.get_tensor(output_info["index"])
                if quantized:
                    scale, zero = output_info["quantization"]
                    actual = (actual.astype(np.float32) - zero) * scale
                np.testing.assert_allclose(actual, expected, atol=0.01 if quantized else 1e-5)


if __name__ == "__main__":
    unittest.main()
