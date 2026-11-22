"""Training helpers embedded after common.py; TensorFlow is passed explicitly."""

CLASSIFIER_RECIPE = "grayscale-hue-light-resolution-v2"


def augment_classifier_image(image, value, tf):
    """Training only. Keep the full half in view; vary color, light and resolution."""
    image = tf.cast(image, tf.float32) / 255.0
    image = tf.image.rot90(image, tf.random.uniform([], 0, 4, dtype=tf.int32))
    image = tf.image.random_flip_left_right(image)
    image = tf.image.random_flip_up_down(image)
    # Hue changes before grayscale also vary the brightness of colored pips.
    image = tf.image.random_hue(image, 0.5)
    image = tf.image.random_saturation(image, 0.0, 1.8)
    image = tf.image.adjust_gamma(tf.clip_by_value(image, 0.0, 1.0),
                                  tf.random.uniform([], 0.7, 1.5))
    image = tf.image.random_contrast(image, 0.65, 1.35)
    # Darken multiplicatively; additive brightening could erase light-colored pips.
    image = image * tf.random.uniform([], 0.65, 1.0)
    image = tf.clip_by_value(image, 0.0, 1.0)
    # Shrink and pad rather than crop: cutting off a pip would invalidate its label.
    side = tf.random.uniform([], 112, 129, dtype=tf.int32)
    image = tf.image.resize(image, [side, side])
    top = tf.random.uniform([], 0, 129 - side, dtype=tf.int32)
    left = tf.random.uniform([], 0, 129 - side, dtype=tf.int32)
    image = tf.pad(image, [[top, 128 - side - top], [left, 128 - side - left], [0, 0]],
                   constant_values=1.0)
    resolution = tf.random.uniform([], 72, 129, dtype=tf.int32)
    image = tf.image.resize(tf.image.resize(image, [resolution, resolution]), [128, 128])
    return tf.ensure_shape(tf.clip_by_value(image * 255.0, 0.0, 255.0), [128, 128, 3]), value


def build_classifier(tf):
    inputs = tf.keras.Input(shape=(128, 128, 3), name="rgb_pixels")
    x = tf.keras.layers.Rescaling(1.0 / 255)(inputs)
    # A serializable Keras operation, present during training AND inference/export.
    # The external contract stays RGB 0–255; callers must not preprocess twice.
    x = tf.keras.ops.image.rgb_to_grayscale(x)
    for filters in (32, 64, 96, 128):
        x = tf.keras.layers.Conv2D(filters, 3, padding="same", activation="relu")(x)
        x = tf.keras.layers.MaxPooling2D()(x)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.25)(x)
    x = tf.keras.layers.Dense(64, activation="relu")(x)
    outputs = tf.keras.layers.Dense(16, activation="softmax", name="pip_probabilities")(x)
    model = tf.keras.Model(inputs, outputs, name="pip_classifier_grayscale")
    model.compile(optimizer=tf.keras.optimizers.Adam(1e-3),
                  loss="sparse_categorical_crossentropy", metrics=["accuracy"])
    return model


def check_run_contract(saved, expected, recipe, action):
    """Allow evaluation of legacy runs, but never resume with a different recipe."""
    data_contract = {k: v for k, v in saved.items() if k != "training_recipe"}
    if data_contract != expected:
        raise ValueError("The saved run does not match the current data, labels, split, or configuration.")
    if action == "resume" and saved.get("training_recipe") != recipe:
        raise ValueError("Training recipe changed. Use evaluate for this checkpoint, or train with a new RUN_NAME.")


def classifier_stress_images(rgb):
    """Deterministic diagnostics, not additional independent validation examples."""
    gray = cv2.cvtColor(rgb, cv2.COLOR_RGB2GRAY)
    return {
        "original": rgb,
        "grayscale": np.repeat(gray[:, :, None], 3, axis=2),
        "channel_swap": rgb[:, :, ::-1].copy(),
        "darker": np.rint(rgb.astype(np.float32) * 0.65).astype(np.uint8),
        "low_resolution": cv2.resize(cv2.resize(rgb, (48, 48)), (128, 128)),
    }


def classifier_robustness_report(classifier, rows, crops, output_dir):
    truth = np.asarray([r["value"] for r in rows])
    images = [classifier_stress_images(read_rgb(crops / r["path"])) for r in rows]
    reports, details = [], []
    original_predictions = None
    for variant in images[0]:
        probabilities = classifier.predict(np.stack([x[variant] for x in images]).astype(np.float32),
                                            batch_size=32, verbose=0)
        predictions = probabilities.argmax(axis=1)
        if original_predictions is None:
            original_predictions = predictions
        accuracy = float((predictions == truth).mean())
        reports.append({"variant": variant, "examples": len(rows), "accuracy": accuracy,
                        "drop_from_original": reports[0]["accuracy"] - accuracy if reports else 0.0,
                        "changed_predictions": int((predictions != original_predictions).sum())})
        details.extend({"variant": variant, "tile_id": r["tile_id"], "side": r["side"],
                        "true_value": r["value"], "predicted_value": int(p),
                        "confidence": float(probabilities[i].max())}
                       for i, (r, p) in enumerate(zip(rows, predictions)))
    output_dir.mkdir(parents=True, exist_ok=True)
    pd.DataFrame(reports).to_csv(output_dir / "summary.csv", index=False)
    pd.DataFrame(details).to_csv(output_dir / "predictions.csv", index=False)
    write_json(output_dir / "summary.json", {"independent_photos": len({r["image"] for r in rows}),
               "warning": "Transformed copies share their source photos; this is not a new test set.",
               "variants": reports})
    return pd.DataFrame(reports)


def prepare_detector_training(root, records, split, work, grayscale_copies=True):
    # A separate cache prevents variants leaking into an older RGB-only experiment.
    config = prepare_detector(root, records, split, work / "rgb-gray-v2" if grayscale_copies else work)
    if grayscale_copies:
        by_name = {r["image"]: r for r in records}
        for row in split["photos"]:
            if row["split"] != "train":
                continue
            record = by_name[row["image"]]
            name = "gray_" + record["stem"]
            rgb = read_rgb(root / "images" / row["image"])
            Image.fromarray(cv2.cvtColor(rgb, cv2.COLOR_RGB2GRAY)).save(config.parent / "train/images" / (name + ".png"))
            shutil.copy2(root / "labels" / (record["stem"] + ".txt"),
                         config.parent / "train/labels" / (name + ".txt"))
    return config
