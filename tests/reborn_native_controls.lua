local specs={
 {"target","AzerothSurvivorsUnitFrameTarget","nativeTargetScale"},
 {"map","Minimap","nativeMinimapScale"},
 {"player","AzerothSurvivorsUnitFramePlayer","nativePlayerScale"},
 {"actions","AzerothSurvivorsActionBar1","nativeActionScale"}}
local clicks,frames,received={},{},{}
for i,def in ipairs(specs) do
 local key=def[1];local scale=1
 local f=CreateFrame((key=="target" or key=="player") and "Button" or "Frame",def[2],UIParent)
 -- Explicit type; the native unit roots are buttons, while map/bar are frames.
 f.kind=(key=="target" or key=="player") and "Button" or "Frame"
 f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",i*100,-50);f:SetAlpha(1)
 f.GetScale=function() return scale end;f.SetScale=function(_,v) scale=v end
 f:SetScript(key=="map" and "OnMouseUp" or "OnClick",function(self,button) received[key]={this,self,button};clicks[key]=(clicks[key] or 0)+1;assert(this==f);if key=="map" then assert(self==f and button=="LeftButton","Native callback arguments were lost") end end)
 if key=="target" or key=="player" then f.Health=CreateFrame("StatusBar",nil,f) end
 frames[key]=f
end
for i=1,6 do
 local b=CreateFrame("Button","AzerothSurvivorsActionBar1Button"..i,frames.actions)
 b:SetScript("OnClick",function() clicks.spell=(clicks.spell or 0)+1;assert(this==b) end)
end
local dash=CreateFrame("Button","AZSDashButton",UIParent)
dash:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",440,48)
fire(FieldKitFrame,"VARIABLES_LOADED")
local N,d=FieldKitNativeHUD,FieldKitRebornDB
N.ReleaseNativeLayouts();d.windowsLocked=false
AZS_RUN={ph="playing",t=10};N.TargetLayout()
for i,def in ipairs(specs) do
 local key,f=def[1],frames[def[1]];local s=N.nativeLayouts[key];local hit=s.hits[1]
 assert(hit:IsShown() and not hit.label and not hit.fieldkitSkin,"Direct drag has a visible mover button")
 assert(hit:IsMouseEnabled(),"Visible native drag surface cannot receive the mouse")
 if key=="map" then assert(hit:GetFrameLevel()==f:GetFrameLevel()+1,"Map surface must sit above the map, below pins") end
 assert(hit:GetParent()==(f.Health or (key=="actions" and AzerothSurvivorsActionBar1Button1) or f))
 hit:Click("LeftButton")
 assert((key=="actions" and clicks.spell or clicks[key])==1,"Native click was lost")
 if key=="map" then assert(received[key][1]==f and received[key][2]==f and received[key][3]=="LeftButton","Native callback context/arguments were lost") end
 hit:GetScript("OnDragStart")();assert(s.dragging)
 f:ClearAllPoints();f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",600+i,-200)
 hit:GetScript("OnDragStop")();assert(not s.dragging)
 hit:Click("LeftButton")
 assert((key=="actions" and clicks.spell or clicks[key])==1,"Drag caused an accidental native click")
 assert(d.frameAnchors[f:GetName()][3]==600+i)
 d[def[3]]=70+i;N.TargetLayout();assert(f:GetScale()==(70+i)/100)
 local _,_,_,x=f:GetPoint();assert(x==600+i,"Refresh discarded native placement")
end
assert(N.nativeLayouts.actions.dash.applied,"Steed did not follow the moved spell bar")
d.windowsLocked=true;N.TargetLayout()
for _,s in pairs(N.nativeLayouts) do for _,hit in ipairs(s.hits) do
 assert(not hit:IsShown() and not hit:IsMouseEnabled());hit:GetScript("OnDragStart")();assert(not s.dragging)
end end
d.windowsLocked=false;AZS_RUN.ph="choosing";N.TargetLayout()
for _,s in pairs(N.nativeLayouts) do for _,hit in ipairs(s.hits) do assert(not hit:IsShown()) end end
AZS_RUN.ph="playing"
local cached=N.nativeHits[frames.target.Health]
for pass=1,3 do
 N.ReleaseNativeLayouts()
 for i,def in ipairs(specs) do
  local f=frames[def[1]];assert(f:GetScale()==1)
  local _,_,_,x=f:GetPoint();assert(x==i*100,"Native geometry was not restored")
 end
 N.TargetLayout();assert(N.nativeHits[frames.target.Health]==cached,"Theme cycling allocated extra drag surfaces")
end
N.ReleaseNativeLayouts()
local point= dash:GetPoint();assert(point=="BOTTOMLEFT","Steed geometry was not restored")
print("PASS invisible direct native drag, four independent scales/anchors, normal clicks, no clicks on drag, locks/choices, Steed following and cached reversible ownership")
