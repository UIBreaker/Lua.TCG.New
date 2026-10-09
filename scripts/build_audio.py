"""Render the original Continental sound library. Requires NumPy only at build time.

python scripts/build_audio.py [--check]
All seeds are local; rebuilding audio never consumes the game's random sequence.
"""
import argparse
import hashlib
import json
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/audio/continental"
RATE = 32000
TAU = 2 * np.pi
CUES = {}


def cue(name, kind, duration, freq=440, gain=.65, priority=3, cooldown=.035):
    CUES[name] = dict(kind=kind, duration=duration, freq=freq, gain=gain,
                      priority=priority, cooldown=cooldown)


for name, kind, duration, freq, gain in [
    ("ui_hover", "wood", .055, 690, .22), ("ui_click", "wood", .10, 390, .50),
    ("card_select", "paper", .11, 560, .50), ("card_deselect", "paper", .10, 380, .43),
    ("card_slide", "paper", .19, 260, .40), ("card_draw", "paper", .22, 610, .52),
    ("card_deal", "riffle", .27, 310, .48), ("card_play", "slam", .32, 150, .70),
    ("chip_tick", "glass", .19, 1174.66, .34), ("mult_pop", "pluck", .23, 587.33, .49),
    ("coin", "metal", .43, 1318.51, .55), ("score_impact", "impact", .52, 95, .77),
    ("damage_hit", "impact", .31, 155, .66), ("damage_heavy", "crush", .65, 72, .78),
    ("xmult_boom", "fusion", .75, 146.83, .71), ("jackpot", "fanfare", 1.25, 587.33, .68),
    ("round_win", "fanfare", 1.65, 293.66, .72), ("game_over", "fall", 1.85, 146.83, .68),
    ("shop_buy", "coins", .65, 1174.66, .58), ("shop_reroll", "riffle", .48, 390, .53),
    ("pack_open", "unseal", .82, 587.33, .66), ("chest_dissolve", "dust", .90, 466.16, .56),
    ("card_activate", "rune", .68, 783.99, .60), ("equip", "metal", .47, 587.33, .58),
    ("sell", "coins", .48, 880, .54), ("consume", "heal", .75, 392, .59),
    ("card_destroy", "shatter", .65, 311.13, .55), ("cant_afford", "wood", .22, 130.81, .48),
    ("armor_gain", "seal", .60, 587.33, .60), ("armor_loss", "shatter", .51, 880, .56),
    ("heal", "heal", .95, 523.25, .62), ("hurt", "crush", .36, 116.54, .66),
    ("enemy_prepare", "growl", .43, 110, .45), ("enemy_strike", "slash", .20, 220, .52),
    ("enemy_first", "growl", .55, 98, .57), ("player_first", "rune", .42, 659.25, .54),
    ("spn_trigger", "astral", .80, 311.13, .58), ("score_charge", "charge", .40, 196, .51),
    ("score_release", "wave", .32, 293.66, .56), ("score_hand", "seal", .38, 392, .52),
    ("bed_explosion_charge", "fuse", .38, 220, .50), ("bed_explosion_boom", "explosion", 1.10, 52, .88),
    ("bed_explosion_debris", "debris", .82, 350, .45), ("bed_explosion_rumble", "rumble", 1.45, 46, .55),
    ("enemy_death_hit", "crush", .70, 65, .72), ("enemy_ash_break", "dust", 1.05, 293.66, .51),
    ("defeat_hit", "crush", .82, 58, .73), ("defeat_collapse", "debris", 1.15, 180, .48),
    ("defeat_ambience", "astral", 2.60, 73.42, .32), ("defeat_text_reveal", "fall", 1.20, 196, .46),
    ("reward_coin_spawn", "glass", .17, 1567.98, .22), ("reward_coin_land", "metal", .21, 1760, .22),
    ("reward_coin_collect", "coins", .32, 1174.66, .45), ("reward_gold_total", "fanfare", .90, 440, .61),
    ("reward_loot_reveal", "rune", .61, 523.25, .46), ("reward_rare_reveal", "fanfare", 1.45, 783.99, .67),
    ("reward_chest_open", "unseal", 1.05, 392, .65),
]:
    priority = 1 if name == "ui_hover" else 2 if name.startswith(("card_", "reward_coin", "ui_")) or name == "chip_tick" else 5 if kind in ("impact", "crush", "explosion", "fanfare", "fall") else 3
    cue(name, kind, duration, freq, gain, priority, .065 if name.startswith("reward_coin") else .035)

