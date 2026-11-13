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
AZS_RUN={ph="playing",t=10};AZS_ZONE={zone="hellfire",dt=0}
SlashCmdList.FieldKit("")
local C,V,d=FieldKitZoneThemes,FieldKitReferenceHUD,FieldKitRebornDB
d.zoneThemeMode="elwynn";d.zoneThemeVariant="complete";d.windowsLocked=false;d.takenFrame=true
FieldKitUI.hudActions.UpdateMeterFrames(true)
local f=FieldKitTakenFrame;local nativeParent=f:GetParent()
local rowLevel=f.rows[1]:GetFrameLevel()
C.Set("zoneThemes",true);C.Refresh(true)
assert(V.frames.Taken==f and f:IsShown() and f:GetParent()==V.canvas,"Taken card is outside the reference layout")
assert(f.rows[1]:GetFrameLevel()>f:GetFrameLevel(),"Taken rows hidden under material")
this=f.rows[1];f.rows[1]:GetScript("OnDragStart")();assert(f.azsMoving and not f.rows[1].azsMoving,"Row dragged itself instead of card")
f.rows[1]:GetScript("OnMouseUp")();assert(not f.azsMoving)
local function Apart(a,b)
 local x,y,w,h=V.LiveRect(a);local u,v,s,t=V.LiveRect(b)
 if a==V.frames.Damage then x=x+10;y=y+6;w=w-10;h=h-12 end
 if b==V.frames.Damage then u=u+10;v=v+6;s=s-10;t=t-12 end
 return math.min(x+w,u+s)-math.max(x,u)<=0 or math.min(y+h,v+t)-math.max(y,v)<=6
end
local function DragOnto(a,b)
 local x,y=V.LiveRect(b);this=a;a:GetScript("OnDragStart")();assert(a.azsMoving,"Card not draggable")
 a:ClearAllPoints();a:SetPoint("TOPLEFT",UIParent,"TOPLEFT",x,-y)
 a:GetScript("OnMouseUp")();assert(not a.azsMoving);C.Refresh(true)
end
DragOnto(f,V.frames.Damage)
assert(C.Position(f) and V.lastMoved=="Taken" and Apart(f,V.frames.Damage),"Dragging Taken did not displace Damage")
DragOnto(V.frames.Damage,f)
assert(V.lastMoved=="Damage" and Apart(f,V.frames.Damage),"Taken ignored another card's collision")
local saved=C.Position(f);assert(saved and saved[1]=="TOPLEFT")
local before=f:GetPoint();C.Refresh(true);assert(C.Position(f)==saved,"Automatic collision displacement rewrote user preference")
C.Set("zoneThemes",false)
assert(f:GetParent()==nativeParent,"Native Taken parent wasn't restored")
assert(f.rows[1]:GetFrameLevel()==rowLevel,"Classic Taken row levels weren't restored")
assert(f:GetScript("OnDragStart"),"Classic drag handler was lost")
for _,variant in ipairs({"minimal","alternative"}) do
 d.zoneThemeVariant=variant;FieldKitUI.hudActions.UpdateMeterFrames(true);C.Set("zoneThemes",true);C.Refresh(true)
 assert(V.frames.Taken==f and f:IsShown() and f:GetParent()==V.canvas,variant.." Taken isn't managed")
 this=f;f:GetScript("OnDragStart")();assert(f.azsMoving);f:GetScript("OnMouseUp")();C.Set("zoneThemes",false)
end
print("PASS Taken uses shared theme drag/collisions in both directions, retains scoped preference, restores classic ownership")
