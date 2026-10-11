# Combat number feedback

`src/combat_feedback.lua` draws resolved values without changing damage, armor, or gold rules.

- Below 100 — BÌNH THƯỜNG: compact ivory number, warm glow, no subtitle.
- 100–999 — CỰC MẠNH: light fire around all four sides of the number.
- 1,000–9,999 — BÙNG NỔ: stronger fire with rising embers.
- 10,000–99,999 — SIÊU VIỆT: strong fire and three branching lightning paths around the number.
- 100,000 and above — TUYỆT ĐỈNH: strongest fire, eight branched lightning arcs and a moving holographic finish inside the glyphs.

Damage numbers enter with one small uniform rebound, then hold their proportions while rising smoothly and fading. Native 28/36px fonts, a dark outline, bright core and controlled tier-colored glow keep the value sharp over the scene. Fire surrounds the whole number with layered turbulence, buoyant billows, hot cores, red outer wisps and sparse rising embers. Its center is hollow so it cannot obscure the value. Lightning follows irregular paths around the number, with thin white cores, blue bloom, secondary branches and staggered afterglow. Geometry buffers are reused, and deterministic strike changes follow elapsed time. The holographic pass colors only the visible glyph pixels. No numeral squashing, rotation, oversized plates, duplicate outlines or decorative wings. The four stronger tiers add a small plain subtitle. Reduced motion preserves the tier with stable scale, static fire/lightning/foil and an 8px rise.

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
& '../love-11.5-win64/lovec.exe' . --test-scoring-feel
& '../love-11.5-win64/lovec.exe' . --test-ux-polish
```

Capture mode avoids player saves. It exports all five damage tiers, 1e15 damage, gold spending, recovery and armor depletion to `docs/combat_feedback/`. `upgrade_gallery.png` compares both impact phases, armor over HP and actual shop purchase/sale effects. `damage_apex.png` shows four damage phases, a rapid burst and the Nen overlay. `damage_fire_tiers.png` compares all five approved fire/lightning/foil treatments at two moments. `damage_fire_motion.gif` presents 48 captured frames with a shared palette; the optional motion flag exports the source PNGs for encoding. `damage_77_nen.png` exercises the real scoring-to-damage path with strongest Nen, 77 resolved damage and a defeated enemy. CPU checks cover all Nen tiers across three target positions, resource gains/losses, proportional rebound, wraparound lightning bounds/buffer reuse/static accessibility/FPS consistency and target lanes at 30/60/120/144 FPS, exact settle, bounded lifetime and unchanged gameplay RNG. GPU checks assert successful fire/foil compilation, reuse and shader/font/blend/color restoration.