HANDS = [
    ("high_card", "pierce", 293.66, ["highcard_compress"]),
    ("pair", "slash", 392, ["pair_slash_1", "pair_slash_2"]),
    ("two_pair", "orbit", 440, ["twopair_orbit_a", "twopair_orbit_b"]),
    ("three_of_a_kind", "rune", 311.13, ["threekind_node_1", "threekind_node_2", "threekind_node_3"]),
    ("straight", "chain", 293.66, [f"straight_step_{i}" for i in range(1, 6)]),
    ("flush", "wave", 196, ["flush_wave"]),
    ("full_house", "fusion", 146.83, ["fullhouse_core_a", "fullhouse_core_b", "fullhouse_core_merge"]),
    ("four_of_a_kind", "seal", 130.81, [f"fourkind_seal_{i}" for i in range(1, 5)]),
    ("straight_flush", "storm", 587.33, ["straightflush_blade_summon", "straightflush_barrage", "straightflush_final"]),
]
for i, (name, kind, freq, beats) in enumerate(HANDS):
    cue(name + "_charge", "charge" if i < 5 else "astral", .33 + i * .015, freq, .48, 3)
    cue(name + "_release", kind, .26 + i * .025, freq, .66, 4)
    cue(name + "_impact", kind, .48 + i * .065, freq * .5, .75, 5, .075)
    for j, beat in enumerate(beats):
        cue(beat, kind, .24 + i * .024, freq * 2 ** (j * 3 / 12), .51, 3, .025)


def tone(t, freq, decay=10, partials=(1, .30, .10), ratios=(1, 2, 3)):
    return sum(a * np.sin(TAU * freq * r * t) * np.exp(-t * decay * (1 + k * .18))
               for k, (a, r) in enumerate(zip(partials, ratios)))


def filtered_noise(n, rng, width=12, loop=False):
    raw = rng.normal(0, 1, n)
    if loop:
        return sum(np.roll(raw, i) for i in range(width)) / np.sqrt(width)
    return np.convolve(raw, np.ones(width) / np.sqrt(width), mode="same")


