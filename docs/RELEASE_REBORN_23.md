FieldKit Reborn 0.1.0-reborn.23

Unlocked native drag hit surfaces now explicitly receive mouse input. The minimap hit surface sits one layer above the map, below native/world pins; locks, reward choices and release disable it. Native clicks and wheel behavior remain forwarded. Unlock window positions in FieldKit to move these widgets.

The Effects card merges the live player aura list with the retained spell-buff list. This includes procs such as Surge of Strength even while Rapid Fire is present. Native AZS_L translations are applied, including Tir rapide and Bouclier divin. Spell ids/visual identities are deduplicated; known expiration and stack values are retained.

Damage/healing modal headers now paint on a dedicated text layer with explicit width/height and visibility, independent of native Button labels. The clickable sorting controls remain intact.

Elwynn boss health bars explicitly share their card's strata, sit above its material and restore visible health text/fill after theme changes. The regression reproduces Le Recousu in all three Elwynn layouts.

Jewelry descriptions now retain the native stat/effect wording without converting thorns into generic damage. Hover distinguishes this item's contribution from character totals compared on upgrade cards, and long native descriptions are measured for wrapping.

Validation: new regression covers live proc plus retained buffs, translation, duplicate/expired/fenced snapshots and both modal column modes; native drag tests now require actual mouse-enabled hit surfaces. Full offline and installed 0.6.5 API suites are checked. Computer Use was stopped with Escape before a live drag could be verified; no post-fix visual/input acceptance is claimed.
