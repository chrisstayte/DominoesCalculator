# %% [markdown]
# # 2 · Label domino halves and train the pip classifier
#
# **Goal:** classify one domino half as a value from **0 to 15**, then read both values
# and calculate a photo's total. This notebook can prepare labels from your existing
# OBB annotations without a trained detector. Its later full-photo evaluation uses notebook 1's detector.
#
# Open in Google Colab with the same Drive project: `MyDrive/DominoesCalculator`.
# Upload `dominoes-v1.zip` there if notebook 1 has not already imported it.
# Use a regular CPU runtime for labeling and a GPU runtime for training.
#
# **Stages:** prepare the crops → label/reject them → inspect class coverage → train →
# validate → export/check → evaluate full photos. Every labeling save goes to Drive;
# reconnecting and rerunning setup reloads your progress. Do not leave training running
# in the detector notebook while this notebook trains on the GPU.
#
# Your 821 boxes produce 1,642 **candidate** halves; each still needs a human pip label.
# Reject a tile if either half is unreadable or the crop is wrong. Rejected photos are
# accounted for explicitly when reporting total-score evaluation coverage.

# %% [markdown]
# ## Setup
# Install before imports. Use the same dataset name and frozen split as notebook 1.
# Setup selects compatible packages for Colab Python 3.12 or 3.13 and shows live progress.
# If setup requests a restart, choose **Runtime → Restart session**, then rerun setup.

# %% setup
install_packages([TENSORFLOW_REQUIREMENT, KERAS_REQUIREMENT, NUMPY_REQUIREMENT, "pandas==2.2.3",
                  "matplotlib==3.10.1", "pillow==11.1.0", "opencv-python==4.11.0.86",
                  "scikit-learn==1.6.1", "ipywidgets==8.1.7", "ultralytics==8.4.144",
                  "torch==2.9.0", "torchvision==0.24.0", "ai-edge-litert==2.1.4"])

# %%
DATASET_NAME = "dominoes-v1"
RUN_NAME = "pips-v1-01"
DETECTOR_RUN_NAME = "domino-v1-01"
ACTION = "label"  # label | train | resume | evaluate | export
SEED = 42
IMAGE_SIZE = 128
BATCH_SIZE = 32
EPOCHS = 60
FINAL_TEST = False
DETECTION_CONFIDENCE = 0.25  # Choose on validation, then freeze.
PIP_CONFIDENCE = 0.80  # Flags predictions needing review; does not silently drop tiles from a score.
BLANK_SCORE = 50  # Match the app's blank-half setting: 0, 25, or 50. Labels always remain 0.
EXPORT_INT8 = True
MAX_EXPORT_ACCURACY_DROP = 0.02
assert ACTION in {"label", "train", "resume", "evaluate", "export"}
assert IMAGE_SIZE == 128, "Changing crop resolution requires a new crop version and dataset."
assert BLANK_SCORE in {0, 25, 50}

# %% shared

# %%
PROJECT, WORK, IN_COLAB = setup_project()
RAW = stage_export(PROJECT, WORK, DATASET_NAME)
STATE = PROJECT / "data/manifests" / DATASET_NAME
STATE.mkdir(parents=True, exist_ok=True)
RUN = PROJECT / "models/classifier" / RUN_NAME
records, fingerprint = audit_export(RAW)
CROPS = PROJECT / "data/classifier" / DATASET_NAME / f"{fingerprint[:16]}-{CROP_VERSION}"
print("Persistent project:", PROJECT)
print("Labeling/crops:", CROPS)
print("Model run:", RUN)

# %% [markdown]
# ## Prepare and inspect the halves
# We use each annotated tile's four corners to straighten it to a horizontal 256×128 RGB
# tile, then save its left half as A and right half as B, each 128×128. A/B refer to the
# displayed crop, not top/bottom in the original photo. A 180° orientation change only swaps
# the sides; full-tile evaluation compares the pair without assuming an ordering.
#
# The same rectification helper is used for predicted boxes during full-photo evaluation.
# Changing crop geometry later requires a new crop version so saved A/B labels never silently swap.
# Original photos and detector labels remain unchanged.

