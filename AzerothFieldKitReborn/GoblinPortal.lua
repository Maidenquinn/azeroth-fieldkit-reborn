-- Read-only adapter for the replaced AZSRIFT snapshot in Reborn. The native
-- payload does not identify an instance, its map, or its lifetime.
local N=FieldKitNative
local P={state="unsynced",reason="startup",points={},refs={},packets=0,decodes=0,poseReads=0}
N.Portal=P
P.rift={state="unsynced",points={}}

local REF_TABLE={AZSCHESTS="AZS_CHESTS",AZSLAIRS="AZS_LAIRS"}
local MAX_BYTES,MAX_ROWS,MAX_REFS=4096,32,16
local function Number01(raw)
 local number=FieldKit.Number(raw)
 if number and number>=0 and number<=1 then return number end
end

local function Decode(raw)
 if type(raw)~="string" or string.len(raw)>MAX_BYTES then return nil end
 local points,rows,offset={p={},o={},v={},c={},rift={},unknown=0},0,1
 if raw=="" then return points end
 while true do
  local first=string.find(raw,"/",offset,true)
  local row=string.sub(raw,offset,first and first-1 or -1)
  local _,_,kind,sx,sy=string.find(row,"^([a-z]):([%d.%-]+):([%d.%-]+)$")
  local x,y=Number01(sx),Number01(sy)
  rows=rows+1
  if not kind or not x or not y or rows>MAX_ROWS then return nil end
  local bucket=points[kind]
  if bucket then
   local duplicate=false
   for _,point in ipairs(bucket) do
    if point.x==x and point.y==y then duplicate=true;break end
   end
   if not duplicate then
    local point={x=x,y=y,kind=kind}
    table.insert(bucket,point)
    if kind=="p" or kind=="o" then table.insert(points.rift,point) end
   end
  else points.unknown=points.unknown+1 end
  if not first then return points end
  offset=first+1
 end
end

local function Current()
 local zone,run=AZS_ZONE,AZS_RUN
 if type(zone)~="table" or type(run)~="table" or tonumber(zone.hub)==1 then return end
 local phase=N.Read("AZS_GetPhase")
 if phase~="ready" and phase~="playing" and phase~="choosing" and phase~="paused" then return end
 local key=zone.run
 if type(key)~="string" then return end
 if string.sub(key,1,4)=="azs:" then key=string.sub(key,5) end
 -- Older counters that restart at reload cannot establish this packet's scope.
 if string.len(key)~=9 or not string.find(key,"^r%x+$") or type(zone.zone)~="string" or zone.zone=="" then return end
 local map,time=FieldKit.Number(zone.map),FieldKit.Number(run.t)
 if not map or map<0 or not time or time<0 then return end
 return "azs:"..key,zone.zone,map,time,FieldKit.Number(zone.mw),FieldKit.Number(zone.mh),phase
end

function P.Reset(reason)
 P.state,P.reason="invalid_context",reason
 P.points,P.refs={},{}
 P.rift.state,P.rift.points="invalid_context",{}
 P.marks,P.nativeState,P.got,P.need,P.receivedAt=nil,nil,nil,nil,nil
 P.runId,P.zone,P.map,P.time,P.width,P.height=nil,nil,nil,nil,nil,nil
 P.area,P.floor,P.phase=nil,nil,nil
 P.source=AZS_RIFT
 P.raw,P.decoded=nil,nil
 P.distanceReason,P.rift.distanceReason="no_context","no_context"
end

-- Only a run packet establishes a baseline after a boundary; an old global
-- snapshot from the preceding run/arena is never adopted while polling.
function P.WorldEntry()
 P.holds,P.zoneReady=nil,nil
 P.Reset("world_entry")
end

