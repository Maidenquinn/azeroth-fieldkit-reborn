FieldKit Reborn 0.1.0-reborn.34 — Creature marker clearance

Remove the .33 fixed 48-pixel height cap measured from a creature's feet, which placed glyphs inside taller guardian/boss models. Creature glyphs now follow the native overhead projection with their bottom eight screen pixels above that point, including scaled world frames and different icon sizes. An off-screen overhead anchor is no longer replaced by a marker inside the body.

Chest placement remains exactly as accepted in .33: the small 16-screen-pixel lift is unchanged. Normal-rank guardian discovery, category/range settings and legacy-client placement are preserved. The extra ground projection requests used for the removed cap are no longer needed.

Validation: Installed native anchor fixture checks clearance above a large overhead point, off-screen behaviour, guardian discovery and unchanged chest spacing. CI fixture checks exact bottom-edge clearance at two effective world scales, with/without themes in French/English. Full runtime/settings/API regressions pass. Live-client visual confirmation of .34 is pending; stable .31 remains available.