# %%
tiles = make_crops(RAW, records, CROPS, fingerprint)
LABELS_PATH = CROPS / "pip_labels.csv"
pip_labels = load_pip_labels(LABELS_PATH, tiles)
print(f"Prepared {len(tiles)} tiles / {2 * len(tiles)} candidate halves.")
print("Labeling status:", dict(Counter(r["status"] for r in pip_labels.values())))
fig, axes = plt.subplots(3, 4, figsize=(12, 8))
sample_tiles = random.Random(SEED).sample(tiles, min(12, len(tiles)))
for ax in axes.flat:
    ax.axis("off")
for ax, tile in zip(axes.flat, sample_tiles):
    joined = np.concatenate([read_rgb(CROPS / tile["a_path"]), read_rgb(CROPS / tile["b_path"])], axis=1)
    ax.imshow(joined)
    ax.set_title(f"{tile['tile_id']}\nA (left) · B (right)", fontsize=8)
plt.tight_layout()
plt.show()

# %% [markdown]
# ### Labeling station
# Pick both pip values, then **Save & next**. Use **Reject crop** for unreadable halves or
# incorrect geometry. Navigation does not save unfinished edits. You can revisit any tile
# by number; **Next pending** jumps to unreviewed work. Existing labels are never regenerated.
# Keep only one labeling session open for this CSV. A previous CSV copy is retained on each save.
#
# If widgets do not render, edit `pip_labels.csv` directly: `a` and `b` must be integers
# `0`–`15`, and `status` must be `pending`, `labeled`, or `rejected`. Keep tile IDs unchanged.
# Label all tiles before starting the first training experiment; review coverage below.

# %%
def labeling_station(tiles, crops, labels_path):
    import ipywidgets as widgets
    from IPython.display import display, clear_output
    if IN_COLAB:
        from google.colab import output
        output.enable_custom_widget_manager()
    index = widgets.BoundedIntText(value=1, min=1, max=len(tiles), description="Tile")
    a = widgets.Dropdown(options=[("Choose…", "")] + [(str(i), str(i)) for i in range(16)], description="A · left")
    b = widgets.Dropdown(options=[("Choose…", "")] + [(str(i), str(i)) for i in range(16)], description="B · right")
    save = widgets.Button(description="Save & next", button_style="primary")
    reject = widgets.Button(description="Reject crop")
    previous = widgets.Button(description="Previous")
    pending = widgets.Button(description="Next pending")
    output = widgets.Output()
    message = widgets.HTML()

    def show(*_):
        current = load_pip_labels(labels_path, tiles)
        tile = tiles[index.value - 1]
        row = current[tile["tile_id"]]
        a.value, b.value = row["a"], row["b"]
        counts = Counter(r["status"] for r in current.values())
        message.value = f"<b>{index.value}/{len(tiles)}</b> · {counts['labeled']} labeled · {counts['rejected']} rejected · {counts['pending']} pending"
        with output:
            clear_output(wait=True)
            combined = np.concatenate([read_rgb(crops / tile["a_path"]), read_rgb(crops / tile["b_path"])], axis=1)
            print(tile["tile_id"], "—", row["status"])
            display(Image.fromarray(combined).resize((768, 384), Image.Resampling.NEAREST))
            print("A = LEFT HALF                         B = RIGHT HALF")

    def advance_pending(*_):
        current = load_pip_labels(labels_path, tiles)
        order = list(range(index.value, len(tiles))) + list(range(index.value))
        next_index = next((i for i in order if current[tiles[i]["tile_id"]]["status"] == "pending"), None)
        if next_index is None:
            show()
            message.value += " · <b>All tiles reviewed. Continue below.</b>"
        elif index.value == next_index + 1:
            show()
        else:
            index.value = next_index + 1

    def persist(status):
        if status == "labeled" and (a.value == "" or b.value == ""):
            message.value = "Choose a value for both A and B before saving."
            return
        current = load_pip_labels(labels_path, tiles)
        tile_id = tiles[index.value - 1]["tile_id"]
        current[tile_id] = {"tile_id": tile_id, "a": a.value if status == "labeled" else "",
                            "b": b.value if status == "labeled" else "", "status": status}
        shutil.copy2(labels_path, labels_path.with_suffix(".previous.csv"))
        write_csv(labels_path, list(current.values()), ["tile_id", "a", "b", "status"])
        advance_pending()

    save.on_click(lambda _: persist("labeled"))
    reject.on_click(lambda _: persist("rejected"))
    previous.on_click(lambda _: setattr(index, "value", max(1, index.value - 1)))
    pending.on_click(advance_pending)
    index.observe(show, names="value")
    panel = widgets.VBox([message, widgets.HBox([index, previous, pending]), output,
                          widgets.HBox([a, b]), widgets.HBox([save, reject])])
    display(panel)
    show()
    return panel

