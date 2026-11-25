-- Synthetic packets model the installed router replacing AZS_RIFT first.
fire(FieldKitFrame,"VARIABLES_LOADED")
local d,T,P=FieldKitRebornDB,FieldKitNativeTools,FieldKitNative.Portal
local profiles=FieldKitProfiles
local runKey="azs:r00000001"
local far="v:0.8:0.7"
local near="v:0.525:0.5"
local writes=0
local native=CreateFrame("Frame","TestNativeRiftPin",Minimap)
native:Show()
SetMapToCurrentZone=function() error("Portal changed the map") end
Minimap.SetZoom=function() error("Portal changed the zoom") end
AZS_WorldUnits=function() error("Portal enumerated units") end
AZS_SetHudShown=function() writes=writes+1 end

local worldX,worldY,px,py,area,floor=10,20,.5,.5,12,0
GetPlayerMapPosition=function(unit) assert(unit=="player");return px,py end
AZS_UnitWorldPosition=function(unit) assert(unit=="player");return worldX,worldY,0 end
GetCurrentMapAreaID=function() return area end
GetCurrentMapDungeonLevel=function() return floor end
WorldMapFrame=CreateFrame("Frame","TestWorldMap",UIParent)
WorldMapFrame:Hide()
AZS_GetPhase=function() return AZS_RUN and AZS_RUN.ph end

local function Packet(prefix,payload)
 arg2=payload;arg3="PARTY";arg4=nil
 fire(FieldKitFrame,"CHAT_MSG_ADDON",prefix)
 arg1,arg2,arg3,arg4=nil,nil,nil,nil
end
local function Rift(m)
 AZS_RIFT={m=m}
 Packet("AZSRIFT","m="..tostring(m))
end
local function Run(map,zone,key,phase)
 runKey=key or runKey
 AZS_ZONE={zone=zone or "elwynn",run=runKey,map=map or 0,mw=800,mh=1000}
 AZS_RUN={ph=phase or "playing",t=100}
 Packet("AZSZONE");Packet("AZSRUN")
end
local function Reference()
 AZS_CHESTS={{x=10,y=20,mx=.5,my=.5,runId=runKey,mapId=AZS_ZONE.map}}
 Packet("AZSCHESTS")
end
local function Expect(state,shown,warnings)
 assert(P.state==state,P.state.." expected "..state)
 assert(not not (T.portalFrame and T.portalFrame:IsShown())==shown,"card visibility")
 assert(table.getn(T.warnings)==warnings,"warning count")
 assert(native:IsShown() and writes==0,"native marker ownership changed")
end

assert(not d.goblinPortalIndicator and not d.goblinPortalAlert)
d.goblinPortalIndicator=true;d.goblinPortalAlert=true
Run(nil,nil,nil,"ready")
T.Update();Expect("unsynced",false,0)
Rift(nil);Expect("unsynced",false,0)
AZS_RIFT={m=far};T.Update();Expect("unsynced",false,0) -- No packet, even if the global is present.
Rift("");Expect("absent",false,0)
AZS_RUN.ph="playing";Packet("AZSRUN")
Reference()
Rift(far.."/"..near.."/"..near.."/p:0.25:0.25")
T.Update();Expect("present",true,1)
assert(table.getn(P.points)==2)
assert(math.abs(P.Distance()-20)<0.001 and P.distanceReason=="ready")
local card=T.portalFrame
assert(card:GetWidth()==240 and card:GetHeight()==44)
assert(card:GetParent()==UIParent,"portal card attached to the minimap")
local decoded=P.decodes
local repeats=500
local started=os.clock()
for i=1,repeats do Rift(far.."/"..near.."/"..near.."/p:0.25:0.25") end
local repetitionTime=os.clock()-started
assert(decoded==P.decodes and T.portalFrame==card)
Expect("present",true,1)
local reads=P.poseReads
assert(type(card:GetScript("OnUpdate"))=="nil" and P.poseReads==reads)

WorldMapFrame:Show();T.PortalView()
assert(P.distanceReason=="map_open" and card:GetHeight()==32)
Expect("present",true,1)
WorldMapFrame:Hide();area=13;T.PortalView()
assert(P.distanceReason=="different_map" and card:GetHeight()==32)
area=12;floor=1;T.PortalView()
assert(P.distanceReason=="different_map")
floor=0;px=.6;T.PortalView()
assert(P.distanceReason=="different_map","wrong map pose with the same map area id was trusted")
px=.5;worldX=nil;T.PortalView()
assert(P.distanceReason=="missing_position")
worldX=10;px=nil;T.PortalView()
assert(P.distanceReason=="missing_position")
px=.5;T.PortalView();assert(card:GetHeight()==44)

