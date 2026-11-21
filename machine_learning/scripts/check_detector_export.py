"""Smoke-test YOLO26 OBB FP32/INT8 export with random weights and synthetic images.

Requires the detector notebook's export dependencies. This checks conversion and
inference mechanics, not accuracy. It never reads or modifies trained checkpoints.
"""
import os
from pathlib import Path
import tempfile

os.environ["JAX_PLATFORMS"] = "cpu"
os.environ.setdefault("YOLO_OFFLINE", "true")
os.environ.setdefault("YOLO_CONFIG_DIR", "/private/tmp/domino-yolo")
os.environ.setdefault("MPLCONFIGDIR", "/private/tmp/domino-mpl")

import numpy as np
from PIL import Image
from ai_edge_litert.interpreter import Interpreter
from ultralytics import YOLO


with tempfile.TemporaryDirectory(prefix="domino-export-smoke-") as temporary:
    root = Path(temporary)
    images = root / "images"
    images.mkdir()
    rng = np.random.default_rng(42)
    for index in range(8):
        Image.fromarray(rng.integers(0, 256, (128, 128, 3), dtype=np.uint8)).save(images / f"synthetic_{index}.png")
    calibration = root / "calibration.yaml"
    calibration.write_text(f"path: {root}\ntrain: images\nval: images\nnames: [domino]\n")
    model = YOLO("yolo26n-obb.yaml")
    checkpoint = root / "synthetic_detector.pt"
    model.save(checkpoint)
    shapes = []
    for quantize in (32, 8):
        exported = Path(YOLO(checkpoint).export(format="litert", quantize=quantize, imgsz=128,
                                               batch=1, device="cpu", data=str(calibration)))
        assert exported.is_file() and exported.suffix == ".tflite"
        interpreter = Interpreter(model_path=str(exported))
        interpreter.allocate_tensors()
        inp = interpreter.get_input_details()[0]
        assert inp["dtype"] == np.float32
        interpreter.set_tensor(inp["index"], rng.random(inp["shape"]).astype(np.float32))
        interpreter.invoke()
        outputs = [interpreter.get_tensor(o["index"]) for o in interpreter.get_output_details()]
        assert outputs and all(o.size and np.isfinite(o).all() for o in outputs)
        shapes.append([o.shape for o in outputs])
        print(f"PASS: YOLO26 OBB quantize={quantize}, {exported.stat().st_size} bytes, outputs {shapes[-1]}", flush=True)
    assert shapes[0] == shapes[1]
    print("PASS: FP32 and INT8 conversion/inference. Synthetic smoke test only; no accuracy claim.", flush=True)