if ACTION == "label" and os.environ.get("DOMINO_NO_WIDGETS") != "1":
    labeling_station(tiles, CROPS, LABELS_PATH)

# %% [markdown]
# ## Check labels and reuse the photo split
# Rerun this cell after labeling. Training requires every tile to be reviewed and at least
# one training example for every value 0–15. Small class counts are a reason to collect more
# examples; augmentation does not create independent scenes. Classes absent from validation
# are displayed as unavailable rather than assigned a zero accuracy.
#
# Both halves and all crops from a photo retain that photo's split from notebook 1. No new
# random crop split is made. If the detector notebook has not frozen its split, labeling still works;
# return to notebook 1's grouping step before training either model.

# %%
pip_labels = load_pip_labels(LABELS_PATH, tiles)
split = None
examples = []
if (STATE / "split.json").is_file():
    split = frozen_split(records, fingerprint, STATE / "photo_groups.csv", STATE / "split.json", seed=SEED)
    examples = classifier_rows(tiles, pip_labels, split)
status_counts = Counter(r["status"] for r in pip_labels.values())
print("Labeling status:", dict(status_counts))
if examples:
    frame = pd.DataFrame(examples)
    coverage = pd.crosstab(frame["value"], frame["split"]).reindex(index=range(16), columns=["train", "val", "test"], fill_value=0).fillna(0).astype(int)
    display(coverage)
    coverage.plot.bar(color=["#34699a", "#d89b45", "#777777"], rot=0, figsize=(12, 4))
    plt.title("Labeled halves by pip value and frozen photo split")
    plt.xlabel("Pip value")
    plt.ylabel("Half-images")
    plt.tight_layout()
    plt.show()
else:
    print("Coverage appears after some tiles are labeled and notebook 1 creates the frozen split.")
if ACTION != "label":
    if split is None or status_counts["pending"]:
        raise RuntimeError("Finish reviewing all crops and create the photo split before training/evaluation.")
    for name in ("train", "val", "test"):
        if not any(r["split"] == name for r in examples):
            raise RuntimeError(f"No labeled crops in {name}. Review coverage or collect more data.")
    missing = sorted(set(range(16)) - {r["value"] for r in examples if r["split"] == "train"})
    if missing:
        raise RuntimeError(f"Training is missing pip values {missing}. Add labeled examples in independent training groups before proceeding.")

# %% [markdown]
# ## Train or resume the classifier
# A compact CNN is the first baseline. Pixel values enter as RGB `0–255`; normalization
# is inside the model. Training-only augmentation uses 90° rotations, flips, and mild
# brightness/contrast changes so pips are not removed by random cropping.
#
# Labels come directly from the numeric CSV values. There is no alphabetical folder inference.
# The saved class list is always `0, 1, 2, …, 15` in that exact order.
#
# The best model is selected on validation loss; class weights balance training examples.
# `last.keras` saves optimizer state and a completed-epoch marker each epoch. Resume uses
# those artifacts; early-stopping/LR-patience counters restart after reconnection.
# A new label set or changed split requires a new run name.

