"""Embedded in each notebook's setup cell; uses only the standard library."""
import os
import subprocess
import sys
from importlib.metadata import PackageNotFoundError, version as package_version


NUMPY_REQUIREMENT = "numpy==2.1.3" if sys.version_info >= (3, 13) else "numpy==1.26.4"
TENSORFLOW_REQUIREMENT = "tensorflow==2.20.0" if sys.version_info >= (3, 13) else "tensorflow==2.19.1"
KERAS_REQUIREMENT = "keras==3.10.0" if sys.version_info >= (3, 13) else "keras==3.9.2"


def install_packages(requirements):
    if os.environ.get("DOMINO_SKIP_INSTALL") == "1":
        return
    if not (3, 10) <= sys.version_info[:2] <= (3, 13):
        raise RuntimeError("Use a Python 3.10–3.13 runtime for these pinned packages.")
    if sys.platform == "darwin" and sys.version_info >= (3, 13):
        raise RuntimeError("Use Colab for Python 3.13, or Python 3.12 for local macOS runs.")
    restart_message = "Choose Runtime → Restart session, then rerun setup before continuing."
    if globals().get("_DOMINO_RESTART_REQUIRED"):
        raise RuntimeError(restart_message)

    def installed(name):
        try:
            return package_version(name)
        except PackageNotFoundError:
            return None

    modules = {"numpy": "numpy", "pandas": "pandas", "matplotlib": "matplotlib",
               "pillow": "PIL", "opencv-python": "cv2", "torch": "torch",
               "torchvision": "torchvision", "tensorflow": "tensorflow", "keras": "keras",
               "scipy": "scipy", "scikit-learn": "sklearn", "h5py": "h5py"}
    loaded = {name: installed(name) for name, module in modules.items() if module in sys.modules}
    print("Installing packages for Python", sys.version.split()[0], "— progress follows:", flush=True)
    command = [sys.executable, "-u", "-m", "pip", "install",
               "--only-binary=numpy,pandas", *requirements]
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    try:
        for line in process.stdout:
            print(line, end="", flush=True)
        returncode = process.wait()
    except KeyboardInterrupt:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
        raise
    finally:
        process.stdout.close()

    # Colab can preload NumPy. Changing files on disk cannot replace its loaded extensions.
    changed = [name for name, previous in loaded.items() if installed(name) != previous]
    if changed:
        globals()["_DOMINO_RESTART_REQUIRED"] = True
        print("Loaded packages changed:", ", ".join(changed), flush=True)
    if returncode:
        raise RuntimeError("Package installation failed. Read the pip error above before continuing. "
                           + (restart_message if changed else ""))
    if changed:
        raise RuntimeError("Installation finished. " + restart_message)
    print("Installation finished. Continue to configuration.", flush=True)
