"""Isolated classifier experiments. Existing Drive inputs are read-only.

Only exclusive new run directories are writable. Raw results stay in Drive.
The final test split is never used for fitting or model selection.
"""
from collections import Counter
import json
from pathlib import Path
import re
import shutil

import numpy as np

from common import (CROP_VERSION, classifier_rows, match_boxes,
                    read_csv, read_rgb, rectify_tile, sha256, tile_halves, write_json)

RECIPE = "mobilenetv2-050-transfer-v1"
VARIANTS = {"rgb": 0.0, "mixed": 0.5}
BASELINE_RUNS = ("pips-v1-02", "pips-v2-01")
DETECTOR_RUN = "domino-v2-01"


def safe_child(root, relative):
    root = Path(root).resolve()
    path = (root / relative).resolve()
    if not path.is_relative_to(root):
        raise ValueError("Input path escapes its dataset directory.")
    return path


def read_existing_data(project):
    """Validate existing manifests without calling any create/repair helpers."""
    project = Path(project)
    state = project / "data/manifests/dominoes-v1"
    split_path = state / "split.json"
    split = json.loads(split_path.read_text())
    contract_path = project / "models/classifier/pips-v2-01/dataset_contract.json"
    contract = json.loads(contract_path.read_text())
    if split["signature"] != contract["split_signature"]:
        raise ValueError("Existing classifier and frozen split do not agree.")
    crops = project / "data/classifier/dominoes-v1" / (split["dataset_fingerprint"][:16] + "-" + CROP_VERSION)
    metadata = json.loads((crops / "metadata.json").read_text())
    if metadata != {"dataset_fingerprint": split["dataset_fingerprint"], "crop_version": CROP_VERSION}:
        raise ValueError("Crop metadata does not match the frozen dataset.")
    if sha256(crops / "pip_labels.csv") != contract["labels_sha256"]:
        raise ValueError("Labels changed since the reviewed baseline. Preserve it and review the new data contract.")
    tiles, labels = read_csv(crops / "tiles.csv"), read_csv(crops / "pip_labels.csv")
    tile_ids, label_ids = [t["tile_id"] for t in tiles], [r["tile_id"] for r in labels]
    if len(set(tile_ids)) != len(tiles) or len(set(label_ids)) != len(labels) or set(tile_ids) != set(label_ids):
        raise ValueError("Duplicate or mismatched crop/label IDs.")
    if any(r["status"] not in {"labeled", "rejected"} for r in labels):
        raise ValueError("Existing labels are incomplete; this experiment never changes them.")
    if any(r[s] not in map(str, range(16)) for r in labels if r["status"] == "labeled" for s in ("a", "b")):
        raise ValueError("Pip values must be numeric classes 0 through 15.")
    photos = split["photos"]
    if len({p["image"] for p in photos}) != len(photos):
        raise ValueError("A photo occurs more than once in the frozen split.")
    groups = {}
    for p in photos:
        if p["split"] not in {"train", "val", "test"}:
            raise ValueError("Unexpected split name.")
        previous = groups.setdefault(p["group"], p["split"])
        if previous != p["split"]:
            raise ValueError("A photo group crosses splits.")
    if not {t["image"] for t in tiles}.issubset({p["image"] for p in photos}):
        raise ValueError("A crop photo is absent from the frozen split.")
    rows = classifier_rows(tiles, {r["tile_id"]: r for r in labels}, split)
    for subset in ("train", "val"):
        if not any(r["split"] == subset for r in rows):
            raise ValueError("Empty training or validation split.")
    if {r["value"] for r in rows if r["split"] == "train"} != set(range(16)):
        raise ValueError("Existing training labels must cover all 16 values.")
    protected = [split_path, state / "photo_groups.csv", contract_path,
                 crops / "metadata.json", crops / "tiles.csv", crops / "pip_labels.csv"]
    protected.extend(safe_child(crops, t[s]) for t in tiles for s in ("a_path", "b_path"))
    for name in BASELINE_RUNS:
        protected.append(project / "models/classifier" / name / "best.keras")
    protected.append(project / "models/detector" / DETECTOR_RUN / "weights/best.pt")
    return crops, rows, split, protected


def inventory(paths):
    return {str(p): sha256(p) for p in paths}


def verify_inventory(before):
    if inventory(map(Path, before)) != before:
        raise RuntimeError("A protected input changed during the experiment; results are not verified.")


