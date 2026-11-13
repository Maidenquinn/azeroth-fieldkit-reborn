fire(FieldKitFrame,"VARIABLES_LOADED")
AZS_ZONE={zone="zangarmarsh",heroic=0};AZS_RUN={ph="playing",t=45,en=4,enm=120}
local C,H,V,d=FieldKitZoneThemes,FieldKitThemeHUD,FieldKitReferenceHUD,FieldKitRebornDB
function Minimap:SetMaskTexture(path) self.mask=path;return true end
function Minimap:GetMaskTexture() return self.mask or "Textures\\MinimapMask" end
local state={clock=true,tally=true,build=true,banners=true,bosses=true,meter=true,levels=true}
AZS_IsHudShown=function(key) return state[key] end
AZS_SetHudShown=function(key,value) state[key]=value end
local function Disjoint(p,h)
 return p[2]+p[4]<=h[1] or p[2]>=h[1]+h[3] or p[3]+p[5]<=h[2] or p[3]>=h[2]+h[4]
end
local function EmptyHoles(frame)
 assert(#frame.referenceArtHoles>0,"No artwork removed")
 for _,p in ipairs(frame.referenceDrawPieces) do
  assert(p[4]>0 and p[5]>0 and p[6]>(p[9] or 0) and p[8]>p[7],"Degenerate native texture quad")
  assert((p[9] or 0)>=0 and p[6]<=1 and p[7]>=0 and p[8]<=1,"UV outside source atlas")
  for _,hole in ipairs(frame.referenceArtHoles) do assert(Disjoint(p,hole),"Hidden feature's artwork is still drawn") end
 end
end
for _,variant in ipairs({"minimal","complete","alternative"}) do for _,shape in ipairs({"square","round","native"}) do
 C.Set("zoneThemes",false);d.zoneThemeMode="elwynn";d.zoneThemeVariant=variant;d.zoneThemeMapShape=shape;d.hideUnknownMode=false
 d.moneyFrame=true;d.runModeCard=true;C.Set("zoneThemes",true)
 assert(H.mode:IsShown() and H.counterRoot:IsShown())
 d.moneyFrame=false;d.runModeCard=false;C.Refresh(true)
 assert(not H.mode:IsShown() and not H.counterRoot:IsShown())
 assert(state.tally==false,"Counter strip was substituted with native counters")
 EmptyHoles(H.dock)
 if V.layout.closedMap then
  local map=FieldKitThemeMinimap.root;local _,parent,_,x,y=Minimap:GetPoint()
  assert(parent==map and x>=8 and y<=-8 and x+Minimap:GetWidth()<=map:GetWidth()-8 and -y+Minimap:GetHeight()<=map:GetHeight()-8,"Native map protrudes past its closed frame")
  assert(map.fieldkitSkin and not map.fieldkitArtOnly,"Mode-off map has no closed material frame")
 elseif not V.modeCut or not V.modeCut.medal then EmptyHoles(H.identity)
 else assert(FieldKitThemeMinimap.roundRing.modeRing:IsShown(),"Round mode foot wasn't replaced with a plain ring segment") end
 local rim=FieldKitThemeMinimap.rim
 if variant=="complete" and shape=="square" and rim and rim:IsShown() then EmptyHoles(rim) end
 for _,b in ipairs(V.counterButtons) do assert(not b:IsShown()) end
 for _,t in ipairs(V.countIcons) do assert(not t:IsShown()) end
 if V.plain and V.plain.counts then assert(not V.plain.counts:IsShown()) end
 -- Disabling the strip must not cut spell sockets or the real XP track.
 local a=V.layout.actions;local dock=V.layout.rects.dock;local xp=V.layout.xp
 local actions={a[1]-dock[1],a[2]-dock[2],6*a[4],a[3]}
 local xpRect={xp[1]-dock[1],xp[2]-dock[2],xp[3],xp[4]}
 local plate=V.layout.compactDock
 if plate then
  assert(V.compactDock:IsShown() and V.layout.actions[2]>V.layout.sourceActions[2],"Missing compact dock composition")
  assert(a[2]>=plate[2] and a[2]+a[3]<=plate[2]+plate[4] and plate[2]+plate[4]-(a[2]+a[3])<=20,"Empty gap remains below actions")
  assert(#FieldKitReborn.sixSlots==6 and FieldKitReborn.sixSlots[6]:IsShown())
 else for _,hole in ipairs(H.dock.referenceArtHoles) do
   assert(Disjoint({"",actions[1],actions[2],actions[3],actions[4]},hole),"Counter removal cut actions")
   assert(Disjoint({"",xpRect[1],xpRect[2],xpRect[3],xpRect[4]},hole),"Counter removal cut XP")
  end
 end
 d.moneyFrame=true;d.runModeCard=true;C.Refresh(true)
 assert(H.counterRoot:IsShown() and H.mode:IsShown() and state.tally==false)
 assert(#H.dock.referenceArtHoles==0 and #H.identity.referenceArtHoles==0,"Re-enabling did not restore original artwork")
 if FieldKitThemeMinimap.roundRing and FieldKitThemeMinimap.roundRing.modeRing then assert(not FieldKitThemeMinimap.roundRing.modeRing:IsShown()) end
end end
C.Set("zoneThemes",false);assert(state.tally==true,"Turning the theme off did not restore original native tally")
print("PASS optional HUD artwork: 3 layouts x 3 map shapes; complete strip removal, no baked badges, valid UVs, actions/XP preserved, original artwork and native tally restored")
