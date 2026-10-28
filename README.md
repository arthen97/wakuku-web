# WAKUKU · 风铃山谷

A small exploration game about gathering heart threads and restoring wind bells.

[Play online](https://p0itacli4cxv.app.stg.medeo.ai/)

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

The Unity WebGL output and UI are prebuilt. No runtime AI service or API keys are required. Serve `.wasm` as `application/wasm`.

## Versions

- `v0.7.0`: preserved original baseline, previously published as menv v1.
- `v0.8.0`: architecture and sound update; preserved as menv v2.
- `v0.9.0`: village, botanical cards, clouds, Moss cover and map.
- `v0.9.1`: natural planting, butterflies, foot-contact vegetation and irregular three-color paving.

The castle is an exterior landmark; there is no interior level. The cover is an illustration, not a game screenshot.

## Rights

Deployment repository, not a standalone asset library. Third-party content retains its original terms. See [Credits](docs/CREDITS.md) and [V8 additions](docs/CREDITS-V8.md) and [V9 additions](docs/CREDITS-V9.md). See also [V9.1 additions](docs/CREDITS-V9.1.md). Editable Unity and Blender authoring files remain in the local project.
