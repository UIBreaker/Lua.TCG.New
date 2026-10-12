# Combat number feedback

`src/combat_feedback.lua` draws resolved values without changing damage, armor, or gold rules.

- Below 100 — BÌNH THƯỜNG: compact ivory number, warm glow, no subtitle. Tens have a stronger glow/scale and two small gold glints flanking the value; single digits stay plain.
- 100–999 — CỰC MẠNH: light fire around all four sides of the number.
- 1,000–9,999 — BÙNG NỔ: stronger fire with rising embers.
- 10,000–99,999 — SIÊU VIỆT: strong fire and three branching lightning paths around the number.
- 100,000 — TUYỆT ĐỈNH starts with eight branched lightning arcs and a moving holographic finish inside the glyphs. Each higher decimal magnitude has its own stronger profile; it no longer shares a single capped treatment.

`F.tier` retains the five approved style families. `F.magnitude` and each number's `power.degree` distinguish every decimal order, including negative amounts by absolute value. Thresholds are parsed from decimal notation and compared directly, avoiding logarithm and exponent rounding at boundaries. Effect strength follows the resolved damage, independently of Nen strength.

| Minimum damage | Magnitude | Lightning paths |
| --- | --- | --- |
| 1 | Đơn vị | 0 |
| 10 | Chục | 0 |
| 100 | Trăm | 0 |
| 1,000 | Nghìn | 0 |
| 10,000 | Chục nghìn | 3 |
| 100,000 | Trăm nghìn | 8 |
| 1,000,000 | Triệu | 9 |
| 10,000,000 | Chục triệu | 10 |
| 100,000,000 | Trăm triệu | 11 |
| 1,000,000,000 | Tỉ | 12 |
| 10,000,000,000 | Chục tỉ | 13 |
| 100,000,000,000 | Trăm tỉ | 14 |
| 1,000,000,000,000 | Nghìn tỉ | 15 |
| 10,000,000,000,000 | Chục nghìn tỉ | 16 |
| 100,000,000,000,000 | Trăm nghìn tỉ | 17 |
| 1,000,000,000,000,000 | Triệu tỉ | 18 |

Every higher order increases scale and glow, with fire extent increasing from hundreds onward. Above a hundred thousand, flame turbulence/heat, rising ember density, lightning spread/thickness/afterglow, foil saturation/sheen and animation speed increase. From ten billion, each lightning path has three secondary branches. Higher magnitudes continue beyond a million billion, approaching bounded visual limits: 20 paths, three branches per path, 30 embers, less than 69 local pixels of fire reach, less than 1.5 base scale and less than 2.5 seconds lifetime. These limits constrain transient drawing, not gameplay damage. The subtitle includes the magnitude so adjacent high tiers are identifiable.

Each order also has a distinct accent and signature, rather than just more identical arcs. In ascending order from tens: gold glints, amber flame, crimson flame, blue lightning, violet holographic lightning, solar gold, turquoise, rose, sapphire, amethyst, white gold, ice blue, molten orange, emerald and opal. Fire keeps its hot warm core while the perimeter takes on the accent. Lightning sweep/orientation, flame noise frequency and holographic band spacing/phase change with each order. From millions, rotating corona glints surround the outer flame, increasing up to eight. Above the authored orders, deterministic spectral accents and distinct phases continue through the finite numeric range; geometry stays bounded. All effects stay attached to the value and do not consume gameplay RNG.

Android/iOS and the mobile package use the existing `Touch.lowPower` flag. Every order keeps the same palette, flame size/turbulence, corona and holographic identity. Mobile draws at most 12 lightning paths, two branches per path and 18 embers; it does not disable the upper style families. Both shared shaders are validated as OpenGL ES in the GPU capture test. If compilation fails on a device, accented animated ember rims, lightning and corona still render without shaders. `damage_magnitudes_mobile.png` shows all orders with the mobile budget; `damage_mobile.png` compares shader and fallback rendering on a 960×540 canvas. These desktop GPU checks do not replace testing on a physical Android device.

Android fire robustness (0.125.1): the procedural pass uses one cached four-vertex mesh with local coordinates, avoiding framebuffer orientation/DPI assumptions and immediate-mode transform baking. Noise helpers explicitly use high precision on GLES without changing LÖVE's effect function precision contract. Mobile also renders a bounded native flame layer (at most 24 tongues) even when the shader exists; a silently incorrect shader cannot remove all fire. The no-shader path uses brighter moving flame tongues with hot cores rather than faint static ellipses. GPU tests count visible warm pixels at 100, 250, 1,000, 7,700 and 9,999 in desktop, mobile and genuinely shader-disabled modes under rotation/nonuniform scaling; compilation success alone is insufficient. Mesh, shader, font and blend state remain bounded/restored. The Android-only symptom reported on the user's phone has not been reproduced on physical hardware here.