# %%
classifier = None
train_ds = val_ds = None
train_examples = val_examples = test_examples = []
if ACTION != "label":
    import tensorflow as tf
    tf.keras.utils.set_random_seed(SEED)
    gpus = tf.config.list_physical_devices("GPU")
    for gpu in gpus:
        tf.config.experimental.set_memory_growth(gpu, True)
    if ACTION in {"train", "resume"} and not gpus and not os.environ.get("DOMINO_ALLOW_CPU"):
        raise RuntimeError("Select a Colab GPU runtime, then rerun setup before training.")
    local_crops = WORK / "classifier_crops" / CROPS.name
    shutil.copytree(CROPS / "halves", local_crops / "halves", dirs_exist_ok=True)
    train_examples = [r for r in examples if r["split"] == "train"]
    val_examples = [r for r in examples if r["split"] == "val"]
    test_examples = [r for r in examples if r["split"] == "test"]

    def image_dataset(rows, training=False):
        paths = [str(local_crops / r["path"]) for r in rows]
        values = np.asarray([r["value"] for r in rows], dtype=np.int32)
        dataset = tf.data.Dataset.from_tensor_slices((paths, values))
        def decode(path, value):
            image = tf.io.decode_png(tf.io.read_file(path), channels=3)
            image = tf.ensure_shape(image, [128, 128, 3])
            return tf.cast(image, tf.float32), value
        dataset = dataset.map(decode, num_parallel_calls=tf.data.AUTOTUNE)
        if training:
            dataset = dataset.shuffle(len(rows), seed=SEED, reshuffle_each_iteration=True)
            def augment(image, value):
                image = tf.image.rot90(image, tf.random.uniform([], 0, 4, dtype=tf.int32))
                image = tf.image.random_flip_left_right(image)
                image = tf.image.random_flip_up_down(image)
                image = tf.image.random_brightness(image, max_delta=12.0)
                image = tf.image.random_contrast(image, 0.9, 1.1)
                return tf.clip_by_value(image, 0.0, 255.0), value
            dataset = dataset.map(augment, num_parallel_calls=tf.data.AUTOTUNE)
        return dataset.batch(BATCH_SIZE).prefetch(tf.data.AUTOTUNE)

    train_ds, val_ds = image_dataset(train_examples, True), image_dataset(val_examples)
    contract = {"split_signature": split["signature"], "labels_sha256": sha256(LABELS_PATH),
                "crop_version": CROP_VERSION, "class_names": CLASS_NAMES, "image_size": IMAGE_SIZE, "seed": SEED}
    if ACTION == "train":
        if RUN.exists():
            raise FileExistsError("Run already exists. Choose resume/evaluate or a new RUN_NAME.")
        RUN.mkdir(parents=True)
        write_json(RUN / "dataset_contract.json", contract)
        (RUN / "environment.txt").write_text(subprocess.check_output([sys.executable, "-m", "pip", "freeze"], text=True))
    elif not (RUN / "dataset_contract.json").exists() or json.loads((RUN / "dataset_contract.json").read_text()) != contract:
        raise ValueError("The saved run does not match the current labels, crops, split, or seed.")

# %%
def build_classifier(tf):
    inputs = tf.keras.Input(shape=(128, 128, 3), name="rgb_pixels")
    x = tf.keras.layers.Rescaling(1.0 / 255)(inputs)
    for filters in (32, 64, 96, 128):
        x = tf.keras.layers.Conv2D(filters, 3, padding="same", activation="relu")(x)
        x = tf.keras.layers.MaxPooling2D()(x)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.25)(x)
    x = tf.keras.layers.Dense(64, activation="relu")(x)
    outputs = tf.keras.layers.Dense(16, activation="softmax", name="pip_probabilities")(x)
    model = tf.keras.Model(inputs, outputs, name="pip_classifier")
    model.compile(optimizer=tf.keras.optimizers.Adam(1e-3), loss="sparse_categorical_crossentropy", metrics=["accuracy"])
    return model


if ACTION in {"train", "resume"}:
    history_rows = []
    initial_epoch = 0
    best_loss = float("inf")
    if ACTION == "resume":
        progress_path = RUN / "progress.json"
        if not progress_path.exists():
            raise FileNotFoundError("No completed epoch to resume. Choose a new RUN_NAME.")
        progress = json.loads(progress_path.read_text())
        checkpoint = RUN / progress["checkpoint"]
        if not checkpoint.exists():
            raise FileNotFoundError(f"Missing checkpoint: {checkpoint}")
        classifier = tf.keras.models.load_model(checkpoint)
        initial_epoch, history_rows, best_loss = progress["completed_epochs"], progress["history"], progress["best_val_loss"]
    else:
        classifier = build_classifier(tf)
    classifier.summary()

    class SaveEpoch(tf.keras.callbacks.Callback):
        def on_epoch_end(self, epoch, logs=None):
            global best_loss
            values = {k: float(v) for k, v in (logs or {}).items()}
            if not all(math.isfinite(v) for v in values.values()):
                raise RuntimeError("Training produced a non-finite metric; checkpoint not promoted.")
            history_rows.append({"epoch": epoch + 1, **values})
            # Alternate checkpoints so a disconnect during saving leaves the previous epoch intact.
            name = f"last_{(epoch + 1) % 2}.keras"
            self.model.save(RUN / name)
            if values["val_loss"] < best_loss:
                self.model.save(RUN / "best.pending.keras")
                (RUN / "best.pending.keras").replace(RUN / "best.keras")
                best_loss = values["val_loss"]
            write_json(RUN / "progress.json", {"completed_epochs": epoch + 1, "checkpoint": name,
                                               "best_val_loss": best_loss, "history": history_rows})
            pd.DataFrame(history_rows).to_csv(RUN / "history.csv", index=False)

    counts = Counter(r["value"] for r in train_examples)
    weights = {i: len(train_examples) / (16 * counts[i]) for i in range(16)}
    if initial_epoch >= EPOCHS:
        raise RuntimeError("Requested epoch budget is already complete. Use evaluate, or increase EPOCHS to continue.")
    classifier.fit(train_ds, validation_data=val_ds, initial_epoch=initial_epoch, epochs=EPOCHS,
                   class_weight=weights, callbacks=[
                       tf.keras.callbacks.ReduceLROnPlateau(monitor="val_loss", factor=0.5, patience=4),
                       SaveEpoch(),
                       tf.keras.callbacks.EarlyStopping(monitor="val_loss", patience=10)])
