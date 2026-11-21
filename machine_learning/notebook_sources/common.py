"""Shared helpers embedded into both standalone Colab notebooks by build_notebooks.py."""
from pathlib import Path
from collections import Counter
import csv
import hashlib
import io
import json
import math
import os
import random
import shutil
import sys
import zipfile

import cv2
import numpy as np
import pandas as pd
from PIL import Image, ImageOps
import matplotlib.pyplot as plt

CLASS_NAMES = [str(i) for i in range(16)]
CROP_VERSION = "long-edge-rgb-128-v1"
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png"}
plt.rcParams.update({"figure.figsize": (10, 4), "font.size": 11,
                     "axes.spines.top": False, "axes.spines.right": False})


def write_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2, allow_nan=False) + "\n")
    temporary.replace(path)


def write_csv(path, rows, fields):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    with temporary.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
    temporary.replace(path)


def read_csv(path):
    with Path(path).open(newline="") as f:
        return list(csv.DictReader(f))


def sha256(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def digest_json(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()


def setup_project():
    """Drive stores durable artifacts; Colab's local disk stores training input."""
    local_override = os.environ.get("DOMINO_ML_ROOT")
    in_colab = not local_override and "google.colab" in sys.modules
    if not local_override:
        try:
            import google.colab  # noqa: F401
            in_colab = True
        except ImportError:
            in_colab = False
    if in_colab:
        from google.colab import drive
        drive.mount("/content/drive")
        project = Path("/content/drive/MyDrive/DominoesCalculator")
        work = Path("/content/domino-work")
    else:
        if local_override:
            project = Path(local_override).expanduser().resolve()
        else:
            candidates = [Path.cwd(), *Path.cwd().parents]
            repo = next((p for p in candidates if (p / "machine_learning").is_dir()), None)
            if repo is None:
                raise RuntimeError("Set DOMINO_ML_ROOT to a local machine_learning folder.")
            project = repo / "machine_learning"
        work = Path(os.environ.get("DOMINO_WORK_DIR", str(project / "data/work")))
    project.mkdir(parents=True, exist_ok=True)
    work.mkdir(parents=True, exist_ok=True)
    return project, work, in_colab


def stage_export(project, work, dataset_name):
    """Accept an extracted export or a ZIP uploaded to the project folder."""
    source = project / "data/raw" / dataset_name
    if not source.is_dir():
        archive = project / f"{dataset_name}.zip"
        if not archive.is_file():
            raise FileNotFoundError(f"Upload {archive.name} to {project}, or place images/ and labels/ in {source}.")
        unpacked = work / "unpacked" / dataset_name
        if unpacked.exists():
            shutil.rmtree(unpacked)  # Only this generated local extraction cache.
        unpacked.mkdir(parents=True)
        with zipfile.ZipFile(archive) as z:
            for member in z.infolist():
                target = (unpacked / member.filename).resolve()
                if not target.is_relative_to(unpacked.resolve()) or (member.external_attr >> 16) & 0o170000 == 0o120000:
                    raise ValueError("Archive contains an unsafe path or symbolic link.")
            z.extractall(unpacked)
        candidates = [p.parent for p in unpacked.rglob("classes.txt")
                      if (p.parent / "images").is_dir() and (p.parent / "labels").is_dir()]
        if len(candidates) != 1:
            raise ValueError("Expected exactly one export with classes.txt, images/, and labels/.")
        source.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(candidates[0], source, ignore=shutil.ignore_patterns(".DS_Store", "__MACOSX"))
    # Refresh the generated local cache when source files change; never change the original export.
    local = work / "raw" / dataset_name
    shutil.copytree(source, local, dirs_exist_ok=True, ignore=shutil.ignore_patterns(".DS_Store", "__MACOSX"))
    source_names = {p.relative_to(source) for p in source.rglob("*") if p.is_file() and p.name != ".DS_Store"}
    for p in local.rglob("*"):
        if p.is_file() and p.relative_to(local) not in source_names:
            p.unlink()
    return local


def read_rgb(path):
    # Match browser/phone display orientation before applying annotation coordinates.
    with Image.open(path) as image:
        return np.asarray(ImageOps.exif_transpose(image).convert("RGB"))


def audit_export(root):
    if (root / "classes.txt").read_text().splitlines() != ["domino"]:
        raise ValueError("This pipeline requires exactly one class: domino, ID 0.")
    images = sorted(p for p in (root / "images").iterdir() if p.suffix.lower() in IMAGE_EXTENSIONS)
    labels = {p.stem: p for p in (root / "labels").glob("*.txt")}
    if not images or len({p.stem for p in images}) != len(images):
        raise ValueError("No supported images, or duplicate image stems.")
    if {p.stem for p in images} != set(labels):
        raise ValueError("Every image needs one matching label file; orphan labels are also rejected.")
    records = []
    for path in images:
        rgb = read_rgb(path)
        h, w = rgb.shape[:2]
        boxes = []
        for line_no, line in enumerate(labels[path.stem].read_text().splitlines(), 1):
            if not line.strip():
                continue
            fields = line.split()
            if len(fields) != 9 or fields[0] != "0":
                raise ValueError(f"{path.stem}:{line_no}: expected class 0 and eight OBB corner coordinates.")
            corners = np.asarray(fields[1:], dtype=np.float32).reshape(4, 2)
            if not np.isfinite(corners).all() or (corners < 0).any() or (corners > 1).any():
                raise ValueError(f"{path.stem}:{line_no}: coordinates must be finite and within [0, 1].")
            pixel_corners = corners * [w, h]
            if not cv2.isContourConvex(pixel_corners.astype(np.float32)) or abs(cv2.contourArea(pixel_corners.astype(np.float32))) < 4:
                raise ValueError(f"{path.stem}:{line_no}: invalid or tiny quadrilateral.")
            boxes.append(corners.tolist())
        records.append({"image": path.name, "stem": path.stem, "width": w, "height": h,
                        "image_sha256": sha256(path), "label_sha256": sha256(labels[path.stem]), "boxes": boxes})
    fingerprint = digest_json(records)
    print(f"Validated {len(records)} photos and {sum(len(r['boxes']) for r in records)} domino boxes.")
    return records, fingerprint


def contact_sheet(records, root, start=0, count=12, overlays=False):
    selected = records[start:start + count]
    if not selected:
        return
    fig, axes = plt.subplots(math.ceil(len(selected) / 3), 3, figsize=(15, 3.8 * math.ceil(len(selected) / 3)), squeeze=False)
    for ax in axes.flat:
        ax.axis("off")
    for ax, record in zip(axes.flat, selected):
        image = read_rgb(root / "images" / record["image"])
        ax.imshow(image)
        if overlays:
            for box in record["boxes"]:
                points = np.asarray(box) * [record["width"], record["height"]]
                points = np.vstack([points, points[0]])
                ax.plot(points[:, 0], points[:, 1], color="#f6ac48", linewidth=1)
        ax.set_title(record["image"], fontsize=9)
    fig.tight_layout()
    plt.show()


def ensure_groups(records, path):
    if not path.exists():
        # Exact duplicates start together. Repeated arrangements still need human review.
        hashes = {}
        rows = []
        for r in records:
            group = hashes.setdefault(r["image_sha256"], r["stem"])
            rows.append({"image": r["image"], "group": group})
        write_csv(path, rows, ["image", "group"])
    return read_csv(path)


def frozen_split(records, fingerprint, groups_path, output_path, reviewed=False, seed=42):
    rows = read_csv(groups_path)
    if len(rows) != len(records) or {r["image"] for r in rows} != {r["image"] for r in records}:
        raise ValueError("Photo grouping CSV must contain exactly one row per source image.")
    grouping = {r["image"]: r["group"].strip() for r in rows}
    if not all(grouping.values()):
        raise ValueError("Every photo needs a nonempty group.")
    hashes = {}
    for r in records:
        previous = hashes.setdefault(r["image_sha256"], grouping[r["image"]])
        if previous != grouping[r["image"]]:
            raise ValueError("Identical photos must use the same group.")
    signature = digest_json({"fingerprint": fingerprint, "groups": grouping, "seed": seed, "fractions": [0.7, 0.15, 0.15]})
    if output_path.exists():
        result = json.loads(output_path.read_text())
        if result["signature"] != signature:
            raise ValueError("Dataset/groups changed after the split was frozen. Use a new DATASET_NAME and run name; do not mix evaluations.")
        return result
    if not reviewed:
        print("Split not created. Review photo_groups.csv, then set GROUPS_REVIEWED=True and rerun this cell.")
        return None
    groups = sorted(set(grouping.values()))
    if len(groups) < 3:
        raise ValueError("At least three independent arrangement groups are needed for train/val/test.")
    random.Random(seed).shuffle(groups)
    holdout = min(max(1, round(len(groups) * 0.15)), (len(groups) - 1) // 2)
    group_splits = {g: "test" if i < holdout else "val" if i < 2 * holdout else "train" for i, g in enumerate(groups)}
    result = {"signature": signature, "dataset_fingerprint": fingerprint, "seed": seed,
              "photos": [{"image": r["image"], "group": grouping[r["image"]], "split": group_splits[grouping[r["image"]]]} for r in records]}
    write_json(output_path, result)
    return result


def prepare_detector(root, records, split, work):
    target = work / "detector" / split["signature"][:16]
    by_name = {r["image"]: r for r in records}
    for row in split["photos"]:
        record = by_name[row["image"]]
        for kind, src in [("images", root / "images" / row["image"]), ("labels", root / "labels" / f"{record['stem']}.txt")]:
            dest = target / row["split"] / kind / src.name
            dest.parent.mkdir(parents=True, exist_ok=True)
            if not dest.exists() or sha256(dest) != sha256(src):
                shutil.copy2(src, dest)
    config = target / "data.yaml"
    config.write_text(f"path: {json.dumps(str(target))}\ntrain: train/images\nval: val/images\ntest: test/images\nnames:\n  0: domino\n")
    # Exporters may read the YAML's val split for calibration. Keep calibration strictly in train.
    (target / "calibration.yaml").write_text(f"path: {json.dumps(str(target))}\ntrain: train/images\nval: train/images\nnames:\n  0: domino\n")
    return config


def rectify_tile(rgb, corners, half_size=128):
    """Four corners in source pixels -> horizontal RGB tile, left half then right half."""
    p = np.asarray(corners, dtype=np.float32).reshape(4, 2)
    if not np.isfinite(p).all() or not cv2.isContourConvex(p) or abs(cv2.contourArea(p)) < 4:
        raise ValueError("Cannot rectify a degenerate domino detection.")
    # Positive winding in image coordinates, then make a long edge the top edge.
    signed_area = np.sum(p[:, 0] * np.roll(p[:, 1], -1) - p[:, 1] * np.roll(p[:, 0], -1))
    if signed_area < 0:
        p = p[::-1]
    lengths = np.linalg.norm(np.roll(p, -1, axis=0) - p, axis=1)
    p = np.roll(p, -int(np.argmax(lengths)), axis=0).copy()
    target = np.float32([[0, 0], [2 * half_size - 1, 0], [2 * half_size - 1, half_size - 1], [0, half_size - 1]])
    transform = cv2.getPerspectiveTransform(p, target)
    return cv2.warpPerspective(rgb, transform, (2 * half_size, half_size), flags=cv2.INTER_LINEAR,
                               borderMode=cv2.BORDER_CONSTANT, borderValue=(127, 127, 127))


def tile_halves(tile):
    center = tile.shape[1] // 2
    return tile[:, :center].copy(), tile[:, center:].copy()


def score_pairs(pairs, blank_score=0):
    return sum(blank_score if value == 0 else value for pair in pairs if pair is not None for value in pair)


def make_crops(root, records, directory, fingerprint):
    metadata = {"dataset_fingerprint": fingerprint, "crop_version": CROP_VERSION}
    marker = directory / "metadata.json"
    if marker.exists() and json.loads(marker.read_text()) != metadata:
        raise ValueError("Crop dataset changed. Use a new crop directory so existing pip labels remain meaningful.")
    directory.mkdir(parents=True, exist_ok=True)
    write_json(marker, metadata)
    tiles = []
    for record in records:
        rgb = read_rgb(root / "images" / record["image"])
        for index, box in enumerate(record["boxes"]):
            tile_id = f"{record['stem']}_d{index:04d}"
            paths = {side: directory / "halves" / f"{tile_id}_{side}.png" for side in ("a", "b")}
            if not all(p.is_file() for p in paths.values()):
                tile = rectify_tile(rgb, np.asarray(box) * [record["width"], record["height"]])
                for side, half in zip(("a", "b"), tile_halves(tile)):
                    paths[side].parent.mkdir(parents=True, exist_ok=True)
                    Image.fromarray(half).save(paths[side])
            tiles.append({"tile_id": tile_id, "image": record["image"], "box_index": index,
                          "a_path": str(paths["a"].relative_to(directory)), "b_path": str(paths["b"].relative_to(directory))})
    write_csv(directory / "tiles.csv", tiles, ["tile_id", "image", "box_index", "a_path", "b_path"])
    return tiles


def load_pip_labels(path, tiles):
    fields = ["tile_id", "a", "b", "status"]
    if not path.exists():
        write_csv(path, [{"tile_id": t["tile_id"], "a": "", "b": "", "status": "pending"} for t in tiles], fields)
    rows = read_csv(path)
    if len(rows) != len(tiles) or {r["tile_id"] for r in rows} != {t["tile_id"] for t in tiles}:
        raise ValueError("Pip label IDs do not match the crop manifest.")
    for row in rows:
        if row["status"] not in {"pending", "labeled", "rejected"}:
            raise ValueError(f"Invalid labeling status: {row}")
        if row["status"] == "labeled" and (row["a"] not in CLASS_NAMES or row["b"] not in CLASS_NAMES):
            raise ValueError(f"Both halves must have values 0–15: {row}")
    return {r["tile_id"]: r for r in rows}


def classifier_rows(tiles, labels, split):
    photo_split = {r["image"]: r["split"] for r in split["photos"]}
    result = []
    for tile in tiles:
        label = labels[tile["tile_id"]]
        if label["status"] != "labeled":
            continue
        for side in ("a", "b"):
            result.append({"tile_id": tile["tile_id"], "image": tile["image"], "side": side,
                           "path": tile[f"{side}_path"], "value": int(label[side]), "split": photo_split[tile["image"]]})
    return result


def polygon_iou(a, b):
    a, b = np.asarray(a, np.float32), np.asarray(b, np.float32)
    area_a, area_b = abs(cv2.contourArea(a)), abs(cv2.contourArea(b))
    intersection, _ = cv2.intersectConvexConvex(a, b)
    return max(0.0, float(intersection)) / max(area_a + area_b - intersection, 1e-9)


def match_boxes(truth, predicted, threshold=0.5):
    candidates = sorted([(polygon_iou(a, b), i, j) for i, a in enumerate(truth) for j, b in enumerate(predicted)], reverse=True)
    used_truth, used_pred, matches = set(), set(), []
    for overlap, i, j in candidates:
        if overlap >= threshold and i not in used_truth and j not in used_pred:
            used_truth.add(i)
            used_pred.add(j)
            matches.append((i, j, overlap))
    return matches
