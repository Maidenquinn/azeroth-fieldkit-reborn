"""Inventory the installed Reborn Lua surface without executing or copying game code."""

import argparse
from collections import defaultdict
from hashlib import sha256
import json
from pathlib import Path
import re


ADDONS = ("!AzerothSurvivorsCompat", "AzerothSurvivors", "AzerothSurvivorsAPI", "AzerothSurvivorsUI")
FUNCTION = re.compile(r"^\s*function\s+(AZS_\w+(?:\.\w+)*|AZS\.\w+)\s*\(")
ASSIGNMENT = re.compile(r"^\s*(AZS_[A-Z][A-Z0-9_]*(?:\.\w+)?)\s*=(?!=)")
ROUTER = re.compile(r'\bAZS\.On\(\s*"(AZS\w*)"\s*,')
API_ROUTER_ALIAS = re.compile(r'^\s*On\(\s*"(AZS\w*)"\s*,')
STAMP = re.compile(r'\bStamp\(\s*"(AZS_\w+_UPDATED)"')
TOPICS = {
    "treasury": r"\b(?:AZSRIFT|AZSVAULT|AZS_RIFT|AZS_VAULT|goblin treasury|trésorerie gobeline|treasure goblin|gobelin au trésor)\b",
    "arena_portals": r"\b(?:AZSGATE|AZSPASSAGE|AZS_PASSAGE|gate_line)\b",
    "rune_pickups": r"\b(?:speed rune|berserker rune|restoration rune|rune (?:jaune|de vitesse|de restauration|du berserker)|yellow rune|AZS_?RUNES?|AZS_?PICKUPS?)\b",
    "rift_crystals": r"\b(?:rift crystals?|cristaux? (?:de|de la) faille)\b",
    "object_catalogs": r"\b(?:AZS_(?:CHESTS|LAIRS)|AZSCHESTS|AZSLAIRS|AZSPING|AZS_GetWorldAnchors|AZS_WorldUnits)\b",
}
FINGERPRINTS = (
    "AzerothSurvivors/AzerothSurvivors.toc",
    "AzerothSurvivors/Core.lua",
    "AzerothSurvivors/Chests.lua",
    "AzerothSurvivors/Generated/Content.lua",
    "AzerothSurvivors/Lairs.lua",
    "AzerothSurvivors/Passage.lua",
    "AzerothSurvivors/Rift.lua",
    "AzerothSurvivors/Run.lua",
    "AzerothSurvivors/Units.lua",
    "AzerothSurvivors/Vault.lua",
    "AzerothSurvivorsAPI/AzerothSurvivorsAPI.toc",
    "AzerothSurvivorsAPI/Anchors.lua",
    "AzerothSurvivorsAPI/Api.lua",
    "AzerothSurvivorsAPI/CombatText.lua",
    "AzerothSurvivorsAPI/Hud.lua",
    "AzerothSurvivorsAPI/Meter.lua",
)


# Source-reviewed contracts for this client version. The declarations index is version-agnostic.
REVIEWED_CONTRACTS = {
    "AZS_RIFT": {
        "prefix": "AZSRIFT",
        "fields": ["st", "got", "need", "m"],
        "rowCoordinates": "map2D",
        "rowEncoding": "kind:mx:my, separated by /",
        "stableInstanceId": False,
        "lifecycle": "replacement snapshot; availability and freshness must be established",
        "evidence": ["AzerothSurvivors/Rift.lua:1", "AzerothSurvivors/Rift.lua:108"],
    },
    "AZS_VAULT": {
        "prefix": "AZSVAULT",
        "fields": ["st", "left", "secs", "got", "of", "at"],
        "atIsLocalReceptionTime": True,
        "rowCoordinates": None,
        "stableInstanceId": False,
        "lifecycle": "enter/open; other states end the display; world-entry and run-end reset",
        "evidence": ["AzerothSurvivors/Vault.lua:460", "AzerothSurvivors/Vault.lua:477"],
    },
    "AZSGATE": {
        "fields": ["id", "x", "y", "z", "wing", "bosses"],
        "rowCoordinates": "world3D",
        "stableInstanceId": "used within the received list; cross-reload scope unverified",
        "lifecycle": "replacement snapshot stored locally by the stock UI; replay unverified",
        "evidence": ["AzerothSurvivors/Passage.lua:389", "AzerothSurvivors/Passage.lua:574"],
    },
    "AZS_CHESTS": {
        "prefix": "AZSCHESTS",
        "fields": ["id", "x", "y", "z", "mx", "my", "boss", "runId", "mapId", "spaceId"],
        "rowCoordinates": "world3D and map2D",
        "stableInstanceId": "id within its current space",
        "lifecycle": "replacement snapshot and AZS_CHESTS_UPDATED",
        "evidence": ["AzerothSurvivors/Units.lua:89", "AzerothSurvivorsAPI/Api.lua:187"],
    },
    "AZS_LAIRS": {
        "prefix": "AZSLAIRS",
        "fields": ["index", "state", "name", "id", "left", "x", "y", "z", "mx", "my", "flag",
                   "hp", "hpm", "runId", "mapId", "spaceId"],
        "rowCoordinates": "world3D and map2D",
        "stableInstanceId": "lair index within its space; id refers to the occupant",
        "lifecycle": "replacement snapshot and AZS_LAIRS_UPDATED; empty lairs can remain in the list",
        "evidence": ["AzerothSurvivors/Lairs.lua:102", "AzerothSurvivorsAPI/Api.lua:192"],
    },
    "AZS_GetWorldAnchors": {
        "parameters": ["query?", "cursor?", "limit?"],
        "fields": ["entries", "hasMore", "nextCursor", "snapshotId", "total"],
        "rowCoordinates": "world3D",
        "stableInstanceId": "anchorId, scoped by the consumer to the current context",
        "lifecycle": "paged catalog; category-specific state",
        "evidence": ["AzerothSurvivorsAPI/Anchors.lua:246", "AzerothSurvivorsAPI/Anchors.lua:382",
                     "AzerothSurvivorsAPI/Anchors.lua:595"],
    },
}