def effect(recipe, rng):
    d, f, kind = recipe["duration"], recipe["freq"], recipe["kind"]
    t = np.arange(round(d * RATE)) / RATE
    n = len(t)
    air = filtered_noise(n, rng, 9)
    hiss = filtered_noise(n, rng, 2)
    low = filtered_noise(n, rng, 150)
    sweep = np.sin(TAU * (f * t + f * .85 * t * t / d))
    swell = np.sin(np.pi * t / d) ** 1.5
    if kind == "wood":
        x = tone(t, f, 55, (1, .28, .16), (1, 1.47, 2.13)) + .5 * hiss * np.exp(-t * 190)
        if d > .15: x += .6 * tone(np.maximum(0, t - .095), f * .79, 45) * (t >= .095)
    elif kind in ("paper", "riffle", "slam"):
        rustle = (hiss - .6 * air) * swell * .50
        if kind == "riffle": rustle *= (.15 + .85 * np.maximum(0, np.sin(TAU * 42 * t)) ** 8)
        x = rustle + .24 * tone(t, f, 48)
        at = d * .62
        x += .48 * tone(np.maximum(0, t - at), 120 if kind == "slam" else 230, 32) * (t >= at)
        if kind == "slam": x += .4 * low * np.exp(-t * 19)
    elif kind in ("glass", "metal", "pluck", "coins"):
        ratios = (1, 2.76, 4.07) if kind in ("metal", "coins") else (1, 2, 3)
        x = tone(t, f, 12 if kind == "metal" else 18, (1, .27, .08), ratios)
        x += .18 * hiss * np.exp(-t * 160)
        if kind == "coins":
            for at, r in ((.065, 1.25), (.13, 1.5), (.23, 2)):
                u = np.maximum(0, t - at)
                x += .48 * tone(u, f * r, 19, (1, .24, .08), ratios) * (t >= at)
    elif kind in ("impact", "crush", "explosion", "rumble", "debris", "shatter", "dust"):
        decay = 6 if kind in ("explosion", "rumble") else 13
        phase = TAU * (f * t + (f * .32 - f) * t * t / (2 * d))
        x = .85 * np.sin(phase) * np.exp(-t * decay) + .55 * low * np.exp(-t * decay * 1.1)
        x += .37 * hiss * np.exp(-t * (23 if kind == "explosion" else 65))
        if kind in ("crush", "debris", "shatter"):
            for at in rng.uniform(.025, d * .8, 9):
                u = np.maximum(0, t - at)
                x += .18 * (tone(u, f * rng.uniform(2, 7), 55, (1, .3, .1), (1, 1.6, 2.8)) + hiss * np.exp(-u * 80)) * (t >= at)
        if kind == "dust": x = .45 * air * swell + .35 * sweep * np.exp(-t * 8)
        if kind == "rumble": x *= np.minimum(1, t * 30)
    elif kind in ("fanfare", "fall", "heal", "unseal", "rune", "seal", "astral"):
        notes = (1, 1.25, 1.5, 2) if kind in ("fanfare", "heal", "unseal") else (1, 1.5, 2)
        if kind == "fall": notes = (1.5, 1.25, 1, .75)
        if kind == "astral": notes = (1, 1.498, 2.01, 2.994)
        x = np.zeros(n)
        for j, r in enumerate(notes):
            at = j * d * .12
            u = np.maximum(0, t - at)
            env = np.minimum(1, u * (25 if kind in ("heal", "astral") else 150))
            x += .42 * tone(u, f * r, 4.5 if kind == "astral" else 7, (1, .23, .12), (1, 2.003, 3.01)) * env * (t >= at)
        if kind in ("seal", "unseal"): x += .32 * low * np.exp(-t * 25) + .25 * hiss * np.exp(-t * 35)
        if kind == "rune": x += .20 * sweep * swell
        if kind == "astral": x += .22 * np.sin(TAU * f * .5 * t) * swell
    elif kind in ("charge", "fuse", "growl"):
        x = .40 * sweep * swell + .27 * air * swell
        if kind == "fuse": x += .36 * hiss * np.maximum(0, np.sin(TAU * (22 * t + 28 * t * t))) ** 10
        if kind == "growl": x = .55 * low * swell + .42 * np.tanh(2 * np.sin(TAU * f * t)) * swell
    else:
        x = .35 * air * swell
        if kind in ("slash", "pierce", "storm"):
            x += .36 * hiss * np.exp(-((t / d - .28) / .12) ** 2)
            x += .35 * tone(t, f, 14, (1, .32, .15), (1, 2.71, 4.16))
            if kind == "storm": x *= .4 + .6 * np.sin(TAU * 18 * t) ** 4
        if kind == "orbit": x += .5 * sweep * swell * (.5 + .5 * np.sin(TAU * 9 * t) ** 2)
        if kind == "wave": x += .6 * low * swell + .25 * np.sin(TAU * f * t) * swell
        if kind == "chain": x += .6 * tone(t, f, 12, (1, .4, .12), (1, 2.76, 4.07))
        if kind == "fusion": x += .70 * tone(t, f * .5, 8) + .4 * sweep * np.exp(-t * 6)
    # Every effect has a click-free envelope; room reflections give it a material.
    x *= np.minimum(1, t * 650) * np.minimum(1, (d - t) * 45)
    return stereo(x, wet=.12 if kind in ("paper", "wood", "riffle") else .24)


