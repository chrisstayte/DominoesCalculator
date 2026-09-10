# Domino ML pipeline in Google Colab

Two standalone notebooks replace the earlier combined training notebook:

1. [01_domino_detector.ipynb](../notebooks/01_domino_detector.ipynb): import and check the OBB dataset, review arrangement groups, freeze train/validation/test splits, train YOLO26-nano OBB, and validate/export the detector.
2. [02_pip_classifier.ipynb](../notebooks/02_pip_classifier.ipynb): generate straightened halves from the existing annotations, label them inside Colab, train a 16-class CNN, validate/export it, and evaluate full-photo scores.

Each notebook contains its helpers. Uploading Python support files or cloning the repository is unnecessary. The readable sources and build script are retained in this repository for maintenance.

## First-time setup

1. Create `MyDrive/DominoesCalculator` in Google Drive.
2. Upload the prepared local archive `machine_learning/data/colab/dominoes-v1.zip` into that folder. Keep its filename unchanged. The archive contains the 74 original export files (about 153 MiB).
3. Open the first notebook using **Colab → File → Upload notebook**.
4. Run installation and configuration. The default `ACTION = "prepare"` checks data without starting training.
5. Run the annotation previews and review all arrangement groups. Set `GROUPS_REVIEWED = True` only after this review, then rerun the split cell.
6. Choose a GPU runtime for training, set `ACTION = "train"`, and rerun configuration followed by the training/check cells. Run installation again after changing/resetting the runtime if packages are missing.
7. Open the second notebook in a separate session. Its default `ACTION = "label"` creates the candidate crops and opens the labeling station; a CPU runtime is enough for this stage.

The classifier's labeling stage can run before the detector is trained. Train the models sequentially to avoid competing for GPU resources.

## Dataset: dominoes-v1

The Label Studio **YOLOv8 OBB with Images** export imported on September 10, 2026 is at `machine_learning/data/raw/dominoes-v1/`:

- 36 original `.jpeg` photos, with 36 matching label files.
- 821 rotated domino boxes, class `0 = domino`.
- `classes.txt` and `notes.json`; the latter is export metadata, not a full Label Studio annotation JSON backup.

All 74 files were copied unchanged from `~/Downloads/dominoes-v1`, excluding `.DS_Store`, and verified with SHA-256. The source download remains available. Every image/label pair matched; every box had eight finite normalized corner coordinates forming a non-degenerate convex quadrilateral.

Keep the original export intact. All `machine_learning/data/` and `machine_learning/models/` contents remain excluded from Git. A normal Git commit does not back up these photos, labels, or models. Google Drive becomes their persistent location when you use Colab.

## The shared photo split

Both notebooks reuse `data/manifests/dominoes-v1/split.json`.

- Photos of the same arrangement, including repeated shots/angles, must have the same group in `photo_groups.csv`.
- Initial group suggestions only combine exact duplicate files. They do not detect repeated arrangements automatically.
- The split uses seed 42 and approximately 70%/15%/15% of groups for train/validation/test. Actual photo proportions depend on group sizes.
- Both halves and all tiles from a photograph inherit its split.
- A dataset fingerprint and grouping signature prevent a rerun from silently changing the split. Changed data/group assignments require a new dataset version and model run.
- Validation is for model/threshold selection. Set `FINAL_TEST = True` only for the final held-out evaluation after choices are settled.

With 36 photographs, evaluation depends strongly on scene variety and group counts. The 821 boxes do not represent 821 independent scenes.

## Label the two halves

The second notebook rectifies each annotated box to a horizontal 256×128 RGB tile, then saves A (left) and B (right) as 128×128 PNGs. This produces 1,642 candidate halves before rejecting unusable crops.

The labeling station displays both halves. Select values 0–15 and click **Save & next**, or **Reject crop** if either half is unreadable or the geometry is wrong. Navigate back by tile number to correct a label. Every save updates `pip_labels.csv` in Drive and preserves the previous CSV copy. Keep one labeling session open at a time.

The classifier can also read a manually edited CSV. Keep `tile_id` unchanged; valid status values are `pending`, `labeled`, and `rejected`. A labeled tile requires both numeric values. The interface never fills in unknown values automatically.

Training waits for all tiles to be reviewed, labeled examples in each split, and at least one training example for every value 0–15. Review the class-count chart: sparse values need more real examples. Missing validation classes are reported as unavailable.

## Training, saving, and restarting

Colab uses `/content/domino-work` for temporary training input. Drive stores the originals, manifests, labeling progress, checkpoints, histories, evaluation results, and exports.

Detector actions: `prepare`, `train`, `resume`, `evaluate`, `export`.

Classifier actions: `label`, `train`, `resume`, `evaluate`, `export`.

- `train` requires a new `RUN_NAME` and refuses to overwrite a previous experiment.
- `resume` requires the same run name/data contract. The detector uses `weights/last.pt`; the classifier uses the checkpoint named by `progress.json`.
- The classifier alternates two last-checkpoint files so interruption during saving leaves the previous completed epoch available. Optimizer state and epoch number resume; early-stopping and LR-patience counters restart.
- `evaluate` loads the run's best saved model without retraining.
- `export` loads the best model, evaluates it, exports mobile variants, and compares their validation performance.

