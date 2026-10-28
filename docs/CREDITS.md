# WAKUKU V7 — asset sources

## Images

Four newly generated illustrations: cover, meadow workshop, creek mill, canopy pavilion. Created with the built-in imagegen tool after the user approved replacing unavailable Midjourney. These are illustration assets, not screenshots of the game. The original generated PNGs and full prompts are retained in `media/` and `asset-plan.json`.

Merouter `mj-fast-imagine-v8.1` was listed by `/v1/models` but the single cover request returned 404 `model_not_found / No route available`. The three remaining Midjourney requests were not sent. No failed V6 jobs were resubmitted.

## Speech

Seven Chinese clips generated with Merouter `eleven_v4`, voice `g7LVvkPWALzPxOQbF6OE` (Jade), language `zh`: brand, hello, thread, mend, return, finish, hint. All seven source files are preserved. No real person's voice was cloned. Runtime files replace their earlier English equivalents.

## Footsteps

Kenney, **Impact Sounds**, CC0 1.0.

- Official source and license: https://kenney.nl/assets/impact-sounds
- Public mirror used because the official ZIP returned HTTP 403: https://github.com/idoraz1/ValTrainer/tree/main/ValTrainerGodot/assets/audio/footsteps
- Mirror attribution: https://github.com/idoraz1/ValTrainer/blob/main/ValTrainerGodot/CREDITS.md

Original OGG metadata identifies Kenney and GameSynth by Tsugi. These are designed sound effects, not claimed field recordings. Five grass, five wood and five carpet samples are retained. Earth footsteps layer a softened carpet contact with low-level grass grit. Each runtime sample retains 0.245–0.280 seconds of contact and decay, with EQ, gain adjustment and fades. The old Merouter music excerpt is no longer selected as a footstep.

## Wildlife

Quaternius, **Animal Pack Vol. 2**, CC0 1.0.

- Author's source and license: https://opengameart.org/content/animated-animales-low-poly
- Source archive: https://opengameart.org/sites/default/files/Animal%20Pack%20Vol.2%20by%20%40Quaternius.zip

Eagle and Cat original Blender files include Flying / Idle and Walking / Idle actions. Recoloured, normalized to the valley, and combined into a single vertex-colour material per animal. Skeletons and original animation curves are retained in editable Blender files. The game uses 12 birds and 2 cats, without dynamic rigidbodies or animal shadow passes.

## Buildings / vegetation

Kenney Fantasy Town Kit, CC0, from the existing project library. Workshop, mill, separate wheel and pavilion are assembled from existing meshes. No borrowed Zelda models, artwork or recordings are used.

User-supplied POLYGON Meadow Forest assets retain their original package license. Existing Geometry Nodes and instanced rendering are retained, with stable ecological drift fields, building clearings and additional flower drifts.
