# FieldKit language support

The .36 release offers Automatic and fourteen languages: English, Polish,
Czech, German, Brazilian Portuguese, Spanish, French, Romanian, Turkish,
Russian, Ukrainian, Simplified Chinese, Japanese and Korean. The maintainer accepted this stable release on 2026-11-17.

Choose a language under Preferences. Automatic reads the game's locale; an
unsupported game locale falls back to English. Existing explicit English/French
choices remain explicit. New installations start on Automatic. Language changes
are immediate and remain part of the existing HUD-profile preference system.
They do not change the game locale, require a UI reload, or alter HUD positions.

The addon translates its settings, HUD labels, help, previews and generated
combat labels. Spell, effect, equipment and creature names supplied by the game
continue to use its native localized data. Known fallback labels cover gaps in
the native name API. Unknown names are preserved, never guessed. Player names,
raw meter attribution keys, filters and protocol identifiers are unchanged.
This does not add languages to the game's own content or translate player chat.

## Catalog maintenance

The established English/French labels remain in Localization.lua and
InterfaceStrings.lua. JSON catalogs in data/locales supply the twelve additional
languages. data/locale-glossary.json is authoritative for reviewed terminology,
selected help and shared reference game names. tools/build_locales.py merges
these sources and emits one Lua 5.0-compatible data module per language.

New catalogs were seeded from exact shared Stats/native labels and completed
with an offline translation model, then corrected with the glossary and
structural checks. They are a first pass, not a native-speaker certification of
every sentence. Further wording corrections should edit the JSON or glossary,
never the generated Lua. No translation model, network client or background
translation process is installed with FieldKit.

## Fonts and verification

The bundled OFL faces include the selected UI alphabets, language autonyms and
mixed-script native names. Regional CJK glyph forms come from hash-pinned
Noto CJK inputs, converted to quadratics and combined with the existing Latin
face. The Latin font's shaping tables remain in place. data/locale-fonts.json
records provenance; the original input files are developer assets outside the
runtime. The player addon performs no font downloads or conversion.

Required checks are build_locales.py --check, audit_locale.py,
check_locale_fonts.py, verify.py and test_reborn.py. They cover complete label
coverage, format placeholders, newline counts, glyph presence, switching,
profile/reload persistence and native label ownership. The optional --game
test_reborn.py check executes the installed public translation catalogs in
isolated Lua states and does not modify the client.

The compiler and runtime catalog audit also reject translation-model unknown
tokens (U+2047, U+FFFD and `<unk>`). Native inspection on client 0.6.8 at
1920x1080 exercised German, Russian and all three CJK alphabets with Elwynn
Complete, plus Korean without a theme and in a FieldKit-owned native tooltip.
The inspection found malformed Chinese text and several terminology errors;
these were corrected in the source catalogs and the CJK glyph subsets rebuilt.
Revised font resource names avoid reusing the earlier client font atlas after
installing the corrected candidate. The player's French preference, profile 1,
Elwynn Complete and paused game were restored after this inspection.

After reloading the corrected candidate, the Chinese panel help, compact action
bar label and guardian countdowns rendered without unknown tokens; all three
revised CJK font resources rendered in the themed HUD. Chinese was also checked
without a theme. Further context review found literal body-part translations of
"chest" in the new catalogs. The treasure-chest labels were reviewed across all
twelve additional languages, and 52 Chinese boss, party, counter and theme texts
were corrected. This is targeted wording review, not certification of every
sentence in every language. French/profile 1/Elwynn Complete were restored and
the game remained paused at 0:01 throughout the inspection.

In-game acceptance still checks layout, clipping and readability at the player's
resolution, with themes off and Elwynn/Naxx on. A font diagnostic rendered by
Pillow and synthetic geometry checks do not replace that client recipe.
