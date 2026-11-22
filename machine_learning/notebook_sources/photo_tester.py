# %% [markdown]
# # 4 · Try your models on a new photo
#
# Two saved models work together: the detector finds whole dominoes; the classifier
# reads each half as 0–15. This notebook loads your existing checkpoints from Drive.
# It does not train, change labels, or need the original dataset archive.
#
# 1. Run Setup. If it requests a restart, restart the session and run Setup again.
# 2. Check the run names and blank-half score below. A CPU runtime is enough.
# 3. Choose **Runtime → Run all**, mount Drive, then upload a JPEG or PNG when prompted.
# 4. Inspect the numbered outlines, predicted values, and straightened crops.
#    Rerun **Upload and test** for another photo.
#
# Try fresh arrangements and count the values yourself to compare. These are exploratory
# predictions, not an accuracy measurement. Confident predictions can still miss or
# double-count tiles; inspect every outline. Keep the frozen test set for final evaluation.

# %% [markdown]
# ## Setup
# Use the same pinned libraries as the training notebooks. No mobile export is needed.

# %% setup
install_packages([TENSORFLOW_REQUIREMENT, KERAS_REQUIREMENT, NUMPY_REQUIREMENT,
                  "pandas==2.2.3", "matplotlib==3.10.1", "pillow==11.1.0",
                  "opencv-python==4.11.0.86", "ultralytics==8.4.144",
                  "torch==2.9.0", "torchvision==0.24.0"])

# %% [markdown]
# ## Choose your saved runs
# The defaults use the original detector and your second classifier run.
# `BLANK_SCORE` is the number of points for each blank half; use 0, 25, or 50.
# Leave `PHOTO_PATH` empty to upload photos in Colab, or set it to a JPEG/PNG path.

# %%
DETECTOR_RUN_NAME = "domino-v1-01"
CLASSIFIER_RUN_NAME = "pips-v1-02"
BLANK_SCORE = 50
DETECTION_CONFIDENCE = 0.25
PIP_CONFIDENCE = 0.80
PHOTO_PATH = ""
assert BLANK_SCORE in {0, 25, 50}
assert 0 < DETECTION_CONFIDENCE <= 1 and 0 < PIP_CONFIDENCE <= 1

# %% shared

# %% [markdown]
# ## Load both models
# Mount the Drive containing `MyDrive/DominoesCalculator/models`. Both checkpoints
# and their saved dataset contracts must exist. CPU inference avoids competing GPU use
# between PyTorch and TensorFlow. Changing run names requires rerunning this section.
# After training notebook 2's new grayscale model, set CLASSIFIER_RUN_NAME="pips-v2-01".
# It accepts RGB input and performs grayscale conversion internally. The current defaults
# still load your existing checkpoints so you can compare the same photos before/after.

# %%
import tensorflow as tf
from ultralytics import YOLO
from IPython.display import display
from uuid import uuid4

PROJECT, WORK, IN_COLAB = setup_project()
detector_run = PROJECT / "models/detector" / DETECTOR_RUN_NAME
classifier_run = PROJECT / "models/classifier" / CLASSIFIER_RUN_NAME
detector_path = detector_run / "weights/best.pt"
classifier_path = classifier_run / "best.keras"
for path in [detector_path, classifier_path, detector_run / "dataset_contract.json",
             classifier_run / "dataset_contract.json"]:
    if not path.is_file():
        raise FileNotFoundError(f"Missing saved model file: {path}. Check your run names and Drive account.")
detector_contract = json.loads((detector_run / "dataset_contract.json").read_text())
classifier_contract = json.loads((classifier_run / "dataset_contract.json").read_text())
if detector_contract["split_signature"] != classifier_contract["split_signature"]:
    raise ValueError("These models were trained with different photo splits. Choose matching runs.")
if (classifier_contract["crop_version"] != CROP_VERSION
        or classifier_contract["class_names"] != CLASS_NAMES
        or classifier_contract["image_size"] != 128):
    raise ValueError("Classifier crop geometry or class order does not match this notebook.")
detector_model = YOLO(str(detector_path))
with tf.device("/CPU:0"):
    classifier = tf.keras.models.load_model(classifier_path, compile=False)
if tuple(classifier.input_shape[1:]) != (128, 128, 3) or classifier.output_shape[-1] != 16:
    raise ValueError("Expected a 128×128 RGB classifier with 16 outputs.")