if ACTION != "label":
    classifier = tf.keras.models.load_model(RUN / "best.keras")
    (RUN / "labels_classifier.txt").write_text("\n".join(CLASS_NAMES) + "\n")
    print("Loaded the best classifier from:", RUN / "best.keras")

# %% [markdown]
# ## Validate: curves, per-value accuracy, and mistakes
# High overall accuracy can hide weak values. Review every class with its sample count,
# the confusion matrix, and wrongly classified halves. Missing validation classes have
# no measured accuracy. Validation crops use annotated boxes; full-photo evaluation below
# also measures mistakes introduced by detection and cropping.

# %%
def classifier_report(rows, probabilities, title, output_dir):
    truth = np.asarray([r["value"] for r in rows])
    predicted = probabilities.argmax(axis=1)
    matrix = np.zeros((16, 16), dtype=int)
    np.add.at(matrix, (truth, predicted), 1)
    support = matrix.sum(axis=1)
    accuracies = np.divide(matrix.diagonal(), support, out=np.full(16, np.nan), where=support > 0)
    report = pd.DataFrame({"pip_value": range(16), "examples": support, "accuracy": accuracies})
    display(report)
    fig, axes = plt.subplots(1, 2, figsize=(15, 5))
    heatmap = axes[0].imshow(matrix, cmap="Blues")
    axes[0].set(xticks=range(16), yticks=range(16), xlabel="Predicted value", ylabel="True value", title=f"{title}: confusion counts")
    fig.colorbar(heatmap, ax=axes[0], label="Half-images")
    axes[1].bar(range(16), accuracies, color="#34699a")
    axes[1].set(xticks=range(16), ylim=(0, 1), xlabel="Pip value", ylabel="Accuracy", title="Per-value accuracy (gaps = no examples)")
    plt.tight_layout()
    plt.show()
    result = {"examples": len(rows), "accuracy": float((truth == predicted).mean()),
              "macro_accuracy_present_classes": float(np.nanmean(accuracies)), "missing_values": np.flatnonzero(support == 0).tolist()}
    output_dir.mkdir(parents=True, exist_ok=True)
    write_json(output_dir / "summary.json", result)
    report.to_csv(output_dir / "per_value.csv", index=False)
    pd.DataFrame(matrix, index=CLASS_NAMES, columns=CLASS_NAMES).to_csv(output_dir / "confusion.csv")
    return result, predicted


if classifier is not None:
    history = pd.read_csv(RUN / "history.csv")
    fig, axes = plt.subplots(1, 2, figsize=(12, 4))
    history.plot(x="epoch", y=["loss", "val_loss"], ax=axes[0], color=["#34699a", "#d89b45"], title="Classifier loss")
    history.plot(x="epoch", y=["accuracy", "val_accuracy"], ax=axes[1], color=["#34699a", "#d89b45"], title="Classifier accuracy")
    axes[0].set_ylabel("Loss")
    axes[1].set(ylabel="Accuracy", ylim=(0, 1))
    plt.tight_layout()
    plt.show()
    val_probabilities = classifier.predict(val_ds.map(lambda x, y: x), verbose=0)
    val_summary, val_predictions = classifier_report(val_examples, val_probabilities, "Validation", RUN / "checks/val")
    print(val_summary)
    mistakes = [i for i, row in enumerate(val_examples) if row["value"] != val_predictions[i]]
    if mistakes:
        fig, axes = plt.subplots(2, 5, figsize=(12, 5))
        for ax in axes.flat:
            ax.axis("off")
        for ax, i in zip(axes.flat, mistakes[:10]):
            row = val_examples[i]
            ax.imshow(read_rgb(local_crops / row["path"]))
            ax.set_title(f"True {row['value']} → {val_predictions[i]}\np={val_probabilities[i].max():.2f}")
        plt.tight_layout()
        plt.show()

