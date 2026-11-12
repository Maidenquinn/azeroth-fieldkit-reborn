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
local presentationNames={"AzerothSurvivorsUnitFramePlayer","AzerothSurvivorsSurvivorsResources","AzerothSurvivorsActionBar1","AzerothSurvivorsSurvivorsBossBar","AZSRiftBar"}
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
function R.HealthColor(current,maximum)
 current=FieldKit.Number(current,nil,0);maximum=FieldKit.Number(maximum,nil,0)
 if not current or not maximum or maximum<=0 then return nil end
 local share=current/maximum
 if share>=.75 then return .12,.76,.18 end
 if share>=.5 then return 1,.85,.12 end
 if share>=.25 then return 1,.48,.08 end
 return .9,.12,.12
end
function R.BossProgress()
 if type(AZS_NextBossProgress)=="function" then
  local ok,share=pcall(AZS_NextBossProgress)
  share=ok and FieldKit.Number(share,nil,0,1)
  if share then return share end
 end
 local run=type(AZS_RUN)=="table" and AZS_RUN or {}
 local last=0
 for _,boss in ipairs(type(AZS_SCHEDULE)=="table" and AZS_SCHEDULE or {}) do
  if boss.state=="due" then
   local rift=FieldKit.Number(run.rift,nil,0,100)
   if rift then return rift/100 end
   local now=FieldKitNative.Time();local at=FieldKit.Number(boss.at)
   if now and at and at>last then return math.max(0,math.min(1,(now-last)/(at-last))) end
   return nil
  end
  last=FieldKit.Number(boss.at,last)
 end
end
function R.EventCurrency()
 local event=AZS_EVENT
 if type(event)~="table" or type(AZS_EventCurrency)~="function" then return nil end
 local ok,name,icon,color=pcall(AZS_EventCurrency,event.key)
 local count=FieldKit.Number(event.n,nil,0)
 if not ok or type(name)~="string" or type(icon)~="string" or not count then return nil end
 return {name=FieldKitNative.Text(name),icon=icon,count=count,color=color}
end
function R.UpdateRunDetails()
 if FieldKit.rebornLegacyFixture then return end
 local H=FieldKitThemeHUD
 if H.next then
  local share=R.BossProgress()
  local text=H.next:GetText() or ""
  if text==R.lastProgressText then text=R.lastProgressBase end
  R.lastProgressBase=text
  R.lastProgressText=share and (text..string.format(" · %.0f%%",math.floor(share*100))) or text
  H.next:SetText(R.lastProgressText)
 end
 local color={R.HealthColor(UnitHealth("player"),UnitHealthMax("player"))}
 if H.health and color[1] then H.health:SetStatusBarColor(color[1],color[2],color[3]) end
 local event=R.EventCurrency()
 if not event then if R.eventFrame then R.eventFrame:Hide() end;return end
 if not R.eventFrame then
  local f=CreateFrame("Frame","FieldKitRebornEventCurrency",H.dock);R.eventFrame=f
  f:SetWidth(240);f:SetHeight(26);f:EnableMouse(true);FieldKitTheme.Surface(f,"card")
  f.icon=f:CreateTexture(nil,"ARTWORK");f.icon:SetWidth(20);f.icon:SetHeight(20);f.icon:SetPoint("LEFT",f,"LEFT",5,0)
  f.label=FieldKitTheme.Label(f,nil,30,2,205,22,13,FieldKitTheme.gold)
  f:SetScript("OnEnter",function()
   local e=R.EventCurrency();if not e then return end
   GameTooltip:SetOwner(this,"ANCHOR_TOP");GameTooltip:SetText(e.name)
   GameTooltip:AddLine(string.format("%.0f",e.count),1,.82,0);GameTooltip:Show()
  end)
  f:SetScript("OnLeave",function() GameTooltip:Hide() end)
 end
 local f=R.eventFrame;f:ClearAllPoints();f:SetPoint("BOTTOM",H.dock,"TOP",0,8)
 f.icon:SetTexture(event.icon);f.label:SetText(string.format("%.0f",event.count).." "..event.name)
 local c=event.color
 if type(c)=="table" then f.label:SetTextColor(FieldKit.Number(c[1],1,0,1),FieldKit.Number(c[2],.82,0,1),FieldKit.Number(c[3],0,0,1)) end
 f:Show()
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
