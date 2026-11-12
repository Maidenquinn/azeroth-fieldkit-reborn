-- Read Reborn's fresh public globals; never predict content from the old game.
FieldKitReborn={}
local R=FieldKitReborn
-- Preserve the shipped addons and their event handling. Only their visual
-- containers yield while FieldKit owns the themed HUD. Real action buttons
-- move to FieldKit's dock, retaining native clicks, ranks and cooldowns.
function R.ActionButton(slot)
 if not FieldKit.rebornLegacyFixture then
  local native=getglobal("AzerothSurvivorsActionBar1Button"..slot)
  if native then return native end
 end
 return getglobal("ActionButton"..slot)
end
local presentationNames={"AzerothSurvivorsUnitFramePlayer","AzerothSurvivorsSurvivorsResources","AzerothSurvivorsActionBar1"}
function R.ReplacePresentation()
 if not FieldKitZoneThemes or not FieldKitZoneThemes.active then return end
 R.presentation=R.presentation or {}
 for _,name in ipairs(presentationNames) do
  local frame=getglobal(name)
  if frame then
   if not R.presentation[frame] then
    R.presentation[frame]={parent=frame:GetParent(),alpha=frame:GetAlpha(),mouse=frame.IsMouseEnabled and frame:IsMouseEnabled()}
   end
   frame:SetParent(FieldKitThemeHUD.Hidden());frame:SetAlpha(0);if frame.EnableMouse then frame:EnableMouse(false) end
  end
 end
end
function R.RestorePresentation()
 for frame,saved in pairs(R.presentation or {}) do
  frame:SetParent(saved.parent)
  frame:SetAlpha(saved.alpha)
  if saved.mouse~=nil and frame.EnableMouse then frame:EnableMouse(saved.mouse) end
 end
 R.presentation={}
end
function R.Capabilities()
 if type(AZS_GetMeterCapabilities)~="function" then return nil end
 local ok,c=pcall(AZS_GetMeterCapabilities)
 if ok and type(c)=="table" then return c end
end
function R.SupportsHealing(perspective)
 local c=R.Capabilities()
 if not c or type(c.healingPerspectives)~="table" then return false end
 for _,p in ipairs(c.healingPerspectives) do if p==perspective then return true end end
 return false
end
function R.Icon(value)
 if type(value)~="string" or value=="" then return nil end
 if string.find(value,"[\\/]") then return value end
 return "Interface\\Icons\\"..value
end
function R.Localize(value)
 if type(value)~="string" then return nil end
 if type(AZS_L)=="table" and type(AZS_L[value])=="string" then return AZS_L[value] end
 return value
end
-- The native class pool supplies metadata only; learned rows come from AZS_SPELLS.
function R.Spell(key)
 local gen=AZS_GEN
 if type(gen)~="table" or type(gen.spells)~="table" then return nil end
 local _,token
 if type(UnitClass)=="function" then _,token=UnitClass("player") end
 local zone=type(AZS_ZONE)=="table" and AZS_ZONE or {}
 if type(gen.classById)=="table" and gen.classById[tonumber(zone.class)] then token=gen.classById[tonumber(zone.class)].token end
 if type(gen.classes)=="table" then
  for _,c in ipairs(gen.classes) do if c.key==zone.class then token=c.token end end
 end
 local pool=gen.spells[token]
 if type(pool)~="table" then return nil end
 for _,s in ipairs(pool) do
  if s.key==key then return {name=R.Localize(s.name),icon=R.Icon(s.icon)} end
 end
end
local slots={amulet=2,trinket1=13,trinket2=14,ring1=11,ring2=12}
function R.Gear()
 local items={}
 local rings,trinkets=0,0
 for _,g in ipairs(type(AZS_GEAR)=="table" and AZS_GEAR or {}) do
  local slot=slots[g.slot]
  if g.slot=="ring" then rings=rings+1;slot=rings<=2 and (10+rings) or nil end
  if g.slot=="trinket" then trinkets=trinkets+1;slot=trinkets<=2 and (12+trinkets) or nil end
  if slot then items[slot]={name=g.name,icon=R.Icon(g.icon),bonuses={g.text or ""},rankValue=tonumber(g.amount)} end
 end
 return items
end
-- Reborn does not implement the 1.12 GetPlayerBuff family. Its server buff
-- list supplies spell ids and remaining seconds; UnitBuff's shim supplies
-- icon/count only when the server list has not arrived.
function R.PlayerBuffs()
 local out={}
 local list=type(AZS_BUFFS)=="table" and AZS_BUFFS or {}
 if FieldKitNative and not FieldKitNative.Fresh("AZSBUFFS") then return out end
 local age=type(AZS_BUFFS_UPDATED)=="number" and math.max(0,GetTime()-AZS_BUFFS_UPDATED) or 0
 for i=1,math.min(32,table.getn(list)) do
  local b=list[i]
  if type(b)=="table" then
   local name,rank,icon
   if type(GetSpellInfo)=="function" and tonumber(b.spell) then
    local ok,a,c,d=pcall(GetSpellInfo,tonumber(b.spell));if ok then name,rank,icon=a,c,d end
   end
   local left=FieldKit.Number(b.left)
   local remaining=left and left>=0 and math.max(0,left-age) or nil
   if not remaining or remaining>0 then
    table.insert(out,{name=name or tostring(b.spell or "?"),icon=icon or "Interface\\Icons\\INV_Misc_QuestionMark",remaining=remaining})
   end
  end
 end
 if table.getn(list)>0 or type(UnitBuff)~="function" then return out end
 for i=1,32 do
  local ok,icon,count=pcall(UnitBuff,"player",i)
  if not ok or type(icon)~="string" or icon=="" then break end
  table.insert(out,{name="Effect",icon=icon,count=FieldKit.Number(count,nil,0)})
 end
 return out
end
-- Creature instance ids must never be used as entry/display ids.
function R.Portrait(frame,name,kind,id)
 local icon
 for _,u in ipairs(type(AZS_UNITS)=="table" and AZS_UNITS or {}) do
  if (u.id or u[2])==id and type(AZS_GEN)=="table" and type(AZS_GEN.creatureIcons)=="table" then
   icon=R.Icon(AZS_GEN.creatureIcons[tonumber(u.entry)])
  end
 end
 local path=icon or "Interface\\Icons\\INV_Misc_QuestionMark"
 if frame.mashPortraitPath~=path then frame.portrait:SetTexture(path);frame.mashPortraitPath=path end
 frame.mashPortraitReason=icon and "Reborn native creature icon" or "Reborn appearance unavailable"
 frame.mashPortraitIdentity=tostring(kind)..":"..tostring(id)
 FieldKit_Portraits.last={name=name,id=id,path=path,reason=frame.mashPortraitReason}
end