function P.Check(accept)
 if not accept and not P.runId then return end
 local id,zone,map,time,width,height,phase=Current()
 local changed=P.runId and (P.runId~=id or P.zone~=zone or P.map~=map or time+1<P.time
   or P.width~=width or P.height~=height or (phase=="ready" and P.phase~="ready"))
 if changed then
  P.Reset("run_or_map_changed")
  if not accept then return true end
 end
 if accept and P.zoneReady and not P.holds and id and not P.runId then
  P.runId,P.zone,P.map,P.time,P.width,P.height=id,zone,map,time,width,height
  P.state,P.reason="unsynced","waiting_for_rift"
  P.rift.state="unsynced"
 end
 if P.runId then P.time,P.phase=time,phase end
 return changed
end

local function ReadReference(prefix)
 local lines=getglobal(REF_TABLE[prefix])
 P.refs[prefix]=nil
 if not P.runId or type(lines)~="table" then return end
 for i=1,math.min(MAX_REFS,table.getn(lines)) do
  local e=lines[i]
  if type(e)=="table" and e.runId==P.runId and tonumber(e.mapId)==P.map then
   local x,y=FieldKit.Number(e.x),FieldKit.Number(e.y)
   local mx,my=Number01(e.mx),Number01(e.my)
   if x and y and mx and my then
    P.refs[prefix]={x=x,y=y,mx=mx,my=my}
    return
   end
  end
 end
end

local function Status(previous,points)
 if table.getn(points)>0 then return "present" end
 if previous=="present" or previous=="disappeared" then return "disappeared" end
 return "absent"
end

local function Contains(points,target)
 for _,point in ipairs(points) do
  if point.x==target.x and point.y==target.y then return true end
 end
 return false
end

local function Opened(previous,current)
 if not previous or previous==current then return false end
 for _,point in ipairs(current.o) do
  if Contains(previous.p,point) and not Contains(previous.o,point) then return true end
 end
 return false
end

local function Count(raw)
 local value=FieldKit.Number(raw)
 if value and value>=0 and value<=2147483647 and value==math.floor(value) then return value end
end

local function Rift()
 P.packets=P.packets+1
 P.lastPacket=GetTime()
 local source=AZS_RIFT
 P.lastPacketReason="native_table_unchanged"
 if source==P.source then return false end
 P.source=source
 P.lastPacketReason="invalid_context"
 if not P.runId or P.holds then return false end
 P.receivedAt=P.lastPacket
 local marks,raw
 P.nativeState,P.got,P.need=nil,nil,nil
 if type(source)=="table" then
  raw=source.m
  if type(source.st)=="number" or type(source.st)=="string" then P.nativeState=N.Text(tostring(source.st),40) end
  P.got,P.need=Count(source.got),Count(source.need)
 end
 if type(raw)=="string" then
  if raw==P.raw then marks=P.decoded
  else
   P.decodes=P.decodes+1
   marks=Decode(raw)
   P.raw,P.decoded=nil,nil
   if string.len(raw)<=MAX_BYTES then P.raw,P.decoded=raw,marks end
  end
 end
 local previous,previousMarks,previousRift=P.state,P.marks,P.rift.state
 P.marks=marks
 if not marks then
  P.state,P.reason,P.points="unsynced",raw==nil and "missing_marks" or "malformed_marks",{}
  P.rift.state,P.rift.points="unsynced",{}
  P.lastPacketReason=P.reason
  return true
 end
 P.reason,P.lastPacketReason="received","received"
 P.state,P.points=Status(previous,marks.v),marks.v
 P.rift.state,P.rift.points=Status(previousRift,marks.rift),marks.rift
 if P.phase~="playing" then return true end
 local goblin=P.state=="present" and (previous=="absent" or previous=="disappeared")
 local rift
 if P.rift.state=="present" then
  if Opened(previousMarks,marks) then rift="open"
  elseif previousRift=="absent" or previousRift=="disappeared" then
   rift=table.getn(marks.o)>0 and "open" or "sealed"
  end
 end
 return true,goblin,rift
end

