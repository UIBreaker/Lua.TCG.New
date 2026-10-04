# Continental Relic Card Design

User-approved default, saved on 2026-10-04: all future card additions should match this existing style unless the user requests a change. Project-level reminders are in `AGENTS.md`. Use the local master image `docs/continental_reference.png` and same-family assets in `assets/cards/continental/` as visual references.

Master reference: the supplied giant continent, from frozen peaks and coastal cliffs through forests and fossil deserts to volcanic wastes and a violet eclipse above floating ruins.

## Shared direction

Cinematic Dark-Fantasy Expedition. Western fantasy, ancient expeditions and lost civilizations. Painterly high-resolution illustration with medium detail, strong silhouettes and one primary subject. Full-bleed 2:3 portraits. Quiet atmospheric backgrounds, controlled cinematic rim light, readable at 64 px. No text, ranks, borders or UI baked into generated art; the game owns these overlays.

Palette: deep ocean navy, glacial blue, forest green, sand and bone ivory, restrained lava orange, void violet, weathered antique gold. Each image uses one biome palette with one accent, rather than every colour at once.

Shape language: eroded monoliths, continental cliffs, western arches, astrolabes, simple runic circles, faceted relics and expedition tools. Large forms before fine texture. The shared bevelled card frame remains attached to the artwork; evolution ornaments remain runtime graphics.

## Family identities

- SPN: a supernatural phenomenon or guardian of the continent, with a clear silhouette and restrained magic.
- ITM: one tangible relic, wearable or tool in the foreground; the environment explains where it was discovered.
- Chests: distinct silhouettes and mechanisms. Transformation uses a living crystal reliquary; editions use a gilding press; SPN enchantment uses a spirit shrine; ordinary enchantment uses an arcane altar; seals use a stone stamping press. Other packs retain their own exploration identity.
- Speed: horizontal wind and afterimages, cyan and silver, one card or a coordinated group moving faster.
- Evolution: upward growth, awakening and progressively elaborated runic structures; white gold and living green, never speed streaks.
- Seals: a readable central stamp connected to its ability. Editions: distinct surface treatments. Planets: celestial landmarks above the continent. Hand styles: western tactical formations reflecting the poker pattern.
- Playing cards: expedition characters or relics reflecting their exact ability, separated by suit biome. Rank and suit indices are rendered by the game. Enemies: readable continental creatures and western antagonists, with runtime indices for creature cards.

Avoid Chinese fantasy, East Asian palace motifs, calligraphy, jade pendants, cloud-scroll dragons, eastern roofs, dense micro-ornament, blown-out white glow, particle noise and palette-only variations.

## Delivery

Each canonical asset gets its own ImageGen call and prompt derived from its current name and ability. New PNGs live in `assets/cards/continental/<category>/`; existing art is retained. `asset_manifest.json` contains inventory, prompts, concepts, source data, prior paths and generation status. Contact sheets and runtime captures provide visual QA.
