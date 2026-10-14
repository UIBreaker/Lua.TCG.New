"""Verify frozen scoring/UI/audio files without rewriting any protected source."""
import hashlib
import json
import re
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
baseline = json.loads((root / "docs/nen_magic/protected.json").read_text(encoding="utf-8-sig"))
failures = []
version_label = rb'g\.print\("beta 0\.\d+\.\d+", 48, 185\)'
original_main = subprocess.check_output(["git", "show", baseline["head"] + ":main.lua"], cwd=root)
for name, digest in baseline["files"].items():
    path = root / name
    if name == "main.lua" and path.is_file():
        # Release packaging changes only the menu version label.
        current = path.read_bytes().replace(b"\r\n", b"\n")
        original = original_main.replace(b"\r\n", b"\n")
        if re.sub(version_label, b"MENU_VERSION", current) != re.sub(version_label, b"MENU_VERSION", original):
            failures.append(name)
        continue
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != digest:
        failures.append(name)
assert not failures, f"Protected bytes changed: {failures}"
diff = subprocess.run(
    ["git", "diff", "--exit-code", baseline["head"], "--", *(name for name in baseline["files"] if name != "main.lua")],
    cwd=root, capture_output=True, check=False,
)
assert diff.returncode == 0, diff.stdout.decode("utf-8", errors="replace")
report = f"PASS: {len(baseline['files']) - 1} protected files byte-identical (SHA-256); main.lua unchanged except menu version. Baseline {baseline['head']}.\n"
(root / "docs/nen_magic/protection_results.txt").write_text(report, encoding="utf-8")
print(report)