# %% [markdown]
# ## Export and compare TFLite classifiers
# Export an FP32 baseline and optionally full INT8 using representative **training crops only**.
# Both are tested against the Keras model on the same validation rows. Exported files include
# exact class order, input/output tensor details, quantization scale/zero point, and preprocessing.
# Never normalize pixels a second time in the app: normalization is part of this model.

# %%
def tflite_predictor(path, tf):
    interpreter = tf.lite.Interpreter(model_path=str(path))
    interpreter.allocate_tensors()
    input_info = interpreter.get_input_details()[0]
    output_info = interpreter.get_output_details()[0]
    def predict(rgb):
        array = np.asarray(rgb, dtype=np.float32)[None]
        if np.issubdtype(input_info["dtype"], np.integer):
            scale, zero = input_info["quantization"]
            if scale <= 0:
                raise ValueError("Quantized input has no valid scale.")
            limits = np.iinfo(input_info["dtype"])
            array = np.clip(np.rint(array / scale + zero), limits.min, limits.max)
        interpreter.set_tensor(input_info["index"], array.astype(input_info["dtype"]))
        interpreter.invoke()
        probabilities = interpreter.get_tensor(output_info["index"])[0].astype(np.float32)
        if np.issubdtype(output_info["dtype"], np.integer):
            scale, zero = output_info["quantization"]
            probabilities = (probabilities - zero) * scale
        return probabilities
    def describe(info):
        return {"name": info["name"], "shape": info["shape"].tolist(), "dtype": np.dtype(info["dtype"]).name,
                "quantization": list(info["quantization"])}
    return predict, {"input": describe(input_info), "output": describe(output_info)}


if ACTION == "export" and classifier is not None:
    export_dir = RUN / "exports"
    export_dir.mkdir(exist_ok=True)
    export_rows = []
    calibration_rows = random.Random(SEED).sample(train_examples, min(256, len(train_examples)))
    def representative_data():
        for row in calibration_rows:
            yield [read_rgb(local_crops / row["path"])[None].astype(np.float32)]
    for mode in ["fp32"] + (["int8"] if EXPORT_INT8 else []):
        converter = tf.lite.TFLiteConverter.from_keras_model(classifier)
        if mode == "int8":
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            converter.representative_dataset = representative_data
            converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
            converter.inference_input_type = tf.uint8
            converter.inference_output_type = tf.uint8
        saved = export_dir / f"pip_classifier_{mode}.tflite"
        saved.write_bytes(converter.convert())
        predict, tensor_info = tflite_predictor(saved, tf)
        probabilities = np.stack([predict(read_rgb(local_crops / r["path"])) for r in val_examples])
        accuracy = float((probabilities.argmax(1) == [r["value"] for r in val_examples]).mean())
        export_rows.append({"format": mode, "file": saved.name, "bytes": saved.stat().st_size, "accuracy": accuracy,
                            "drop_from_keras": val_summary["accuracy"] - accuracy,
                            "max_probability_difference": float(np.max(np.abs(probabilities - val_probabilities))), "tensors": tensor_info})
    acceptable = [r for r in export_rows if r["drop_from_keras"] <= MAX_EXPORT_ACCURACY_DROP]
    preferred = next((r for r in acceptable if r["format"] == "int8"), next((r for r in acceptable if r["format"] == "fp32"), None))
    metadata = {"class_names": CLASS_NAMES, "crop_version": CROP_VERSION, "split_signature": split["signature"],
                "labels_sha256": sha256(LABELS_PATH), "image_size": [128, 128], "color_order": "RGB",
                "pixel_range_before_input_quantization": [0, 255], "normalization": "Rescaling(1/255) is embedded in the model",
                "pip_confidence": PIP_CONFIDENCE, "preferred_file": preferred["file"] if preferred else None, "validation": export_rows}
    write_json(export_dir / "classifier_metadata.json", metadata)
    (export_dir / "labels_classifier.txt").write_text("\n".join(CLASS_NAMES) + "\n")
    display(pd.DataFrame([{k: v for k, v in r.items() if k != "tensors"} for r in export_rows]))
    if preferred is None:
        raise RuntimeError("No classifier export met the accuracy tolerance. Investigate conversion before deployment.")
    print("Preferred validated export:", export_dir / preferred["file"])

