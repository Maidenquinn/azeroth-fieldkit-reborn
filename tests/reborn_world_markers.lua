fire(FieldKitFrame,"VARIABLES_LOADED")
local A,M=FieldKitWorldAnchors,FieldKitWorldMarkers
M.Disable();A.Disable()
AZS_GetWorldAnchorCapabilities=nil;AZS_GetPhase=function() return "playing" end
AZS_ProjectWorldPoint=function() return 10,20,1,1,true end
local handler,calls=nil,0
AZS_GetWorldAnchors=function(query,cursor,limit)
 assert(limit==256 and type(query.kinds)=="table")
 return {entries={{anchorId="test:"..(cursor or "first"),kind="elite",state="alive"}},snapshotId=tostring(GetTime())..tostring(cursor),hasMore=not cursor,nextCursor=not cursor and "wa:1" or nil}
end
AZS_ProjectWorldAnchors=function(requests)
 calls=calls+1;local entries={}
 for i,r in ipairs(requests) do entries[i]={state="onScreen",x=300,y=200,playerDistance=20} end
 return {entries=entries,frameId=1}
end
AZS_RegisterWorldAnchorFrameHandler=function(fn) handler=fn;return true end
AZS_UnregisterWorldAnchorFrameHandler=function(fn) assert(handler==fn);handler=nil;return true end
for _,language in ipairs({"en","fr"}) do for _,themed in ipairs({false,true}) do
 FieldKit_SetLanguage(language);FieldKitRebornDB.zoneThemeMode="elwynn";FieldKitRebornDB.zoneThemeVariant="complete";FieldKitZoneThemes.Set("zoneThemes",themed)
 assert(M.Enable() and M.IsEnabled() and A.Refresh());local entries=A.Snapshot();assert(#entries==2)
 assert(not A.Project({{anchorId="test:first"}}) and calls==0)
 handler();assert(calls>0)
 local shown=0;for _,f in ipairs(objects) do if f.markerKind=="elite" and f:IsShown() then shown=shown+1 end end
 assert(shown==2,"Reborn marker missing with/without theme")
 M.SetCategoryRange("elite",10);handler()
 for _,f in ipairs(objects) do if f.markerKind=="elite" then assert(not f:IsShown()) end end
 M.SetCategoryRange("elite",130);M.Disable();A.Disable();calls=0;assert(not handler)
end end
print("PASS Reborn world-marker contract: bare snapshots/frameId, two-page catalogue, FR/EN x theme on/off, post-camera only, range filtering and cleanup")