def stereo(x, wet=.22, loop=False):
    y = np.column_stack((x, x))
    for seconds, amount in ((.031, .65), (.067, .42), (.113, .28), (.173, .16)):
        shift = round(seconds * RATE)
        if shift >= len(x): continue
        delayed = np.roll(x, shift)
        if not loop: delayed[:shift] = 0
        y[:, 0] += delayed * wet * amount
        delayed = np.roll(x, shift + 173)
        if not loop: delayed[:min(len(x), shift + 173)] = 0
        y[:, 1] += delayed * wet * amount * .85
    return y


def add_note(y, at, duration, midi, instrument, amplitude, pan=0):
    t = np.arange(round(duration * RATE)) / RATE
    f = 440 * 2 ** ((midi - 69) / 12)
    if instrument == "strings":
        vibrato = .003 * np.sin(TAU * 4.7 * t)
        phase = TAU * f * t + vibrato * np.sin(TAU * f * t)
        x = sum(np.sin(phase * h) / h ** 1.6 for h in range(1, 6))
        x *= np.minimum(1, t * 3) * np.minimum(1, (duration - t) * 2)
    elif instrument == "choir":
        x = sum(np.sin(TAU * f * r * t) * a for r, a in ((.998, .4), (1.002, .4), (2, .12), (3, .06)))
        x *= np.sin(np.pi * t / duration) ** .8
    elif instrument == "bass":
        x = tone(t, f, 2.2, (1, .15, .05)) * np.minimum(1, t * 80)
    else:
        x = tone(t, f, 3.7 if instrument == "harp" else 6, (1, .3, .09), (1, 2, 3) if instrument == "harp" else (1, 2.003, 4.01))
        x *= np.minimum(1, t * 180)
    x *= np.minimum(1, (duration - t) * 25) * amplitude
    idx = (np.arange(len(t)) + round(at * RATE)) % len(y)
    np.add.at(y[:, 0], idx, x * np.sqrt((1 - pan) / 2))
    np.add.at(y[:, 1], idx, x * np.sqrt((1 + pan) / 2))


MUSIC = {"exploration": (96, .20), "combat": (120, .28), "boss": (120, .31),
         "tension": (120, .18), "shop": (80, .18), "rest": (64, .16),
         "mystery": (80, .19), "victory": (96, .23), "defeat": (64, .17)}


