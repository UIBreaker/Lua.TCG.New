# Nine Continental Edition Imprints

All nine canonical PNGs were generated separately with the built-in ImageGen tool at 1024×1536, full bleed, without text or an external card frame. Their production directory is `assets/cards/continental/edition/`. The shared runtime frame remains `ui/components/card_frame.lua`.

Generation prompts, concepts and original source paths: `docs/edition_generation.json`. The main asset manifest and prompt catalog have also been updated. The previous Foil, Holographic and Polychrome artworks are retained in `docs/editions/previous/`.

Review sequence: concept contact sheet → nine individual images → `contact_sheet.png` → actual 100×150 thumbnails → production mapping → LÖVE capture. `runtime_catalog.png` and `runtime_chest.png` use the real loaders, frame and chest buttons.

## Distinct animated materials

Each of the nine editions now owns its own GLSL shader. Playing cards, SPN, edition rewards and collection artworks use the same runtime effects, beneath the common frame and text. Hover, selection and scoring amplify the shared interaction state.

| Edition | Visual identity |
| --- | --- |
| Foil | Cool silver material, narrow metallic sweep and white glint |
| Holographic | Thin-film spectral interference reacting to tilt |
| Polychrome | Broad moving jewel facets and chromatic seams |
| Gilded | Warm gold embossed seal with an expanding golden ring |
| Echo | Two displaced cyan afterimages and an expanding echo wave |
| Ancient | Carved branching rune awakened by an upward light pulse |
| Void | Purple vortex rim, dark core and local inward distortion |
| Astral | Twinkling stars and four rotating elliptical orbits |
| Resonant | Two counter-travelling cyan waves connecting three nodes |

`shader_comparison.png` and `edition_effects.gif` demonstrate all nine materials on **identical artwork**, making their visual differences reviewable independently of the nine separate illustrations. The GIF uses 48 GPU-rendered frames at 12 fps. The six new materials no longer borrow the Foil or Holographic shader.

## Gameplay

- Foil: +20 flat damage on scoring; Holographic: +10 Mult on scoring.
- Polychrome: +50% of the source's marginal Aura contribution at its resolution point in the existing left-to-right sequence, before global damage conversion. Does not multiply the base hand or the entire hand. The extra contribution is exposed as `localAuraBonus` in results and in the scoring formula.
- Gilded: +3 gold while still held at `Combat.onPlayerTurnEnd`, excluding destroyed cards.
- Echo: one extra trigger per hand at full effectiveness; no repeated base hand scoring. Uses existing retrigger limits.
- Ancient: evolution-derived parameter gains ×3 (200% stronger), leaving the base values unchanged.
- Void: ten final ability activations routed through the existing handler before deletion and soul award, with an idempotent destruction guard. Conditions still apply. Optional abilities reuse an approved decision, target and cost when available.
- Astral: wildcard only during flush/straight-flush suit evaluation. Rank, stored suit and faction abilities remain unchanged.
- Resonant: +20% quantitative ability parameters for each immediate neighbor of a held source. Two sources add to +40%. During scoring, targets retain their pre-play positions and played sources no longer grant the held bonus.

The edition chest offers three distinct random choices from the full nine-edition pool, using the existing use/keep/socket/consume flow. Collection entries use the same canonical definitions. Existing shop optical rolls remain Foil/Holographic/Polychrome; the other six are available through edition consumables. Editions that need rank, suit, hand position, evolution or destruction are restricted to playing cards, and clicking an incompatible SPN preserves the consumable.

## Validation

- `lua tests/editions_smoke.lua`: nine definitions, all pool entries reachable, no duplicates per chest, actual stored-target click handler, consumption/imprint feedback hooks, failed-target preservation, persistent copies, each edition mechanic, all 52 Void targets outside scoring, paid Void decisions and source-local SPN Polychrome.
- `lovec . --test-editions-render`: production PNG decode/downsample, nine distinct shader paths, successful GPU compilation, all 36 shader output pairs distinct on identical artwork, shared frame, descriptions and all six chest actions. Exports runtime images, the shader comparison and animation frames here and exits without running the normal game or writing player saves.
- Runtime captures completed successfully, including the final rerun. During verification the growing `main.lua` exceeded Lua's 200-local limit; its unused `Expedition` local binding was removed while preserving module initialization. Syntax and runtime checks passed afterwards.
- Poker, scoring-presentation and soul-relic regression checks passed.
- Broader pre-existing tests are not all passing: `tests/card_effects_smoke.lua` expects destruction in every upper shop row, although the slot can also roll a potion; `tests/chest_expansion_smoke.lua` omits Inventory from its stored-consumable UI mock. Concurrent chest-pool additions also make that test's old fixed counts stale. These unrelated assertions were left in place.
