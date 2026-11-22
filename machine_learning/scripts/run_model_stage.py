"""Run reviewed notebooks in separate Colab processes so GPU memory is released.

Mount Drive and install notebook 2's model dependencies in Colab first. Then run:
  python machine_learning/scripts/run_model_stage.py classifier
  python machine_learning/scripts/run_model_stage.py detector
  python machine_learning/scripts/run_model_stage.py compare

This does not download code, install packages, change labels, or overwrite existing runs.
"""
import argparse
import ast
import hashlib
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNS = {"classifier": "pips-v2-01", "detector": "domino-v2-01"}


def configured_cell(source, overrides, filename):
    tree = ast.parse(source, filename=filename)
    # Only top-level configuration assignments; never rewrite helper function locals.
    for node in tree.body:
        if isinstance(node, ast.Assign) and len(node.targets) == 1:
            target = node.targets[0]
            if isinstance(target, ast.Name) and target.id in overrides:
                node.value = ast.copy_location(ast.Constant(overrides[target.id]), node.value)
    return compile(ast.fix_missing_locations(tree), filename, "exec")


def run(stage, project, work):
    os.environ.update(DOMINO_ML_ROOT=str(project), DOMINO_WORK_DIR=str(work),
                      DOMINO_SKIP_INSTALL="1", DOMINO_NO_WIDGETS="1", MPLBACKEND="Agg")
    from IPython.display import display
    import matplotlib.pyplot as plt
    reports = project / "training_reports" / (RUNS.get(stage, "v2-comparison"))
    reports.mkdir(parents=True, exist_ok=True)
    figure_number = 0

    def save_figures(*args, **kwargs):
        nonlocal figure_number
        for number in plt.get_fignums():
            figure_number += 1
            plt.figure(number).savefig(reports / f"figure-{figure_number:03d}.png", dpi=130, bbox_inches="tight")
        plt.close("all")

    plt.show = save_figures
    name = {"classifier": "02_pip_classifier", "detector": "01_domino_detector", "compare": "04_test_photo"}[stage]
    path = ROOT / "notebooks" / (name + ".ipynb")
    notebook = json.loads(path.read_text())
    cells = ["".join(c["source"]) for c in notebook["cells"] if c["cell_type"] == "code"]
    overrides = {"ACTION": "train", "RUN_NAME": RUNS.get(stage), "FINAL_TEST": False}
    if stage == "compare":
        overrides.update(DETECTOR_RUN_NAME=RUNS["detector"], CLASSIFIER_RUN_NAME=RUNS["classifier"])
    namespace = {"__name__": "__main__", "display": display}
    for index, source in enumerate(cells[:-1] if stage == "compare" else cells):
        print(f"{stage}: code cell {index + 1}/{len(cells)}", flush=True)
        exec(configured_cell(source, overrides, str(path)), namespace)
    if stage == "compare":
        summary = compare(namespace, cells[-1], project, reports)
    else:
        model = project / "models" / stage / RUNS[stage] / ("best.keras" if stage == "classifier" else "weights/best.pt")
        if not model.is_file():
            raise RuntimeError(f"Training ended without its best checkpoint: {model}")
        summary = {"stage": stage, "run": RUNS[stage], "best_checkpoint": str(model),
                   "notebook_sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
    (reports / "completed.json").write_text(json.dumps(summary, indent=2) + "\n")
    print("DOMINO_STAGE_COMPLETE " + json.dumps(summary), flush=True)


def compare(namespace, upload_source, project, reports):
    import pandas as pd
    review = json.loads((ROOT / "reviews/2026-11-22-photo-tests.json").read_text())
    pair_results, photo_results = [], []
    # Reuse the notebook's actual save/display path, with original filenames and no picker.
    upload_body = upload_source[upload_source.index("for filename, content in uploads.items():"):]
    for test in review["tests"]:
        directory = project / "photo_tests" / test["run_id"]
        baseline_file = directory / "predictions.json"
        if hashlib.sha256(baseline_file.read_bytes()).hexdigest() != test["baseline_predictions_sha256"]:
            raise ValueError("A baseline test changed after visual review: " + test["run_id"])
        rgb = namespace["read_rgb"](directory / "photo.png")
        for tile in test["reviewed_tiles"]:
            crop = namespace["rectify_tile"](rgb, tile["corners"])
            predicted = [int(namespace["half_predict"](half).argmax()) for half in namespace["tile_halves"](crop)]
            pair_results.append({"source_run": test["run_id"], "tile": tile["tile"],
                                 "expected": tile["expected_pair"], "baseline": tile["baseline_pair"],
                                 "new": predicted, "baseline_correct": tile["baseline_correct"],
                                 "new_correct": sorted(predicted) == sorted(tile["expected_pair"])})
        namespace["uploads"] = {test["image_name"]: (directory / "photo.png").read_bytes()}
        exec(compile(upload_body, "batch photo test", "exec"), namespace)
        photo_results.append({"source_run": test["run_id"], "new_run": namespace["output_dir"].name,
                              "baseline_detected_tiles": test["detected_tiles"],
                              "new_detected_tiles": namespace["report"]["detected_tiles"]})
    frame = pd.DataFrame(pair_results)
    frame.to_csv(reports / "reviewed_pairs.csv", index=False)
    pd.DataFrame(photo_results).to_csv(reports / "photos.csv", index=False)
    summary = {"stage": "compare", "reviewed_pairs": len(frame),
               "baseline_correct_pairs": int(frame["baseline_correct"].sum()),
               "new_correct_pairs": int(frame["new_correct"].sum()), "photos": photo_results,
               "limitation": "Selected development pairs on fixed original crops; not independent test accuracy. New full-photo boxes still require visual review."}
    (reports / "comparison.json").write_text(json.dumps({**summary, "pairs": pair_results}, indent=2) + "\n")
    print(frame.to_string(index=False), flush=True)
    return summary


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("stage", choices=["classifier", "detector", "compare"])
    parser.add_argument("--project", type=Path, default=Path("/content/drive/MyDrive/DominoesCalculator"))
    parser.add_argument("--work", type=Path, default=Path("/content/domino-work"))
    args = parser.parse_args()
    run(args.stage, args.project, args.work)