def music(name, rng):
    bpm, _ = MUSIC[name]
    beat = 60 / bpm
    y = np.zeros((round(32 * beat * RATE), 2))
    roots = [50, 46, 53, 48, 50, 46, 48, 45]
    if name in ("shop", "victory"): roots = [50, 55, 59, 57, 50, 55, 52, 57]
    melody = [0, 7, 12, 10, 7, 3, 5, 7, 0, 3, 7, 10, 12, 7, 5, 3]
    for bar, root in enumerate(roots):
        at = bar * 4 * beat
        if name != "tension":
            major = name in ("shop", "victory")
            for k, interval in enumerate((0, 4 if major else 3, 7)):
                add_note(y, at, 4.8 * beat, root + interval, "choir" if name in ("mystery", "defeat") else "strings", .075, (k - 1) * .48)
            add_note(y, at, 3.8 * beat, root - 12, "bass", .17, 0)
            count = 8 if name in ("combat", "boss", "exploration") else 4
            for j in range(count):
                interval = (0, 7, 12, 4 if major else 3)[j % 4]
                add_note(y, at + j * 4 * beat / count, 1.7 * beat, root + 12 + interval, "harp", .10, .48 if j % 2 else -.48)
            if name not in ("defeat", "mystery"):
                for j in range(2):
                    add_note(y, at + (j * 2 + .5) * beat, 2.4 * beat, 62 + melody[(bar * 2 + j) % len(melody)], "bell", .095, -.18)
        if name in ("combat", "boss", "tension", "exploration", "victory"):
            for j in range(4):
                t = np.arange(round(beat * .7 * RATE)) / RATE
                drum = np.sin(TAU * (72 * t - 38 * t * t)) * np.exp(-t * 16)
                drum += filtered_noise(len(t), rng, 5) * np.exp(-t * 60) * .16
                amp = .24 if name == "boss" else .15 if name in ("combat", "tension") else .065
                idx = (np.arange(len(t)) + round((at + j * beat) * RATE)) % len(y)
                y[idx] += (drum * amp)[:, None]
                if name == "tension":
                    add_note(y, at + j * beat + .25 * beat, .6 * beat, 38, "bass", .13)
            if name == "boss":
                for k in (0, 7): add_note(y, at, 3.5 * beat, root + k, "choir", .16, -.25 if k == 0 else .25)
    # Wrapped reverberation preserves tails across the exact musical loop boundary.
    dry = y.copy()
    for sec, amount in ((.127, .20), (.283, .14), (.431, .09), (.677, .05)):
        y += np.roll(dry[:, ::-1], round(sec * RATE), axis=0) * amount
    return y


AMBIENCE = ("ruins", "sea", "forest", "ice", "desert", "void", "volcanic", "mystic", "rain", "storm")


def ambience(name, rng):
    d = 12
    t = np.arange(d * RATE) / RATE
    low = filtered_noise(len(t), rng, 400, loop=True)
    air = filtered_noise(len(t), rng, 20, loop=True)
    # Periodic swells and wrapped noise avoid an audible loop seam.
    swell = .6 + .4 * np.sin(TAU * t / d) ** 2
    x = .14 * low * swell + .05 * air
    if name == "sea":
        x = .22 * low * swell + .13 * air * (.2 + .8 * np.sin(TAU * t / 6) ** 4)
    elif name == "forest":
        x *= .6
        for at in (1.2, 4.7, 8.5):
            u = (t - at) % d
            x += .08 * np.sin(TAU * (2100 * u + 550 * u * u)) * np.exp(-u * 12) * np.sin(np.minimum(u * 15, np.pi)) ** 2
    elif name == "ice":
        x += .07 * np.sin(TAU * 740 * t) * np.sin(TAU * t / d) ** 12
    elif name == "desert": x = .18 * low * swell + .06 * air * swell
    elif name in ("void", "mystic"):
        x *= .5
        for f in (55, 82.5, 110): x += .07 * np.sin(TAU * f * t) * (.7 + .3 * np.sin(TAU * t / d))
        if name == "mystic": x += .025 * np.sin(TAU * 880 * t) * np.sin(TAU * t / 6) ** 6
    elif name == "volcanic":
        x += .16 * np.sin(TAU * 40 * t) * swell + .045 * air * np.sin(TAU * 3 * t) ** 12
    elif name in ("rain", "storm"):
        x = .15 * air + .06 * filtered_noise(len(t), rng, 2, loop=True)
        if name == "storm": x += .27 * low * np.sin(TAU * t / d) ** 18
    return stereo(x, .40, loop=True)


def seed(name):
    return np.random.default_rng(int.from_bytes(hashlib.sha256(name.encode()).digest()[:8], "little"))


