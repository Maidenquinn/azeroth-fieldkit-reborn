-- Synthetic geometry and real editor callbacks; no native renderer claim.
fire(FieldKitFrame,"VARIABLES_LOADED")
local G=FieldKitAlignment
local function near(a,b) assert(math.abs(a-b)<.00001,tostring(a).." != "..tostring(b)) end
for _,size in ipairs({{1920,1080},{2560,1080},{3440,1440},{1280,720}}) do
 local w,h=size[1],size[2]
 local r={x=w/2+3,y=h/2+3,w=100,h=60}
 local dx,dy=G.Resolve(r,{},w,h,32,8,true)
 near(dx,-3);near(dy,-3)
 dx,dy=G.Resolve({x=93,y=408,w=100,h=60},{{x=100,y=400,w=100,h=60}},w,h,32,8,false)
 near(dx,7);near(dy,-8)
 dx,dy=G.Resolve({x=-50,y=h+20,w=100,h=60},{},w,h,32,8,false)
 near(dx,50);near(dy,-20)
 dx,dy=G.Resolve({x=w+50,y=-20,w=100,h=60},{},w,h,32,8,false)
 near(dx,-150);near(dy,80)
 dx,dy=G.Resolve({x=47,y=147,w=30,h=30},{},w,h,32,0,false)
 near(dx,0);near(dy,0)
end
-- Actual point conversion preserves rendered location under independent scales.
local f=CreateFrame("Frame","FieldKitAlignmentTest",UIParent)
f:SetWidth(100);f:SetHeight(60)
function f:GetLeft() return 201 end
function f:GetTop() return 401 end
function f:GetEffectiveScale() return 1.5 end
function UIParent:GetEffectiveScale() return .75 end
function UIParent:GetWidth() return 2560 end
function UIParent:GetHeight() return 1080 end
local r=G.Rect(f);near(r.x,402);near(r.y,802);near(r.w,200);near(r.h,120)
local delta=G.Delta;G.Delta=function() return 4,-2 end
assert(not G.Snap(f),'Closed editor must never move a frame')
G.active=true;FieldKitRebornDB.alignmentSnap=false;assert(not G.Snap(f))
FieldKitRebornDB.alignmentSnap=true;assert(G.Snap(f))
local p={f:GetPoint()};assert(p[1]=='TOPLEFT' and p[2]==UIParent and p[3]=='BOTTOMLEFT');near(p[4],203);near(p[5],400)
G.active=false;G.Delta=delta
-- Use the real settings journey and buttons. No theme suspension on entry.
SlashCmdList.FieldKit("")
local refreshes=0;local suspend=FieldKitZoneThemes.Suspend
FieldKitZoneThemes.Suspend=function() refreshes=refreshes+1 end
FieldKitRebornDB.windowsLocked=true
for _,lang in ipairs({'en','fr'}) do
 FieldKitRebornDB.language=lang
 G.Start();assert(G.active and G.overlay:IsShown() and G.toolbar:IsShown())
 assert(not FieldKitRebornDB.windowsLocked and not FieldKit.layoutEditing)
 assert(not FieldKitUI.frame:IsShown() and refreshes==0)
 local count=table.getn(G.lines);G.Refresh();assert(table.getn(G.lines)==count)
 G.grid:Click();assert(not FieldKitRebornDB.alignmentGrid);G.grid:Click();assert(FieldKitRebornDB.alignmentGrid)
 G.snap:Click();assert(not FieldKitRebornDB.alignmentSnap);G.snap:Click();assert(FieldKitRebornDB.alignmentSnap)
 -- Region reuse on spacing and viewport changes.
 FieldKitRebornDB.alignmentStep=8;G.Refresh();local max=table.getn(G.lines)
 for i=1,12 do FieldKitRebornDB.alignmentStep=64;G.Refresh();FieldKitRebornDB.alignmentStep=8;G.Refresh() end
 assert(table.getn(G.lines)==max and max<=604)
 G.Stop();assert(not G.active and not G.overlay:IsShown() and not G.toolbar:IsShown() and FieldKitRebornDB.windowsLocked)
end
FieldKitZoneThemes.Suspend=suspend
FieldKitRebornDB.alignmentStep=48;assert(FieldKitProfiles.Save(2))
FieldKitRebornDB.alignmentStep=16;G.Start();assert(FieldKitProfiles.Load(2));assert(not G.active and FieldKitRebornDB.alignmentStep==48)
-- Existing schema-2 slots from .35 have no alignment fields. They must still
-- load without silently discarding their saved geometry or appearance.
local slot=FieldKitRebornDB.interfaceProfiles[2]
slot.values.alignmentStep=nil;slot.values.alignmentGrid=nil;slot.values.alignmentSnap=nil
slot.nilValues.alignmentStep=nil;slot.nilValues.alignmentGrid=nil;slot.nilValues.alignmentSnap=nil
slot.values.cardOpacity=47
assert(slot.schema==2 and FieldKitProfiles.Load(2))
assert(FieldKitRebornDB.cardOpacity==47 and FieldKitRebornDB.alignmentStep==48)
assert(slot.values.alignmentStep==48 and slot.values.alignmentGrid)
-- Viewport cache invalidation: not just a changed top-left position.
local M=FieldKitThemeMinimap
local m=CreateFrame('Frame','FieldKitViewportOwner',UIParent)
function m:GetLeft() return 100 end;function m:GetTop() return 500 end
local paints=0;local show=Minimap.Show
Minimap.Show=function(self) paints=paints+1;show(self) end
M.screenStamp=nil;Minimap:Show();assert(M.RefreshViewport(m));local n=paints
assert(not M.RefreshViewport(m) and paints==n)
Minimap:SetWidth(240);assert(M.RefreshViewport(m) and paints==n+1);n=paints
function UIParent:GetWidth() return 3440 end
assert(M.RefreshViewport(m) and paints==n+1)
Minimap:Hide();n=paints;Minimap:SetHeight(241);assert(M.RefreshViewport(m) and not Minimap:IsShown() and paints==n)
Minimap.Show=show
print('PASS alignment: four viewports, scaled drops, opt-in movement, live theme retained, FR/EN controls, region reuse, profile isolation and minimap invalidation')
