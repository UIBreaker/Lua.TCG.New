# Selection, drag and equipment motion

Continues the shared `Motion.spring`, `Motion.settle` and `Motion.impact` rhythm used by combat, dealing and the shop. Uses the existing Continental illustrations, attached card frame and antique gold / cold cyan equipment accents.

- Selecting by mouse, sweep, keyboard or Shift-click uses a spring toward the selected pose. There is no immediate scale jump. Selection is still immediate; raised cards retain stable logical hit areas and the existing selection limit.
- Pickup is restrained: 5.5% scale, 9 px lift, 0.28 rad maximum tilt and 1.8% stretch. Drag tracking stays at real pointer speed even with fast animation enabled. Release preserves position and velocity; the return accelerates with the existing fast option.
- Equipment travels for 0.54 s, then lands with a 0.28 s card response and a soft locking ring. The whole item frame follows the relic. Detach opens the lock and returns the relic toward the backpack pocket. Normal timing is 0.9 s to rest; fast mode halves it.
- The socket picker stays visible until the equipment settles, then returns to combat, shop, map or the next act. Equipment ownership and item consumption commit once on successful input. Repeated clicks cannot attach twice, skip or change pages during docking. Completion callbacks are transient and clear before returning.
- Reporting changes now considers a changed persistent card even when an unchanged hand instance shares its ID. Changed visible instances still take priority and duplicate feedback is suppressed.
- Reduced motion keeps functional dragging and selected-card height, with critical damping, no decorative tilt/bob/stretch/scale and no equipment flight. A small stationary contact cue and readable status remain. Shop hover/focus obey the same preference.
- Scene entry clears old physics geometry after capturing the outgoing frame, preventing a stale hand/shop pose from leaking into a new layout. No new assets, save fields, canvases or gameplay RNG are introduced.

Validation uses LÖVE 11.5:

```powershell
& '..\love-11.5-win64\lovec.exe' . --test-interaction-motion
& '..\love-11.5-win64\lovec.exe' . --test-interaction-motion --no-motion-preview --interaction-case=reduced
& '..\love-11.5-win64\lovec.exe' . --test-card-motion
```

`interaction_motion_smoke.lua` checks selection, return, exact flight endpoints, soft start/stop, contact, callback expiry and the shared-ID regression at 30/60/120/144 FPS in normal/fast/reduced combinations. The GPU checks actual drag/return matrices, pointer timing, attached-frame regressions and reduced shop hover. The runtime harness uses real mouse input for sweep selection, deselection, reorder, shop returns, backpack attach/detach, picker docking, repeated input and failed duplicate attachments. It also covers map/shop/next-act/stored-combat return paths. Capture mode disables player save writes.

Related hand selection, touch, dealing/chest, equipment feedback, backpack and equipment transfer smoke checks pass. `interaction_motion.mp4` records 308 real game frames at 20 FPS, exported at 1280×720 with a 0.6 s final hold. Simulation frame rates above verify timing; physical phone performance has not been measured.
