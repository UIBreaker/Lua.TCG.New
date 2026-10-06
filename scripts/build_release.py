"""Package only runtime files. Pillow is needed only for the smaller phone/web assets."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import shutil
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
REVISION = "c4f04e185033a7c9fbefa9be3bec88c41a90421b"
VERSION = "0.83.3"


def runtime_files(root):
    for name in ("main.lua", "conf.lua", "LICENSE"):
        yield root / name
    for name in ("src", "ui", "render", "shaders", "config", "assets", "fonts"):
        for path in sorted((root / name).rglob("*")):
            if path.is_file() and path.suffix.lower() not in (".md", ".json", ".psd", ".log"):
                yield path


def packed_image(path, mobile):
    from PIL import Image
    with Image.open(path) as image:
        # UI atlases use pixel coordinates: keep their dimensions and alpha intact.
        if "ui" in path.relative_to(ROOT).parts:
            return path.read_bytes()
        image = image.convert("RGBA")
        if "scene" in path.parts and image.width > image.height:
            bounds = (1280, 720) if mobile else (1920, 1080)
        else:
            bounds = (256, 384) if mobile else (512, 768)
        image.thumbnail(bounds, Image.Resampling.LANCZOS)
        if path.suffix.lower() in (".jpg", ".jpeg"):
            output = io.BytesIO()
            image.convert("RGB").save(output, "JPEG", quality=94, subsampling=0, optimize=True)
            return output.getvalue()
        image = image.quantize(colors=192 if mobile else 256, method=Image.Quantize.FASTOCTREE)
        output = io.BytesIO()
        image.save(output, "PNG", optimize=True)
        return output.getvalue()


def package(target, mobile=False):
    from build_runtime_card_art import build
    build()
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in runtime_files(ROOT):
            if mobile and path.suffix == ".ogv":
                continue
            data = packed_image(path, mobile) if path.suffix.lower() in (".png", ".jpg", ".jpeg") else path.read_bytes()
            archive.writestr(path.relative_to(ROOT).as_posix(), data)
        if mobile:
            archive.writestr("mobile_build.flag", "phone/web build\n")
    with zipfile.ZipFile(target) as archive:
        assert archive.testzip() is None
        assert "main.lua" in archive.namelist() and not any(p.startswith("docs/") for p in archive.namelist())
    print(f"{target.name}: {target.stat().st_size / 1048576:.1f} MiB", flush=True)


def windows(love_file, runtime, out):
    assert (runtime / "love.exe").is_file(), "Pass the extracted LÖVE 11.5 Windows x64 runtime with --love-runtime"
    target = out / f"LUA-TCG-{VERSION}-Windows-x64.zip"
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED, compresslevel=1) as archive:
        archive.writestr("LUA-TCG/LUA-TCG.exe", (runtime / "love.exe").read_bytes() + love_file.read_bytes())
        for dll in runtime.glob("*.dll"):
            archive.write(dll, f"LUA-TCG/{dll.name}")
        archive.write(runtime / "license.txt", "LUA-TCG/LICENSE-LOVE.txt")
        archive.write(ROOT / "LICENSE", "LUA-TCG/LICENSE-game.txt")
        archive.writestr("LUA-TCG/README.txt", f"LUA.TCG {VERSION}\nExtract this entire ZIP, then open LUA-TCG.exe.\nKeep the DLL files next to the EXE. No LÖVE installation is required.\n")
    print(f"{target.name}: {target.stat().st_size / 1048576:.1f} MiB", flush=True)


def web(love_file, out):
    cache = out / "runtime"
    cache.mkdir(exist_ok=True)
    names = {"love.js": "src/compat/love.js", "love.wasm": "src/compat/love.wasm",
             "game-template.js": "src/game.js", "LICENSE-lovejs": "LICENSE"}
    for name, source in names.items():
        if not (cache / name).exists():
            url = f"https://raw.githubusercontent.com/Davidobot/love.js/{REVISION}/{source}"
            with urllib.request.urlopen(url) as response:
                (cache / name).write_bytes(response.read())
    destination = out / "web"
    destination.mkdir(exist_ok=True)
    data = love_file.read_bytes()
    metadata = {"package_uuid": hashlib.sha256(data).hexdigest(), "remote_package_size": len(data),
                "files": [{"filename": "/game.love", "start": 0, "end": len(data), "audio": False}]}
    template = (cache / "game-template.js").read_text(encoding="utf-8")
    template = template.replace("{{{metadata}}}", json.dumps(metadata)).replace("{{{create_file_paths}}}", "")
    assert "{{" not in template, "Unexpected love.js template field"
    (destination / "game.js").write_text(template, encoding="utf-8")
    (destination / "game.data").write_bytes(data)
    for name in ("love.js", "love.wasm", "LICENSE-lovejs"):
        shutil.copy2(cache / name, destination / name)
    # The upstream port syncs its IDBFS save only at beforeunload, which mobile
    # browsers may skip when the OS closes a background tab. Also sync periodically.
    engine = (destination / "love.js").read_text(encoding="utf-8")
    marker = 'FS.mount(IDBFS,{},"/home/web_user/love");'
    assert marker in engine, "Upstream save mount changed; review browser persistence"
    engine = engine.replace(marker, marker + 'var saveSyncBusy=false;function persistGame(){if(saveSyncBusy)return;saveSyncBusy=true;FS.syncfs(false,function(err){saveSyncBusy=false;if(err)Module["printErr"](err)})}setInterval(persistGame,10000);window.addEventListener("pagehide",persistGame);')
    (destination / "love.js").write_text(engine, encoding="utf-8")
    shutil.copy2(ROOT / "web/index.html", destination / "index.html")
    (destination / ".nojekyll").touch()
    print("Web build: dist/web", flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", choices=("windows", "mobile", "web", "all"), default="all")
    parser.add_argument("--love-runtime", type=Path, default=ROOT.parent / "love-11.5-win64")
    args = parser.parse_args()
    out = ROOT / "dist"
    out.mkdir(exist_ok=True)
    if args.target in ("windows", "all"):
        desktop = out / f"LUA-TCG-{VERSION}.love"
        package(desktop)
        windows(desktop, args.love_runtime, out)
    if args.target in ("mobile", "web", "all"):
        phone = out / f"LUA-TCG-{VERSION}-Mobile.love"
        package(phone, mobile=True)
        if args.target in ("web", "all"):
            web(phone, out)
    sums = []
    for path in sorted(out.glob("LUA-TCG-*")):
        if path.is_file():
            with path.open("rb") as stream:
                sums.append(f"{hashlib.file_digest(stream, 'sha256').hexdigest()}  {path.name}")
    (out / "SHA256SUMS.txt").write_text("\n".join(sums) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
