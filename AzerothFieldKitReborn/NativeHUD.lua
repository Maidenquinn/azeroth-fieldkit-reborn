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
 N.ReleaseNativeLayouts()
 for f,scale in pairs(N.cardScales or {}) do f:SetScale(scale) end;N.cardScales={}
 N.RestoreMeterFooter()
 if FieldKitReborn065 then FieldKitReborn065.RestoreCastbar() end
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
 if timeline and timeline:IsShown() then f:SetPoint("TOP",timeline,"BOTTOM",0,-30) else f:SetPoint("TOP",UIParent,"TOP",0,-20) end
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
 local choosing=FieldKit.IsChoiceScreen and FieldKit.IsChoiceScreen()
 local run=phase
 local money=run and d.moneyFrame and (choosing or Shown("FieldKitMoneyFrame"))
 local gear=run and d.gearFrame and (choosing or Shown("FieldKitGearFrame"))
 local meter=run and d.meterFrame and (choosing or Shown("FieldKitMeterFrame"))
 local progress=run and d.bossTimeline and (choosing or Shown("FieldKitBossTimelineFrame"))
 local bosses,target=false,false
 local castOwner
 local represented={}
 local id=type(AZS_TARGET)=="table" and FieldKit.Number(AZS_TARGET.id)
 for i=1,4 do
  local f=getglobal("FieldKitBossFrame"..i)
  if run and d.bossFrame and f and (choosing or f:IsShown()) and f.fieldkitUnitId then
   bosses=true;represented[f.fieldkitUnitId]=true;if id and id==f.fieldkitUnitId then target=true;castOwner=(f.compact and f.compact:IsShown()) and f.compact or f end
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
 if FieldKitReborn065 then FieldKitReborn065.MoveCastbar(target and castOwner or nil) end
 N.ScaleCards()
 N.Polish()
 if FieldKitNativeLayout then FieldKitNativeLayout.Apply() end
 N.TargetLayout()
 if run then Clock() elseif N.clock then N.clock:Hide() end
 if choosing and FieldKitScreenLayers then FieldKitScreenLayers.ApplyChoice() end
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
 table.insert(entries,{FieldKitTheme.media.."WorldMarkers\\cache.tga",chest,"Chest"})
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

-- Reserve independent default regions rather than tethering cards to a group.
-- Existing individually dragged anchors win over the inherited auto positions.
function N.SeparateDefaults()
 if not N.layoutReset or not FieldKit.zoneThemeReady then return end
 N.layoutReset=nil
 local d=FieldKitRebornDB
 local locations={FieldKitModeFrame={24,32},FieldKitMeterFrame={24,150},FieldKitTakenFrame={24,610},FieldKitLairFrame={24,420},FieldKitGearFrame={-24,32},FieldKitStatsFrame={-24,300},FieldKitEffectsFrame={-24,480}}
 for name,point in pairs(locations) do
  local f=getglobal(name)
  if f and not d.frameAnchors[name] then
   local side=point[1]<0 and "TOPRIGHT" or "TOPLEFT"
   d.frameAnchors[name]={side,side,point[1],-point[2]};FieldKitPositions.Restore(f)
  end
 end
 if not d.frameAnchors.FieldKitMoneyFrame then
  d.frameAnchors.FieldKitMoneyFrame={"BOTTOM","BOTTOM",0,30};FieldKitPositions.Restore(FieldKitMoneyFrame)
 end
end

function N.ScaleCards()
 N.cardScales=N.cardScales or {}
 local scale=FieldKit.Number(FieldKitRebornDB.nativeCardScale,100,75,110)/100
 for _,name in ipairs(FieldKitCardLayout.names) do
  local f=getglobal(name)
  if f then
   if not N.cardScales[f] then N.cardScales[f]=f:GetScale() end
   if f:GetScale()~=scale then f:SetScale(scale) end
  end
 end
end

