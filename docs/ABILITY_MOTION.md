# Consumables, SPN activation and evolution

Uses the existing Continental art, shared card frame and `Motion` curves. No new illustrations, gameplay rules or save fields.

- Potion flight takes 0.42 s with a soft start, shallow arc and exact arrival. The source card and its frame travel and dissolve together. Each of the 12 existing motifs starts at contact, then fades; local light also starts once at contact. Reactive dodge/accuracy/blood-gold events start directly at their actual target.
- Source geometry is captured before removing the item, preserving physical inventory slots. The potion renderer owns successful potion feedback; it no longer overlaps the generic consumption ghost. Utility items only dissolve after actual consumption, so canceled target selection retains its item and does not show a false consumption.
- Generic consumed items and changed-value feedback use the shared settle/impact rhythm. Contact gives the target a small physical response. Short animation clocks cap a stalled frame at 0.05 s.
- Scored SPNs use a 0.36 s impact envelope: up to roughly 4.5% scale, 5 px lift and restrained rim light. Consecutive activations share an active lift. Their clock is the scoring timeline, including fast/forward playback; reactions outside scoring advance separately. Contribution labels fade in and use the same restrained response.
- Evolution and socket/rule-break rituals commit exactly once on confirmation, preserving the existing callback/save timing. The picker then shows the previous card, a brief flip at contact (0.44 s), the upgraded frame and a short rest. It closes at 0.96 s, or 0.48 s in fast mode. Input cannot re-confirm, cancel or change targets during the committed ritual. Cancel before confirmation preserves the item.
- Reduced motion keeps stationary fades and contact cues. It removes potion flight, SPN lift/rotation/scale, ritual flip/lift and drifting particles. Existing buff labels and world effects stay behind tooltips and are hidden while a modal or inventory covers the game.

Validation with LÖVE 11.5:

```powershell
& '..\love-11.5-win64\lovec.exe' . --test-ability-motion
& '..\love-11.5-win64\lovec.exe' . --test-ability-motion --no-motion-preview --ability-case=reduced
& '..\love-11.5-win64\lovec.exe' . --test-evolution-ui
```

`ability_motion_smoke.lua` covers 12 potion motifs and both card/SPN rituals at 30/60/120/144 FPS with normal/fast/reduced combinations, exact rest poses, one commit/callback, input spam, resources and RNG isolation. The runtime capture exercises successful healing and hand buffs, failed/canceled/successful targeted potions, card/SPN evolution, socket upgrades and real combat with two scored SPNs. Existing potion, evolution picker, scoring, edition, equipment-feedback and combat-motion checks pass. The real backpack return/workshop test also passes at 960×540 and 1920×1080, preserving the original page/query/sort after each ritual.

`ability_motion.mp4` contains 335 real game frames at 20 FPS, exported at 1280×720 with a 0.6 s final hold. These timing checks do not measure physical phone performance.
