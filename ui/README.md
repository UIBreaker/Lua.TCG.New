# Procedural UI

`theme.lua` is the single source for UI colors, borders, spacing, radii,
typography sizes, glow and shadows. `components/` contains the reusable
renderers. Battle composes them without altering card, enemy or scoring rules.

The game renders a 1920×1080 virtual canvas and presents it with one uniform
scale factor plus letterboxing. Existing 1280×720 layout coordinates are
converted once when rendering into that canvas; individual component PNGs are
not stretched. No generated bitmap assets are needed for the current icon and
ornament set: they are simple procedural marks and text.

Open **UI Gallery** from Settings, or press **F8**. Press Escape/F8 or click
**ĐÓNG** to close it. The gallery shows the reusable components and their
visual states.
