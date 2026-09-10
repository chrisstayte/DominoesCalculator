# %% [markdown]
# # 1 · Train the domino detector
#
# **Goal:** find whole domino tiles and their angles with YOLO26-nano OBB.
# The second notebook reads each tile's two pip values. This notebook is self-contained:
# upload the notebook and your dataset ZIP; no repository clone or helper upload is needed.
#
# **First Colab session**
# 1. In Google Drive, create `MyDrive/DominoesCalculator` and upload `dominoes-v1.zip` there.
# 2. Open this notebook in Colab. Choose **Runtime → Change runtime type → GPU** for training.
# 3. Run setup and preparation. Review the photo groups before creating the split.
# 4. Set `ACTION = "train"`, rerun configuration and the training/evaluation cells.
#
# The default `prepare` action performs data checks without GPU training. Human review
# is intentional: this is a staged experiment, not a blind “Run all” training job.
# Keep the final test set untouched until model/threshold choices are settled.
#
# **Storage:** original data, grouping decisions, splits, checkpoints, plots, and exports
# stay in Drive. Training images are copied to `/content/domino-work` for faster reads.
# Saving the notebook alone does not save its runtime. [Colab storage](https://research.google.com/colaboratory/faq.html).

# %% [markdown]
# ## Setup
# Run installation before importing packages. If Colab asks for a runtime restart, restart
# and rerun setup. Package versions are pinned; an environment snapshot is also saved per run.
# Export conversion may install additional backend dependencies; restart after such changes if requested.

# %%
import os
import subprocess
import sys

if os.environ.get("DOMINO_SKIP_INSTALL") != "1":
    subprocess.check_call([sys.executable, "-m", "pip", "install", "-q",
                           "ultralytics==8.4.144", "torch==2.9.0", "torchvision==0.24.0", "numpy==1.26.4", "pandas==2.2.3",
                           "matplotlib==3.10.1", "pillow==11.1.0", "opencv-python==4.11.0.86"])

# %% [markdown]
# ### Configuration
# `prepare` checks and splits data; `train` starts a new run; `resume` continues its last
# checkpoint; `evaluate` loads its best checkpoint; `export` also creates and checks mobile models.
# Choose a new `RUN_NAME` for a new experiment. Never overwrite an old run to try new settings.

# %%
DATASET_NAME = "dominoes-v1"
RUN_NAME = "domino-v1-01"
ACTION = "prepare"  # prepare | train | resume | evaluate | export
GROUPS_REVIEWED = False  # Set True only after checking the grouping CSV/contact sheets below.
SEED = 42
EPOCHS = 100
IMAGE_SIZE = 640
BATCH_SIZE = 8  # Increase if GPU memory allows.
DETECTION_CONFIDENCE = 0.25  # Tune on validation only, then freeze for the final test.
FINAL_TEST = False
EXPORT_INT8 = True
MAX_EXPORT_MAP_DROP = 0.02  # Absolute mAP50–95 drop allowed relative to FP32/PyTorch.
assert ACTION in {"prepare", "train", "resume", "evaluate", "export"}

# %% [markdown]
# ### Export runtime dependencies
# This runs only for `export`, before importing PyTorch. If you changed to export after
# already importing/training in this session, restart the runtime and run from setup with
# `ACTION = "export"`. This lets the package resolver keep NumPy/PyTorch compatible.

# %%
if ACTION == "export" and os.environ.get("DOMINO_SKIP_INSTALL") != "1":
    subprocess.check_call([sys.executable, "-m", "pip", "install", "-q", "numpy==1.26.4",
                           "torch==2.9.0", "torchvision==0.24.0", "litert-torch==0.9.0",
                           "ai-edge-litert==2.1.4", "ai-edge-quantizer==0.6.0"])

# %% shared

# %%
from importlib.metadata import version

PROJECT, WORK, IN_COLAB = setup_project()
RAW = stage_export(PROJECT, WORK, DATASET_NAME)
STATE = PROJECT / "data/manifests" / DATASET_NAME
STATE.mkdir(parents=True, exist_ok=True)
RUN = PROJECT / "models/detector" / RUN_NAME
print("Persistent project:", PROJECT)
print("Local training cache:", WORK)
print("Run:", RUN)
print("Action:", ACTION)
print("Python:", sys.version.split()[0])