def write_audio(path, samples, peak, loop=False):
    samples -= np.mean(samples, axis=0)
    samples *= peak / max(.001, np.max(np.abs(samples)))
    if not loop:
        n = min(256, len(samples) // 4)
        samples[:n] *= np.linspace(0, 1, n)[:, None]
        samples[-n:] *= np.linspace(1, 0, n)[:, None]
    assert np.isfinite(samples).all() and np.max(np.abs(samples)) < .9
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as f:
        f.setparams((2, 2, RATE, len(samples), "NONE", "not compressed"))
        f.writeframes(np.round(samples * 32767).astype("<i2").tobytes())
    return {"path": path.relative_to(ROOT).as_posix(), "seconds": len(samples) / RATE,
            "peak": float(np.max(np.abs(samples))), "rms": float(np.sqrt(np.mean(samples ** 2))),
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}


def build():
    manifest = {"description": "Original deterministic Continental DSP compositions; no third-party samples.",
                "sampleRate": RATE, "channels": 2, "bits": 16, "sfx": {}, "music": {}, "ambience": {}}
    lines = ["-- Generated by scripts/build_audio.py; edit recipes there, then rebuild.", "return {", "    cues = {"]
    for name, recipe in CUES.items():
        meta = write_audio(OUT / "sfx" / (name + ".wav"), effect(recipe, seed(name)), .64)
        manifest["sfx"][name] = {**meta, **recipe}
        lines.append(f'        {name} = {{path="{meta["path"]}", gain={recipe["gain"]}, priority={recipe["priority"]}, cooldown={recipe["cooldown"]}}},')
    lines += ["    },", "    music = {"]
    lines.append('        menu = {path="assets/audio/menu_theme.mp3", gain=0.38},')
    for name, (_, gain) in MUSIC.items():
        meta = write_audio(OUT / "music" / (name + ".wav"), music(name, seed(name)), .48, loop=True)
        manifest["music"][name] = meta
        lines.append(f'        {name} = {{path="{meta["path"]}", gain={gain}}},')
    lines += ["    },", "    ambience = {"]
    for name in AMBIENCE:
        meta = write_audio(OUT / "ambience" / (name + ".wav"), ambience(name, seed(name)), .32, loop=True)
        manifest["ambience"][name] = meta
        lines.append(f'        {name} = {{path="{meta["path"]}", gain=0.25}},')
    lines += ["    },", "}"]
    (ROOT / "config/audio_catalog.lua").write_text("\n".join(lines) + "\n", encoding="utf-8")
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    reel = np.zeros((RATE * 20, 2))
    for i, name in enumerate(("card_draw", "shop_buy", "heal", "pair_release", "flush_impact", "straight_flush_impact", "bed_explosion_boom", "reward_rare_reveal", "round_win")):
        x = effect(CUES[name], seed(name)) * .32
        start = round((.5 + i * 2.05) * RATE)
        reel[start:start + len(x)] += x
    write_audio(ROOT / "docs/audio/continental_preview.wav", reel, .64)
    check()


def check():
    manifest = json.loads((OUT / "manifest.json").read_text())
    hashes = set()
    count = 0
    for section in ("sfx", "music", "ambience"):
        for name, meta in manifest[section].items():
            path = ROOT / meta["path"]
            assert hashlib.sha256(path.read_bytes()).hexdigest() == meta["sha256"], name
            assert meta["sha256"] not in hashes, f"Duplicate audio: {name}"
            hashes.add(meta["sha256"])
            with wave.open(str(path)) as f:
                assert f.getnchannels() == 2 and f.getframerate() == RATE and f.getsampwidth() == 2
                pcm = np.frombuffer(f.readframes(f.getnframes()), "<i2").reshape(-1, 2) / 32768
            assert 0 < np.max(np.abs(pcm)) < .9 and np.sqrt(np.mean(pcm ** 2)) > .001, name
            if section == "sfx": assert np.max(np.abs(pcm[[0, -1]])) == 0, name
            else: assert np.max(np.abs(pcm[0] - pcm[-1])) < .06, f"Loop discontinuity: {name}"
            count += 1
    print(f"Audio PASS: {count} distinct stereo WAVs; hashes, headroom, energy, envelopes and loop seams checked.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    check() if args.check else build()
