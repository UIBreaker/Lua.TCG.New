"""Embed the phone game in official LÖVE 11.5a, then align and privately sign it.

Requires Java 17, APKTool 3.0.3 and Android build-tools 35.0.0.
Keep .android-signing/ backed up privately: future updates must use the same key.
"""
import argparse
import ctypes
import hashlib
import io
import os
from pathlib import Path
import secrets
import subprocess
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ANDROID = "{http://schemas.android.com/apk/res/android}"
PACKAGE = "com.uibreaker.terrasuit"
BUILD_CWD = str(ROOT)
if os.name == "nt":
    short = ctypes.create_unicode_buffer(32768)
    if ctypes.windll.kernel32.GetShortPathNameW(str(ROOT), short, len(short)):
        BUILD_CWD = short.value


def run(*args):
    # Java 17 on Windows can mangle non-ASCII absolute paths in CLI arguments.
    arguments = [str(a.relative_to(ROOT)) if isinstance(a, Path) and a.is_relative_to(ROOT) else str(a) for a in args]
    subprocess.run(arguments, check=True, cwd=BUILD_CWD)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tools", type=Path, default=ROOT / "dist/android-tools")
    parser.add_argument("--game", type=Path, help="Optional freshly built game; every Lua file must match current source")
    args = parser.parse_args()
    from build_release import package, runtime_files
    if args.game is None:
        args.game = ROOT / "dist/LUA-TCG-0.88.7-Mobile.love"
        package(args.game, mobile=True)
    with zipfile.ZipFile(args.game) as game:
        for path in runtime_files(ROOT):
            if path.suffix == ".lua":
                assert game.read(path.relative_to(ROOT).as_posix()) == path.read_bytes(), f"Stale packaged source: {path.name}"
    tools = args.tools.resolve()
    work = ROOT / "dist" / ("android-build-" + secrets.token_hex(4))
    assert not work.exists(), "Build directory must be fresh"
    sdk = tools / "sdk/android-15"
    suffix = ".exe" if os.name == "nt" else ""
    run("java", "-jar", tools / "apktool.jar", "d", "-s", "-o", work, tools / "love-embed.apk")
    manifest = ET.parse(work / "AndroidManifest.xml")
    root = manifest.getroot()
    root.set("package", PACKAGE)
    for permission in list(root.findall("uses-permission")):
        root.remove(permission)
    # No network, microphone or external-storage permissions are needed offline.
    for permission in root.findall("permission"):
        name = permission.get(ANDROID + "name").replace("org.love2d.android", PACKAGE)
        permission.set(ANDROID + "name", name)
        ET.SubElement(root, "uses-permission", {ANDROID + "name": name})
    app = root.find("application")
    app.set(ANDROID + "label", "Terra Suit")
    app.set(ANDROID + "usesCleartextTraffic", "false")
    app.set(ANDROID + "maxAspectRatio", "3.0")
    for activity in app.findall("activity"):
        activity.set(ANDROID + "label", "Terra Suit")
        activity.set(ANDROID + "screenOrientation", "landscape")
        activity.set(ANDROID + "maxAspectRatio", "3.0")
        activity.set(ANDROID + "theme", "@style/TerraSuitFullscreen")
    for provider in app.findall("provider"):
        provider.set(ANDROID + "authorities", provider.get(ANDROID + "authorities").replace("org.love2d.android", PACKAGE))
    ET.register_namespace("android", "http://schemas.android.com/apk/res/android")
    manifest.write(work / "AndroidManifest.xml", encoding="utf-8", xml_declaration=True)
    for folder, cutout in (("values", ""), ("values-v28", '<item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>')):
        target = work / "res" / folder
        target.mkdir(exist_ok=True)
        (target / "terrasuit_fullscreen.xml").write_text(
            '<resources><style name="TerraSuitFullscreen" parent="@android:style/Theme.NoTitleBar.Fullscreen">'
            '<item name="android:windowFullscreen">true</item>' + cutout + '</style></resources>', encoding="utf-8")
    metadata = work / "apktool.yml"
    text = metadata.read_text(encoding="utf-8").replace("versionCode: 32", "versionCode: 887")
    text = text.replace("versionName: 11.5a", "versionName: 0.88.7-beta").replace("minSdkVersion: 16", "minSdkVersion: 23")
    metadata.write_text(text, encoding="utf-8")
    # Boot in immersive mode too, before Lua initializes or restores old settings.
    with zipfile.ZipFile(args.game) as source, zipfile.ZipFile(work / "assets/game.love", "w", zipfile.ZIP_DEFLATED) as bundled:
        for entry in source.infolist():
            data = source.read(entry.filename)
            if entry.filename == "conf.lua":
                data = data.replace(b"t.window.fullscreen = false", b"t.window.fullscreen = true")
                # SDL may override the manifest orientation when resizable is true.
                data = data.replace(b"t.window.resizable = true", b"t.window.resizable = false")
            bundled.writestr(entry, data)
    from PIL import Image, ImageOps
    with Image.open(ROOT / "assets/cards/continental/back/card_back.png") as source:
        for icon in (work / "res").glob("drawable-*/love.png"):
            with Image.open(icon) as old:
                size = old.size
            ImageOps.fit(source.convert("RGBA"), size).save(icon)
    unsigned = ROOT / "dist/android-unsigned.apk"
    aligned = ROOT / "dist/android-aligned.apk"
    run("java", "-jar", tools / "apktool.jar", "b", work, "-o", unsigned)
    run(sdk / ("zipalign" + suffix), "-P", "16", "-f", "4", unsigned, aligned)
    signing = ROOT / ".android-signing"
    signing.mkdir(exist_ok=True)
    key, password = signing / "release.jks", signing / "password.txt"
    assert key.exists() == password.exists(), "Signing key/password pair is incomplete"
    if not key.exists():
        password.write_text(secrets.token_urlsafe(32), encoding="ascii")
        os.environ["TERRA_SIGNING_PASSWORD"] = password.read_text(encoding="ascii")
        run("keytool", "-genkeypair", "-noprompt", "-keystore", key, "-alias", "terrasuit",
            "-keyalg", "RSA", "-keysize", "3072", "-validity", "10000", "-storetype", "PKCS12",
            "-storepass:env", "TERRA_SIGNING_PASSWORD", "-dname", "CN=Terra Suit, OU=Game, O=UIBreaker, C=VN")
        del os.environ["TERRA_SIGNING_PASSWORD"]
    output = ROOT / "downloads/LUA-TCG-0.88.7-Android.apk"
    output.parent.mkdir(exist_ok=True)
    signer = sdk / "lib/apksigner.jar"
    run("java", "-jar", signer, "sign", "--ks", key, "--ks-pass", "file:" + str(password.relative_to(ROOT)),
        "--v4-signing-enabled", "false", "--out", output, aligned)
    run("java", "-jar", signer, "verify", "--verbose", "--print-certs", output)
    run(sdk / ("zipalign" + suffix), "-c", "-P", "16", "4", output)
    with zipfile.ZipFile(output) as apk:
        assert apk.testzip() is None
        with zipfile.ZipFile(io.BytesIO(apk.read("assets/game.love"))) as game, zipfile.ZipFile(args.game) as source:
            assert b"t.window.fullscreen = true" in game.read("conf.lua")
            assert b"t.window.resizable = false" in game.read("conf.lua")
            assert b"beta 0.88.7" in game.read("main.lua")
            assert game.read("main.lua") == source.read("main.lua")
        assert all(f"lib/{abi}/liblove.so" in apk.namelist() for abi in ("arm64-v8a", "armeabi-v7a"))
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix(".apk.sha256").write_text(f"{digest}  {output.name}\n", encoding="ascii")
    print(f"Signed Android APK: {output.stat().st_size / 1048576:.1f} MiB")


if __name__ == "__main__":
    main()
