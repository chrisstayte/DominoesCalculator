# %% [markdown]
# # 6 · Pretrained classifier experiments
#
# Reuse existing labels without changing the detector, original data, or earlier runs.
# Train two separately named MobileNetV2 candidates, then compare all classifiers on
# identical saved detector boxes and the previously checked development pairs.
# The frozen final test split stays unused.
#
# Use a Colab GPU runtime. Save a private copy in Drive to retain executed results.
# This public notebook intentionally has no saved outputs. Keep raw logs, predictions,
# images, labels, weights and executed notebooks in Drive; publish only reviewed aggregates.

# %% setup
install_packages([TENSORFLOW_REQUIREMENT, KERAS_REQUIREMENT, NUMPY_REQUIREMENT,
                  "pandas==2.2.3", "matplotlib==3.10.1", "pillow==11.1.0",
                  "opencv-python==4.11.0.86"])

# %% [markdown]
# ## Configuration and immutable code
# A new experiment requires new run names and a new comparison name. Existing run
# folders are never overwritten. The code revision below is fixed for reproducibility.
# If a job is interrupted, its best/last checkpoints remain in that run directory.
# Do not rename old folders or delete labels to restart a trial.

# %%
from pathlib import Path
import json
import os
import subprocess
import sys
import urllib.request

REVISION = "02ece7476a6abf619d25b0af9dda4205229dc0f9"
PROJECT = Path("/content/drive/MyDrive/DominoesCalculator")
CODE = Path("/content/domino-classifier-v3") / REVISION
TRIALS = [("pips-v3-mnv2-rgb-01", "rgb"), ("pips-v3-mnv2-mixed-01", "mixed")]
COMPARISON = "classifier-v3-01"
FILES = ["notebook_sources/common.py", "notebook_sources/pretrained_classifier.py",
         "scripts/run_classifier_experiment.py", "reviews/2026-11-22-photo-tests.json",
         "reviews/2026-11-22-v2/summary.json"]
for relative in FILES:
    target = CODE / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    urllib.request.urlretrieve(
        f"https://raw.githubusercontent.com/chrisstayte/DominoesCalculator/{REVISION}/machine_learning/{relative}", target)
print("Pinned experiment code ready. Detector: domino-v2-01, unchanged.")

# %% [markdown]
# ## Train and compare
# Mount the existing Drive project. Each stage runs in a separate process to release
# GPU memory between classifiers. Detailed outputs stay in the new private report
# folder. Both candidates are trained before the development photos are compared.
# Validation loss chooses each checkpoint; challenge-photo results do not choose it.

# %%
from google.colab import drive
drive.mount("/content/drive")
if not PROJECT.is_dir():
    raise FileNotFoundError("The existing DominoesCalculator Drive project is required.")
JOB = PROJECT / "training_reports" / (COMPARISON + "-job")
JOB.mkdir(parents=True, exist_ok=False)
stages = [(name, ["train", "--run", name, "--variant", variant]) for name, variant in TRIALS]
stages.append(("compare", ["compare", "--runs", *[name for name, _ in TRIALS], "--comparison", COMPARISON]))
status = {"completed": [], "current": "starting", "revision": REVISION}
for name, arguments in stages:
    status["current"] = name
    (JOB / "status.json").write_text(json.dumps(status, indent=2) + "\n")
    print("STARTING", name, flush=True)
    command = [sys.executable, "-u", str(CODE / "scripts/run_classifier_experiment.py"),
               *arguments, "--project", str(PROJECT)]
    environment = dict(os.environ, MPLBACKEND="Agg", TF_CPP_MIN_LOG_LEVEL="2",
                       PYTHONUNBUFFERED="1", MPLCONFIGDIR="/content/domino-matplotlib")
    with (JOB / (name + ".log")).open("w") as log:
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   text=True, env=environment)
        for line in process.stdout:
            log.write(line)
            log.flush()
            print(line, end="", flush=True)
        code = process.wait()
    if code:
        status["failed"] = name
        (JOB / "status.json").write_text(json.dumps(status, indent=2) + "\n")
        raise RuntimeError(f"Stage {name} stopped; its private log and checkpoints are preserved.")
    status["completed"].append(name)
status["current"] = "complete"
(JOB / "status.json").write_text(json.dumps(status, indent=2) + "\n")
print("ALL CLASSIFIER EXPERIMENTS AND COMPARISON COMPLETE", flush=True)

# %% [markdown]
# ## Results
# This chart uses the same 36 selected development pairs for every classifier.
# These are not independent full-photo accuracy estimates. The fixed detector still
# contributes its existing missed/extra boxes. Review the private overlays as well.

# %%
from IPython.display import Image, display
summary = json.loads((PROJECT / "training_reports" / COMPARISON / "summary.json").read_text())
for run in summary["runs"]:
    print(run["run"], "validation:", round(run["validation"]["original"]["accuracy"] * 100, 2), "%",
          "fixed original pairs:", run["fixed_original_crops"]["correct_pairs"], "/36",
          "frozen detector pairs:", run["frozen_detector_crops"]["correct_pairs"], "/36")
print("Protected inputs unchanged:", summary["protected_inputs_unchanged"])
display(Image(filename=str(PROJECT / "training_reports" / COMPARISON / "comparison.png")))
