assert(GetPlayerBuff==nil and GetPlayerBuffTexture==nil)
NOW=100;AZS_BUFFS_UPDATED=100
AZS_BUFFS={{spell=17,left=10},{spell=133,left=-1}}
GetSpellInfo=function(id) return id==17 and "Shield" or "Permanent",nil,"Interface\\Icons\\NativeBuff" end
local buffs=FieldKitReborn.PlayerBuffs()
assert(#buffs==2 and buffs[1].name=="Shield" and buffs[1].remaining==10)
assert(buffs[2].remaining==nil)
NOW=104;assert(FieldKitReborn.PlayerBuffs()[1].remaining==6)
NOW=111;buffs=FieldKitReborn.PlayerBuffs();assert(#buffs==1 and buffs[1].name=="Permanent")
fire(FieldKitFrame,"VARIABLES_LOADED")
assert(FieldKit.zoneThemeReady and FieldKitBossFrame1 and FieldKitMeterFrame and FieldKitGearFrame)
local rows={};assert(FieldKitNativeTools.Buffs(rows) and #rows==1 and rows[1].icon=="Interface\\Icons\\NativeBuff")
AZS_BUFFS={};UnitBuff=function(unit,index) if index==1 then return "Interface\\Icons\\FallbackBuff",3 end end
buffs=FieldKitReborn.PlayerBuffs()
assert(#buffs==1 and buffs[1].count==3 and buffs[1].remaining==nil)
update(FieldKitFrame,.3)
assert(FieldKitPlayerBuff1:IsShown())
SlashCmdList.FieldKit("");assert(FieldKitUI.frame and FieldKitUI.frame:IsShown())
print("PASS Reborn complete startup and settings without GetPlayerBuff; native buff timers, permanent buffs, expiry and icon-only UnitBuff fallback")
