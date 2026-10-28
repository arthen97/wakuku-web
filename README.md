# WAKUKU · 风铃山谷

A small exploration game about gathering heart threads and restoring wind bells.

## V7 archive — 2026-10-28

This repository preserves the playable V7 web build before the upcoming bridge, castle, audio and cover update.

- Build: `npm ci && npm run build`
- Hosting type: static website
- Output directory: `dist`
- Entry: `index.html`
- Git release tag: `v0.7.0`
- Controls: WASD move, Shift run, Space jump, E mend, Z/C camera, R return.

The Unity WebGL output and original UI/media are already built. No API keys, runtime AI calls or external game backend are required. Keep the directory layout intact and serve `.wasm` as `application/wasm`.

## Rights

This is a game deployment repository, not a reusable asset library. Third-party content retains its original terms. See [Credits](docs/CREDITS.md). Source Blender and Unity authoring projects are retained locally.
