# Niệm light, surface and impact pass — 2026-10-11

Incremental upgrade of the existing 27 hands, six Nen families and 81 tier variants, based on `f192e52`. Existing trajectories, formation identities and procedural rendering remain the foundation.

## Presentation changes

- Removed polygon outlines, card-to-technique construction links, formation triangles, rank arrows, aiming brackets, etched fold lines and decorative geometry around Nen damage numbers. Meaningful lightning, orbit paths, constellations, weapon edges and magical seals remain.
- Guardians and riders use curved armor masses, smooth joints and local surface lighting. Mounted silhouettes gain a curved neck, muzzle and rounded leg joints. Cloth uses continuous moving strips. No sprite atlas or generated card art is introduced.
- Brighter steel, crystal and spectral surfaces retain shadow response. Broad moving glints and fine continuous grain replace blocky surface changes. LOW retains a shader-free fallback.
- Travel trails have tapered filled bands, a narrow luminous core and deterministic drifting sparkles. Water plumes and energy veins use curved strips with shared edges instead of zigzag strokes. Leading silhouettes remain visible until contact.
- Existing impacts gain a compact bright core, colored overlapping light lobes and outward fragments. Enhancement biases fragments along incoming motion; Emission expands faster; Transmutation and Conjuration use filled shards, with rotating conjured debris; Manipulation curls its wake; Specialization collapses toward a dark center. Each hand's existing contact silhouette remains as a quieter accent.
- Particles share the existing LOW/MEDIUM/HIGH budgets of 8/16/24. Reduced Motion reduces sparkles and fragment movement. All halos reuse the preloaded radial image; attack drawing creates no GPU resources.
- Shorter anticipation and recovery, six family acceleration curves, clearer contact recoil and less upper-tier camera movement. Impact audio gains a short transient and descending body; the existing 108-cue catalog and mixer remain.
- Nen damage numbers keep their pulse and readable outline, use the technique color and lose their surrounding wire crest/rings.

Hand recognition, damage, advanced bonuses, initiative, equipment, SPNs, resources and save data are unchanged.

## Verification

- `lovec tests/nen_runner`: passed. All 81 variants completed 10 consecutive logic sequences each (810 measured), plus 810 warm-up sequences. Coverage includes 30/60/144 FPS, quality modes, Fast/Skip/Reduced Motion, immutable snapshots, continuous launches, arrival, one release/contact and camera settle.
- Retained presentation heap: -1.3 KB after collection. The test disables LuaJIT compilation during both warm-up and measurement, then restores it, to exclude the process-wide trace cache. The original trace-enabled run reported 259.2 KB against the 250 KB threshold. Native rendering and benchmarking use normal JIT operation.
- Native Lab: all 81 variants × Normal/Fast = 162 completed after final geometry cleanup. Graphics state restoration, audio reload, missing optional cues and particle-budget assertions passed. HIGH normal pass, LOW/MEDIUM/HIGH fast pass, Reduced Motion on the third fast tier.
- Native real combat: six representative hands × three tiers × 10 consecutive repeats = 180 passed. A further 18 captures passed after final cleanup. HP ordering, input lock, bonuses, one release/contact, shader compilation and zero GPU creation during attack drawing passed.
- Audio: 108 synthesized cues passed distinctness, audible-energy and peak checks. These are PCM checks; a listening evaluation was not performed.
- Gameplay regression suites passed, including 11,232 Continental 52 scenarios, advanced hands, editions, equipment, SPNs, persistence and initiative.

`final_formation_1..5.jpg`, `final_attack_1..5.jpg`, `final_impact_1..5.jpg` and `final_aftermath_1..5.jpg` contain all 81 variants at four native capture stages. They were inspected for silhouette, unwanted lines, travel light, contact overlap and falloff. `combat/` contains three galleries covering 18 cases on the actual bright battle background, plus individual examples. The original 324 Lab and 72 combat PNGs were compacted into these review sheets. `preview_final.jpg` is a crop montage of actual gameplay captures.

The separate `benchmark.txt` run measures all 81 HIGH variants in Normal/Fast without screenshots or encoding: 21,792 frames, mean 6.06 ms, P95 6.78 ms, P99 7.06 ms, peak 9.89 ms; zero frames over 16.67 ms. Peak Lab draw calls: 316; particles: 24. `combat/performance.txt` includes capture/encoding and concurrent QA, so it is not a steady gameplay benchmark. Windows-host measurements do not establish Android performance; Android hardware has not been profiled for this pass.

## Reproduce

Create `docs/nen_vfx/juice/combat/`, then run from the project root:

```powershell
& '..\love-11.5-win64\lovec.exe' tests/nen_runner
& '..\love-11.5-win64\lovec.exe' . --test-hand-vfx --nen-lab --nen-juice
& '..\love-11.5-win64\lovec.exe' . --test-hand-vfx-combat --nen-juice --vfx-review
& '..\love-11.5-win64\lovec.exe' . --test-hand-vfx --nen-lab --nen-juice --nen-benchmark
```

`tests/nen_gallery.py <capture-directory> <phase>` rebuilds review sheets from PNG captures. JPEG galleries are QA artifacts, not game assets.
