fire(FieldKitFrame,"VARIABLES_LOADED")
UIParent:SetWidth(1686);UIParent:SetHeight(933)
local points={TOPLEFT={0,1},TOP={.5,1},TOPRIGHT={1,1},LEFT={0,.5},CENTER={.5,.5},RIGHT={1,.5},BOTTOMLEFT={0,0},BOTTOM={.5,0},BOTTOMRIGHT={1,0}}
local function Bounds(f,depth)
 if f==UIParent then return 0,933 end
 if (depth or 0)>20 then return 0,933 end
 local p,rel,rp,x,y=f:GetPoint();rel=type(rel)=="string" and getglobal(rel) or rel
 if not p or not rel then return 0,933 end
 local l,t=Bounds(rel,(depth or 0)+1);local a,b=points[p],points[rp or p]
 return l+rel:GetWidth()*b[1]+(x or 0)-f:GetWidth()*a[1],t-rel:GetHeight()*(1-b[2])+(y or 0)+f:GetHeight()*(1-a[2])
end
local methods=getmetatable(UIParent).__index
methods.GetLeft=function(self) local l=Bounds(self);return l end
methods.GetTop=function(self) local _,t=Bounds(self);return t end

AZS_RUN={ph="playing",t=10};AZS_ZONE={zone="elwynn",dt=0}
AZS_SCHEDULE={{index=1,name="Hogger",state="due"},{index=2,name="Mother Fang",state="due"}}
local C,V,T,d=FieldKitZoneThemes,FieldKitReferenceHUD,FieldKitNativeTools,FieldKitRebornDB
C.allowUnfinishedThemes=true;d.windowsLocked=false;d.zoneThemeOverlap=false;d.bossListCard=true
SlashCmdList.FieldKit("");FieldKitNative.Watch();FieldKitNative.Packet("AZSBOSSES")
local f=FieldKitBossListFrame;local parent=f:GetParent();local level=f.rows[1]:GetFrameLevel()
local function Apart(a,b)
 local x,y,w,h=V.LiveRect(a);local u,v,s,t=V.LiveRect(b)
 -- The roster uses inset 6/2/6/4; the other frame has its own measured rim.
 local damage=V.key=="naxx_complete" and {4,1,6,5} or {10,6,0,6}
 local n=a==f and {6,2,6,4} or damage
 local m=b==f and {6,2,6,4} or damage
 return math.min(x+w-n[3],u+s-m[3])-math.max(x+n[1],u+m[1])<=0 or
  math.min(y+h-n[4],v+t-m[4])-math.max(y+n[2],v+m[2])<=6
end
local function Drag(a,b)
 local x,y=V.LiveRect(b);this=a;a:GetScript("OnDragStart")();assert(a.azsMoving)
 a:ClearAllPoints();a:SetPoint("TOPLEFT",UIParent,"TOPLEFT",x,-y)
 a:GetScript("OnMouseUp")();assert(not a.azsMoving);C.Refresh(true)
end
local function DockButton()
 for _,b in ipairs(objects) do
  if b.GetParent and b:GetParent()==FieldKitCollapseDock and b.fieldkitLabel and b.fieldkitLabel:GetText()==FieldKit_L("Campaign bosses") and b:IsShown() then return b end
 end
end
for _,zone in ipairs({"elwynn","naxx"}) do for _,variant in ipairs({"complete","minimal","alternative"}) do
 d.zoneThemeMode=zone;d.zoneThemeVariant=variant;C.Set("zoneThemes",true);T.Update();C.Refresh(true)
 assert(V.frames.BossList==f and f:GetParent()==V.canvas and f:IsShown())
 assert(f.mashCollapseButton:GetFrameStrata()=="MEDIUM" and f.mashCollapseButton:GetFrameLevel()>f:GetFrameLevel())
 assert(f.rows[1]:GetFrameStrata()=="MEDIUM" and f.rows[1]:GetFrameLevel()>f:GetFrameLevel())
 this=f.rows[1];f.rows[1]:GetScript("OnDragStart")();assert(f.azsMoving and not f.rows[1].azsMoving);f.rows[1]:GetScript("OnMouseUp")()
 if variant=="complete" then
  Drag(f,V.frames.Damage);assert(V.lastMoved=="BossList" and Apart(f,V.frames.Damage),"Roster does not displace the meter")
  local saved=C.Position(f);assert(saved)
  Drag(V.frames.Damage,f);assert(V.lastMoved=="Damage" and Apart(f,V.frames.Damage),"Meter does not displace the roster")
  assert(C.Position(f)==saved,"Collision overwrote the preferred anchor")
 end
 click(f.mashCollapseButton);local button=DockButton()
 assert(button and f.fieldkitDockHidden and not f:IsShown(),"Roster did not join the shared dock")
 for i=1,5 do T.Update();C.Refresh(true);assert(not f:IsShown(),"Refresh resurrected the collapsed roster") end
 click(button);T.Update();C.Refresh(true)
 assert(not f.mashCollapsed and not f.fieldkitDockHidden and f:IsShown(),"Dock did not restore the roster")
 C.Set("zoneThemes",false);T.Update()
 assert(f:GetParent()==parent and f.rows[1]:GetFrameLevel()==level,"Theme release lost native ownership")
 click(f.mashCollapseButton);button=DockButton();assert(button and not f:IsShown())
 T.Update();assert(not f:IsShown());click(button);T.Update();assert(f:IsShown())
end end
print("PASS campaign roster: bidirectional reference collisions, row drag, scoped anchor, shared dock collapse/restore over repeated refreshes, two theme families/all variants and native restoration")

-- Themes off uses the native resolver, with the roster as both mover and neighbour.
d.linkLeftCards=false;d.linkRightCards=false;d.zoneThemeOverlap=false
local meter=FieldKitMeterFrame;local L=FieldKitNativeLayout
local function NativeDrop(a,b)
 a:Show();b:Show();a:ClearAllPoints();b:ClearAllPoints()
 a:SetPoint("TOPLEFT",UIParent,"TOPLEFT",620,-240);b:SetPoint("TOPLEFT",UIParent,"TOPLEFT",620,-240)
 L.lastMoved=a;L.Apply()
 assert(not L.Overlap(L.Rect(a),L.Rect(b)),"Native roster/meter collision ignored")
end
NativeDrop(f,meter);NativeDrop(meter,f)
print("PASS native campaign card bidirectional collision regression")
