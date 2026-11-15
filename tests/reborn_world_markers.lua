fire(FieldKitFrame,"VARIABLES_LOADED")
local A,M=FieldKitWorldAnchors,FieldKitWorldMarkers
M.Disable();A.Disable()
AZS_GetWorldAnchorCapabilities=nil;AZS_GetPhase=function() return "playing" end
AZS_ProjectWorldPoint=function() return 10,20,1,1,true end
AZS_UnitWorldPosition=function() return 0,0,10,6.6,true end
local handler,calls=nil,0
AZS_GetWorldAnchors=function(query,cursor,limit)
 assert(limit==256 and type(query.kinds)=="table")
 local full=false;for _,kind in ipairs(query.kinds) do if kind=="enemy" then full=true end end;assert(full,"Normal-rank guardians cannot enter special-only enumeration")
 return {entries={{anchorId="test:"..(cursor or "first"),kind="elite",state="alive"},{anchorId="ordinary",kind="enemy",state="alive"}},snapshotId=tostring(GetTime())..tostring(cursor),hasMore=not cursor,nextCursor=not cursor and "wa:1" or nil}
end
AZS_ProjectWorldAnchors=function(requests)
 calls=calls+1;local entries={}
 for i,r in ipairs(requests) do entries[i]={state="onScreen",x=300,y=r.attachment=="overhead" and 900 or 200+((r.offset and r.offset.z) or 0)*10,playerDistance=20} end
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
 for _,scale in ipairs({1,.5}) do
  WorldFrame:SetScale(scale);WorldFrame.GetEffectiveScale=function() return scale end;handler()
  for _,f in ipairs(objects) do if f.markerKind=="elite" and f:IsShown() then
   local _,_,_,_,y=f:GetPoint();assert(math.abs((y-f:GetHeight()/2-(200+(6.6*M.GetAnchorHeight("elite")/100+M.GetCategoryHeight("elite")/.9144)*10))*scale-8)<.001,"Glyph bottom does not clear the native head by eight screen pixels")
  end end
 end
 WorldFrame:SetScale(1);WorldFrame.GetEffectiveScale=nil
 M.SetCategoryRange("elite",10);handler()
 for _,f in ipairs(objects) do if f.markerKind=="elite" then assert(not f:IsShown()) end end
 M.SetCategoryRange("elite",130);M.Disable();A.Disable();calls=0;assert(not handler)
end end
print("PASS Reborn world-marker contract: bare snapshots/frameId, two-page catalogue, FR/EN x theme on/off, post-camera only, range filtering and cleanup")

assert(M.SetCategoryHeight("guardian",1.25)==1.25 and M.SetAnchorHeight("guardian",42)==42)
assert(M.SetCategoryHeight("cache",1)==nil and M.GetCategoryHeight("cache")==nil)
assert(M.SetCategoryHeight("guardian",0/0)==1.25)
assert(M.SetCategoryHeight("guardian",99)==3)
assert(M.SetAnchorHeight("guardian",-50)==0)
assert(FieldKitProfiles.Save(1))
M.SetCategoryHeight("guardian",.25);M.SetAnchorHeight("guardian",80);assert(FieldKitProfiles.Save(2))
assert(FieldKitProfiles.Load(1));assert(M.GetCategoryHeight("guardian")==3 and M.GetAnchorHeight("guardian")==0)
assert(FieldKitProfiles.Load(2));assert(M.GetCategoryHeight("guardian")==.25 and M.GetAnchorHeight("guardian")==80)
print("PASS marker height controls: category support, finite bounds, rounding and independent profile restoration")
