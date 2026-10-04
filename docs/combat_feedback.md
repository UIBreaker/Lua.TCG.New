# Combat number feedback

`src/combat_feedback.lua` draws resolved values without changing damage, armor, or gold rules.

- Damage below 100: cream, compact pop.
- 100–999: gold, larger pop.
- 1,000–9,999: orange, impact ring and short rays.
- 10,000–99,999: red, stronger ring and larger number.
- 100,000 and above: violet, largest number and impact rays.

Numbers have dark outlines, a short spring entrance, gentle rise, and a fade only at the end. Damage labels and numbers scale together. Repeated hits stagger vertically; queues are bounded. Values are formatted by the existing UI formatter.

Player armor is a cyan layer directly above health, filled against the existing armor cap, with an explicit zero. Creature armor uses its actual maximum and sits above enemy HP. Armor absorbed at contact is cyan; health damage and recovery use separate red/green numbers. A fully blocked hit does not show misleading zero HP damage.

Gold gains and spending use distinct gold/orange numbers. Gains send a bounded number of coin particles into the active HUD counter, and the battle gold counter pulses. Existing shop transaction animation remains responsible for its own coins while busy.

Validation:

```powershell
lua tests/combat_feedback_smoke.lua
lua tests/scoring_presentation_smoke.lua
lua tests/enemy_attack_presentation_smoke.lua
& '../love-11.5-win64/lovec.exe' . --test-combat-feedback
```

The capture mode avoids player saves and exports the five damage tiers and gold spending to `docs/combat_feedback/`. The existing live scoring test passed its normal and fast cases; case 3 currently assumes immediate scoring even when a fast enemy attacks first, so that test cannot complete as written.