def create_run(project, run_name):
    if not re.fullmatch(r"pips-v3-[a-z0-9][a-z0-9-]{0,55}", run_name):
        raise ValueError("Use a new run name beginning pips-v3- and lowercase letters/digits/hyphens.")
    path = Path(project) / "models/classifier" / run_name
    path.mkdir(parents=True, exist_ok=False)
    return path


def save_model_contract(run, experiment):
    """Write the photo tester's metadata contract without replacing an existing one."""
    fields = ("split_signature", "labels_sha256", "crop_version", "class_names", "image_size", "seed")
    contract = {key: experiment[key] for key in fields}
    contract["training_recipe"] = {"version": RECIPE, "variant": experiment["variant"],
                                   "embedded_grayscale": False,
                                   "normalization": "Rescaling(1/127.5, offset=-1) embedded",
                                   "pretrained_weights": "ImageNet MobileNetV2 alpha=0.5"}
    path = Path(run) / "dataset_contract.json"
    if path.exists():
        if json.loads(path.read_text()) != contract:
            raise ValueError("Existing model contract differs; refusing to overwrite it.")
    else:
        with path.open("x") as stream:
            stream.write(json.dumps(contract, indent=2, allow_nan=False) + "\n")
    return contract


def finalize_contracts(project, run_names):
    """Add compatible metadata to completed v3 trials, preserving all checkpoints."""
    project = Path(project)
    for name in run_names:
        if not re.fullmatch(r"pips-v3-[a-z0-9-]+", name):
            raise ValueError("Only separately named v3 candidates can be finalized.")
        run = project / "models/classifier" / name
        experiment = json.loads((run / "experiment.json").read_text())
        receipt = json.loads((run / "completed.json").read_text())
        if experiment["recipe"] != RECIPE or not receipt["protected_inputs_unchanged"]:
            raise ValueError("Candidate did not complete the expected protected experiment.")
        if sha256(run / "best.keras") != receipt["best_sha256"]:
            raise ValueError("Completed candidate checkpoint changed.")
        save_model_contract(run, experiment)
    print("CLASSIFIER_CONTRACTS_READY " + json.dumps({"runs": run_names, "weights_changed": False}), flush=True)


def augment(image, value, tf, gray_probability):
    """Full-half transforms only: no pip-cutting crops, erasing, or mixup."""
    x = tf.cast(image, tf.float32) / 255.0
    x = tf.image.rot90(x, tf.random.uniform([], 0, 4, dtype=tf.int32))
    x = tf.image.random_flip_left_right(x)
    x = tf.image.random_flip_up_down(x)
    x = tf.image.random_hue(x, 0.08 if gray_probability == 0 else 0.5)
    x = tf.image.random_saturation(x, 0.75 if gray_probability == 0 else 0.25, 1.25)
    x = tf.cond(tf.random.uniform([]) < gray_probability,
                lambda: tf.repeat(tf.image.rgb_to_grayscale(x), 3, axis=-1), lambda: x)
    x = tf.image.adjust_gamma(tf.clip_by_value(x, 0, 1), tf.random.uniform([], 0.85, 1.15))
    x = tf.image.random_contrast(x, 0.8, 1.2)
    x = tf.clip_by_value(x * tf.random.uniform([], 0.85, 1.05), 0, 1)
    side = tf.random.uniform([], 120, 129, dtype=tf.int32)
    x = tf.image.resize_with_crop_or_pad(tf.image.resize(x, [side, side]), 128, 128)
    return tf.ensure_shape(x * 255.0, [128, 128, 3]), value


def build_model(tf, weights="imagenet"):
    base = tf.keras.applications.MobileNetV2(input_shape=(128, 128, 3), alpha=0.5,
                                            include_top=False, weights=weights)
    base.trainable = False
    inputs = tf.keras.Input((128, 128, 3), name="rgb_pixels")
    x = tf.keras.layers.Rescaling(1 / 127.5, offset=-1, name="mobilenet_scaling")(inputs)
    x = base(x, training=False)  # Keep pretrained BN statistics in both phases.
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.2)(x)
    x = tf.keras.layers.Dense(128, activation="relu")(x)
    outputs = tf.keras.layers.Dense(16, activation="softmax", name="pip_probabilities")(x)
    return tf.keras.Model(inputs, outputs, name="pip_mobilenetv2_050"), base


def unfreeze_convolutions(base, tf):
    base.trainable = True
    for layer in base.layers:
        if isinstance(layer, tf.keras.layers.BatchNormalization):
            layer.trainable = False


def probabilities(model, images, batch_size=32):
    return np.concatenate([np.asarray(model(images[i:i + batch_size], training=False))
                           for i in range(0, len(images), batch_size)])


