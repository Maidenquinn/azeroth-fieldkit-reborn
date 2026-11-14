FieldKit Reborn 0.1.0-reborn.13

Native borders are now drawn behind the parent content rather than in an overlay frame above it. This fixes obscured button labels. Buttons have text padding, profile selectors have more width, HUD rows have more breathing room and meter tabs have larger hit areas. Default HUD cards are independent, with separate initial regions. Existing inherited grouping is migrated once while individually dragged anchors are preserved; grouping can still be explicitly enabled.

Offline validation covers default and existing-save migration, explicit opt-in after migration, backdrop ownership, button dimensions, native/themed transitions, all 940 production setter cases and the existing installed Reborn 0.6.4 API tests. Live visual and co-op acceptance remain pending. Restart the client to load this version.