function N.Polish()
 N.MeterFooter()
 for _,name in ipairs(FieldKitCardLayout.names) do
  local f=getglobal(name)
  if f and f.title and f.total and f.mashCollapseButton then
   if f.mashCollapsed and f:GetHeight()<36 then f:SetHeight(36);FieldKitTheme.Update(f) end
   f.title:ClearAllPoints();f.title:SetPoint("TOPLEFT",f,"TOPLEFT",12,-12)
   f.total:ClearAllPoints();f.total:SetPoint("TOPRIGHT",f,"TOPRIGHT",-42,-12)
   local b=f.mashCollapseButton;b:SetWidth(24);b:SetHeight(24);b:ClearAllPoints();b:SetPoint("TOPRIGHT",f,"TOPRIGHT",-6,-6)
   FieldKitTheme.Update(b)
  end
 end
end

function N.RestoreMeterFooter()
 local p=N.meterProxy
 if not p then return end
 for f,parent in pairs(p.saved) do f:SetParent(parent) end
 p.saved={};p:Hide();if p.reset then p.reset:Hide() end
end
function N.MeterFooter()
 local source=getglobal("FieldKitMeterFrame")
 if not source or not source.fieldkitTabs or not source.fieldkitReset then return end
 local p=N.meterProxy
 if not p then
  p=CreateFrame("Frame",nil,source);N.meterProxy=p;p.saved={};p.buttons={};p:SetHeight(26)
  local function Forward(original)
   local callback=original and original:GetScript("OnClick");if not callback then return end
   local prior=this;this=original;pcall(callback);this=prior
  end
  for i=1,6 do
   local index=i;local b=CreateFrame("Button",nil,p);p.buttons[i]=b;b:SetHeight(26);b:RegisterForClicks("LeftButtonUp","RightButtonUp")
   b.label=b:CreateFontString(nil,"OVERLAY");b.label:SetPoint("CENTER",b,"CENTER",0,1);b.label:SetHeight(18)
   if b.label.SetWordWrap then b.label:SetWordWrap(false) end
   FieldKitTheme.Font(b.label,11,FieldKitTheme.text)
   b.line=b:CreateTexture(nil,"ARTWORK");FieldKitTheme.Solid(b.line,{1,.78,.18});b.line:SetHeight(2);b.line:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",6,0);b.line:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-6,0)
   b:SetScript("OnClick",function() Forward(source.fieldkitTabs.buttons[index]) end)
   b:SetScript("OnEnter",function()
    GameTooltip:SetOwner(this,"ANCHOR_TOP");GameTooltip:SetText(FieldKit_L(source.fieldkitTabs.buttons[index].fieldkitFullLabel))
    GameTooltip:AddLine(FieldKit_L("Left-click: switch tab. Right-click: detach / reattach window."),.8,.8,.8,true);GameTooltip:Show()
   end)
   b:SetScript("OnLeave",function() GameTooltip:Hide() end)
  end
  p.reset=CreateFrame("Button",nil,source);p.reset:SetWidth(112);p.reset:SetHeight(22)
  p.reset.label=p.reset:CreateFontString(nil,"OVERLAY");p.reset.label:SetAllPoints(p.reset)
  if p.reset.label.SetWordWrap then p.reset.label:SetWordWrap(false) end
  FieldKitTheme.Font(p.reset.label,11,FieldKitTheme.muted)
  p.reset:SetScript("OnClick",function() Forward(source.fieldkitReset) end)
 end
 if not N.storage then N.storage=CreateFrame("Frame",nil,UIParent);N.storage:Hide() end
 for _,f in ipairs({source.fieldkitTabs,source.fieldkitReset}) do
  if not p.saved[f] then p.saved[f]=f:GetParent() end;f:SetParent(N.storage)
 end
 if not source:IsShown() or source.mashCollapsed or not FieldKitRebornDB.meterTabs then p:Hide();p.reset:Hide();return end
 p:ClearAllPoints();p:SetPoint("BOTTOMLEFT",source,"BOTTOMLEFT",12,8);p:SetPoint("BOTTOMRIGHT",source,"BOTTOMRIGHT",-12,8)
 p:SetFrameLevel(source:GetFrameLevel()+3)
 local width=(source:GetWidth()-24-116)/6
 local labels={"Dmg","Heal","Boss","Taken","Party","Kills short"}
 if FieldKit_L("Kills short")=="Kills short" then labels[6]="Kills" end
 for i,b in ipairs(p.buttons) do
  b:SetWidth(width);b:ClearAllPoints();b:SetPoint("LEFT",p,"LEFT",(i-1)*width,0);b.label:SetWidth(math.max(12,width-8));b.label:SetText(FieldKit_L(labels[i]))
  local selected=source.fieldkitMeterView==source.fieldkitTabs.buttons[i].fieldkitView
  if selected then b.line:Show();b.label:SetTextColor(1,.82,.25) else b.line:Hide();b.label:SetTextColor(.77,.77,.77) end
 end
 p.reset:ClearAllPoints();p.reset:SetPoint("BOTTOMRIGHT",source,"BOTTOMRIGHT",-12,10);p.reset.label:SetText(FieldKit_L("Reset"));p.reset:SetFrameLevel(source:GetFrameLevel()+3)
 p.reset:Show();p:Show()