function P.Packet(prefix,message)
 if prefix=="AZSZONE" or prefix=="AZSEND" then
  if prefix=="AZSZONE" then P.zoneReady=true end
  P.Reset(prefix)
  return true
 end
 if prefix=="AZSPASSAGE" or prefix=="AZSHANDOVER" then
  local _,_,state=string.find(type(message)=="string" and message or "","^st=([^;]+)")
  if not state then
   _,_,state=string.find(type(message)=="string" and message or "",";st=([^;]+)")
  end
  local resumed=(prefix=="AZSPASSAGE" and state=="arrive") or (prefix=="AZSHANDOVER" and state=="done")
  if resumed then
   if P.holds then
    P.holds[prefix]=nil
    if not next(P.holds) then P.holds=nil end
   end
  else
   P.holds=P.holds or {};P.holds[prefix]=true
  end
  P.Reset(prefix)
  return true
 end
 if prefix=="AZSRUN" then
  return P.Check(true)
 end
 if prefix=="AZSRIFT" or REF_TABLE[prefix] then
  local changed=P.Check()
  if prefix=="AZSRIFT" then
   local snapshot,appearance,rift=Rift()
   return changed or snapshot,appearance,rift
  end
  ReadReference(prefix)
  return changed
 end
end

local function MapPose()
 if not P.width or P.width<=0 or not P.height or P.height<=0 then return nil,"missing_dimensions" end
 local ref=P.refs.AZSCHESTS or P.refs.AZSLAIRS
 if not ref then return nil,"missing_reference" end
 -- Do not let a browsed map drive a distance. Neither stock getter below
 -- changes the map selection or zoom.
 if WorldMapFrame and WorldMapFrame:IsShown() then return nil,"map_open" end
 if type(GetPlayerMapPosition)~="function" or type(AZS_UnitWorldPosition)~="function"
    or type(GetCurrentMapAreaID)~="function" then return nil,"missing_position_api" end
 P.poseReads=P.poseReads+1
 local area=FieldKit.Number(GetCurrentMapAreaID())
 local floor=GetCurrentMapDungeonLevel and FieldKit.Number(GetCurrentMapDungeonLevel())
 if not area or area<=0 or (P.area and (P.area~=area or P.floor~=floor)) then return nil,"different_map" end
 local px,py=GetPlayerMapPosition("player")
 px,py=Number01(px),Number01(py)
 local x,y=AZS_UnitWorldPosition("player")
 x,y=FieldKit.Number(x),FieldKit.Number(y)
 if not px or not py or (px==0 and py==0) or not x or not y then return nil,"missing_position" end
 -- Independent native world pose must agree with the stock map pose, using
 -- a fresh run-scoped point carrying both coordinate systems (Api.lua).
 local mapX=ref.mx-(y-ref.y)/P.width
 local mapY=ref.my-(x-ref.x)/P.height
 if math.abs((mapX-px)*P.width)>1 or math.abs((mapY-py)*P.height)>1 then return nil,"different_map" end
 P.area,P.floor=area,floor
 return px,py
end

local function Distance(points,px,py)
 local nearest
 for _,point in ipairs(points) do
  local dx,dy=(point.x-px)*P.width,(point.y-py)*P.height
  local square=dx*dx+dy*dy
  if not nearest or square<nearest then nearest=square end
 end
 return nearest and math.sqrt(nearest)
end

-- Both display cards use the same checked pose and the same snapshot scope.
function P.Distances(goblin,rift)
 local ok,px,py=pcall(MapPose)
 local reason=ok and (px and "ready" or py) or "position_error"
 if goblin then P.distanceReason=reason end
 if rift then P.rift.distanceReason=reason end
 if ok and px then
  return goblin and Distance(P.points,px,py),rift and Distance(P.rift.points,px,py)
 end
end

function P.Distance()
 if P.state=="present" then return P.Distances(true,false) end
end