def accuracy_report(truth, probs):
    truth = np.asarray(truth, dtype=int)
    predicted = probs.argmax(axis=1)
    counts = np.bincount(truth, minlength=16)
    correct = np.bincount(truth[predicted == truth], minlength=16)
    return {"examples": len(truth), "accuracy": float(np.mean(predicted == truth)),
            "per_value": [{"value": i, "examples": int(counts[i]),
                           "accuracy": float(correct[i] / counts[i]) if counts[i] else None} for i in range(16)]}


def load_images(crops, rows, subset):
    selected = [r for r in rows if r["split"] == subset]
    images = np.stack([read_rgb(safe_child(crops, r["path"])) for r in selected]).astype(np.float32)
    return images, np.asarray([r["value"] for r in selected], np.int32)


def train(project, run_name, variant, head_epochs=12, fine_epochs=40):
    import tensorflow as tf
    if variant not in VARIANTS:
        raise ValueError("Unknown augmentation variant.")
    tf.keras.utils.set_random_seed(42)
    gpus = tf.config.list_physical_devices("GPU")
    if not gpus:
        raise RuntimeError("Use a Colab GPU for this experiment.")
    for gpu in gpus:
        tf.config.experimental.set_memory_growth(gpu, True)
    crops, rows, split, protected = read_existing_data(project)
    before = inventory(protected)
    run = create_run(project, run_name)
    (run / "input_snapshot").mkdir()
    for name in ("metadata.json", "tiles.csv", "pip_labels.csv"):
        shutil.copyfile(crops / name, run / "input_snapshot" / name)
    shutil.copyfile(Path(project) / "data/manifests/dominoes-v1/split.json", run / "input_snapshot/split.json")
    contract = {"recipe": RECIPE, "variant": variant, "gray_probability": VARIANTS[variant],
                "seed": 42, "image_size": 128, "class_names": list(map(str, range(16))),
                "split_signature": split["signature"], "crop_version": CROP_VERSION,
                "labels_sha256": sha256(crops / "pip_labels.csv"),
                "detector_run": DETECTOR_RUN, "head_epochs": head_epochs, "fine_epochs": fine_epochs,
                "selection": "Minimum original-validation cross entropy across both phases; challenge photos excluded.",
                "inputs": before, "source_sha256": sha256(Path(__file__))}
    write_json(run / "experiment.json", contract)
    save_model_contract(run, contract)
    x_train, y_train = load_images(crops, rows, "train")
    x_val, y_val = load_images(crops, rows, "val")
    dataset = tf.data.Dataset.from_tensor_slices((x_train, y_train)).shuffle(len(y_train), seed=42)
    dataset = dataset.map(lambda x, y: augment(x, y, tf, VARIANTS[variant]), num_parallel_calls=tf.data.AUTOTUNE)
    dataset = dataset.batch(32).prefetch(tf.data.AUTOTUNE)
    validation = tf.data.Dataset.from_tensor_slices((x_val, y_val)).batch(32)
    model, base = build_model(tf)
    counts = Counter(y_train.tolist())
    weights = {i: len(y_train) / (16 * counts[i]) for i in range(16)}
    history = []
    best_loss = float("inf")

    class SaveCheckpoint(tf.keras.callbacks.Callback):
        def on_epoch_end(self, epoch, logs=None):
            nonlocal best_loss
            values = {k: float(v) for k, v in logs.items()}
            if not all(np.isfinite(v) for v in values.values()):
                raise RuntimeError("Non-finite training metric.")
            history.append({"phase": phase, "epoch": epoch + 1, **values})
            if values["val_loss"] < best_loss:
                model.save(run / "best.pending.keras")
                (run / "best.pending.keras").replace(run / "best.keras")
                best_loss = values["val_loss"]
            model.save(run / "last.pending.keras")
            (run / "last.pending.keras").replace(run / "last.keras")
            write_json(run / "progress.json", {"phase": phase, "best_val_loss": best_loss, "history": history})

    for phase, epochs, lr in (("head", head_epochs, 1e-3), ("fine", fine_epochs, 1e-4)):
        if phase == "fine":
            # Start fine-tuning from the best head, not a potentially worse last epoch.
            model.load_weights(run / "best.keras")
            unfreeze_convolutions(base, tf)
        model.compile(optimizer=tf.keras.optimizers.Adam(lr), loss="sparse_categorical_crossentropy",
                      metrics=["accuracy"], jit_compile=False)
        print(f"{run_name}: {phase} phase, {len(y_train)} training / {len(y_val)} validation halves", flush=True)
        model.fit(dataset, validation_data=validation, epochs=epochs, class_weight=weights, verbose=2,
                  callbacks=[SaveCheckpoint(),
                             tf.keras.callbacks.ReduceLROnPlateau(monitor="val_loss", patience=3, factor=0.5, min_lr=1e-6),
                             tf.keras.callbacks.EarlyStopping(monitor="val_loss", patience=8)])
        shutil.copyfile(run / "best.keras", run / (phase + "-best.keras"))
    model = tf.keras.models.load_model(run / "best.keras", compile=False)
    report = accuracy_report(y_val, probabilities(model, x_val))
    (run / "labels_classifier.txt").write_text("\n".join(map(str, range(16))) + "\n")
    write_json(run / "validation.json", report)
    verify_inventory(before)
    receipt = {"run": run_name, "variant": variant, "completed_epochs": len(history),
               "best_val_loss": best_loss, "validation_accuracy": report["accuracy"],
               "parameters": model.count_params(), "best_sha256": sha256(run / "best.keras"),
               "protected_inputs_unchanged": True, "test_split_evaluated": False}
    write_json(run / "completed.json", receipt)
    print("CLASSIFIER_TRAINING_COMPLETE " + json.dumps(receipt), flush=True)
    return receipt


