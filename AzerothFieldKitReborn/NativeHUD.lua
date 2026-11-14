-- Per-element visual ownership for the unthemed Reborn HUD. Native events and
-- action buttons keep running; every acquired parent/alpha/mouse state returns.
FieldKitNativeHUD={frames={}}
local N=FieldKitNativeHUD
local parts={"clock","tally","bosses","meter"}
local function Saved()
 local d=FieldKitRebornDB
 if type(d.nativeHudBefore)~="table" then d.nativeHudBefore={} end
 return d.nativeHudBefore
end
local function Part(key,hide)
 local saved=Saved()
 if hide then
  if type(AZS_IsHudShown)~="function" then return end
  local ok,value=pcall(AZS_IsHudShown,key)
  if not ok or type(value)~="boolean" then return end
  if saved[key]==nil then saved[key]=value end
  if value then FieldKit.SetHudShown(key,false) end
 elseif type(saved[key])=="boolean" then
  FieldKit.SetHudShown(key,saved[key]);saved[key]=nil
 end
end
local function Mask(name,hide)
 local f=getglobal(name);if not f then return end
 local s=N.frames[f]
 if hide then
  if not s then s={parent=f:GetParent(),alpha=f:GetAlpha(),mouse=f.IsMouseEnabled and f:IsMouseEnabled()};N.frames[f]=s end
  if not N.storage then N.storage=CreateFrame("Frame",nil,UIParent);N.storage:Hide() end
  f:SetParent(N.storage);f:SetAlpha(0);if f.EnableMouse then f:EnableMouse(false) end
 elseif s then
  f:SetParent(s.parent);f:SetAlpha(s.alpha);if s.mouse~=nil and f.EnableMouse then f:EnableMouse(s.mouse) end
  N.frames[f]=nil
 end
end
function N.Release()
 for f in pairs(N.frames) do Mask(f:GetName(),false) end
 if FieldKitRebornDB then for _,key in ipairs(parts) do Part(key,false) end;FieldKitRebornDB.nativeHudBefore=nil end
 if N.clock then N.clock:Hide() end
end
local function Shown(name)
 local f=getglobal(name);return f and f:IsShown()
end
local function Clock()
 if not N.clock then
  local f=CreateFrame("Frame","FieldKitRunClockFrame",UIParent);N.clock=f
  f:SetWidth(128);f:SetHeight(28);f:SetFrameStrata("LOW");FieldKitTheme.Surface(f,"card",true)
  f.text=f:CreateFontString(nil,"OVERLAY");f.text:SetPoint("CENTER",f,"CENTER",0,0)
  FieldKitTheme.Font(f.text,14,FieldKitTheme.text)
 end
 local f=N.clock;f:ClearAllPoints()
 local timeline=getglobal("FieldKitBossTimelineFrame")
 if timeline and timeline:IsShown() then f:SetPoint("TOP",timeline,"BOTTOM",0,-4) else f:SetPoint("TOP",UIParent,"TOP",0,-8) end
 local sec=FieldKit.Number(FieldKitNative.Read("AZS_GetRunTime"),nil,0)
 if not sec and type(AZS_RUN)=="table" then sec=FieldKit.Number(AZS_RUN.t,nil,0) end
 if sec then
  sec=math.floor(sec);f.text:SetText(string.format("%d:%02d",math.floor(sec/60),sec-math.floor(sec/60)*60))
 else f.text:SetText("?") end
 FieldKitTheme.Update(f);f:Show()
end
function N.RestoreLegacy()
 if N.migrated or not FieldKitRebornDB or FieldKit.rebornLegacyFixture then return end
 N.migrated=true
 local d=FieldKitRebornDB
 for key,flag in pairs({bosses="hudBossesHidden",tally="hudTallyHidden",meter="hudMeterHidden"}) do
  if d[flag] and not d.nativeHudBefore and not d.zoneThemeNativeBefore then FieldKit.SetHudShown(key,true) end
  d[flag]=nil
 end
end
function N.Update()
 if FieldKit.rebornLegacyFixture or not FieldKit.zoneThemeReady or not FieldKitRebornDB then return end
 N.RestoreLegacy()
 if FieldKitZoneThemes and FieldKitZoneThemes.active then N.Release();return end
 local d=FieldKitRebornDB
 local phase=FieldKitNative.Read("AZS_GetPhase")
 local run=phase and not (FieldKit.IsChoiceScreen and FieldKit.IsChoiceScreen())
 local money=run and d.moneyFrame and Shown("FieldKitMoneyFrame")
 local gear=run and d.gearFrame and Shown("FieldKitGearFrame")
 local meter=run and d.meterFrame and Shown("FieldKitMeterFrame")
 local progress=run and d.bossTimeline and Shown("FieldKitBossTimelineFrame")
 local bosses,target=false,false
 local represented={}
 local id=type(AZS_TARGET)=="table" and FieldKit.Number(AZS_TARGET.id)
 for i=1,4 do
  local f=getglobal("FieldKitBossFrame"..i)
  if run and d.bossFrame and f and f:IsShown() and f.fieldkitUnitId then
   bosses=true;represented[f.fieldkitUnitId]=true;if id and id==f.fieldkitUnitId then target=true end
  end
 end
 -- This native frame alternates live boss health and next-boss progression.
 local live,covered=false,true
 for _,u in ipairs(type(AZS_UNITS)=="table" and AZS_UNITS or {}) do
  if FieldKit.Number(u.hp or u[4],0,0)>0 then
   live=true;if not represented[FieldKit.Number(u.id or u[2],0)] then covered=false end
  end
 end
 Part("tally",money);Part("meter",meter);Part("bosses",bosses);Part("clock",run and true or false)
 Mask("AzerothSurvivorsSurvivorsResources",money)
 Mask("AzerothSurvivorsMinimapStatusButton",money and d.replaceTally)
 Mask("AZSGearRow",gear)
 Mask("AZSMeterFrame",meter)
 Mask("AZSRiftBar",progress)
 Mask("AzerothSurvivorsSurvivorsBossBar",(bosses and covered) or (progress and not live))
 Mask("AzerothSurvivorsUnitFrameTarget",target)
 if run then Clock() elseif N.clock then N.clock:Hide() end