# %% [markdown]
# ## Prepare and inspect the dataset
# Accepts `.jpeg`, `.jpg`, and `.png`, with class `0 = domino` and eight normalized
# corner coordinates per object. Images are opened in their display/EXIF orientation.
# Inspect overlays before training; format validity alone does not prove boxes are well placed.

# %%
records, fingerprint = audit_export(RAW)
write_json(STATE / "dataset.json", {"fingerprint": fingerprint, "photos": records})
contact_sheet(records, RAW, start=0, count=6, overlays=True)

# %% [markdown]
# ### Review repeated arrangements before splitting
# The CSV starts with one group per photo; exact file duplicates share a group automatically.
# Photos of the **same arrangement**, including alternate angles, belong to the same group.
# Review all contact-sheet pages. Edit the table below and rerun it, or edit
# `data/manifests/dominoes-v1/photo_groups.csv` in Drive. Keep the image names unchanged.
#
# Use stable short group names such as `wood_arrangement_1`. Group by arrangement/session
# when shots are closely related, not merely by which physical domino tiles appear.
# If there are fewer than three independent groups, collect more arrangements first.

# %%
GROUPS_PATH = STATE / "photo_groups.csv"
group_rows = ensure_groups(records, GROUPS_PATH)
# Example after viewing your photos: {"a94404f6-IMG_0801.jpeg": "wood_arrangement_1"}
GROUP_OVERRIDES = {}
unknown = set(GROUP_OVERRIDES) - {r["image"] for r in group_rows}
if unknown:
    raise ValueError(f"Unknown image names in GROUP_OVERRIDES: {sorted(unknown)}")
for row in group_rows:
    row["group"] = GROUP_OVERRIDES.get(row["image"], row["group"])
write_csv(GROUPS_PATH, group_rows, ["image", "group"])
display(pd.DataFrame(group_rows))
for start in range(0, len(records), 12):
    contact_sheet(records, RAW, start=start, count=12)

# %%
split = frozen_split(records, fingerprint, GROUPS_PATH, STATE / "split.json", GROUPS_REVIEWED, SEED)
DATA_YAML = None
if split:
    DATA_YAML = prepare_detector(RAW, records, split, WORK)
    counts = pd.DataFrame(split["photos"]).groupby("split").agg(photos=("image", "count"), groups=("group", "nunique"))
    display(counts.reindex(["train", "val", "test"]))
    ax = counts.reindex(["train", "val", "test"])["photos"].plot.bar(color="#34699a", rot=0)
    ax.set(title="Photos in the frozen split", ylabel="Original photos", xlabel="Split", ylim=(0, None))
    plt.tight_layout()
    plt.show()
    print("Frozen split:", STATE / "split.json")
    print("Dataset YAML:", DATA_YAML)

# %% [markdown]
# ## Train or resume
# Uses `yolo26n-obb.pt`, which accepts the Label Studio OBB export. The “YOLOv8” export name
# describes the annotation format; it does not require using a YOLOv8 model.
# [OBB training and results](https://docs.ultralytics.com/tasks/obb/).
#
# Checkpoints are written to Drive each epoch. For an interrupted run, reconnect, rerun setup
# and preparation, keep the same `RUN_NAME`, and choose `resume`. For a completed experiment,
# choose `evaluate` or a new run name. Resume restores the model/optimizer from `last.pt`.
# Set a realistic epoch budget and inspect validation; no fixed training time or accuracy is promised.

