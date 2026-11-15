FieldKit Reborn 0.1.0-reborn.33 — World-marker placement

Reborn's special-only world enumeration can omit guardians whose creature rank is normal. FieldKit now requests the full native anchor catalogue and retains only the supported special kinds, including those guardians; ordinary enemies never receive markers.

Creature markers compare native head and ground projections. Oversized model overhead points are limited to a 48-screen-pixel lift from the ground projection, with the glyph's bottom separated by four pixels. A visible ground point remains usable if the oversized head point is off screen. Chest icons receive a small 16-screen-pixel lift instead of the previous eight units. Native camera projection, distance filters, categories and the original-client rendering path remain intact.

Validation: Installed Anchors.lua fixture reproduces normal-rank guardians omitted by special-only enumeration, excludes ordinary enemies, bounds exaggerated model height, keeps markers when only the head leaves the screen, checks chest spacing and off-screen/zone cleanup. Full runtime, theme/locale marker matrix, settings and installed API regressions pass. No live-client visual acceptance of .33 is claimed; stable .31 remains available.
