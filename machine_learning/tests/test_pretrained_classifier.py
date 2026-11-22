"""Check isolation and portable transfer-learning behavior without private data."""
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "notebook_sources"))
import pretrained_classifier as experiment


class ExperimentSafetyTests(unittest.TestCase):
    def test_missing_existing_inputs_are_not_created_or_repaired(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaises(FileNotFoundError):
                experiment.read_existing_data(root)
            self.assertEqual(list(root.iterdir()), [])

    def test_candidate_contract_matches_photo_tester_and_refuses_replacement(self):
        metadata = {"split_signature": "fixed", "labels_sha256": "labels",
                    "crop_version": "long-edge-rgb-128-v1", "class_names": list(map(str, range(16))),
                    "image_size": 128, "seed": 42, "variant": "mixed", "inputs": {"private": "omitted"}}
        with tempfile.TemporaryDirectory() as directory:
            contract = experiment.save_model_contract(directory, metadata)
            self.assertEqual(contract["class_names"], list(map(str, range(16))))
            self.assertEqual(contract["image_size"], 128)
            self.assertNotIn("inputs", contract)
            self.assertFalse(contract["training_recipe"]["embedded_grayscale"])
            self.assertEqual(experiment.save_model_contract(directory, metadata), contract)
            with self.assertRaisesRegex(ValueError, "refusing to overwrite"):
                experiment.save_model_contract(directory, {**metadata, "split_signature": "different"})

    def test_new_runs_refuse_overwrite_and_path_escape(self):
        with tempfile.TemporaryDirectory() as directory:
            run = experiment.create_run(directory, "pips-v3-synthetic-01")
            marker = run / "best.keras"
            marker.write_bytes(b"existing checkpoint")
            with self.assertRaises(FileExistsError):
                experiment.create_run(directory, "pips-v3-synthetic-01")
            with self.assertRaises(ValueError):
                experiment.create_run(directory, "../../older-run")
            with self.assertRaises(ValueError):
                experiment.safe_child(directory, "../../outside.png")
            self.assertEqual(marker.read_bytes(), b"existing checkpoint")

    def test_input_inventory_detects_mutation(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "labels.csv"
            path.write_text("original labels")
            before = experiment.inventory([path])
            experiment.verify_inventory(before)
            path.write_text("changed labels")
            with self.assertRaisesRegex(RuntimeError, "protected input"):
                experiment.verify_inventory(before)

    def test_validation_metrics_preserve_absent_class_as_unknown(self):
        probabilities = np.zeros((3, 16))
        probabilities[[0, 1, 2], [0, 2, 2]] = 1
        report = experiment.accuracy_report([0, 1, 2], probabilities)
        self.assertEqual(report["accuracy"], 2 / 3)
        self.assertIsNone(report["per_value"][15]["accuracy"])
        self.assertEqual(report["per_value"][1]["accuracy"], 0)


@unittest.skipUnless(importlib.util.find_spec("tensorflow"), "TensorFlow required")
class TransferLearningTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        import tensorflow as tf
        cls.tf = tf

    def test_fine_tuning_keeps_batchnorm_frozen_and_saved_input_contract(self):
        tf = self.tf
        model, base = experiment.build_model(tf, weights=None)
        self.assertFalse(base.trainable)
        experiment.unfreeze_convolutions(base, tf)
        bn = [layer for layer in base.layers if isinstance(layer, tf.keras.layers.BatchNormalization)]
        self.assertTrue(bn)
        self.assertTrue(all(not layer.trainable for layer in bn))
        self.assertTrue(any(layer.trainable for layer in base.layers if isinstance(layer, tf.keras.layers.Conv2D)))
        before = [layer.moving_mean.numpy().copy() for layer in bn]
        model.compile(optimizer=tf.keras.optimizers.Adam(1e-4), loss="sparse_categorical_crossentropy")
        pixels = np.random.default_rng(42).uniform(0, 255, (2, 128, 128, 3)).astype(np.float32)
        loss = model.train_on_batch(pixels, np.array([0, 6]))
        self.assertTrue(np.isfinite(loss))
        for layer, original in zip(bn, before):
            np.testing.assert_array_equal(layer.moving_mean.numpy(), original)
        expected = model(pixels, training=False).numpy()
        self.assertEqual(expected.shape, (2, 16))
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "best.keras"
            model.save(path)
            model.load_weights(path)
            reloaded = tf.keras.models.load_model(path, compile=False)
            np.testing.assert_allclose(reloaded(pixels, training=False), expected, atol=1e-6)

    def test_augmentation_keeps_shape_numeric_range_and_labels(self):
        tf = self.tf
        pixels = np.full((128, 128, 3), 240, np.uint8)
        pixels[8:20, 8:20] = (10, 30, 90)
        for probability in (0.0, 0.5):
            dataset = tf.data.Dataset.from_tensor_slices((np.stack([pixels] * 4), [6] * 4))
            dataset = dataset.map(lambda x, y: experiment.augment(x, y, tf, probability)).batch(4)
            images, labels = next(iter(dataset))
            self.assertEqual(tuple(images.shape), (4, 128, 128, 3))
            np.testing.assert_array_equal(labels, [6] * 4)
            self.assertGreaterEqual(float(tf.reduce_min(images)), 0)
            self.assertLessEqual(float(tf.reduce_max(images)), 255)
            self.assertTrue(np.isfinite(images).all())


if __name__ == "__main__":
    unittest.main()
