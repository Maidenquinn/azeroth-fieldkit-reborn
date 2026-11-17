-- Synthetic visual fixtures must never leak into live gameplay or sharing state.
FieldKitRebornDB={meterFrame=false,takenFrame=false,partyMeter=false,partyCards=false,
 effectsFrame=false,reviveFrame=false,bossFrame=false,windowsLocked=true}
fire(FieldKitFrame,"VARIABLES_LOADED");SlashCmdList.FieldKit("")
local P,U=FieldKitPreview,FieldKitUI
local meter,taken,party=AZS_METER,AZS_TAKEN,FieldKitCoop.party
local writes=0
SetCVar=function() writes=writes+1 end
AZS_SetHudShown=function() writes=writes+1 end
SendAddonMessage=function() writes=writes+1 end
AZS_SetOnTopOfScreens=function() writes=writes+1 end
for i=1,table.getn(P.names) do
 P.Open(i);assert(P.mode=="inspect" and P.frames[i]:IsShown())
 if P.frames[i].sampleLines then
  for _,row in ipairs(P.frames[i].rows) do assert(not row:IsShown(),"Preview rendered native rows over sample text") end
  assert(P.frames[i].sampleLines[1]:IsShown())
 end
 assert(P.frames[i]~=getglobal(P.names[i]),"Preview reused a live frame")
 assert(not FieldKitRebornDB.meterFrame and not FieldKitRebornDB.partyCards and not FieldKitRebornDB.bossFrame)
end
assert(AZS_METER==meter and AZS_TAKEN==taken and FieldKitCoop.party==party and writes==0)
assert(P.Rows(17)[1][1]=="Player" and P.Rows(17)[2][1]=="Health","My card reused the warning samples")
P.Open(9);FieldKitRebornDB.partyHealthMode=2;P.Refresh()
assert(P.frames[9].rows[1].value:GetText()=="55%")
FieldKitRebornDB.partyHealthMode=3;P.Refresh();assert(P.frames[9].rows[1].value:GetText()=="6705 / 12200 (55%)")
P.Open(P.playerIndex);FieldKitRebornDB.playerHealthMode=2;P.Refresh();assert(P.frames[P.playerIndex].hp:GetText()=="55%")
P.Open(P.targetIndex);FieldKitRebornDB.targetHealthMode=3;P.Refresh();assert(P.frames[P.targetIndex].hp:GetText()=="6705 / 12200 (55%)")
P.Open(P.bossIndex);FieldKitRebornDB.bossHealthMode=2;P.Refresh();assert(P.frames[P.bossIndex].hp:GetText()=="55%")
assert(not P.frames[P.bossIndex].hp:IsShown() and not P.frames[P.bossIndex].name:IsShown())
assert(not P.frames[P.bossIndex].previewDetail:IsShown() and P.frames[P.bossIndex].previewHealth:IsShown())
assert(P.frames[P.bossIndex].previewOverlay:GetFrameLevel()>P.frames[P.bossIndex]:GetFrameLevel())
assert(P.inspector.place:GetFrameLevel()>P.inspector:GetFrameLevel())
P.Open(2);FieldKitRebornDB.meterValues=3;P.Refresh()
assert(P.frames[2].rows[1].meterColumns[1]:GetText()=="42000")
FieldKitRebornDB.cardStyle=2;FieldKitRebornDB.cardOpacity=18;FieldKitTheme.Refresh()
assert(FieldKitTheme.Style(P.frames[2])==2 and FieldKitTheme.Opacity(P.frames[2])==.18)
assert(FieldKitTheme.Opacity(P.inspector)==1)
FieldKit_SetLanguage("fr");P.Refresh();assert(P.frames[2].title:GetText()=="Aperçu")
FieldKit_SetLanguage("en");P.Refresh();assert(P.frames[2].title:GetText()=="Preview")
local allocated=table.getn(objects)
for i=1,30 do P.Refresh() end
assert(table.getn(objects)==allocated,"Preview refresh allocated frames")
-- A single explicit drag saves geometry under the live frame's name only.
FieldKitRebornDB.linkLeftCards=false;FieldKitHudStack.Apply()
U.SetLayoutEditing(true,false);P.Start(false)
local f=P.frames[2];P.Drag(f,true);f:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-2,-40);P.Drag(f,false)
assert(FieldKitRebornDB.frameAnchors.FieldKitMeterFrame[3]==-2)
assert(not FieldKitRebornDB.frameAnchors.FieldKitPreviewCard2)
assert(FieldKitRebornDB.windowsLocked,"Arrangement changed the saved lock")
local anchor=FieldKitRebornDB.frameAnchors.FieldKitMeterFrame
P.selected=3;P.Reset()
assert(FieldKitRebornDB.frameAnchors.FieldKitMeterFrame==anchor,"Reset affected an unrelated window")
-- Disabled windows are selectable in global composition; linked examples don't overlap.
P.included[9]=true;FieldKitRebornDB.linkLeftCards=true;U.SetLayoutEditing(true,false)
assert(P.frames[9]:IsShown() and P.frames[3]:IsShown())
local _,root,_,_,y=P.frames[3]:GetPoint(1)
assert(root==P.roots.FieldKitLeftStack and y<0)
U.SetLayoutEditing(false,true)
assert(not P.mode and not FieldKit.layoutEditing)
for _,v in pairs(P.frames) do assert(not v:IsShown()) end
assert(not FieldKitRebornDB.meterFrame and not FieldKitRebornDB.partyCards and writes==0)
-- Inspector selectors track resize selection without activating a module.
P.Open(2);click(P.inspector.choice);click(P.inspector.choice.choiceButtons[3])
assert(P.selected==3 and FieldKitCardLayout.selected==3)
for _,control in ipairs(U.controls) do
 if control.label=="Window to resize" then click(control);click(control.choiceButtons[5]) end
