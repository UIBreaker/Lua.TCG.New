# Shop chest opening

The shop's `currentPackOpening` now uses the shared chest ash shader and particle pool, followed by three face-down cards that flip in sequence. Names and actions sit below the full card face; actions become clickable only after that card finishes flipping.

Existing individual art is used for playing cards, equipment, patrons and hands. Spells, seals and editions without individual art use the existing pack illustration with the reward's tint and emblem. Their descriptions remain available on hover. Keep is available for the five consumable pack categories supported by `Shop.keepPackCard`; full inventory disables it.

Run with the bundled LÖVE runtime:

```
lovec.exe . --test-shop-chest
lovec.exe . --test-pack-skip
lovec.exe . --test-chest-vfx
```

All three passed. The first test captures ash, backs, flip and choices in `docs/shop_chest_*.png` and verifies real mouse actions for use, keep, full inventory and skip. The second buys and skips all nine shop pack types without extra charges, refunds or rewards. The third checks boss/treasure rewards. These harnesses stub persistence writes/deletion.