def half_predict(half):
    with tf.device("/CPU:0"):
        # RGB 0–255; normalization is already inside the saved classifier.
        inputs = {classifier.inputs[0].name.split(":")[0]: np.asarray(half, np.float32)[None]}
        return classifier(inputs, training=False).numpy()[0]


print("Detector:", detector_path)
print("Pip classifier:", classifier_path)
print("Classifier recipe:", classifier_contract.get("training_recipe", "legacy RGB model; no embedded grayscale"))
print("Blank-half score:", BLANK_SCORE)

# %% [markdown]
# ## Read the photo
# Overlapping detections are marked as possible duplicates; they remain in the predicted
# total so you can inspect them. Orange outlines also mark low-confidence or unreadable
# crops. A missing tile may have no outline or warning, so compare the overlay to the photo.

# %%
def predict_photo(rgb, detector, predict_half, detector_image_size=640,
                  detection_confidence=0.25, pip_confidence=0.8, blank_score=50):
    # YOLO's NumPy input uses BGR; crop geometry and classifier input use RGB.
    result = detector.predict(rgb[:, :, ::-1].copy(), imgsz=detector_image_size,
                              conf=detection_confidence, device="cpu", verbose=False)[0]
    corners = result.obb.xyxyxyxy.cpu().numpy()
    detection_scores = result.obb.conf.cpu().numpy()
    rows, crops, pairs = [], [], []
    for index, box in enumerate(corners):
        row = {"tile": index + 1, "a": None, "b": None, "score": None,
               "detector_confidence": float(detection_scores[index]),
               "a_confidence": None, "b_confidence": None,
               "corners": box.tolist(), "review_reasons": []}
        if (np.any(box[:, 0] < 0) or np.any(box[:, 0] > rgb.shape[1] - 1)
                or np.any(box[:, 1] < 0) or np.any(box[:, 1] > rgb.shape[0] - 1)):
            row["review_reasons"].append("Detection extends outside the photo")
        crop = None
        pair = None
        try:
            crop = rectify_tile(rgb, box)
            probabilities = [np.asarray(predict_half(half)) for half in tile_halves(crop)]
            if any(p.shape != (16,) or not np.isfinite(p).all() for p in probabilities):
                raise ValueError("Classifier returned invalid probabilities.")
            pair = tuple(int(p.argmax()) for p in probabilities)
            row.update(a=pair[0], b=pair[1], score=score_pairs([pair], blank_score),
                       a_confidence=float(probabilities[0].max()),
                       b_confidence=float(probabilities[1].max()))
            if min(row["a_confidence"], row["b_confidence"]) < pip_confidence:
                row["review_reasons"].append("Low pip confidence")
        except ValueError as error:
            row["review_reasons"].append(f"Unreadable: {error}")
        rows.append(row)
        crops.append(crop)
        pairs.append(pair)
    for i, box in enumerate(corners):
        for j in range(i + 1, len(corners)):
            if polygon_iou(box, corners[j]) >= 0.5:
                rows[i]["review_reasons"].append(f"Possible duplicate of tile {j + 1}")
                rows[j]["review_reasons"].append(f"Possible duplicate of tile {i + 1}")
    for row in rows:
        row["needs_review"] = bool(row["review_reasons"])
    complete = bool(rows) and all(pair is not None for pair in pairs)
    return {"detected_tiles": len(rows), "blank_score": blank_score,
            "predicted_total": score_pairs(pairs, blank_score) if complete else None,
            "readable_subtotal": score_pairs(pairs, blank_score),
            "raw_pips": score_pairs(pairs) if complete else None,
            "needs_review": not complete or any(row["needs_review"] for row in rows),
            "tiles": rows}, crops


