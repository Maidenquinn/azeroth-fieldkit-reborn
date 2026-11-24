-- Native Lua 5.0.3 port of the fixture runs in tools/verify.py and tools/test_reborn.py:
-- the same production modules, in the TOC's own order, with no modern string API.
-- Run from the repository root: lua50 tests/native50.lua (verify.py --lua50 does this).

-- verify.py gives every fixture a fresh LuaRuntime. One Lua 5.0 process has one global
-- table, so each boot first removes every global created after this line (mock,
-- addon and fixture state: AZS_* tables and stamps, frames, FieldKit*), and restores
-- any built-in a fixture replaced. Without it, one fixture's leftovers (e.g. an
-- AZS_UNITS_UPDATED stamp) silently change the next fixture's code path.
local pristine={}
for k,v in pairs(_G) do pristine[k]=v end
local function Fresh()
 local created={}
 for k in pairs(_G) do if pristine[k]==nil then table.insert(created,k) end end
 for i=1,table.getn(created) do _G[created[i]]=nil end
 for k,v in pairs(pristine) do if _G[k]~=v then _G[k]=v end end
end

-- The module list is the TOC's, never a copy that can drift from it.
local files={}
for line in io.lines("AzerothFieldKitReborn/AzerothFieldKitReborn.toc") do
 local _,_,name=string.find(line,"^([%w_]+%.lua)%s*$")
 if name then table.insert(files,name) end
end
assert(table.getn(files)>=70,"TOC module list not read")

-- verify.py runtime(): legacy-mode fixtures (FieldKit.rebornLegacyFixture right after
-- Runtime.lua), optional saved table before the modules load.
local function Legacy(saved)
 Fresh()
 FieldKitRebornDB=nil
 dofile("tests/mock.lua")
 string.match=nil;string.gmatch=nil
 if saved then FieldKitRebornDB=saved end
 for i=1,table.getn(files) do
  dofile("AzerothFieldKitReborn/"..files[i])
  if files[i]=="Runtime.lua" then FieldKit.rebornLegacyFixture=true end
 end
end

-- test_reborn.py runtime(): Reborn mode, no legacy buff getters, neutral preferences.
local function Reborn()
 Fresh()
 FieldKitRebornDB=nil
 dofile("tests/mock.lua")
 string.match=nil;string.gmatch=nil
 GetPlayerBuff=nil;GetPlayerBuffTexture=nil;GetPlayerBuffTimeLeft=nil;GetPlayerBuffApplications=nil
 for i=1,table.getn(files) do dofile("AzerothFieldKitReborn/"..files[i]) end
 FieldKitProfiles.factoryPresets=nil
end

local function Run(name) dofile("tests/"..name);print("PASS "..name) end

Legacy();Run("diagnostics.lua")
Legacy();Run("profiles.lua")
Legacy();Run("profile_chat.lua")
Legacy();Run("profile_ui.lua")

-- Security fixture with the chat hook shim verify.py installs.
Legacy()
function hooksecurefunc(object,key,callback)
 local original=object[key]
 object[key]=function(self,msg,r,g,b,id)
  local result=original(self,msg,r,g,b,id);callback(self,msg);return result
 end
end
fire(FieldKitFrame,"VARIABLES_LOADED")
Run("security.lua")

Legacy();Run("action_effects.lua")
Legacy();Run("official_api.lua")
Legacy();Run("game_0121.lua")
Legacy();Run("mode_stack.lua")
Legacy();Run("edge_positions.lua")
Legacy();Run("individual_layout.lua")
Legacy();Run("coop.lua")
Legacy();Run("party_details.lua")
Legacy();Run("group_history.lua")
Legacy();Run("previews.lua")
Legacy();Run("portraits_native.lua")
Legacy();Run("loadout.lua")
Legacy();Run("native_tools.lua")
Legacy();Run("ux_simplification.lua")
Legacy();Run("window_lock.lua")
Legacy();Run("party_sync.lua")

-- The shared UI journey, including the three suites no runner executed before QA-01
-- (combat_world, meter_suite, boss_timeline), on verify.py's saved table.
Legacy({compactBar=true,bossFrame=true,hidePlates=true,replaceTally=true,chestPins=true,guardianPins=true,moneyDetached=true,pos={FieldKitMoneyFrame={-2.5374755859375,-348.0493927001953}}})
fire(FieldKitFrame,"VARIABLES_LOADED");SlashCmdList.FieldKit("")
for _,name in ipairs({"test_money.lua","tests.lua","test_worldpins.lua","test_combat_editor.lua","combat_world.lua","meter_suite.lua","boss_timeline.lua","test_localization.lua","interface_journey.lua","card_preferences.lua"}) do Run(name) end

Legacy();Run("zone_themes.lua")

-- Reborn-mode meter: .39 periodic crits from the native combat feed, chat fallback,
-- unknown-vs-zero, paging, gaps; and the native tooltip value extraction.
Reborn();Run("reborn_meter_feed.lua")
Reborn();Run("reborn_loadout_values.lua")

print("Native Lua 5.0 fixtures passed: "..table.getn(files).." TOC modules")
