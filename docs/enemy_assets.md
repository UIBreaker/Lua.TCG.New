# Enemy asset pack

Generated with the built-in ImageGen tool. PNG sprites preserve the generated transparent alpha; no background-removal or recoloring pass is applied.

Six normal sprites cycle by Ante. The ten current RunManager.BOSS_KEYS each have a distinct PNG. Five additional legacy/debug boss sprites are also available. Elites and unmapped older bosses retain their existing fallback sprites. Selection reads current bossData so debug swaps and loaded encounters resolve correctly.

Assets: `assets/scene/enemies/<id>.png`.

Validation: `lua tests/enemy_art_smoke.lua`, or `lovec . --test-enemy-art` for texture loading, transparency checks and `docs/enemy_art_gallery.png`.

## Shared generation prompt

Use case: stylized-concept. Create ONE production-ready isolated full-body enemy sprite for a grimdark fantasy poker roguelike. Stylized low-poly 3D painted render, angular facets, rich tactile materials, crisp silhouette legible at 180 pixels, three-quarter view facing slightly toward viewer's left, entire character including weapons visible with 8% transparent margin. Centered standing/hovering battle pose, feet near bottom center. Soft upper-left lighting, controlled saturated accent colors, dark fantasy menace. No scenery, no floor, no text, no letters, no borders, no sheet, no extra characters. True transparent background. Subject: 

## Subject prompts

- **forest_goblin**: Small hunched forest goblin, moss green skin, huge pointed ears, leafy hood, crooked wooden spear and mushroom pouch.
- **lava_golem**: Stocky basalt rock golem with glowing orange lava fissures, broad stone fists, squat faceted legs, burning core.
- **swamp_wraith**: Floating swamp wraith, ragged teal spectral shroud, elongated hood, pale glowing eyes, mist tendrils instead of feet.
- **frost_wolf**: Lean arctic frost wolf on four legs, icy blue crystalline mane and fangs, white fur, snarling, broad tail.
- **desert_scorpion**: Giant ochre desert scorpion, six jointed legs, two enormous claws, curled segmented tail with violet venom stinger.
- **ancient_skeleton**: Ancient skeletal knight, exposed skull, corroded bronze armor, round cracked shield, chipped straight sword, tattered red sash.
- **echo_knight**: ECHO KNIGHT boss: slender blue silver armored knight, closed resonant bell shaped helmet, tuning fork greatsword, layered spectral echo rings behind shoulders.
- **taxman**: TAXMAN boss: grotesque portly coin collector wearing burgundy coat and gold crown, chained scales in one hand, heavy overflowing coin sack in other.
- **gem_devourer**: GEM DEVOURER boss: squat purple crystal beast with gigantic toothed circular mouth in chest, gemstones embedded in back, four clawed limbs, luminous pink crystal horns.
- **executioner**: EXECUTIONER boss: hulking muscular hooded executioner, black triangular hood, crimson leather apron, gigantic double headed crescent axe, heavy wrist chains.
- **faceless**: FACELESS boss: eerie tall thin humanoid in flowing ivory robes, absolutely smooth blank porcelain face without eyes nose mouth, black elongated claw hands, floating blank masks around shoulders.
- **the_needle**: THE NEEDLE boss: insectoid crimson needle lord, exceptionally slender body, four long rapier needle arms, narrow spiked crown, pointed stilt legs.
- **the_water**: THE WATER boss: turquoise flood deity with flowing water lower body, coral crown, broad water shoulders, luminous trident, swirling translucent waves.
- **the_hook**: THE HOOK boss: undead pirate demon, rusty enormous fishing hook replacing right arm, ragged orange coat, anchor and chains, skeletal tricorne face.
- **the_fish**: THE FISH boss: enormous deep sea angler fish monster, navy scales, wide gaping jaws, luminous lure over forehead, fan fins and clawed fish legs, pearls.
- **the_arm**: THE ARM boss: giant moss green disembodied hand monster walking on thick finger limbs, single glowing eye in palm, bark armor and vines around wrist.
- **lock_royals**: ROYAL SLAYER boss: skeletal monarch in violet royal mantle, broken crown, massive guillotine blade and three severed ornamental crowns on belt, angular golden shoulder armor.
- **black_tax_collector**: BLACK TAX COLLECTOR boss: lanky raven headed sinister banker wearing black gold brocade robes, chained iron tax ledger, gold abacus staff, claw feet, black feathers.
- **memory_eater**: MEMORY EATER boss: floating lavender tentacled brain creature with a hollow skull core, translucent violet wisps holding torn parchment memories, spiral eye, long trailing spectral tendrils.
- **gatekeeper**: GATEKEEPER boss: broad turquoise bronze armored sentinel with a stone doorway built into torso, enormous key shaped polearm, paired tower shields, rigid arch shaped helmet.
- **max_3_cards**: THREE CARD WARLORD boss: imposing triangular scarlet obsidian demon with exactly three arms, each holding a different saber, three horned heads, triangular plated torso, heavy digitigrade legs.