def show_photo_result(rgb, report, crops, title):
    fig, ax = plt.subplots(figsize=(14, 10))
    ax.imshow(rgb)
    ax.axis("off")
    total = report["predicted_total"]
    total_text = f"Predicted total: {total}" if total is not None else "No complete total available"
    ax.set_title(f"{title}\n{total_text} · {report['detected_tiles']} detected tiles · blanks = {report['blank_score']}")
    for row in report["tiles"]:
        points = np.asarray(row["corners"])
        outline = np.vstack([points, points[0]])
        color = "#ffad33" if row["needs_review"] else "#50c9ff"
        ax.plot(outline[:, 0], outline[:, 1], color=color, linewidth=2)
        values = "unreadable" if row["a"] is None else f"{row['a']} | {row['b']}"
        x, y = points.mean(axis=0)
        ax.text(x, y, f"#{row['tile']}  {values}", ha="center", va="center", color="white",
                fontsize=10, bbox={"facecolor": "#18232d", "alpha": 0.85, "edgecolor": color})
    fig.tight_layout()
    plt.show()
    for start in range(0, len(crops), 6):
        count = min(6, len(crops) - start)
        preview, axes = plt.subplots(math.ceil(count / 3), 3, figsize=(15, 3 * math.ceil(count / 3)), squeeze=False)
        for axis in axes.flat:
            axis.axis("off")
        for axis, row, crop in zip(axes.flat, report["tiles"][start:start + 6], crops[start:start + 6]):
            if crop is not None:
                axis.imshow(crop)
            values = "unreadable" if row["a"] is None else f"{row['a']} | {row['b']} · score {row['score']}"
            axis.set_title(f"#{row['tile']} · {values}", fontsize=11)
        preview.tight_layout()
        plt.show()
        plt.close(preview)
    return fig

# %% [markdown]
# ## Upload and test
# Run this cell again for more photos. You may select several JPEG/PNG files at once.
# Each result is saved in a new folder under `MyDrive/DominoesCalculator/photo_tests/`:
# the oriented input photo, annotated overlay, per-tile CSV, and JSON predictions.
# Numbered tile crops are also saved under `crops/` to inspect exactly what the value
# reader saw. Confirm that each crop contains one complete tile with a centered divider.
# These files do not change your training data, labels, checkpoints, or frozen split.

# %%
if PHOTO_PATH:
    photo_path = Path(PHOTO_PATH).expanduser()
    uploads = {photo_path.name: photo_path.read_bytes()}
elif IN_COLAB:
    from google.colab import files
    uploads = files.upload()
else:
    raise RuntimeError("Set PHOTO_PATH to a JPEG or PNG, then rerun this cell.")

for filename, content in uploads.items():
    if Path(filename).suffix.lower() not in IMAGE_EXTENSIONS:
        print(f"Skipped {filename}: select a JPEG or PNG. Convert HEIC photos before uploading.")
        continue
    with Image.open(io.BytesIO(content)) as photo:
        rgb = np.asarray(ImageOps.exif_transpose(photo).convert("RGB"))
    report, crops = predict_photo(rgb, detector_model, half_predict,
                                 detector_image_size=detector_contract["image_size"],
                                 detection_confidence=DETECTION_CONFIDENCE,
                                 pip_confidence=PIP_CONFIDENCE, blank_score=BLANK_SCORE)
    report.update(photo=Path(filename).name, detector_run=DETECTOR_RUN_NAME,
                  classifier_run=CLASSIFIER_RUN_NAME, detection_confidence=DETECTION_CONFIDENCE,
                  pip_confidence=PIP_CONFIDENCE)
    output_dir = PROJECT / "photo_tests" / uuid4().hex
    output_dir.mkdir(parents=True)
    Image.fromarray(rgb).save(output_dir / "photo.png")
    crop_dir = output_dir / "crops"
    crop_dir.mkdir()
    for row, crop in zip(report["tiles"], crops):
        if crop is not None:
            Image.fromarray(crop).save(crop_dir / f"tile-{row['tile']:03d}.png")
    overlay = show_photo_result(rgb, report, crops, Path(filename).name)
    overlay.savefig(output_dir / "overlay.png", dpi=150, bbox_inches="tight")
    plt.close(overlay)
    write_json(output_dir / "predictions.json", report)
    table = pd.DataFrame([{k: v for k, v in row.items() if k != "corners"} for row in report["tiles"]],
                         columns=["tile", "a", "b", "score", "detector_confidence", "a_confidence",
                                  "b_confidence", "review_reasons", "needs_review"])
    table.to_csv(output_dir / "tiles.csv", index=False)
    display(table)
    if not report["detected_tiles"]:
        print("No dominoes found. No reliable total; check the photo and detection threshold.")
    elif report["predicted_total"] is None:
        print("Some tiles could not be read. Readable subtotal:", report["readable_subtotal"])
    else:
        print("Predicted total:", report["predicted_total"], "· Raw pips:", report["raw_pips"])
    if report["needs_review"]:
        print("Review the orange outlines and the reasons in the table.")
    print("Compare every outline and value to the photo; unflagged predictions can still be wrong.")
    print("Saved photo and results:", output_dir)
