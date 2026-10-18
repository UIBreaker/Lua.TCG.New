"""python tests/test_release_packaging.py"""
from pathlib import Path
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from build_android import write_parts

with tempfile.TemporaryDirectory() as folder:
    apk = Path(folder) / "test.apk"
    apk.write_bytes(b"0123456789")
    note = apk.with_name("test.apk.part-notes")
    note.write_text("keep")
    write_parts(apk, 4)
    assert [p.read_bytes() for p in sorted(apk.parent.glob("*.part[0-9][0-9]"))] == [b"0123", b"4567", b"89"]
    apk.write_bytes(b"xy")
    write_parts(apk, 4)
    assert [p.read_bytes() for p in sorted(apk.parent.glob("*.part[0-9][0-9]"))] == [b"xy"]
    assert note.read_text() == "keep"
print("Release parts PASS: small APKs, exact reconstruction, shrinking rebuild removes only stale generated parts")
