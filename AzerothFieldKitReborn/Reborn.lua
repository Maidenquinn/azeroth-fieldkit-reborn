-- Read Reborn's fresh public globals; never predict content from the old game.
FieldKitReborn={}
local R=FieldKitReborn
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
