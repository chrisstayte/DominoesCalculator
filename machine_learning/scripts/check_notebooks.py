"""Execute preparation/labeling paths on real data in an isolated local project.

Training remains disabled: true pip labels and a reviewed arrangement split are needed.
Requires nbformat, nbclient, ipykernel and the notebooks' image/plot dependencies.
"""
from pathlib import Path
import json
import os
import shutil
import sys

import nbformat
from nbclient import NotebookClient
from nbconvert import HTMLExporter

ROOT = Path(__file__).resolve().parents[1]
CHECK = ROOT / "data/notebook_checks"
PROJECT = CHECK / "project"
source = ROOT / "data/raw/dominoes-v1"
destination = PROJECT / "data/raw/dominoes-v1"
destination.parent.mkdir(parents=True, exist_ok=True)
if not destination.exists():
    shutil.copytree(source, destination)

os.environ.update({"DOMINO_SKIP_INSTALL": "1", "DOMINO_NO_WIDGETS": "1",
                   "DOMINO_ML_ROOT": str(PROJECT), "DOMINO_WORK_DIR": str(CHECK / "work"),
                   "MPLCONFIGDIR": str(CHECK / "matplotlib"), "JUPYTER_RUNTIME_DIR": str(CHECK / "jupyter")})
for name in ["01_domino_detector", "02_pip_classifier"]:
    path = ROOT / "notebooks" / (name + ".ipynb")
    notebook = nbformat.read(path, as_version=4)
    nbformat.validate(notebook)
    client = NotebookClient(notebook, timeout=600, kernel_name="python3", resources={"metadata": {"path": str(ROOT)}})
    client.execute()
    out = CHECK / (name + ".executed.ipynb")
    nbformat.write(notebook, out)
    body, _ = HTMLExporter().from_notebook_node(notebook)
    (CHECK / (name + ".html")).write_text(body)
    images = []
    for index, cell in enumerate(notebook.cells):
        for output_index, output in enumerate(cell.get("outputs", [])):
            image = output.get("data", {}).get("image/png")
            if image:
                import base64
                image_path = CHECK / f"{name}-cell-{index}-{output_index}.png"
                image_path.write_bytes(base64.b64decode(image))
                images.append(str(image_path))
    print(json.dumps({"notebook": name, "executed_code_cells": sum(c.cell_type == "code" for c in notebook.cells),
                      "preview": str(CHECK / (name + ".html")), "figures": images}, indent=2), flush=True)