end
assert(P.selected==5)
click(P.inspector.choice);assert(P.inspector.choice.menu:IsShown())
P.Stop();assert(not P.inspector.choice.menu:IsShown())
-- Interrupted grouped drag commits only the group anchor.
P.selected=2;U.SetLayoutEditing(true,false);P.Start(false)
local group=P.roots.FieldKitLeftStack
P.Drag(P.frames[2],true);group:SetPoint("TOPLEFT",UIParent,"TOPLEFT",5,-22)
U.SetLayoutEditing(false,true)
assert(not group.moving and FieldKitRebornDB.frameAnchors.FieldKitLeftStack[3]==5)
P.Open(14);P.inspector:Hide();P.inspector:GetScript("OnHide")()
assert(not P.mode and not P.inspector:IsShown())
-- Escape/close while dragging must stop, persist the deliberate move, then
-- hide every sample. Subsequent live native updates remain independent.
P.Open(3);P.included[3]=false;U.SetLayoutEditing(true,false)
assert(not P.frames[3]:IsShown());U.dock:Hide();U.dock:GetScript("OnHide")()
assert(not P.mode and not FieldKit.layoutEditing)
AZS_RUN.ph=nil;P.Open(8);U.frame:Hide();U.frame:GetScript("OnHide")();assert(not P.mode)
local oldW,oldH=UIParent.width,UIParent.height;UIParent.width=800;UIParent.height=600
U.frame:Show();P.Open(P.bossIndex);P.Refresh();assert(P.inspector:IsShown())
UIParent.width=oldW;UIParent.height=oldH;P.Stop()
assert(writes==0 and AZS_METER==meter and AZS_TAKEN==taken)
print("Context-free previews: isolation, settings, grouping, placement, scoped reset and cleanup passed")

-- Placement isolates live FieldKit even when the rest of the HUD is restored.
local V=FieldKitPreviewVisibility
local foreign=CreateFrame("Frame","UnrelatedAddonPanel",UIParent)
foreign:SetAlpha(.37);foreign.mouse=true
foreign.IsMouseEnabled=function(self) return self.mouse end
foreign.EnableMouse=function(self,v) self.mouse=v end
local child=CreateFrame("Button",nil,foreign);child.mouse=true
child.IsMouseEnabled=foreign.IsMouseEnabled;child.EnableMouse=foreign.EnableMouse
foreign.GetChildren=function() return child end
local children=UIParent.GetChildren
UIParent.GetChildren=function() return foreign,FieldKitMeterFrame,FieldKitUI.dock,P.frames[2],WorldFrame end
local events=0;foreign:SetScript("OnHide",function() events=events+1 end)
FieldKitMeterFrame:SetAlpha(.61);P.selected=2;V.hideOthers=true
U.SetLayoutEditing(true,false)
assert(FieldKitMeterFrame:GetAlpha()==0 and foreign:GetAlpha()==0)
assert(not foreign.mouse and not child.mouse)
assert(P.frames[2]:GetAlpha()==1 and FieldKitUI.dock:GetAlpha()==1)
assert(V.Keep(U.done) and V.Keep(P.frames[2].rows[1]),"Editor descendants must remain visible and interactive")
assert(foreign:IsShown() and events==0,"Isolation invoked foreign Hide callbacks")
click(U.otherUI)
assert(not V.hideOthers and foreign:GetAlpha()==.37 and foreign.mouse and child.mouse)
assert(FieldKitMeterFrame:GetAlpha()==0,"Showing other UI exposed live FieldKit")
click(U.otherUI);assert(foreign:GetAlpha()==0)
-- Renderers can still change visibility and data behind the alpha mask.
foreign:Hide();foreign:SetAlpha(.8);P.Refresh();assert(foreign:GetAlpha()==0)
U.SetLayoutEditing(false,true)
assert(foreign:GetAlpha()==.37 and FieldKitMeterFrame:GetAlpha()==.61)
assert(not foreign:IsShown() and foreign.mouse and child.mouse and events==0)
assert(next(V.masked)==nil)
-- Escape cleanup takes the same restoration path; already transparent UI stays so.
foreign:SetAlpha(0);U.SetLayoutEditing(true,false)
U.dock:Hide();U.dock:GetScript("OnHide")()
assert(foreign:GetAlpha()==0 and next(V.masked)==nil)
UIParent.GetChildren=children
print("Preview isolation: live HUD masking, other-UI toggle, input and exact restoration passed")