Damage numbers enter with one small uniform rebound, then hold their proportions while rising smoothly and fading. Native 28/36px fonts, a dark outline, bright core and controlled tier-colored glow keep the value sharp over the scene. Fire surrounds the whole number with layered turbulence, buoyant billows, hot cores, red outer wisps and rising embers. Its center is hollow so it cannot obscure the value. Lightning follows irregular paths around the number, with thin white cores, blue bloom, secondary branches and staggered afterglow. Geometry buffers are reused, and deterministic strike changes follow elapsed time. The holographic pass colors only the visible glyph pixels. No numeral squashing, rotation, oversized plates, duplicate outlines or decorative wings. The four stronger style families add a small plain subtitle. Reduced motion preserves the magnitude with stable scale, static fire/lightning/foil and an 8px rise.

Rapid hits use three bounded lanes per target, replacing the oldest value on a reused lane. Older values shrink and dim, with fire, lightning and subtitles hidden; the latest stays bright. Values use the existing UI formatter through 1e15 and fit within a bounded width. Numbers are anchored to the actual enemy center with only 16px lateral variation for repeated hits. Nen's relative attack intensity must never override the resolved damage tier, label, color or lifetime: 77 damage stays compact even with the strongest Nen. The numerical fire/lightning stays attached to the glyphs during Nen; there are no duplicate physical impact rings.

Advanced lightning hits also stay at their enemy centers and use compact numbers without duplicate impact rings. The victory interest notice is compact and starts below the enemy, away from the damage number and its subtitle.

Coins have rotating faces, shaded edges and sparkles; gains fly into the counter and spending flies outward. Armor uses a metallic gradient, segmented fill and a change-driven shine. HUD shield accents sit beside the value at half size so the number remains readable. Procedural fire uses the same layered noise approach as the world's bed explosion, with its own shared steady combustion shader. Fire and holographic shaders are compiled when fonts are initialized, with lazy preparation for isolated callers, never during drawing. Shader state is restored after drawing; compilation failure preserves readable ivory text and a simple ember rim. No new textures or gameplay RNG.

Damage and gold glyphs also emit two soft layers of colored light before their sharp outline/core is drawn. Gold keeps a warm highlight and coin trails; the damage glow grows with its tier and remains visible during the number's hold.

Player armor is a cyan layer directly above health, filled against the existing armor cap, with an explicit zero. Creature armor uses its actual maximum and sits above enemy HP. HP and armor fill smoothly; losses leave a short delayed trail so absorption is visible. Exact HP/armor labels stay authoritative. Armor absorbed at contact is cyan; health damage and recovery use separate red/green numbers. A fully blocked hit does not show misleading zero HP damage. Equipment resource popups use the same compact beveled plates and distinct icons.

Gold gains and spending use distinct gold/orange numbers and coin emblems. Larger rewards release more coins, up to 16; coins spin, arc toward the wallet and leave a brief arrival glint. Spending flies outward. Battle and shop balances count smoothly to the exact resolved amount. Confirmed shop transactions use the shared effect and a four-entry bounded queue that survives the shorter card transfer. Gold awarded alongside soul destruction has its own feedback. Prices, caps and resource mutations are unchanged.

Validation:

```powershell
lua tests/combat_feedback_smoke.lua
lua tests/scoring_presentation_smoke.lua
lua tests/ux_polish_smoke.lua
lua tests/enemy_attack_presentation_smoke.lua
& '../love-11.5-win64/lovec.exe' . --test-combat-feedback
& '../love-11.5-win64/lovec.exe' . --test-feedback-render
& '../love-11.5-win64/lovec.exe' . --test-feedback-render --feedback-motion
& '../love-11.5-win64/lovec.exe' . --test-feedback-render --magnitude-motion
& '../love-11.5-win64/lovec.exe' . --test-scoring-feel
& '../love-11.5-win64/lovec.exe' . --test-ux-polish
```

Capture mode avoids player saves. It exports all five damage style families, 1e15 damage, gold spending, recovery and armor depletion to `docs/combat_feedback/`. `upgrade_gallery.png` compares both impact phases, armor over HP and actual shop purchase/sale effects. `damage_apex.png` shows four damage phases, a rapid burst and the Nen overlay. `damage_fire_tiers.png` compares all five approved fire/lightning/foil treatments at two moments. `damage_fire_motion.gif` presents 48 captured frames with a shared palette; the optional motion flag exports the source PNGs for encoding. `damage_magnitudes.png` compares all 16 orders from single digits through a million billion; `damage_magnitudes_motion.gif` shows their evolution over 40 frames at 20 FPS. The magnitude motion flag exports its source PNGs for encoding. `damage_77_nen.png` exercises the real scoring-to-damage path with strongest Nen, 77 resolved damage and a defeated enemy. CPU checks cover positive/negative magnitude boundaries and escalating profiles through 1e30, extreme values through 1e308, all Nen tiers across three target positions, resource gains/losses, proportional rebound, wraparound lightning bounds/buffer reuse/static accessibility/FPS consistency and target lanes at 30/60/120/144 FPS, exact settle, bounded lifetime and unchanged gameplay RNG. GPU checks assert successful fire/foil compilation, reuse and shader/font/blend/color restoration.
