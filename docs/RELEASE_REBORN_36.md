# Azeroth FieldKit Reborn .36 — Align your HUD, in your language

## New live HUD editor
- Open **Interface → Layout & arrange → Align HUD**, or type `/fieldkit align`.
- Keep your current theme visible while arranging the HUD.
- Use a centre-based alignment grid with adjustable spacing (8–64) and optional snapping.
- With the grid visible, cards snap to grid lines. Hide it to align edges and centres with other cards and the screen. Existing overlap rules still apply.
- Chat unlocks temporarily in edit mode, so you can move it too. Its normal lock returns when you finish.

## Fourteen UI languages
English, Français, Deutsch, Español, Português (Brasil), Polski, Čeština, Română, Türkçe, Русский, Українська, 简体中文, 日本語 and 한국어.

Choose your language in **Preferences**, or select **Automatic** to follow the game's language. Labels and fonts update immediately with or without a theme. Bundled fonts support Latin, Cyrillic and CJK text. Names supplied by the game keep the game's language; changing FieldKit does not change the game itself. Additional translations are a first pass with reviewed terminology; wording feedback is welcome.

## Fixes and polish
- Correct minimap scaling inside themed frames and refresh its viewport after movement, resizing or screen changes.
- Preserve existing layouts and language choices; hydrate missing settings in older HUD profiles.
- Improve translation consistency, readable script fonts and tooltip font restoration.

**Update:** Install the release ZIP, or update through the launcher once its registry pin has been merged and published. Existing FieldKit settings and profiles are preserved. Open settings with `/fieldkit`.

Maintainer accepted .36 for stable publication on 2026-11-17. Automated runtime, persistence, settings, localization, font and Reborn API checks pass. Native inspection covered selected Latin/Cyrillic/CJK languages and themed/unthemed cases at 1920×1080; exhaustive wording, co-op and ultrawide certification is not claimed.
