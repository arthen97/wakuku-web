# WAKUKU · 星球来信

A small planet story about tending one flower, repairing a wind bell and making a promise.

[Play online](https://p0itacli4cxv.app.stg.medeo.ai/)

## V10.1 — 2026-10-28

The Godot cinematic preview is now a complete HTML / WebGL 2 release. Only Moss and Windbell Meadow are currently playable; four travellers and two destinations remain clearly marked previews.

- Five original character campaign posters replace all white-background model cards.
- Free mouse orbit is requested directly by the entry click; click the scene to recapture after Esc.
- 21:9 framing, character/destination selection, Chinese narrative and choice ending.
- All 56,876 world instances, imported textured models, 25 bones / 9 animation takes, map and Chinese audio are included in the pack.
- Subtle depth-aware distance blur, warm/cool film grading, glow and creek caustics.
- Browser rendering uses transparent sunlight shafts instead of native Forward+ volumetric fog; native camera DOF is replaced by a lightweight depth shader. The browser is not a pixel-identical Forward+ renderer.
- Autosave, localStorage mirror and manual JSON save export/import. Saves are private to each browser; no player save is distributed in the build.
- WASD move; Shift run, R toggle run; Space jump; mouse free-look, wheel zoom, Esc releases cursor; right-drag also works; E interact; M map; J journal; Esc pause.

The `index.pck` game pack is split into Git-safe parts without lossy recompression. `npm run build` reassembles it in `dist/`, checking each chunk and the final SHA-256. The public release manifest records the complete source-file inventory. Upload **all of dist**, not only index.html. Serve over HTTP(S); direct file:// opening is unsupported.

## V9.1 — 2026-10-28

- Flower and fine-grass drifts use seeded, warped ecology fields with sparse, irregular edges.
- 18 supplied butterflies follow flowers, pause to perch and flutter away from the player.
- Grass and flowers bend under grounded footsteps and recover gradually; batched GPU deformation preserves movement collision.
- Three coordinated paving materials — limestone, slate and sandstone — vary in mesh shape, size, orientation and spacing.
- Existing castle, cottages, cover, HUD map and Chinese audio retained.

## V9 — 2026-10-28

- New single cover featuring Moss, the valley and the bell castle.
- A 15.84 m landmark castle, three new painted cottage designs and ten residential placements.
- Curved stone lanes and a castle forecourt; planting respects paths and foundations.
- Four detailed botanical card species, flower drifts and a richer grass understory.
- Brighter sky fill, warm sunlight and sculpted cartoon cloud volumes.
- A terrain-derived HUD map with live heading, heart threads, bells and active target. Press M to expand; movement pauses while the map is open.
- Existing Chinese narration, environmental audio, footsteps, bird flocks and locomotion retained.
- WASD move, Shift run, Space jump, E mend, Z/C camera, R return, M map.

Build: `npm ci && npm run build`. Static output: `dist`. Entry: `index.html`.

The Godot WebGL runtime, assets and UI are prebuilt. No runtime AI service or API keys are required. Serve `.wasm` as `application/wasm`.

## Versions

- `v0.10.0`: Godot HTML cinematic chapter. Earlier Unity versions remain available in their original tags.

- `v0.7.0`: preserved original baseline, previously published as menv v1.
- `v0.8.0`: architecture and sound update; preserved as menv v2.
- `v0.9.0`: village, botanical cards, clouds, Moss cover and map.
- `v0.9.1`: natural planting, butterflies, foot-contact vegetation and irregular three-color paving.

The castle is an exterior landmark; there is no interior level. The cover is an illustration, not a game screenshot.

## Rights

Deployment repository, not a standalone asset library. Third-party content retains its original terms. See [Credits](docs/CREDITS.md) and [V8 additions](docs/CREDITS-V8.md) and [V9 additions](docs/CREDITS-V9.md). See also [V9.1 additions](docs/CREDITS-V9.1.md). Editable Godot, Unity and Blender authoring files remain in the local project. Godot runtime source is included in `godot-source/`; original asset files are compiled into the game pack. See `godot-source/licenses/` for additional credits and Noto Sans SC OFL license.