end

-- Invisible hit surfaces let unlocked native widgets drag directly. Locked
-- widgets receive their original mouse input; no native script is replaced.
local nativeLayouts={
 {key="target",name="AzerothSurvivorsUnitFrameTarget",scale="nativeTargetScale",health=true},
 {key="map",name="Minimap",scale="nativeMinimapScale"},
 {key="player",name="AzerothSurvivorsUnitFramePlayer",scale="nativePlayerScale",health=true},
 {key="actions",name="AzerothSurvivorsActionBar1",scale="nativeActionScale",actions=true}}
local function Points(f)
 local out={}
 for i=1,(f.GetNumPoints and f:GetNumPoints() or 1) do
  local a={f:GetPoint(i)};if a[1] then table.insert(out,a) end
 end
 return out
end
local function RestorePoints(f,points)
 f:ClearAllPoints();for _,a in ipairs(points) do f:SetPoint(unpack(a)) end
end
local function StopNative(s)
 if not s or not s.dragging then return end
 s.dragging=nil;s.frame:StopMovingOrSizing();FieldKitPositions.Save(s.frame)
end
local function ForwardNative(hit,root,script)
 local source=hit;local fn=source:GetScript(script)
 if not fn and root~=hit then source=root;fn=source:GetScript(script) end
 if fn then local prior=this;this=source;pcall(fn,source,arg1);this=prior end
end
local function NativeHit(s,hit,index)
 s.hits=s.hits or {};N.nativeHits=N.nativeHits or {};local m=N.nativeHits[hit]
 if not m then
  m=CreateFrame("Button",nil,hit);N.nativeHits[hit]=m;m:RegisterForDrag("LeftButton");m:RegisterForClicks("LeftButtonUp","RightButtonUp")
  m:SetScript("OnMouseDown",function() m.suppressClick=nil end)
  m:SetScript("OnDragStart",function()
   local state=m.state
   if not state or FieldKitRebornDB.windowsLocked or FieldKit.IsChoiceScreen() then return end
   m.suppressClick=true;state.dragging=true;state.frame:SetMovable(true);state.frame:StartMoving()
  end)
  m:SetScript("OnDragStop",function() StopNative(m.state) end)
  m:SetScript("OnMouseUp",function() StopNative(m.state) end)
  m:SetScript("OnHide",function() StopNative(m.state) end)
  m:SetScript("OnClick",function()
   if m.suppressClick then m.suppressClick=nil;return end
   if hit.GetObjectType and hit:GetObjectType()=="Button" and hit.Click then hit:Click(arg1 or "LeftButton")
   elseif m.state.frame.GetObjectType and m.state.frame:GetObjectType()=="Button" and m.state.frame.Click then m.state.frame:Click(arg1 or "LeftButton")
   else ForwardNative(hit,m.state.frame,"OnMouseUp") end
  end)
  m:SetScript("OnEnter",function() ForwardNative(hit,m.state.frame,"OnEnter") end)
  m:SetScript("OnLeave",function() ForwardNative(hit,m.state.frame,"OnLeave") end)
  if m.EnableMouseWheel then m:EnableMouseWheel(true);m:SetScript("OnMouseWheel",function() ForwardNative(hit,m.state.frame,"OnMouseWheel") end) end
 end
 s.hits[index]=m;m.state=s
 m:SetAllPoints(hit);m:SetFrameLevel(hit:GetFrameLevel()+(s.key=="map" and 1 or 20))
 -- RegisterForDrag does not enable mouse input in Reborn. A visible Button
 -- can otherwise pass all synthetic callback tests while receiving no clicks.
 m:EnableMouse(s.enabled and true or false)
 if s.enabled then m:Show() else m:Hide() end
 return m
