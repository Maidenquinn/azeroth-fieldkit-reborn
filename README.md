# Azeroth FieldKit Reborn

Independent FieldKit adaptation for **Azeroth Survivors Reborn**, initially
targeting client **0.6.1**. Version **0.1.0-reborn.4** is a development candidate.

[Français](README.fr.md) · [Port audit](docs/REBORN_PORT.md) ·
[Native acceptance recipe](docs/REBORN_ACCEPTANCE.txt) ·
[Downloads](https://github.com/Maidenquinn/azeroth-fieldkit-reborn/releases)

Combat HUD, meters, learned spells, run jewelry, boss schedules, minimap/world
markers, configurable themes and English/French settings. Reborn's native data
supplies its maps and class spells, including expansion content. Dedicated
illustrated themes reuse the existing Elwynn skin on other maps in Auto mode,
with native zone names and data. Unsupported received-healing counters, recent windows, checkpoints
and unidentified appearances stay unavailable.

## Install

Download the named `AzerothFieldKitReborn-*.zip` release asset. Extract its single
`AzerothFieldKitReborn` folder into Reborn's `Interface/AddOns`, enable it together
with the game's bundled `AzerothSurvivorsAPI`, then restart normally. The final
path is `Interface/AddOns/AzerothFieldKitReborn/AzerothFieldKitReborn.toc`.
Open `/fieldkit`. Keep original-game FieldKit in the original game's client.
Do not enable both FieldKit editions in one client: runtime frame/slash names
are retained for compatibility. No executable installer is required.

Settings use **FieldKitRebornDB**. Original **FieldKitDB** is neither imported nor
modified. Optional peer sharing uses a separate wire prefix and is off by default.
Disable the addon to uninstall; retain its own SavedVariables if you want settings.

## Validation and distribution

```text
python -m pip install -r requirements-dev.txt
python tools/audit.py
python tools/verify.py
python tools/test_reborn.py
python tools/test_reborn.py --game <Reborn client directory>
python tools/reborn_audit.py --game <Reborn client directory>
```

The last two commands read local public API/catalog files; they do not launch or
modify the client. Automated fixtures do not prove live rendering, performance
or co-op network transport. See the audit and acceptance recipe for actual scope.

The launcher-registry entry is in `distribution/azeroth-fieldkit-reborn.toml`.
Registry status is `untested`; availability in the launcher requires a qualifying
release, maintainer review/merge and the game's signed index. A GitHub prerelease
is manually downloadable but is not pinned by the registry.

## Origins and rights

Maintained by Kevin Radlowski / Maidenhead. Derived from
[Azeroth FieldKit](https://github.com/Maidenquinn/azeroth-fieldkit), itself derived
from MASH by Malk. The original repository remains separately maintained and
unchanged. History and credits are retained. Read [NOTICE](NOTICE.md) and
[LICENSE](LICENSE.md); no new project-wide license or Reborn approval is asserted.
Historical documents describe the original game unless explicitly headed Reborn.
