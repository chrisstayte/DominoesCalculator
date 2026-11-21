"""Build two self-contained notebooks from reviewable percent-format Python sources.

Run: python machine_learning/scripts/build_notebooks.py (requires nbformat).
"""
from pathlib import Path
import ast
import re
import nbformat

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "notebook_sources"
OUT = ROOT / "notebooks"


def build(name, filename):
    sections = re.split(r"^# %%([^\n]*)\n", (SOURCE / filename).read_text(), flags=re.MULTILINE)
    cells = []
    for kind, body in zip(sections[1::2], sections[2::2]):
        if "shared" in kind:
            body = (SOURCE / "common.py").read_text()
            cell = nbformat.v4.new_code_cell(body.strip(), metadata={"tags": ["helpers"], "jupyter": {"source_hidden": True}})
        elif "markdown" in kind:
            body = "\n".join(line[2:] if line.startswith("# ") else line[1:] if line.startswith("#") else line for line in body.splitlines())
            cell = nbformat.v4.new_markdown_cell(body.strip())
        else:
            if "setup" in kind:
                body = (SOURCE / "installer.py").read_text() + "\n\n" + body
            ast.parse(body)
            cell = nbformat.v4.new_code_cell(body.strip())
        # Stable IDs keep regenerated diffs small.
        cell["id"] = f"{name[:3]}-{len(cells):03d}"
        cells.append(cell)
    notebook = nbformat.v4.new_notebook(cells=cells, metadata={
        "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
        "language_info": {"name": "python", "version": "3.12"},
        "colab": {"provenance": [], "name": name + ".ipynb"},
        "accelerator": "GPU",
    })
    nbformat.validate(notebook)
    OUT.mkdir(exist_ok=True)
    path = OUT / f"{name}.ipynb"
    nbformat.write(notebook, path)
    print(path)


if __name__ == "__main__":
    build("01_domino_detector", "detector.py")
    build("02_pip_classifier", "classifier.py")