end
function N.ReleaseNativeLayout(key)
 local s=N.nativeLayouts and N.nativeLayouts[key];if not s then return end
 StopNative(s)
 for _,hit in ipairs(s.hits or {}) do hit:EnableMouse(false);hit:Hide() end
 s.frame:SetScale(s.scale);RestorePoints(s.frame,s.points);s.frame:SetMovable(s.movable)
 if s.dash then s.dash.frame:SetScale(s.dash.scale);RestorePoints(s.dash.frame,s.dash.points) end
 N.nativeLayouts[key]=nil
 if key=="target" then N.targetLayout=nil end
end
function N.ReleaseTargetLayout() N.ReleaseNativeLayout("target") end
function N.ReleaseNativeLayouts()
 for _,def in ipairs(nativeLayouts) do N.ReleaseNativeLayout(def.key) end
end
function N.TargetLayout()
 local d=FieldKitRebornDB;if not d or FieldKit.rebornLegacyFixture then return end
 N.nativeLayouts=N.nativeLayouts or {}
 for _,def in ipairs(nativeLayouts) do
  local f=getglobal(def.name)
  if f then
   local s=N.nativeLayouts[def.key]
   if s and s.frame~=f then N.ReleaseNativeLayout(def.key);s=nil end
   if not s then
    s={key=def.key,frame=f,scale=f:GetScale(),points=Points(f),movable=f.IsMovable and f:IsMovable() or false}
    N.nativeLayouts[def.key]=s
    if def.actions then
     local dash=getglobal("AZSDashButton")
     if dash and dash.GetCenter and f.GetCenter then
      local dx,dy=dash:GetCenter();local x,y=f:GetCenter()
      if dx and dy and x and y then
       local ds=dash:GetEffectiveScale();local fs=f:GetEffectiveScale()
       s.dash={frame=dash,points=Points(dash),scale=dash:GetScale(),x=(dx*ds-x*fs)/ds,y=(dy*ds-y*fs)/ds}
      end
     end
    end
   end
   local factor=FieldKit.Number(d[def.scale],100,50,150)/100
   local saved=d.frameAnchors[f:GetName()]
   if not s.dragging then
    if FieldKitPositions.Valid(saved) then FieldKitPositions.Restore(f);s.applied=true
    elseif s.applied then RestorePoints(f,s.points);s.applied=nil end
    f:SetScale(s.scale*factor)
   end
   if s.dash then
    local dash=s.dash
    if s.dragging or s.applied or factor~=1 then
     dash.frame:SetScale(dash.scale*factor);dash.frame:ClearAllPoints();dash.frame:SetPoint("CENTER",f,"CENTER",dash.x,dash.y);dash.applied=true
    elseif dash.applied then dash.frame:SetScale(dash.scale);RestorePoints(dash.frame,dash.points);dash.applied=nil end
   end
   s.enabled=not d.windowsLocked and f:IsShown() and f:GetAlpha()>0 and not FieldKit.IsChoiceScreen()
   if def.actions then
    for i=1,6 do local b=getglobal("AzerothSurvivorsActionBar1Button"..i);if b then NativeHit(s,b,i) end end
   else
    local hit=def.health and f.Health or f
    local m=NativeHit(s,hit,1)
    if def.key=="target" then N.targetLayout=s;N.targetMover=m end
   end
  end
 end
end