def inventory(game):
    addons = game / "Interface" / "AddOns"
    manifest = (game / ".azs" / "installed.json").read_bytes()
    build = json.loads(manifest)
    definitions, tables, stamps, receivers = (defaultdict(list) for _ in range(4))
    topic_patterns = {key: re.compile(value, re.I) for key, value in TOPICS.items()}
    topic_hits = {key: [] for key in TOPICS}
    scanned = {}

    for folder in ADDONS:
        root = addons / folder
        paths = sorted(root.rglob("*.lua"), key=lambda path: path.relative_to(addons).as_posix())
        if not paths:
            raise ValueError(f"No Lua files in {root}")
        scanned[folder] = len(paths)
        for path in paths:
            relative = path.relative_to(addons).as_posix()
            for number, line in enumerate(path.read_text(encoding="utf-8-sig").splitlines(), 1):
                location = f"{relative}:{number}"
                for key, pattern in topic_patterns.items():
                    if pattern.search(line):
                        topic_hits[key].append(location)
                if line.lstrip().startswith("--"):
                    continue
                for pattern, matches in ((FUNCTION, definitions), (ASSIGNMENT, tables),
                                         (STAMP, stamps), (ROUTER, receivers)):
                    for match in pattern.finditer(line):
                        matches[match[1]].append(location)
                if relative == "AzerothSurvivorsAPI/Api.lua":
                    match = API_ROUTER_ALIAS.search(line)
                    if match:
                        receivers[match[1]].append(location)

    return {
        "schema": 1,
        "scope": "Static Lua index. Matches can be internal, conditional, unused or comments (topics only). "
                 "Native executable bindings and dynamic registrations require separate review.",
        "version": build["version"],
        "manifestSerial": build["serial"],
        "manifestSha256": sha256(manifest).hexdigest(),
        "luaFilesScanned": scanned,
        "sourceSha256": {name: sha256((addons / name).read_bytes()).hexdigest() for name in FINGERPRINTS},
        "luaFunctionDeclarations": definitions,
        "globalAssignments": tables,
        "literalStampCalls": stamps,
        "literalRouterReceivers": receivers,
        "reviewedContracts": REVIEWED_CONTRACTS if (build["version"], build["serial"]) == ("0.7.4", 1795141447) else {},
        "topicExpressions": TOPICS,
        "topicMatches": topic_hits,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--game", type=Path, required=True)
    output = parser.add_mutually_exclusive_group(required=True)
    output.add_argument("--output", type=Path, help="Write JSON outside the game directory.")
    output.add_argument("--check", type=Path, help="Compare with a saved JSON without writing.")
    args = parser.parse_args()

    game = args.game.resolve()
    if args.output and args.output.resolve().is_relative_to(game):
        parser.error("--output must be outside the game directory")
    result = inventory(game)
    encoded = json.dumps(result, indent=2, sort_keys=True, ensure_ascii=False) + "\n"
    if args.check and json.loads(args.check.read_text(encoding="utf-8")) != result:
        parser.exit(1, f"Evidence differs from {args.check}\n")
    if args.output:
        args.output.write_text(encoded, encoding="utf-8", newline="\n")
    print(f"Reborn {result['version']}, serial {result['manifestSerial']}, "
          f"{sum(result['luaFilesScanned'].values())} Lua files, "
          f"{len(result['luaFunctionDeclarations'])} function declarations, "
          f"{len(result['literalRouterReceivers'])} literal router prefixes")


if __name__ == "__main__":
    main()
