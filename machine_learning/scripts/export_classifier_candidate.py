"""Export a trained candidate into a new private folder and verify CPU inference.

This does not change app assets, the trained model, labels, or detector.
CPU timing is a host diagnostic, not a phone benchmark.
"""
import argparse
import json
from pathlib import Path
import re
import sys
import time

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "notebook_sources"))
from common import sha256, write_json
from pretrained_classifier import accuracy_report, inventory, load_images, probabilities, read_existing_data, verify_inventory


def convert_model(model, destination, fp16=False):
    import tensorflow as tf
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    if fp16:
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_types = [tf.float16]
    Path(destination).write_bytes(converter.convert())


def lite_predictions(path, images, measure=False):
    import tensorflow as tf
    interpreter = tf.lite.Interpreter(model_path=str(path), num_threads=4)
    interpreter.allocate_tensors()
    input_info, output_info = interpreter.get_input_details()[0], interpreter.get_output_details()[0]
    if tuple(input_info["shape"]) != (1, 128, 128, 3) or input_info["dtype"] != np.float32:
        raise ValueError("Export changed the RGB 0–255 input contract.")
    values, elapsed = [], []
    for index, pixels in enumerate(images):
        interpreter.set_tensor(input_info["index"], pixels[None].astype(np.float32))
        started = time.perf_counter()
        interpreter.invoke()
        elapsed.append((time.perf_counter() - started) * 1000)
        values.append(interpreter.get_tensor(output_info["index"])[0])
    timings = {"cpu_threads": 4, "timed_examples": max(0, len(elapsed) - 10),
               "p50_ms_per_half": float(np.median(elapsed[10:])),
               "p95_ms_per_half": float(np.percentile(elapsed[10:], 95)),
               "scope": "Current host CPU, batch 1, first 10 invokes excluded; not phone latency."} if measure and len(elapsed) > 10 else None
    return np.asarray(values), timings


def export(project, run_name, export_name):
    import tensorflow as tf
    if not re.fullmatch(r"pips-v3-[a-z0-9-]+", run_name) or not re.fullmatch(r"[a-z0-9-]+", export_name):
        raise ValueError("Choose a candidate run and a new lowercase export name.")
    project = Path(project)
    crops, rows, _, protected = read_existing_data(project)
    run = project / "models/classifier" / run_name
    before = inventory([*protected, run / "best.keras"])
    output = run / "exports" / export_name
    output.mkdir(parents=True, exist_ok=False)
    pixels, truth = load_images(crops, rows, "val")
    model = tf.keras.models.load_model(run / "best.keras", compile=False)
    expected = probabilities(model, pixels)
    original = accuracy_report(truth, expected)
    reports = []
    for fp16 in (False, True):
        name = "fp16" if fp16 else "fp32"
        path = output / (name + ".tflite")
        convert_model(model, path, fp16=fp16)
        actual, timing = lite_predictions(path, pixels, measure=True)
        if not np.isfinite(actual).all() or actual.shape != expected.shape:
            raise RuntimeError("Invalid exported classifier output.")
        report = {"format": name, "bytes": path.stat().st_size, "sha256": sha256(path),
                  "validation": accuracy_report(truth, actual),
                  "changed_predictions": int(np.sum(actual.argmax(axis=1) != expected.argmax(axis=1))),
                  "max_probability_difference": float(np.max(np.abs(actual - expected))), "timing": timing}
        if report["validation"]["accuracy"] < original["accuracy"] - 0.02:
            raise RuntimeError("Export accuracy dropped more than two percentage points; candidate not approved.")
        reports.append(report)
    verify_inventory(before)
    summary = {"run": run_name, "keras_validation": original, "formats": reports,
               "external_input": "RGB float32 0–255; scaling embedded", "classes": list(range(16)),
               "protected_inputs_unchanged": True, "phone_verified": False}
    write_json(output / "validation.json", summary)
    print("CLASSIFIER_EXPORT_COMPLETE " + json.dumps(summary), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, required=True)
    parser.add_argument("--run", required=True)
    parser.add_argument("--export", default="portable-01")
    args = parser.parse_args()
    export(args.project, args.run, args.export)