Dependency installation is explicit and primary libraries are pinned. Environment snapshots are saved per model run. The notebooks target Python 3.12 and a Colab NVIDIA GPU for training; default preparation/labeling do not require GPU computation.

## What gets measured

Detector checks include official mAP50 and mAP50–95, training curves, missed/extra tile counts at a configurable confidence, and labeled/detected overlays. Diagnostic matching uses one-to-one OBB IoU 0.5.

Classifier checks include training curves, confusion counts, per-value sample counts/accuracy, and examples of wrong predictions. Half-classification evaluation uses annotated crops; full-photo evaluation includes detector crop errors as well.

The complete pipeline reports:

- Exact total-score accuracy and mean absolute score error.
- Whether every tile and its unordered pair of values was correctly identified.
- Missed/extra tiles and photos flagged for review by pip confidence.
- Evaluated and excluded photo counts. Photos with rejected/unlabeled annotated tiles lack a known full score and are explicitly excluded, with reasons saved.

Exact total scores can conceal offsetting mistakes, so use the all-tiles-correct metric too. A pip confidence threshold cannot establish that every domino was detected.

`BLANK_SCORE` matches the app's setting (0, 25, or 50 points per blank half; default 50). The classifier always predicts actual pip values, including 0. Evaluation saves both raw pip sums and totals with this scoring rule.

## Mobile exports

The detector uses Ultralytics LiteRT export; the classifier uses TensorFlow Lite conversion. Each produces an FP32 baseline and an optional INT8 variant. Calibration only uses training images/crops, including a dedicated detector YAML whose validation path also points to training data.

Exports are compared on validation, with a configurable tolerance. The metadata identifies the preferred acceptable model, measured file size, class order, preprocessing, and evaluation results. If no export meets the tolerance, the notebook stops instead of declaring it ready.

When both preferred exports exist, notebook 2 checks their combined full-photo pipeline. Retain the export bundles and their JSON metadata alongside `labels_classifier.txt`.

The Flutter app currently uses an SSD decoder. Integrating these models still requires OBB output decoding, reversing detector letterbox transforms, matching EXIF/RGB handling, the same tile rectification/splitting, and correct input/output quantization. Classifier normalization is embedded; do not apply it twice. Test the final implementation and latency on the target phone.

## Repository maintenance and validation

The notebooks are generated from `machine_learning/notebook_sources/` and embed `common.py` into each notebook. Edit those sources, then rebuild:

```sh
python machine_learning/scripts/build_notebooks.py
python -m unittest discover -s machine_learning/tests -v
python machine_learning/scripts/check_notebooks.py
python machine_learning/scripts/check_model_paths.py
```

The build uses `nbformat`. Local execution checks also need `nbclient`, `nbconvert`, `ipykernel`, and the notebooks' image/plot libraries. `check_notebooks.py` executes preparation/labeling against the real dataset in an isolated local project under the ignored `data/notebook_checks/` folder and writes executed copies, figures, and HTML previews. It does not invent pip labels, approve arrangement groups, or train a model.

`check_model_paths.py` separately exercises the classifier's train/resume/evaluate/FP32-and-INT8-export cells on a tiny explicitly synthetic dataset in a temporary directory. It also checks construction/inference of the installed YOLO26 OBB architecture without downloading pretrained weights. Synthetic smoke-test accuracy has no bearing on domino recognition quality.

### Validation performed on September 10, 2026

- Both generated notebooks passed `nbformat` schema and Python syntax validation.
- Both preparation/labeling paths executed top-to-bottom against all 36 real photos; 821 tile crops and 1,642 half-images were generated in the isolated check directory. Rendered annotation overlays and crop previews were visually inspected.
- Nine regression tests passed: dataset validation, rotated geometry, frozen group separation, numeric pip labels, labeling saves/reloads, one-to-one matching, total-score cancellation, blank scoring, and ZIP extraction boundaries.
- Classifier training, optimizer/epoch resume, evaluation, numeric label export, and FP32/INT8 conversion/inference passed the synthetic smoke test with TensorFlow 2.19.1/Keras 3.9.2. The YOLO26 OBB architecture and result API passed with PyTorch 2.9.0/Ultralytics 8.4.144. Detector export dependencies resolved with the pinned versions.
- Real detector/classifier training, pretrained-detector LiteRT conversion, Google Drive mounting/widget rendering inside Colab, and target-phone integration have not been run here. In Colab, complete the grouping review, run detector `train`, label the halves, run classifier `train`, then use each notebook's `export` action to validate the actual trained models. The local labeling widget's save/reload callbacks were tested.

To run the notebooks locally, set `DOMINO_ML_ROOT` to a persistent project folder with `data/raw/dominoes-v1`; optionally set `DOMINO_WORK_DIR` for generated local input. `DOMINO_SKIP_INSTALL=1` uses an already prepared environment. These overrides are not needed in Colab.

## Sources

- [Google Colab runtime and storage FAQ](https://research.google.com/colaboratory/faq.html)
- [Ultralytics OBB training, results, and validation](https://docs.ultralytics.com/tasks/obb/)
- [Ultralytics LiteRT export and calibration](https://docs.ultralytics.com/integrations/litert/)
- [Keras image loading and class order](https://keras.io/api/data_loading/image/)