# %%
detector = None
if ACTION != "prepare":
    if split is None:
        raise RuntimeError("Review photo groups and create the split before training/evaluation.")
    import torch
    from ultralytics import YOLO
    DEVICE = 0 if torch.cuda.is_available() else "cpu"
    if ACTION in {"train", "resume"} and DEVICE == "cpu" and not os.environ.get("DOMINO_ALLOW_CPU"):
        raise RuntimeError("Select a Colab GPU runtime, then rerun setup. CPU training is disabled by default.")
    contract = {"split_signature": split["signature"], "model": "yolo26n-obb.pt", "image_size": IMAGE_SIZE, "seed": SEED}
    if ACTION == "train":
        if RUN.exists():
            raise FileExistsError("Run already exists. Use resume/evaluate or choose a new RUN_NAME.")
        RUN.mkdir(parents=True)
        write_json(RUN / "dataset_contract.json", contract)
        (RUN / "environment.txt").write_text(subprocess.check_output([sys.executable, "-m", "pip", "freeze"], text=True))
        detector = YOLO("yolo26n-obb.pt")
        detector.train(data=str(DATA_YAML), epochs=EPOCHS, imgsz=IMAGE_SIZE, batch=BATCH_SIZE,
                       seed=SEED, deterministic=True, patience=20, device=DEVICE,
                       project=str(RUN.parent), name=RUN.name, exist_ok=True, save=True, plots=True)
    else:
        if not (RUN / "dataset_contract.json").is_file() or json.loads((RUN / "dataset_contract.json").read_text()) != contract:
            raise ValueError("Run configuration does not match this dataset/model/image size/seed.")
        if ACTION == "resume":
            checkpoint = RUN / "weights/last.pt"
            if not checkpoint.exists():
                raise FileNotFoundError("No last.pt exists yet. Choose a new run name to restart.")
            detector = YOLO(str(checkpoint))
            detector.train(resume=True, device=DEVICE)
    best = RUN / "weights/best.pt"
    if not best.is_file():
        raise FileNotFoundError(f"No trained checkpoint found: {best}")
    detector = YOLO(str(best))
    print("Using this run's best checkpoint:", best)
else:
    print("Preparation complete. Set ACTION='train' when the grouping and overlays are reviewed.")

# %% [markdown]
# ## Check detection quality
# Validation mAP measures overlap and ranking, while missed/extra-tile counts show failures
# that matter for scoring. Inspect the examples as well as the numbers. Diagnostics below use
# one-to-one matching at IoU 0.5; official mAP is calculated separately by Ultralytics.

# %%
if detector is not None:
    validation = detector.val(data=str(DATA_YAML), split="val", imgsz=IMAGE_SIZE,
                              device=DEVICE, project=str(RUN / "checks"), name="val", exist_ok=True, plots=True)
    val_scores = {"map50": float(validation.box.map50), "map50_95": float(validation.box.map)}
    write_json(RUN / "validation.json", val_scores)
    display(pd.DataFrame([val_scores]))
    training_csv = RUN / "results.csv"
    if training_csv.exists():
        history = pd.read_csv(training_csv)
        history.columns = history.columns.str.strip()
        metric_columns = [c for c in history if "mAP" in c]
        loss_columns = [c for c in history if "loss" in c]
        fig, axes = plt.subplots(1, 2, figsize=(13, 4))
        history.plot(x="epoch", y=loss_columns, ax=axes[0], title="Detector losses")
        history.plot(x="epoch", y=metric_columns, ax=axes[1], title="Validation detection accuracy")
        axes[0].set_ylabel("Loss")
        axes[1].set_ylabel("mAP")
        axes[1].set_ylim(0, 1)
        plt.tight_layout()
        plt.show()

# %%
if detector is not None:
    val_names = {r["image"] for r in split["photos"] if r["split"] == "val"}
    diagnostics, previews = [], []
    for record in records:
        if record["image"] not in val_names:
            continue
        result = detector.predict(str(RAW / "images" / record["image"]), imgsz=IMAGE_SIZE,
                                  conf=DETECTION_CONFIDENCE, device=DEVICE, verbose=False)[0]
        predicted = result.obb.xyxyxyxy.cpu().numpy()
        truth = np.asarray(record["boxes"]).reshape(-1, 4, 2) * [record["width"], record["height"]]
        matches = match_boxes(truth, predicted)
        missed, extra = len(truth) - len(matches), len(predicted) - len(matches)
        diagnostics.append({"image": record["image"], "expected": len(truth), "detected": len(predicted), "missed": missed, "extra": extra})
        previews.append((missed + extra, record, predicted, truth))
    frame = pd.DataFrame(diagnostics)
    display(frame.sort_values(["missed", "extra"], ascending=False))
    frame.to_csv(RUN / "validation_tile_counts.csv", index=False)
    for _, record, predicted, truth in sorted(previews, key=lambda x: x[0], reverse=True)[:3]:
        fig, ax = plt.subplots(figsize=(10, 7))
        ax.imshow(read_rgb(RAW / "images" / record["image"]))
        for boxes, color, label in [(truth, "#e6a044", "Labeled"), (predicted, "#367bb1", "Detected")]:
            for i, box in enumerate(boxes):
                p = np.vstack([box, box[0]])
                ax.plot(p[:, 0], p[:, 1], color=color, linewidth=1.5, label=label if i == 0 else None)
        ax.set_title(record["image"])
        ax.legend()
        ax.axis("off")
        plt.show()

