# %% [markdown]
# # 3 · Review and correct pip labels
#
# Run all cells to open the review panel. A CPU runtime is enough; training is not needed.
# It reads your saved crops and labels from `MyDrive/DominoesCalculator`.
#
# Start with **Flagged** tiles when a `pip_review_flags.json` is available, or choose
# **All tiles** to check every domino. Click the correct value **0–15** for A (left)
# and B (right), then **Save & next**. The existing values are selected initially;
# suggestions are prompts for you to inspect, and are never applied automatically.
#
# Every save records your review progress in Drive. Changed labels have a session backup
# in `label_review_backups/`, plus `pip_labels.previous.csv`. **Skip** and navigation
# do not save changes. Use **Reject unreadable crop** when either half cannot be read.
# Keep one labeling/review session open at a time.
#
# After corrections, return to notebook 2, choose a new run name (for example
# `pips-v1-02`), rerun the label check, and train again. Saved model runs keep their
# original label contract. The photo split stays frozen.

# %%
DATASET_NAME = "dominoes-v1"
CROP_DIRECTORY = ""  # Leave blank when the dataset has one crop version.

# %%
import os
from pathlib import Path

if os.environ.get("DOMINO_ML_ROOT"):
    PROJECT = Path(os.environ["DOMINO_ML_ROOT"]).expanduser().resolve()
else:
    from google.colab import drive
    drive.mount("/content/drive")
    PROJECT = Path("/content/drive/MyDrive/DominoesCalculator")

dataset_crops = PROJECT / "data/classifier" / DATASET_NAME
if CROP_DIRECTORY:
    CROPS = (dataset_crops / CROP_DIRECTORY).resolve()
    if not CROPS.is_relative_to(dataset_crops.resolve()):
        raise ValueError("CROP_DIRECTORY must name a folder inside this dataset.")
else:
    choices = sorted(p for p in dataset_crops.iterdir() if p.is_dir() and (p / "pip_labels.csv").is_file())
    if len(choices) != 1:
        raise ValueError(f"Set CROP_DIRECTORY to one of these saved crop folders: {[p.name for p in choices]}")
    CROPS = choices[0]
print("Reviewing saved labels in:", CROPS)

# %% review_helpers

# %% [markdown]
# ## Check the values and save
# The panel resumes your unreviewed tiles automatically. **Save & next** also confirms
# tiles whose labels are already correct. You can switch between Flagged, All tiles,
# and Unreviewed at any time, or jump to a tile by number.

# %%
if os.environ.get("DOMINO_NO_WIDGETS") == "1":
    review_session = PipLabelReview(CROPS)
    print("Review data loaded:", len(review_session.tiles), "tiles;", len(review_session.flags), "flagged.")
else:
    review_session = open_pip_label_review(CROPS)