def pair_totals(pairs):
    return {"reviewed_pairs": len(pairs), "correct_pairs": sum(p["correct"] for p in pairs)}


def evaluate(project, run_names, repository, comparison_name):
    """Compare locked checkpoints on exactly the same saved detector boxes."""
    import tensorflow as tf
    import cv2
    import matplotlib.pyplot as plt
    project, repository = Path(project), Path(repository)
    if not re.fullmatch(r"classifier-v3-[a-z0-9-]+", comparison_name):
        raise ValueError("Use a new classifier-v3- comparison name.")
    crops, rows, split, protected = read_existing_data(project)
    before = inventory(protected)
    reports = project / "training_reports" / comparison_name
    reports.mkdir(parents=True, exist_ok=False)
    review = json.loads((repository / "reviews/2026-11-22-photo-tests.json").read_text())
    detector_reference = json.loads((repository / "reviews/2026-11-22-v2/summary.json").read_text())
    x_val, y_val = load_images(crops, rows, "val")
    gray = np.stack([cv2.cvtColor(x.astype(np.uint8), cv2.COLOR_RGB2GRAY) for x in x_val])
    variants = {"original": x_val, "grayscale": np.repeat(gray[..., None], 3, axis=-1).astype(np.float32),
                "channel_swap": x_val[..., ::-1].copy(), "darker": x_val * 0.65}
    # Read all reference images/boxes once, without running or modifying the detector.
    cases = []
    for test in review["tests"]:
        source = project / "photo_tests" / test["run_id"]
        if sha256(source / "predictions.json") != test["baseline_predictions_sha256"]:
            raise ValueError("Original photo-test predictions changed.")
        rgb = read_rgb(source / "photo.png")
        reference = next(p for p in detector_reference["photos"] if p["source_run"] == test["run_id"])
        detection_path = project / "photo_tests" / reference["new_run"] / "predictions.json"
        if sha256(detection_path) != reference["predictions_sha256"]:
            raise ValueError("Frozen detector predictions changed.")
        detected = json.loads(detection_path.read_text())["tiles"]
        original_halves = [h for t in test["reviewed_tiles"] for h in tile_halves(rectify_tile(rgb, t["corners"]))]
        detected_halves = [h for t in detected for h in tile_halves(rectify_tile(rgb, t["corners"]))]
        cases.append((test, rgb, detected, original_halves, detected_halves))
        before.update(inventory([source / "photo.png", source / "predictions.json", detection_path]))
    all_results = []
    for name in (*BASELINE_RUNS, *run_names):
        run = project / "models/classifier" / name
        model_file = run / "best.keras"
        before.update(inventory([model_file]))
        model = tf.keras.models.load_model(model_file, compile=False)
        val_reports = {v: accuracy_report(y_val, probabilities(model, x)) for v, x in variants.items()}
        original_pairs, detected_pairs, photos = [], [], []
        for photo_index, (test, rgb, detections, original_halves, detected_halves) in enumerate(cases):
            original_probs = probabilities(model, np.asarray(original_halves, np.float32)) if original_halves else None
            detected_probs = probabilities(model, np.asarray(detected_halves, np.float32)) if detected_halves else None
            for i, tile in enumerate(test["reviewed_tiles"]):
                new = original_probs[2*i:2*i+2].argmax(axis=1).tolist()
                original_pairs.append({"photo": photo_index + 1, "tile": tile["tile"],
                                       "expected": tile["expected_pair"], "predicted": new,
                                       "correct": sorted(new) == sorted(tile["expected_pair"]),
                                       "style": "black" if test["image_name"].startswith(("1000_F_88049010_", "360_F_109730848_")) else "colored"})
            matches = match_boxes([t["corners"] for t in test["reviewed_tiles"]], [t["corners"] for t in detections])
            for i, j, overlap in matches:
                new = detected_probs[2*j:2*j+2].argmax(axis=1).tolist()
                tile = test["reviewed_tiles"][i]
                detected_pairs.append({"photo": photo_index + 1, "tile": tile["tile"],
                                       "detector_tile": detections[j]["tile"], "iou": overlap,
                                       "expected": tile["expected_pair"], "predicted": new,
                                       "correct": sorted(new) == sorted(tile["expected_pair"])})
            photo_dir = reports / name / f"photo-{photo_index + 1:02d}"
            photo_dir.mkdir(parents=True)
            tiles = []
            fig, ax = plt.subplots(figsize=(12, 9))
            ax.imshow(rgb)
            for i, tile in enumerate(detections):
                p = detected_probs[2*i:2*i+2]
                a, b = p.argmax(axis=1).tolist()
                tiles.append({"tile": tile["tile"], "a": a, "b": b, "corners": tile["corners"],
                              "confidence": p.max(axis=1).tolist()})
                points = np.asarray(tile["corners"])
                closed = np.vstack([points, points[0]])
                ax.plot(closed[:, 0], closed[:, 1], color="#e39421", linewidth=1)
                center = points.mean(axis=0)
                ax.text(*center, f"{tile['tile']} {a}|{b}", fontsize=7, color="white", backgroundcolor="#172833")
            ax.axis("off")
            ax.set_title(f"{name} · photo {photo_index + 1} · {len(detections)} unchanged detector boxes")
            fig.tight_layout()
            fig.savefig(photo_dir / "overlay.png", dpi=130)
            plt.close(fig)
            write_json(photo_dir / "predictions.json", {"detector_run": DETECTOR_RUN, "tiles": tiles})
            photos.append({"photo": photo_index + 1, "detected_tiles": len(detections)})
        result = {"run": name, "checkpoint_sha256": sha256(model_file), "validation": val_reports,
                  "fixed_original_crops": {**pair_totals(original_pairs),
                     "black": pair_totals([p for p in original_pairs if p["style"] == "black"]),
                     "colored": pair_totals([p for p in original_pairs if p["style"] == "colored"])},
                  "frozen_detector_crops": {**pair_totals(detected_pairs), "reference_pairs": 36},
                  "photos": photos, "original_pairs": original_pairs, "detected_pairs": detected_pairs,
                  "parameters": model.count_params(), "checkpoint_bytes": model_file.stat().st_size}
        write_json(reports / name / "results.json", result)
        all_results.append(result)
        print(json.dumps({k: result[k] for k in ("run", "fixed_original_crops", "frozen_detector_crops")}), flush=True)
        tf.keras.backend.clear_session()
    verify_inventory(before)
    summary = {"detector_run": DETECTOR_RUN, "protected_inputs_unchanged": True,
               "test_split_evaluated": False,
               "scope": "Selected development pairs; challenge photos excluded from fitting and checkpoint selection. Not independent full-photo accuracy.",
               "runs": [{k: r[k] for k in ("run", "fixed_original_crops", "frozen_detector_crops", "validation", "parameters", "checkpoint_bytes")} for r in all_results]}
    write_json(reports / "summary.json", summary)
    write_json(reports / "inputs_verified.json", before)
    fig, ax = plt.subplots(figsize=(10, 5))
    labels = [r["run"].replace("pips-", "") for r in all_results]
    ax.bar(labels, [r["fixed_original_crops"]["correct_pairs"] for r in all_results], color="#34699a")
    for i, r in enumerate(all_results):
        ax.text(i, r["fixed_original_crops"]["correct_pairs"] + 0.5, str(r["fixed_original_crops"]["correct_pairs"]) + "/36", ha="center")
    ax.set(ylim=(0, 39), ylabel="Correct tile pairs out of 36", title="Classifier comparison on identical original crops\nSelected development examples, not independent test accuracy")
    fig.tight_layout()
    fig.savefig(reports / "comparison.png", dpi=150)
    plt.close(fig)
    print("CLASSIFIER_COMPARISON_COMPLETE " + json.dumps(summary), flush=True)
    return summary
