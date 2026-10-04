# Continental asset validation

- 157 / 157 dedicated PNGs generated; no missing assets. Every source PNG is at least 512 × 768 and uses a 2:3 portrait ratio.
- Live LÖVE coverage passed: all asset paths, 52 playing cards with native indices, 11 separate planet cards, distinct enchantment chest aliases and utility aliases.
- Shared frame passed across six card families; top-right pennants at three sizes; attack/recoil attachment; no stationary frames for defeated enemies; nine evolution appearances.
- Live rendering passed: shop, three chest reward screens, collection, handbook, battle inventory and defeated enemy formation. Captures: `illustrated_*.png`.
- Card back passed: transparent corners at three sizes, opaque artwork, shared cache.
- Card effects passed: all three shaders and gameplay effects.
- Death VFX passed mini/elite/boss and player renders, and five combat integration scenarios. The existing Needle exhaustion scenario timed out; the full death suite therefore did not pass. This remains an outstanding combat test, separate from complete asset/render coverage.
- `git diff --check` passed.

Original raster files remain available; `asset_manifest.json` records previous paths and which entries replace existing raster or code-drawn artwork.
