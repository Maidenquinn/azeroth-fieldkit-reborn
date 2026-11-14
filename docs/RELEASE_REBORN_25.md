FieldKit Reborn 0.1.0-reborn.25

Spell names now pass through native AZS_L localisation after the structured loadout source, GetSpellInfo and action tooltip lookup. English source names can no longer overwrite a translated display name. Canonical and localised names remain usable as icon aliases.

The Elwynn Equipment card now draws a compact green native bonus line below each occupied item's name. The name/rank and bonus have separate vertical regions inside the existing artwork socket; a long summary is fitted with an ellipsis while the full native item effects remain available on hover. Equipment bonus text is cleared from spell rows and empty slots.

Validation: six hunter names through every override path, icon aliases, native inline item details, bounded socket geometry and gear/spell/empty transitions; full runtime/settings/theme and installed 0.6.5 public API/content fixtures. No new live client visual test is claimed.
