FieldKit Reborn 0.1.0-reborn.32 — Reborn world markers

Fix world markers remaining off on Reborn. The adapter now accepts Reborn's public catalogue, projection and post-camera registration operations without requiring the original client's capability endpoint. Reborn returns snapshotId/frameId rather than the original worldId/streamId/frameCurrent contract. FieldKit projects only inside the native post-camera callback and clears marker state across native run/zone boundaries.

The original v1 capability/stream validation remains supported. Registration failures cannot report the engine as on. Existing marker preferences, categories, ranges and theme behaviour are retained; no native game files are changed.

Validation: Installed Reborn Anchors.lua execution demonstrates enable/catalogue/render callback/visible marker, off-screen hide, zone cleanup, callback reuse/unregistration and registration rejection. CI fixtures cover the bare Reborn contract, pagination, FR/EN with themes on/off, post-camera-only projection and distance filtering. Full runtime/settings/API regressions pass. No live-client visual acceptance of .32 is claimed; stable .31 remains available until this patch is accepted.
