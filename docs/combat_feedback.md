# Combat number feedback

`src/combat_feedback.lua` draws resolved values without changing damage, armor, or gold rules.

- Damage below 100: cream, compact pop.
- 100–999: gold, larger pop.
- 1,000–9,999: orange, impact ring and short rays.
- 10,000–99,999: red, stronger ring and larger number.
- 100,000 and above: violet, largest number and impact rays.

Numbers have dark outlines, a short spring entrance, gentle rise, and a fade only at the end. Damage labels and numbers scale together. Repeated hits stagger vertically; queues are bounded. Values are formatted by the existing UI formatter.

The visual pass adds tier-scaled double shockwaves, diamond sparks, brief afterimages on the top two tiers, ivory impact highlights, and dark label plates. Coins have rotating faces, shaded edges and sparkles; gains fly into the counter and spending flies outward. Armor uses a metallic gradient, segmented fill and a change-driven shine. HUD shield accents sit beside the value at half size so the number remains readable. These accents use the existing drawing primitives and no new shaders, textures or gameplay RNG.

Damage and gold glyphs also emit two soft layers of colored light before their sharp outline/core is drawn. Gold keeps a warm highlight and coin trails; the damage glow grows with its tier and remains visible during the number's hold.

Player armor is a cyan layer directly above health, filled against the existing armor cap, with an explicit zero. Creature armor uses its actual maximum and sits above enemy HP. Armor absorbed at contact is cyan; health damage and recovery use separate red/green numbers. A fully blocked hit does not show misleading zero HP damage.

Gold gains and spending use distinct gold/orange numbers. Gains send a bounded number of coin particles into the active HUD counter, and the battle gold counter pulses. Existing shop transaction animation remains responsible for its own coins while busy.

Validation:

```powershell
lua tests/combat_feedback_smoke.lua
lua tests/scoring_presentation_smoke.lua
lua tests/enemy_attack_presentation_smoke.lua
& '../love-11.5-win64/lovec.exe' . --test-combat-feedback
```

The capture mode avoids player saves and exports the five damage tiers and gold spending to `docs/combat_feedback/`. The live scoring fixture now waits for fast enemies and supplies valid equipment IDs; all four normal/fast/boss/lethal cases and the isolated lab pass.