Rift("p:0.20:0.30");Expect("disappeared",false,0)
Rift("");Expect("disappeared",false,0)
Rift("v:NaN:0.5");Expect("unsynced",false,0)
Rift(near.."/");Expect("unsynced",false,0)
Rift(string.rep("v:0:0/",33).."v:0:0");Expect("unsynced",false,0)
Rift(near);T.Update();Expect("present",true,0) -- Unknown to present does not notify.

Run(1,"karazhan",nil)
Expect("unsynced",false,0)
local stale=AZS_RIFT
Packet("AZSRIFT");assert(stale==AZS_RIFT)
Expect("unsynced",false,0)
Rift(near);T.Update();Expect("present",true,0)
assert(P.distanceReason=="missing_reference")
AZS_ZONE.run="azs:r00000002";Packet("AZSRUN")
Expect("unsynced",false,0)
Rift(near);T.Update();Expect("present",true,0)

Packet("AZSPASSAGE","st=enter;left=1")
Expect("invalid_context",false,0)
Packet("AZSHANDOVER","st=start")
Packet("AZSHANDOVER","st=done");Packet("AZSRUN");Rift(near)
Expect("invalid_context",false,0) -- An overlapping handover does not release the arena gate.
Packet("AZSPASSAGE","st=arrive");Packet("AZSRUN");Rift(near)
T.Update();Expect("present",true,0)
Packet("AZSHANDOVER","st=start");Rift(near);Expect("invalid_context",false,0)
Packet("AZSHANDOVER","st=done");Packet("AZSRUN");Rift(near)
T.Update();Expect("present",true,0)
Packet("AZSEND");Expect("invalid_context",false,0)
AZS_RUN.ph="victory";Packet("AZSRUN");Rift(near);Expect("invalid_context",false,0)
AZS_RUN.ph="playing";AZS_RUN.endless=1;Packet("AZSRUN");Rift(near)
T.Update();Expect("present",true,0)
fire(FieldKitFrame,"PLAYER_ENTERING_WORLD")
Expect("invalid_context",false,0)
Packet("AZSRUN");Rift(near);Expect("invalid_context",false,0)
Packet("AZSZONE");Packet("AZSRUN");Rift(near)
T.Update();Expect("present",true,0) -- Reload sync while the portal is already open.

d.goblinPortalIndicator=false;d.goblinPortalAlert=false;assert(profiles.Save(1))
d.goblinPortalIndicator=true;d.goblinPortalAlert=true;assert(profiles.Save(2))
assert(profiles.Load(1));Expect("present",false,0)
reads=P.poseReads;T.Update();assert(P.poseReads==reads)
NOW=NOW+6;Rift("");Rift(near);Expect("present",false,0)
assert(profiles.Load(2));Expect("present",true,0)
d.goblinPortalIndicator=false;d.goblinPortalAlert=true;T.Update()
Rift("");Rift(near);Expect("present",false,1)
assert(T.warnings[1].kind=="portal" and not T.subscribed)
d.goblinPortalAlert=false;T.Update();Expect("present",false,0)
d.goblinPortalIndicator=true;T.Update();Expect("present",true,0)
local theme=FieldKitZoneThemes
theme.allowUnfinishedThemes=true
for _,name in ipairs({"elwynn","naxx"}) do
 theme.Set("zoneThemes",false)
 d.zoneThemeMode=name;d.zoneThemeVariant="complete"
 theme.Set("zoneThemes",true)
 T.Update();Expect("present",true,0)
 assert(T.portalFrame==card and card.fieldkitSkin.hud)
end
theme.Set("zoneThemes",false)
AZS_RUN.ph="choosing";Packet("AZSRUN");T.Update();Expect("present",false,0)
AZS_RUN.ph="playing";Packet("AZSRUN");T.Update();Expect("present",true,0)
SlashCmdList.FieldKit("portal")
AZS_ZONE.mw=nil;T.Update()
Expect("invalid_context",false,0)
assert(T.portalFrame==card,"portal rendering rebuilt its frame")
print(string.format("PASS goblin portal lifecycle, distance, profile/reload and native ownership (%d synthetic repeated messages in %.1f ms, 0 reparses)",repeats,repetitionTime*1000))
