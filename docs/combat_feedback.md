# Combat number feedback

`src/combat_feedback.lua` draws resolved values without changing damage, armor, or gold rules.

- Damage below 100: cream, compact pop.
- 100–999: gold, larger pop.
- 1,000–9,999: orange rays, an ivory number core and impact ring.
- 10,000–99,999: red double shockwave, a diamond crest and heavier number entrance.
- 100,000 and above: violet halo, orbit and crest sparks, largest number and longest hold.

Numbers have dark outlines, a short spring entrance, gentle rise, and a fade only at the end. Damage labels and numbers scale together. Repeated hits stagger vertically; queues are bounded. Values are formatted by the existing UI formatter, including scientific notation through 1e15. Damage uses larger native fonts on the top tiers, with fitted width and bounded horizontal placement.

The visual pass adds tier-scaled double shockwaves, diamond sparks, brief afterimages on the top two tiers, ivory impact highlights, and dark label plates. Coins have rotating faces, shaded edges and sparkles; gains fly into the counter and spending flies outward. Armor uses a metallic gradient, segmented fill and a change-driven shine. HUD shield accents sit beside the value at half size so the number remains readable. These accents use the existing drawing primitives and no new shaders, textures or gameplay RNG.

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
& '../love-11.5-win64/lovec.exe' . --test-ux-polish
```

Capture mode avoids player saves. It exports all five damage tiers, 1e15 damage, gold spending, recovery and armor depletion to `docs/combat_feedback/`. `upgrade_gallery.png` compares both impact phases, armor over HP and actual shop purchase/sale effects. CPU checks cover interrupted gains/losses at 30/60/120/144 FPS, exact settle, bounded lifetime and unchanged gameplay RNG.
