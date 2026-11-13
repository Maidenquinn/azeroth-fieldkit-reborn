-- Declarative options only: each descriptor defines a getter and a user-action
-- setter. No setting is applied while this schema is built. The HUD injects the
-- actions instead of exposing its local functions as global names.
function FieldKit.CreateOptionsSchema(actions)
local SECTIONS = {
	{
		title = "Nameplates",
		items = {
			{
				kind = "check",
				id = "hidePlates",
				label = "Show only elites and bosses",
				tip = "Common monsters get no nameplate. The V key shows or hides the elite and boss plates.",
				get = function() return FieldKitRebornDB.hidePlates end,
				set = function(v) actions.SetFilter(v) end,
			},
			{
				kind = "check",
				id = "hideUnknown",
				label = "Hide unclassified monsters",
				tip = "Monsters FieldKit has not learned yet are hidden too. They are learned when you target or mouse over them.",
				get = function() return FieldKitRebornDB.hideUnknown end,
				set = function(v) FieldKitRebornDB.hideUnknown = v end,
			},
		},
	},
	{
		title = "Target",
		items = {
			{
				kind = "check",
				id = "targetHealth",
				label = "Enemy target health numbers",
				tip = "Shows current / max health on the target frame.",
				get = function() return FieldKitRebornDB.targetHealth end,
				set = function(v) FieldKitRebornDB.targetHealth = v; actions.UpdateTargetHealth() end,
			},

		},
	},
	{
		title = "Combat",
		items = {
			{
				kind = "check",
				id = "bossFrame",
				label = "Replace the game's boss bars",
				tip = "Hides the big boss bars of the HUD and shows bosses and awake guardians in target-style frames instead. Drag active windows directly; lock positions in Windows > Layout.",
				get = function() return FieldKitRebornDB.bossFrame end,
				set = function(v) FieldKitRebornDB.bossFrame = v; actions.SyncHudBosses(); actions.UpdateBossFrame() end,
			},
			{
				kind = "check",
				id = "hideDamage",
				-- Same CVar as Options → Combat → Show Target Damage (CombatDamage).
				label = "Show target damage (game)",
				tip = "Same as Options → Combat → Show Target Damage. Uncheck to keep only FieldKit combat text.",
				get = function() return FieldKitRebornDB.hideDamage ~= true end,
				set = function(v) FieldKitRebornDB.hideDamage = not v; actions.ApplyDamageNumbers() end,
			},
			{
				kind = "check",
				id = "showCrits",
				label = "Show my crits above the hero",
				tip = "Your critical hits pop up above your character. Uncheck Show target damage (game) to avoid duplicates.",
				get = function() return FieldKitRebornDB.showCrits end,
				set = function(v) FieldKitRebornDB.showCrits = v end,
			},
			{
				kind = "check",
				id = "groupCrits",
				label = "Group crits",
				tip = "Crits that land within a quarter second become one line: the biggest, with how many there were (x7).",
				get = function() return FieldKitRebornDB.groupCrits end,
				set = function(v) FieldKitRebornDB.groupCrits = v end,
			},
		},
	},
	{
		title = "Player",
		items = {
			{
				kind = "check",
				id = "playerBar",
				label = "Health bar under the character",
				tip = "A small green bar under your hero. Drag it directly; lock positions in Windows > Layout.",
				get = function() return FieldKitRebornDB.playerBar end,
				set = function(v) FieldKitRebornDB.playerBar = v; actions.UpdatePlayerBar() end,
			},

			{
				kind = "check",
				id = "playerBuffs",
				label = "Buff icons under the health bar",
				tip = "Your active buffs with their time left.",
				get = function() return FieldKitRebornDB.playerBuffs end,
				set = function(v) FieldKitRebornDB.playerBuffs = v; actions.UpdatePlayerBuffs() end,
			},
			{
				kind = "check",
				id = "playerShield",
				label = "Shield on the health bar",
				tip = "Your absorb shield shows as a light blue band over the health bar, with its value in numbers.",
				get = function() return FieldKitRebornDB.playerShield end,
				set = function(v) FieldKitRebornDB.playerShield = v; actions.UpdatePlayerBar() end,
			},
		},
	},
	{
		title = "Warnings",
		items = {
			{
				kind = "check",
				label = "Low health warning",
				tip = "The health bar under your hero flashes red when your health drops below the limit.",
				get = function() return FieldKitRebornDB.lowHealth end,
				set = function(v) FieldKitRebornDB.lowHealth = v; actions.UpdatePlayerBar() end,
				button = { text = "Test", onClick = function() actions.TestLowHealth() end },
			},
			{
				kind = "check",
				label = "Sound on low health",
				tip = "Plays a warning sound once each time your health drops below the limit.",
				get = function() return FieldKitRebornDB.lowHealthSound end,
				set = function(v) FieldKitRebornDB.lowHealthSound = v end,
			},
			{
				kind = "slider",
				label = "Low health limit",
				tip = "Below this much health the warning starts.",
				min = 10, max = 70, step = 5,
				format = function(v) return FieldKit_L("Low health below ")..v.."%" end,
				get = function() return FieldKitRebornDB.lowHealthPct end,
				set = function(v) FieldKitRebornDB.lowHealthPct = v; actions.UpdatePlayerBar() end,
			},
		},
	},
	{
		title = "Windows",
		items = {
			{
				kind = "check",
				id = "statsFrame",
				label = "Stats",
				tip = "Your character bonuses: damage, haste, critical chance, lifesteal and other selected statistics. Currency counters are configured separately.",
				get = function() return FieldKitRebornDB.statsFrame end,
				set = function(v) FieldKitRebornDB.statsFrame = v; actions.UpdateStatsFrame() end,
				button = { text = "Choose...", onClick = function() actions.ToggleStatsPicker() end },
			},
			{
				kind = "check",
				id = "replaceTally",
				label = "Kills under the gold",
				tip = "Shows your kills below the gold and chest price, and hides the game's Kills / Gold / cache box.",
				get = function() return FieldKitRebornDB.replaceTally end,
				set = function(v) FieldKitRebornDB.replaceTally = v; actions.SyncHudTally(); actions.UpdateMoneyFrame() end,
			},
			{
				kind = "check",
				id = "meterFrame",
				label = "Damage meter",
				tip = "Damage, DPS and share of each spell this run. The game's own meter stays as it is.",
				get = function() return FieldKitRebornDB.meterFrame end,
				set = function(v) FieldKitRebornDB.meterFrame = v; actions.UpdateMeterFrames(true) end,
			},
			{
				kind = "check",
				id = "takenFrame",
				label = "Damage taken",
				tip = "Where the damage you took came from: bosses, elites, monsters or ground effects.",
				get = function() return FieldKitRebornDB.takenFrame end,
				set = function(v) FieldKitRebornDB.takenFrame = v; actions.UpdateMeterFrames(true) end,
			},
			{
				kind = "check",
				id = "gearFrame",
				label = "Accessories",
				tip = "Your amulet, trinkets and rings with rarity colors. Empty slots show in red.",
				get = function() return FieldKitRebornDB.gearFrame end,
				set = function(v) FieldKitRebornDB.gearFrame = v; actions.UpdateGearFrame() end,
			},
		},
	},
	{
		title = "Map",
		items = {
			{
				kind = "check",
				label = "Chests on the minimap",
				tip = "Every Battleground Cache on the field gets an icon on the minimap. Far ones sit on the edge, pointing the way.",
				get = function() return FieldKitRebornDB.chestPins end,
				set = function(v) FieldKitRebornDB.chestPins = v; actions.UpdateChestPins() end,
			},
			{
				kind = "check",
				label = "Lairs",
				tip = "A window with every guardian lair: who holds it, asleep or awake, when an empty one fills again, and how far it is.",
				get = function() return FieldKitRebornDB.lairFrame end,
				set = function(v) FieldKitRebornDB.lairFrame = v; actions.UpdateLairFrame() end,
			},
		},
	},
	{
		title = "Interface",
		items = {
			{
				kind = "check",
				id = "compactBar",
				label = "Compact action bar",
				tip = "Your 6 spells and racial in a small bar with the XP bar below and the kills, gold and chest line above, and the menu buttons in the bottom right corner. Changing this reloads the interface.",
				get = function() return FieldKitRebornDB.compactBar end,
				set = function(v) FieldKitRebornDB.compactBar = v end,
			},
			{
				kind = "check",
				label = "Hide gryphons",
				tip = "Hides the two gryphons at the ends of the action bar.",
				get = function() return FieldKitRebornDB.hideGryphons end,
				set = function(v) FieldKitRebornDB.hideGryphons = v; actions.UpdateGryphons() end,
			},
		},
	},
	{
		title = "Camera",
		items = {
			{ kind = "camera" },
		},
	},
}


 return SECTIONS
end