end

local function Short(value)
 local n=FieldKit.Number(value,nil,0)
 if not n then return "?" end
 if n<1000 then return tostring(math.floor(n)) end
 if n<1000000 then return string.format("%.1fk",n/1000) end
 return string.format("%.1fm",n/1000000)
end
-- The same evenly spaced cells include the event currency, including zero.
function N.Money(frame,gold,chest)
 local themed=FieldKitZoneThemes and FieldKitZoneThemes.active
 if themed then
  if frame.nativeCells then for _,c in ipairs(frame.nativeCells) do c:Hide() end end
  return false
 end
 for _,key in ipairs({"coin","gold","chest","chestLabel","kills","killsLabel"}) do if frame[key] then frame[key]:Hide() end end
 local entries={}
 if FieldKitRebornDB.replaceTally then table.insert(entries,{"Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",type(AZS_RUN)=="table" and AZS_RUN.kills or 0,"Kills"}) end
 table.insert(entries,{"Interface\\MoneyFrame\\UI-GoldIcon",gold,"Gold"})
 table.insert(entries,{"Interface\\Icons\\INV_Misc_TreasureChest01",chest,"Chest"})
 local event=FieldKitReborn.EventCurrency()
 if event then table.insert(entries,{event.icon,event.count,event.name}) end
 frame.nativeCells=frame.nativeCells or {}
 frame:SetWidth(math.max(280,frame:GetWidth()));frame:SetHeight(math.max(32,frame:GetHeight()))
 local width=(frame:GetWidth()-16)/table.getn(entries)
 for i,e in ipairs(entries) do
  local c=frame.nativeCells[i]
  if not c then
   c=CreateFrame("Frame",nil,frame);frame.nativeCells[i]=c;c:SetHeight(22)
   c.icon=c:CreateTexture(nil,"ARTWORK");c.icon:SetWidth(16);c.icon:SetHeight(16);c.icon:SetPoint("LEFT",c,"LEFT",0,0)
   c.value=c:CreateFontString(nil,"OVERLAY");c.value:SetPoint("LEFT",c.icon,"RIGHT",5,0);c.value:SetJustifyH("LEFT");FieldKitTheme.Font(c.value,12,FieldKitTheme.text)
   c:EnableMouse(true);c:SetScript("OnEnter",function() GameTooltip:SetOwner(this,"ANCHOR_TOP");GameTooltip:SetText(this.label);GameTooltip:Show() end)
   c:SetScript("OnLeave",function() GameTooltip:Hide() end)
   -- Cell tooltips must not turn the movable footer into a mouse trap.
   c:RegisterForDrag("LeftButton")
   c:SetScript("OnDragStart",function() local start=frame:GetScript("OnDragStart");if start then start() end end)
   c:SetScript("OnDragStop",function() local stop=frame:GetScript("OnDragStop");if stop then stop() end end)
   c:SetScript("OnMouseUp",function() local stop=frame:GetScript("OnDragStop");if stop then stop() end end)

  end
  c:ClearAllPoints();c:SetPoint("LEFT",frame,"LEFT",8+(i-1)*width,0);c:SetWidth(width)
  c.value:SetWidth(math.max(20,width-24));c.icon:SetTexture(e[1]);c.value:SetText(Short(e[2]));c.label=FieldKit_L(e[3]);c:Show()
 end
 for i=table.getn(entries)+1,table.getn(frame.nativeCells) do frame.nativeCells[i]:Hide() end
 FieldKitTheme.Update(frame);return true
end

function N.BossLook(frame)
 local native=FieldKitTheme.Style(frame)==4
 for _,part in ipairs(frame.nativeOrnaments or {}) do if native then part:Hide() else part:Show() end end
 for i,part in ipairs(frame.nativeEdges or {}) do
  local color=native and {.4,.4,.44} or ((i==1 or i==3) and FieldKitTheme.gold or FieldKitTheme.bronze)
  part:SetVertexColor(color[1],color[2],color[3])
 end
end
