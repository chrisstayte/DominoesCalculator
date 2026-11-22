"""Train/evaluate isolated classifiers from existing labels; never train the detector."""
import argparse
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "notebook_sources"))
from pretrained_classifier import evaluate, finalize_contracts, train

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["train", "compare", "finalize"])
    parser.add_argument("--project", type=Path, required=True)
    parser.add_argument("--run")
    parser.add_argument("--variant", choices=["rgb", "mixed"], default="mixed")
    parser.add_argument("--runs", nargs="+")
    parser.add_argument("--comparison", default="classifier-v3-01")
    args = parser.parse_args()
    if args.action == "train":
        if not args.run:
            parser.error("train requires --run with a new name")
        train(args.project, args.run, args.variant)
    elif args.action == "compare":
        if not args.runs:
            parser.error("compare requires --runs")
        evaluate(args.project, args.runs, ROOT, args.comparison)
    else:
        if not args.runs:
            parser.error("finalize requires --runs")
        finalize_contracts(args.project, args.runs)