# %% [markdown]
# ## Full-photo evaluation
# This checks the actual chain: detector → straightened tile → two predicted values → sum.
# It reports total-score accuracy **and** whether every tile/value pair is correct; wrong
# values can otherwise cancel out in a total. Detector matching uses IoU 0.5 and accepts A/B swaps.
#
# Only photos with all annotated tiles labeled have a known full score. Excluded photos
# and reasons are saved and counted; never describe their score as zero or hide their exclusion.
# Low-confidence predictions are flagged for review and still included in the raw score.
# This confidence rule cannot guarantee that the detector found every tile.
#
# By default this evaluates validation photos. Set `FINAL_TEST=True` only after settling choices.
# If both notebooks have validated mobile exports, this also measures their combined pipeline.
# Labels always describe actual pips. `BLANK_SCORE` applies the app's house rule only when
# totaling values (default 50 per blank half). Raw pip sums are also saved for comparison.
# Results on Python/Colab do not establish phone latency or app integration correctness.

# %%
def evaluate_photos(detector_model, half_predict, selected_split, output_dir, device="cpu", detector_image_size=640):
    chosen_names = {r["image"] for r in split["photos"] if r["split"] == selected_split}
    by_image = {}
    for tile in tiles:
        by_image.setdefault(tile["image"], []).append(tile)
    results, excluded = [], []
    for record in records:
        if record["image"] not in chosen_names:
            continue
        image_tiles = by_image.get(record["image"], [])
        if any(pip_labels[t["tile_id"]]["status"] != "labeled" for t in image_tiles):
            excluded.append({"image": record["image"], "reason": "One or more annotated tiles are rejected or unlabeled"})
            continue
        rgb = read_rgb(RAW / "images" / record["image"])
        # NumPy YOLO input is BGR, so convert explicitly from our RGB geometry space.
        result = detector_model.predict(rgb[:, :, ::-1].copy(), imgsz=detector_image_size, conf=DETECTION_CONFIDENCE, device=device, verbose=False)[0]
        corners = result.obb.xyxyxyxy.cpu().numpy()
        pairs, confidences = [], []
        invalid_crops = 0
        for box in corners:
            try:
                halves = tile_halves(rectify_tile(rgb, box))
                probabilities = [half_predict(half) for half in halves]
                pairs.append(tuple(int(p.argmax()) for p in probabilities))
                confidences.append(min(float(p.max()) for p in probabilities))
            except ValueError:
                invalid_crops += 1
                pairs.append(None)
                confidences.append(0.0)
        expected_pairs = [(int(pip_labels[t["tile_id"]]["a"]), int(pip_labels[t["tile_id"]]["b"])) for t in image_tiles]
        expected_score = score_pairs(expected_pairs, BLANK_SCORE)
        score = score_pairs(pairs, BLANK_SCORE)
        truth = np.asarray(record["boxes"]).reshape(-1, 4, 2) * [record["width"], record["height"]]
        matches = match_boxes(truth, corners)
        correct_pairs = sum(pairs[j] is not None and sorted(expected_pairs[i]) == sorted(pairs[j]) for i, j, _ in matches)
        results.append({"image": record["image"], "expected_tiles": len(truth), "detected_tiles": len(corners),
                        "missed_tiles": len(truth) - len(matches), "extra_tiles": len(corners) - len(matches),
                        "correct_pairs": correct_pairs, "expected_score": expected_score, "predicted_score": score,
                        "expected_raw_pips": score_pairs(expected_pairs), "predicted_raw_pips": score_pairs(pairs),
                        "absolute_score_error": abs(score - expected_score), "exact_score": invalid_crops == 0 and score == expected_score,
                        "all_tiles_correct": invalid_crops == 0 and correct_pairs == len(truth) == len(corners),
                        "needs_review": invalid_crops > 0 or any(c < PIP_CONFIDENCE for c in confidences), "invalid_crops": invalid_crops})
    output_dir.mkdir(parents=True, exist_ok=True)
    pd.DataFrame(excluded, columns=["image", "reason"]).to_csv(output_dir / "excluded_photos.csv", index=False)
    frame = pd.DataFrame(results)
    if frame.empty:
        print(f"No fully labeled {selected_split} photos available; excluded {len(excluded)}.")
        return
    frame.to_csv(output_dir / "photo_scores.csv", index=False)
    summary = {"split": selected_split, "evaluated_photos": len(frame), "excluded_photos": len(excluded),
               "blank_score": BLANK_SCORE, "detection_confidence": DETECTION_CONFIDENCE, "pip_confidence": PIP_CONFIDENCE,
               "exact_score_accuracy": float(frame["exact_score"].mean()),
               "all_tiles_correct_accuracy": float(frame["all_tiles_correct"].mean()),
               "mean_absolute_score_error": float(frame["absolute_score_error"].mean()),
               "photos_flagged_for_review": int(frame["needs_review"].sum())}
    write_json(output_dir / "summary.json", summary)
    display(pd.DataFrame([summary]))
    display(frame.sort_values("absolute_score_error", ascending=False))
    fig, ax = plt.subplots(figsize=(6, 5))
    ax.scatter(frame["expected_score"], frame["predicted_score"], color="#34699a")
    high = max(1, int(max(frame["expected_score"].max(), frame["predicted_score"].max())))
    ax.plot([0, high], [0, high], "--", color="#777777", label="Exact score")
    ax.set(xlabel="Labeled photo total", ylabel="Predicted photo total", title=f"Full pipeline · {selected_split} photos")
    ax.legend()
    plt.tight_layout()
    plt.show()


