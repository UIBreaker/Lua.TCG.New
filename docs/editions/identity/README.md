# Nine immediately distinct Edition signatures

This pass strengthens the visual identity in the nine production shaders. It preserves the shared runtime card frame, source alpha and the existing gameplay values.

| Edition | Primary shape and motion |
| --- | --- |
| Foil — Kim Quang | Cool silver diagonal satin beams with a travelling metallic glint |
| Holographic — Huyễn Quang | Horizontal cyan/magenta interference ribbons flowing over thin film |
| Polychrome — Đa Sắc | Six large prism faces, a bright hexagonal outline and refracting seams |
| Gilded — Kim Ấn | Antique-gold solar seal with twelve rays and a rotating specular highlight |
| Echo — Vọng Ảnh | Two visibly displaced cyan/violet silhouettes and two side curtains; no circular echo halo |
| Ancient — Cổ Đại | Large branching green rune, upward awakening wave and rising embers |
| Void — Hư Không | Dark eclipse core with a violet event horizon and tilted accretion disc |
| Astral — Tinh Tú | Five-point stellar constellation with white/blue beacons and orbiting comets |
| Resonant — Cộng Hưởng | Three pulsing circular cores linked by two broad counter-travelling waves |

Run `lovec . --test-editions-render` from the project root. The existing GPU preview checks shader compilation, all 36 distinct-output pairs, production reward rendering, alpha preservation and gameplay integration. Captures for this pass are exported to this directory so earlier previews remain available.

`identity_at_96px.png` uses identical artwork at 96×144 for all nine effects, across idle, hover and scoring states. `edition_gallery_idle.png` and `edition_gallery.png` use the nine actual artworks. `edition_effects_identity.gif` contains 96 GPU-rendered frames cycling through idle, hover, selection and scoring at approximately 24 fps.

Pixel-output differences are asserted automatically. Recognizability, silhouette separation and artwork readability are reviewed visually in the captures. The tiny-card comparison is particularly useful for distinguishing the gold solar seal from the green rune, and the six-faced prism from horizontal holographic ribbons.

The published 96px contact sheet preserves all 27 card faces as untouched crops from the GPU capture. Its headings and names are laid out separately with Pillow and the project's Arial Bold font, avoiding intermittent glyph-atlas artifacts in the tiny-label capture. The gallery animation is checked for 96 complete frames, visible and stable captions, and visible movement in each of the nine effects.
