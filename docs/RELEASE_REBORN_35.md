FieldKit Reborn 0.1.0-reborn.35 — World markers and adjustable height

Stable world-marker update, accepted by the maintainer after the final in-game recipe on 2026-11-15. Includes the Reborn API connection and normal-rank guardian discovery introduced in .32/.33, with the final approved placement controls.

Under World > World markers, boss/final boss/guardian/elite categories now have independent Anchor height (0–100 percent of the native overhead height) and Extra height (0–3 metres) controls. Defaults are 35 percent and 0.5 m; both are saved per HUD profile and update live. Reborn's overhead point may be well above visible model geometry, so it is calibrated rather than treated as an exact head position. FieldKit converts the metre offset to native yards and projects the resulting world-space point; no universal one-metre guarantee above every model is claimed.

Chest spacing accepted in .33 is unchanged. Native special-only enumeration is expanded to recover normal-rank guardians, but ordinary enemies never receive markers. Camera-synchronized projection, distance/category filters, cleanup on run/zone changes, callback registration and native/illustrated themes remain supported. Native catalogue tables are not modified when height metadata is attached.

Validation: Full runtime/settings/locale/API tests; installed native anchor catalogue and projection; guardian enumeration, creature height/metric projection, unchanged chest clearance, finite setting bounds and independent profile restoration. The maintainer confirmed final live gameplay acceptance and authorized stable release. Live visual acceptance was supplied by the maintainer; completed agent visual validation is not claimed. Co-op and other resolutions are not independently certified.