if classifier is not None:
    selected_split = "test" if FINAL_TEST else "val"
    if FINAL_TEST:
        test_ds = image_dataset(test_examples)
        test_probabilities = classifier.predict(test_ds.map(lambda x, y: x), verbose=0)
        classifier_report(test_examples, test_probabilities, "Final test", RUN / "checks/test")
    detector_run = PROJECT / "models/detector" / DETECTOR_RUN_NAME
    detector_weights = detector_run / "weights/best.pt"
    if detector_weights.exists():
        saved_contract = json.loads((detector_run / "dataset_contract.json").read_text())
        if saved_contract["split_signature"] != split["signature"]:
            raise ValueError("Detector and classifier must use the same frozen photo split.")
        from ultralytics import YOLO
        # Keep detector inference on CPU here to avoid competing with TensorFlow for GPU memory.
        detector_model = YOLO(str(detector_weights))
        keras_predict = lambda half: classifier(np.asarray(half, np.float32)[None], training=False).numpy()[0]
        evaluate_photos(detector_model, keras_predict, selected_split, RUN / "checks" / f"pipeline_{selected_split}", detector_image_size=saved_contract["image_size"])
        detector_meta = detector_run / "exports/detector_metadata.json"
        classifier_meta = RUN / "exports/classifier_metadata.json"
        if detector_meta.exists() and classifier_meta.exists():
            dm, cm = json.loads(detector_meta.read_text()), json.loads(classifier_meta.read_text())
            if dm["split_signature"] != split["signature"] or cm["split_signature"] != split["signature"] or cm["labels_sha256"] != sha256(LABELS_PATH):
                raise ValueError("Mobile exports are stale for these labels/splits. Export again.")
            if dm["preferred_file"] and cm["preferred_file"]:
                mobile_detector = YOLO(str(detector_meta.parent / dm["preferred_file"]), task="obb")
                mobile_classifier, _ = tflite_predictor(classifier_meta.parent / cm["preferred_file"], tf)
                evaluate_photos(mobile_detector, mobile_classifier, selected_split, RUN / "checks" / f"mobile_pipeline_{selected_split}", detector_image_size=dm["image_size"])
    else:
        print("Classifier checks complete. Full-photo evaluation waits for notebook 1's trained detector:", detector_weights)

# %% [markdown]
# ## Handoff
# Keep the best detector/classifier checkpoints, both export bundles, their metadata/label
# files, frozen split, and labeling CSV together. The app must apply the same RGB orientation,
# OBB rectification, half order, and model normalization. Verify exported predictions and
# score accuracy on held-out photos before integrating, then measure on the target phone.
#
# Future improvements should follow observed errors: more independent arrangements,
# coverage for weak pip values, and training crops with realistic detector jitter. Keep
# held-out photos out of every training/calibration step. This CNN is a baseline, not a claim
# that 36 photographs establish production accuracy.

# %%
print("Labeling progress:", LABELS_PATH)
print("Models/checks/exports:", RUN)
print("Return with ACTION='evaluate' to reload the best saved model without retraining.")
