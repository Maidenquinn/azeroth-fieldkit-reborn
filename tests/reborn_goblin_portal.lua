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

-- Rifts use the same snapshot and checked pose, with independent preference and lifecycle.
d.goblinPortalAlert=false
d.riftPortalIndicator=true;d.riftPortalAlert=true
Run()
Reference()
local function Marks(raw,got,need,st)
 AZS_RIFT={m=raw,got=got,need=need,st=st}
 Packet("AZSRIFT")
end
local function RiftCard(title)
 assert(T.riftFrame and T.riftFrame:IsShown())
 assert(T.riftFrame.portalTitle==title,T.riftFrame.portalTitle)
end
Marks(nil,2,4,"sealed");T.Update()
assert(P.got==2 and P.need==4 and P.rift.state=="unsynced" and not T.riftFrame)
Marks("",2,4);assert(P.rift.state=="absent")
Marks("p:0.525:0.5",2,4,"sealed");T.Update()
RiftCard("Rift portal sealed")
assert(T.riftFrame.portalProgress==string.format(FieldKit_L("Crystals: %d/%d"),2,4))
assert(table.getn(T.warnings)==1 and T.warnings[1].kind=="rift")
assert(P.nativeState=="sealed" and P.receivedAt==NOW)
Marks("p:0.525:0.5",3,4,"sealed");T.Update()
assert(table.getn(T.warnings)==1)
assert(T.riftFrame.portalProgress==string.format(FieldKit_L("Crystals: %d/%d"),3,4))
Marks("o:0.525:0.5/v:0.8:0.7/c:0.51:0.51/z:0.1:0.2",4,4,"open")
local poseReads=P.poseReads
T.PortalView()
RiftCard("Rift portal open")
assert(P.poseReads==poseReads+1 and T.portalFrame:IsShown(),"distance did not share one pose")
assert(table.getn(P.marks.c)==1 and P.marks.unknown==1)
assert(table.getn(T.warnings)==2 and T.warnings[2].text==FieldKit_L("Rift portal open"))
Marks("o:0.525:0.5/p:0.2:0.3",0,4,"open")
T.Update();RiftCard("Open and sealed rifts");Expect("disappeared",false,2)
Marks("o:0.525:0.5/p:0.2:0.3",7,4,"open");T.Update()
assert(T.riftFrame.portalProgress==nil)
d.riftPortalAlert=false;T.Update();assert(table.getn(T.warnings)==0)
Marks("c:0.51:0.51",4,4,"open");T.Update()
assert(P.rift.state=="disappeared" and not T.riftFrame:IsShown() and table.getn(P.marks.c)==1)
assert(native:IsShown() and writes==0 and not T.subscribed)
SlashCmdList.FieldKit("rift")
d.riftPortalAlert=true
Packet("AZSPASSAGE","st=enter")
Marks("p:0.525:0.5",1,4);assert(P.rift.state=="invalid_context")
Packet("AZSPASSAGE","st=arrive");Packet("AZSRUN")
Marks("o:0.525:0.5",4,4);T.Update()
RiftCard("Rift portal open");assert(table.getn(T.warnings)==0)
NOW=NOW+6;Marks("p:0.2:0.3",0,4)
Marks("o:0.21:0.3",4,4)
assert(table.getn(T.warnings)==0,"opening event correlated unrelated points")
WorldMapFrame:Show();T.PortalView()
assert(P.rift.distanceReason=="missing_reference" or P.rift.distanceReason=="map_open")
assert(T.riftFrame:IsShown() and native:IsShown())
Marks("p:1.2:0.3",1,4);T.Update()
assert(P.rift.state=="unsynced" and not T.riftFrame:IsShown())
print("PASS sealed/open rifts, startup and overlap, crystal counters, diagnostic-only c, shared pose, arena boundary and no false or duplicate alert")
