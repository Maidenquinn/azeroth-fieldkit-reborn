-- Execute after the installed Reborn Anchors.lua: no fabricated capability endpoint or legacy fields.
fire(FieldKitFrame,"VARIABLES_LOADED")
AZS_GetWorldAnchorCapabilities=nil
AZS_RUN={ph="playing",id="markers32",t=10};AZS_ZONE={zone="elwynn"};AZS_UNITS={{id=3841,kind="boss",name="Boss"}};AZS_LAIRS={{id=3842,name="Guardian",state="awake"}};AZS_REVIVE={friends={}};AZS_CHESTS={{id=1,x=15,y=25,z=30,boss=0}}
UnitExists=function() return true end
UnitGUID=function(unit) return unit=="player" and "player" or nil end
AZS_WorldUnits=function(filter) local units={{guid="0x0000000000000F00",x=10,y=20,z=30,h=2,alive=true,rank=1,name="Elite"},{guid="0x0000000000000F01",x=10,y=20,z=30,h=2,alive=true,rank=3,name="Boss"},{guid="0x0000000000000F02",x=10,y=20,z=30,h=2,alive=true,rank=0,name="Guardian"},{guid="0x0000000000000F03",x=10,y=20,z=30,h=2,alive=true,rank=0,name="Ordinary mob"}};if filter==1 then table.remove(units,4);table.remove(units,3) end;return units end
AZS_UnitWorldPosition=function() return 10,20,30,50,true,0,1,123 end
local onScreen,headVisible=true,true
AZS_ProjectWorldPoint=function(x,y,z) return 400,300+z*10,1,1,onScreen and (headVisible or z<=30) end
NOW=20000
local A,M=FieldKitWorldAnchors,FieldKitWorldMarkers
M.Disable();A.Disable();FieldKitNative.Watch()
assert(A.Available(),"Installed Reborn anchors rejected because the legacy capability endpoint is missing")
assert(M.Enable() and M.IsEnabled() and A.Refresh())
local entries=A.Snapshot();assert(#entries>=1)
for _,e in ipairs(entries) do assert(e.kind~="enemy","Ordinary mobs leaked into the marker catalogue") end
assert(A.Project({{anchorId="0x0000000000000F00"}})==nil,"Projection escaped the post-camera handler")
AZS_OnWorldProjected()
local marker
for _,f in ipairs(objects) do if f.markerKind=="elite" and f:IsShown() then marker=f end end
assert(marker,"No marker rendered through the installed catalogue/projection/frame callback")
for _,kind in ipairs({"boss","guardian","cache"}) do
 local found=false;for _,f in ipairs(objects) do if f.markerKind==kind and f:IsShown() then found=true end end
 assert(found,"Installed native category missing: "..kind)
end
local _,relative,_,mx,my=marker:GetPoint();assert(relative==WorldFrame)
assert(math.abs(my-marker:GetHeight()/2-(300+(30+50*.35+.5/.9144)*10+8))<.001,"Calibrated native height/metric offset were not projected in world space")
for _,f in ipairs(objects) do if f.markerKind=="cache" and f:IsShown() then
 local _,_,_,_,cy=f:GetPoint();assert(cy==620+16,"Chest marker lacks its small screen-space gap")
end end
headVisible=false;AZS_OnWorldProjected();assert(not marker:IsShown(),"Off-screen head was replaced by a misleading marker inside the body")
headVisible=true
onScreen=false;AZS_OnWorldProjected();assert(not marker:IsShown(),"Off-screen native marker stayed visible")
onScreen=true;AZS_OnWorldProjected();assert(marker:IsShown())
AZS_ZONE={zone="naxxramas"};FieldKitNative.Watch();AZS_OnWorldProjected()
assert(not marker:IsShown(),"Previous-zone marker survived a native boundary")
NOW=20001;assert(A.Refresh());AZS_OnWorldProjected()
local count=#AZS_ApiWorld.worldHandlers;assert(M.Enable() and #AZS_ApiWorld.worldHandlers==count,"Repeated activation duplicated callbacks")
M.Disable();assert(not marker:IsShown());A.Disable();assert(#AZS_ApiWorld.worldHandlers==count-1)
local register=AZS_RegisterWorldAnchorFrameHandler
AZS_RegisterWorldAnchorFrameHandler=function() return nil,{code="UNAVAILABLE"} end
assert(not A.Enable() and not A.IsEnabled(),"Registration rejection reported engine on")
AZS_RegisterWorldAnchorFrameHandler=register
print("PASS installed Reborn world markers: missing legacy capabilities, native catalogue/projection/frame callback, outside-frame rejection, off-screen hide, zone clear, activation reuse, unregister and registration failure")