-- Reproduce the screenshot's unpositioned centre cards at several screen sizes.
local function separated(a,b)
 return a.x+a.w<=b.x or b.x+b.w<=a.x or a.y+a.h<=b.y or b.y+b.h<=a.y
end
for _,viewport in ipairs({{800,600},{1280,720},{1365,768},{1920,1080},{2560,1080}}) do
 local w,h=viewport[1],viewport[2]
 local reserved={x=(w-560)/2,y=12,w=560,h=172}
 reserved.extras={{x=w/2-280,y=h*.58,w=280,h=32},{x=w/2,y=h*.58,w=280,h=32}}
 local items={}
 for i=1,15 do table.insert(items,{x=w/2-180,y=h/2-50,w=i==1 and 420 or 360,h=i==2 and 190 or 100}) end
 local packed,scale
 for step=0,15 do scale=1-step*.05;packed=P.Pack(items,w,h,reserved,scale);if packed then break end end
 assert(packed and table.getn(packed)==15,"All samples must fit "..w.."x"..h)
 for i,r in ipairs(packed) do
  assert(r.x>=0 and r.y>=0 and r.x+r.w<=w and r.y+r.h<=h)
  assert(separated(r,reserved),"Preview overlaps toolbar")
  for _,area in ipairs(reserved.extras) do assert(separated(r,area),"Preview overlaps combat drag area") end
  for j=1,i-1 do assert(separated(r,packed[j]),"Preview samples overlap") end
 end
end
-- Merely arranging examples must not rewrite saved anchors; a deliberate drag
-- from a scaled example commits screen-equivalent coordinates once.
P.Open(2);FieldKitRebornDB.linkLeftCards=false
local preview=P.frames[2];P.mode="place";preview.fieldkitCompositionScale=.5
preview:SetPoint("TOPLEFT",UIParent,"TOPLEFT",200,-160)
preview.moving=true;P.Refresh()
assert(preview.fieldkitCompositionScale==.5,"Refreshing during a drag reset preview scale")
preview.moving=nil
P.Commit(preview,FieldKitMeterFrame)
assert(FieldKitRebornDB.frameAnchors.FieldKitMeterFrame[3]==100 and FieldKitRebornDB.frameAnchors.FieldKitMeterFrame[4]==-80)
P.Stop()
local bossEnabled=FieldKitRebornDB.bossFrame
FieldKitRebornDB.bossFrame=true;U.SetLayoutEditing(true,false);U.context.bosses()
for i=1,4 do local boss=getglobal("FieldKitBossFrame"..i);assert(not boss:IsShown());assert(not boss.compact:IsShown()) end
FieldKitRebornDB.bossFrame=bossEnabled;U.SetLayoutEditing(false,true)
local oldLocale,legacy=AZS_L,FieldKit.rebornLegacyFixture;AZS_L={Fireball="Boule de feu"};FieldKit.rebornLegacyFixture=false
FieldKit_SetLanguage("fr");assert(P.Text("Fireball")=="Boule de feu")
assert(P.Rows(4)[1][2]=="awake" and P.Text("awake")==FieldKit_L("awake"))
AZS_L=oldLocale;FieldKit.rebornLegacyFixture=legacy
-- Exercise the actual page buttons: numeric indexes silently drifted when the
-- campaign-boss and player cards were added to the catalog.
for pageId,expected in pairs({bosses=P.bossIndex,health=P.playerIndex}) do
 U.Select(pageId)
 local button
 for _,page in ipairs(U.pages) do if page.section.id==pageId then
  for _,entry in ipairs(page.flow) do if entry.frame.previewButton then button=entry.frame.previewButton;break end end
 end end
 assert(button,"Missing preview action for "..pageId);click(button)
 assert(P.selected==expected,"Wrong preview from "..pageId);P.Stop()
end
print("Preview rendering: single text owner, boss overlay isolation, toolbar descendants and five-viewport collision packing passed")
