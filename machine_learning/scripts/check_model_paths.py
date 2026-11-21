"""Exercise classifier train/resume/export cells on synthetic data, never user labels.

This checks execution mechanics, not model accuracy. Outputs stay in a temporary directory.
Requires the notebook training dependencies. Run separately from lightweight unit tests.
"""
from pathlib import Path
import json
import os
import tempfile

os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")
os.environ.setdefault("TF_NUM_INTEROP_THREADS", "1")
os.environ.setdefault("TF_NUM_INTRAOP_THREADS", "2")
os.environ.setdefault("MPLBACKEND", "Agg")
os.environ.setdefault("MPLCONFIGDIR", "/private/tmp/domino-model-mpl")
os.environ.setdefault("YOLO_CONFIG_DIR", "/private/tmp/domino-yolo")
os.environ.setdefault("YOLO_OFFLINE", "true")

import nbformat
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def run_cells(notebook, namespace, action):
    for i, cell in enumerate(notebook.cells):
        if cell.cell_type != "code":
            continue
        code = cell.source
        if 'ACTION = "label"' in code:
            code = code.replace('ACTION = "label"', f'ACTION = "{action}"')
            code = code.replace('EPOCHS = 60', 'EPOCHS = 1' if action == "train" else 'EPOCHS = 2')
            code = code.replace('BATCH_SIZE = 32', 'BATCH_SIZE = 16')
        print(f"SMOKE {action}: cell {i}", flush=True)
        exec(compile(code, f"classifier cell {i}", "exec"), namespace)
        if "matplotlib" in __import__("sys").modules:
            namespace.get("plt", __import__("matplotlib.pyplot", fromlist=["pyplot"])).close("all")


with tempfile.TemporaryDirectory(prefix="domino-model-smoke-") as temporary:
    project = Path(temporary)
    raw = project / "data/raw/dominoes-v1"
    (raw / "images").mkdir(parents=True)
    (raw / "labels").mkdir()
    (raw / "classes.txt").write_text("domino\n")
    # Three independent synthetic scenes, each containing 16 rectangular tiles.
    for scene in range(3):
        image = np.full((256, 512, 3), 240 - scene * 10, dtype=np.uint8)
        annotations = []
        for tile in range(16):
            x, y = (tile % 4) * 128, (tile // 4) * 64
            image[y:y+64, x:x+64] = ((tile * 13) % 255, 30 + scene * 10, 150)
            image[y:y+64, x+64:x+128] = (50, ((tile + 1) * 13) % 255, 100 + scene * 20)
            corners = np.array([[x, y], [x + 127, y], [x + 127, y + 63], [x, y + 63]]) / [512, 256]
            annotations.append("0 " + " ".join(map(str, corners.ravel())))
        Image.fromarray(image).save(raw / "images" / f"synthetic_{scene}.jpeg")
        (raw / "labels" / f"synthetic_{scene}.txt").write_text("\n".join(annotations))
    os.environ.update({"DOMINO_ML_ROOT": str(project), "DOMINO_WORK_DIR": str(project / "work"),
                       "DOMINO_SKIP_INSTALL": "1", "DOMINO_NO_WIDGETS": "1", "DOMINO_ALLOW_CPU": "1"})
    notebook = nbformat.read(ROOT / "notebooks/02_pip_classifier.ipynb", as_version=4)
    ns = {"display": lambda *_: None}
    run_cells(notebook, ns, "label")
    state = ns["STATE"]
    ns["ensure_groups"](ns["records"], state / "photo_groups.csv")
    ns["frozen_split"](ns["records"], ns["fingerprint"], state / "photo_groups.csv", state / "split.json", reviewed=True)
    labels = ns["load_pip_labels"](ns["LABELS_PATH"], ns["tiles"])
    for tile in ns["tiles"]:
        index = int(tile["box_index"])
        labels[tile["tile_id"]].update(a=str(index), b=str((index + 1) % 16), status="labeled")
    ns["write_csv"](ns["LABELS_PATH"], list(labels.values()), ["tile_id", "a", "b", "status"])
    run_cells(notebook, ns, "train")
    iterations_before = int(ns["classifier"].optimizer.iterations.numpy())
    run_cells(notebook, ns, "resume")
    progress = json.loads((ns["RUN"] / "progress.json").read_text())
    assert progress["completed_epochs"] == 2
    resumed = ns["tf"].keras.models.load_model(ns["RUN"] / progress["checkpoint"])
    assert int(resumed.optimizer.iterations.numpy()) > iterations_before
    run_cells(notebook, ns, "export")
    metadata = json.loads((ns["RUN"] / "exports/classifier_metadata.json").read_text())
    assert metadata["class_names"] == list(map(str, range(16)))
    assert {r["format"] for r in metadata["validation"]} == {"fp32", "int8"}
    assert next(r for r in metadata["validation"] if r["format"] == "fp32")["max_probability_difference"] < 1e-4
    print("PASS: synthetic classifier preparation, training, resume, evaluation, FP32/INT8 export, and numeric labels.", flush=True)

# Construct and predict with the installed YOLO26 OBB architecture without downloading weights.
from ultralytics import YOLO
from ultralytics.engine.exporter import export_formats
model = YOLO("yolo26n-obb.yaml")
result = model.predict(np.zeros((64, 64, 3), np.uint8), imgsz=64, device="cpu", verbose=False)[0]
assert result.obb is not None
assert "litert" in export_formats()["Argument"]
print("PASS: YOLO26 OBB architecture, result API, and LiteRT format availability.")
