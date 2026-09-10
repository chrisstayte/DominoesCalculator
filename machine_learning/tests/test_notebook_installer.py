"""Check that installation failures and loaded binary changes stop notebook execution."""
from contextlib import redirect_stdout
import importlib.util
import io
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import patch


class InstallerTests(unittest.TestCase):
    def setUp(self):
        source = Path(__file__).resolve().parents[1] / "notebook_sources/installer.py"
        spec = importlib.util.spec_from_file_location("installer", source)
        self.installer = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.installer)

    def test_loaded_numpy_change_requires_restart_even_on_retry(self):
        versions = {"numpy": "2.2.6"}

        def finish():
            versions["numpy"] = "2.1.3"
            return 0

        process = SimpleNamespace(stdout=io.StringIO("Successfully installed numpy-2.1.3\n"), wait=finish)
        with patch.dict(self.installer.os.environ, {"DOMINO_SKIP_INSTALL": "0"}), \
             patch.dict(self.installer.sys.modules, {"numpy": SimpleNamespace()}), \
             patch.object(self.installer, "package_version", side_effect=lambda name: versions.get(name)), \
             patch.object(self.installer.subprocess, "Popen", return_value=process) as popen, \
             redirect_stdout(io.StringIO()) as output:
            with self.assertRaisesRegex(RuntimeError, "Restart session"):
                self.installer.install_packages(["numpy==2.1.3"])
            with self.assertRaisesRegex(RuntimeError, "Restart session"):
                self.installer.install_packages(["numpy==2.1.3"])
            self.assertEqual(popen.call_count, 1)
            self.assertIn("Successfully installed", output.getvalue())

    def test_failed_install_displays_pip_error_and_stops(self):
        process = SimpleNamespace(stdout=io.StringIO("ERROR: No matching distribution found\n"), wait=lambda: 1)
        with patch.dict(self.installer.os.environ, {"DOMINO_SKIP_INSTALL": "0"}), \
             patch.object(self.installer.subprocess, "Popen", return_value=process), \
             redirect_stdout(io.StringIO()) as output:
            with self.assertRaisesRegex(RuntimeError, "installation failed"):
                self.installer.install_packages(["missing-package==1"])
            self.assertIn("ERROR: No matching distribution found", output.getvalue())

    def test_loaded_export_dependencies_change_requires_restart_before_export(self):
        versions = {"jax": "0.4.35", "jaxlib": "0.4.35", "torchao": "0.18.0"}

        def finish():
            versions.update(jax="0.6.2", jaxlib="0.6.2", torchao="0.14.1")
            return 0

        process = SimpleNamespace(stdout=io.StringIO("Successfully installed jax-0.6.2 jaxlib-0.6.2\n"), wait=finish)
        with patch.dict(self.installer.os.environ, {"DOMINO_SKIP_INSTALL": "0"}), \
             patch.dict(self.installer.sys.modules, {name: SimpleNamespace() for name in versions}), \
             patch.object(self.installer, "package_version", side_effect=lambda name: versions.get(name)), \
             patch.object(self.installer.subprocess, "Popen", return_value=process) as popen, \
             redirect_stdout(io.StringIO()) as output:
            with self.assertRaisesRegex(RuntimeError, "Restart session"):
                self.installer.install_packages(["jax==0.6.2", "jaxlib==0.6.2", "torchao==0.14.1"])
            with self.assertRaisesRegex(RuntimeError, "Restart session"):
                self.installer.install_packages(["jax==0.6.2", "jaxlib==0.6.2", "torchao==0.14.1"])
            self.assertEqual(popen.call_count, 1)
            self.assertIn("Loaded packages changed: jax, jaxlib, torchao", output.getvalue())

    def test_satisfied_loaded_packages_do_not_request_restart_on_rerun(self):
        versions = {"numpy": "2.1.3", "jax": "0.6.2", "jaxlib": "0.6.2", "torchao": "0.14.1"}

        def process(*args, **kwargs):
            return SimpleNamespace(stdout=io.StringIO("Requirement already satisfied\n"), wait=lambda: 0)

        with patch.dict(self.installer.os.environ, {"DOMINO_SKIP_INSTALL": "0"}), \
             patch.dict(self.installer.sys.modules, {name: SimpleNamespace() for name in versions}), \
             patch.object(self.installer, "package_version", side_effect=lambda name: versions.get(name)), \
             patch.object(self.installer.subprocess, "Popen", side_effect=process), \
             redirect_stdout(io.StringIO()) as output:
            for _ in range(2):
                self.installer.install_packages([f"{name}=={value}" for name, value in versions.items()])
            self.assertNotIn("Restart session", output.getvalue())
            self.assertFalse(getattr(self.installer, "_DOMINO_RESTART_REQUIRED", False))

    def test_prepared_environment_skips_installer(self):
        with patch.dict(self.installer.os.environ, {"DOMINO_SKIP_INSTALL": "1"}), \
             patch.object(self.installer.subprocess, "Popen") as popen:
            self.installer.install_packages(["numpy==2.1.3"])
            popen.assert_not_called()


if __name__ == "__main__":
    unittest.main()