# %% [markdown]
# ## Export and verify mobile models
# Export FP32 first, then optionally INT8. INT8 calibration uses **training photos only**.
# Compare exports on validation before selecting a default. Keep both versions and measured
# sizes. [Current LiteRT export API](https://docs.ultralytics.com/integrations/litert/).
#
# The export bundle is an integration input. The app still needs OBB tensor decoding,
# letterbox coordinate reversal, and the identical tile rectification used in notebook 2.
# The current SSD app decoder cannot consume these models just by changing a filename.

# %%
if ACTION == "export" and detector is not None:
    export_dir = RUN / "exports"
    export_dir.mkdir(exist_ok=True)
    local_export = WORK / "export" / RUN_NAME
    local_export.mkdir(parents=True, exist_ok=True)
    export_checkpoint = local_export / "domino_detector.pt"
    shutil.copy2(RUN / "weights/best.pt", export_checkpoint)
    export_rows = []
    for mode, quantize in [("fp32", 32)] + ([("int8", 8)] if EXPORT_INT8 else []):
        export_model = YOLO(str(export_checkpoint))
        produced = Path(export_model.export(format="litert", quantize=quantize, imgsz=IMAGE_SIZE,
                                            batch=1, device="cpu", data=str(DATA_YAML.parent / "calibration.yaml")))
        if not produced.is_file() or produced.suffix != ".tflite":
            raise RuntimeError(f"Exporter did not return a .tflite file: {produced}")
        saved = export_dir / f"domino_detector_{mode}.tflite"
        shutil.copy2(produced, saved)
        exported_metrics = YOLO(str(saved), task="obb").val(data=str(DATA_YAML), split="val", imgsz=IMAGE_SIZE,
                                                           device="cpu", project=str(RUN / "checks"), name=f"export_{mode}", exist_ok=True)
        score = float(exported_metrics.box.map)
        export_rows.append({"format": mode, "file": saved.name, "bytes": saved.stat().st_size,
                            "map50_95": score, "drop_from_pytorch": val_scores["map50_95"] - score})
    acceptable = [r for r in export_rows if r["drop_from_pytorch"] <= MAX_EXPORT_MAP_DROP]
    preferred = next((r for r in acceptable if r["format"] == "int8"), next((r for r in acceptable if r["format"] == "fp32"), None))
    write_json(export_dir / "detector_metadata.json", {"task": "obb", "classes": ["domino"], "image_size": IMAGE_SIZE,
               "confidence": DETECTION_CONFIDENCE, "split_signature": split["signature"], "crop_version": CROP_VERSION,
               "preferred_file": preferred["file"] if preferred else None, "validation": export_rows,
               "preprocessing": "RGB, preserve aspect ratio with Ultralytics letterbox; invert padding/scale to original pixels",
               "postprocessing": "Read the exported tensor metadata; decode OBB, confidences and classes using the pinned Ultralytics backend. Do not reuse SSD output parsing."})
    display(pd.DataFrame(export_rows))
    if preferred is None:
        raise RuntimeError("No export met the validation tolerance. Keep the checkpoint and investigate conversion before deployment.")
    print("Preferred validated export:", export_dir / preferred["file"])

# %% [markdown]
# ## Final test and handoff
# Enable `FINAL_TEST` only after choosing the model, confidence, and export using validation.
# Do not use these test results to repeatedly tune the same experiment. Notebook 2 also
# reports full-photo scores once its pip labels and classifier are available.

# %%
if FINAL_TEST and detector is not None:
    test_metrics = detector.val(data=str(DATA_YAML), split="test", imgsz=IMAGE_SIZE, device=DEVICE,
                                project=str(RUN / "checks"), name="test", exist_ok=True, plots=True)
    write_json(RUN / "test.json", {"map50": float(test_metrics.box.map50), "map50_95": float(test_metrics.box.map)})
    print("Final held-out detection mAP50–95:", float(test_metrics.box.map))
print("Next: open 02_pip_classifier.ipynb with the same DATASET_NAME and Drive project.")
print("Labeling can start before detector training finishes; do not run both notebooks' GPU training at once.")
