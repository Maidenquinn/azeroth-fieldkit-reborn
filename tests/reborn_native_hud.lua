fire(FieldKitFrame,"VARIABLES_LOADED")
local N,C,d=FieldKitNativeHUD,FieldKitZoneThemes,FieldKitRebornDB
assert(not d.linkLeftCards and not d.linkRightCards and d.schema==3,"Default cards are still grouped")
assert(d.frameAnchors.FieldKitMeterFrame[4]~=d.frameAnchors.FieldKitTakenFrame[4],"Independent defaults overlap")
N.Release()
local state={clock=true,tally=true,bosses=true,meter=false,build=true}
AZS_IsHudShown=function(key) return state[key] end
AZS_SetHudShown=function(key,on) state[key]=on end
local names={"AzerothSurvivorsSurvivorsResources","AzerothSurvivorsMinimapStatusButton","AZSGearRow","AZSMeterFrame","AZSRiftBar","AzerothSurvivorsSurvivorsBossBar","AzerothSurvivorsUnitFrameTarget"}
for _,name in ipairs(names) do local f=CreateFrame("Frame",name,UIParent);f:SetAlpha(.73);f:EnableMouse(true);f:Show() end
AZS_ZONE={zone="hellfire",heroic=0};AZS_RUN={ph="playing",t=125,kills=14,gold=30,cache=42,rift=25}
AZS_SCHEDULE={{name="Boss",state="due",index=1}};AZS_UNITS={}
AZS_EVENT={key="halloween",n=0}
AZS_EventCurrency=function() return "Candy","Interface\\Icons\\INV_Misc_Candy_01" end
d.zoneThemes=false;d.moneyFrame=true;d.replaceTally=true;d.gearFrame=true;d.meterFrame=true;d.bossTimeline=true;d.bossFrame=true
FieldKitUI.hudActions.UpdateMoneyFrame();FieldKitUI.hudActions.UpdateGearFrame();FieldKitUI.hudActions.UpdateMeterFrames(true);FieldKitBossTimeline.Update();N.Update()
local function Hidden(name) local f=getglobal(name);return f:GetParent()==N.storage and f:GetAlpha()==0 and not f:IsMouseEnabled() end
for i=1,6 do assert(Hidden(names[i]),"Unthemed duplicate: "..names[i]) end
assert(not Hidden(names[7]),"Ordinary target was hidden without a replacement")
assert(state.clock==false and state.tally==false and state.meter==false and state.build==true,"Native spell bar was suppressed")
assert(N.clock:IsShown() and N.clock.text:GetText()=="2:05")
assert(FieldKitMoneyFrame.nativeCells[4]:IsShown() and FieldKitMoneyFrame.nativeCells[4].value:GetText()=="0","Zero event currency missing")
assert(FieldKitMoneyFrame.nativeCells[4].label=="Candy")
assert(FieldKitMoneyFrame.nativeCells[3].icon:GetTexture()==FieldKitTheme.media.."WorldMarkers\\cache.tga","Chest counter must use the packaged verified texture")
assert(not FieldKitMoneyFrame.coin:IsShown() and not FieldKitMoneyFrame.chestLabel:IsShown(),"Old footer labels survived")
d.windowsLocked=false
FieldKitMoneyFrame.nativeCells[1]:GetScript("OnDragStart")();assert(FieldKitMoneyFrame.azsMoving,"Counter tooltip cell blocked dragging")
FieldKitMoneyFrame.nativeCells[1]:GetScript("OnMouseUp")();assert(not FieldKitMoneyFrame.azsMoving and d.moneyDetached,"Counter drag did not detach/persist")
d.windowsLocked=true;FieldKitMoneyFrame.nativeCells[1]:GetScript("OnDragStart")();assert(not FieldKitMoneyFrame.azsMoving,"Counter cell bypassed lock")
d.windowsLocked=false
AZS_EVENT.n=34;FieldKitUI.hudActions.UpdateMoneyFrame();assert(FieldKitMoneyFrame.nativeCells[4].value:GetText()=="34")
AZS_EVENT=nil;FieldKitUI.hudActions.UpdateMoneyFrame();assert(not FieldKitMoneyFrame.nativeCells[4]:IsShown(),"Stale currency cell after event ended")
AZS_RUN.ph="paused";N.Update();assert(N.clock.text:GetText()=="2:05","Paused run clock extrapolated")
AZS_RUN.ph="playing"
local own=FieldKitBossFrame1;own.fieldkitUnitId=17;own:Show()
AZS_UNITS={{id=17,name="Boss",hp=50,hpm=100,kind="boss"}};AZS_TARGET={id=17,kind="boss"};N.Update()
assert(Hidden(names[6]) and Hidden(names[7]),"Boss/target duplicated despite represented identity")
AZS_TARGET.id=18;N.Update();assert(not Hidden(names[7]),"Unrepresented target lost its health bar")
AZS_UNITS[2]={id=18,name="Another",hp=80,hpm=100,kind="boss"};N.Update();assert(not Hidden(names[6]),"Native boss outside the bounded replacement pool lost")
AZS_UNITS={};own:Hide()
C.allowUnfinishedThemes=true -- test the gated family without exposing it to players
for _,zone in ipairs({"elwynn","naxx"}) do for _,variant in ipairs({"minimal","complete","alternative"}) do
 d.zoneThemeMode=zone;d.zoneThemeVariant=variant;C.Set("zoneThemes",true)
 assert(C.active and not N.clock:IsShown() and next(N.frames)==nil,"Standalone ownership leaked into theme")
 assert(AzerothSurvivorsSurvivorsResources:GetParent()==FieldKitThemeHUD.Hidden())
 assert(FieldKitTheme.Style(FieldKitStatsFrame)==3)
 C.Set("zoneThemes",false);FieldKitUI.hudActions.UpdateMoneyFrame();N.Update()
 assert(Hidden(names[1]) and N.clock:IsShown(),"Off/on/off lost replacement ownership")
 assert(FieldKitTheme.Style(FieldKitStatsFrame)==4,"Native default material not restored")
 assert(not FieldKitStatsFrame.fieldkitSkin.grain:GetAlpha() or FieldKitStatsFrame.fieldkitSkin.grain:GetAlpha()==0)
end end
d.moneyFrame=false;d.gearFrame=false;d.meterFrame=false;d.bossFrame=false;d.bossTimeline=false;N.Update()
for i=1,7 do assert(not Hidden(names[i]),"Opt-out retained native ownership: "..names[i]) end
assert(state.tally==true and state.meter==false and state.bosses==true,"Original disabled meter preference was overwritten")
assert(N.clock:IsShown(),"Clock depended on optional boss progression")
AZS_RUN.ph=nil;N.Update();assert(state.clock==true and not N.clock:IsShown())
N.Release();assert(d.nativeHudBefore==nil)
for _,name in ipairs(names) do local f=getglobal(name);assert(f:GetParent()==UIParent and f:GetAlpha()==.73 and f:IsMouseEnabled(),"Native presentation not restored: "..name) end
-- Simulate SavedVariables surviving a reload while the API retains our mask.
d.nativeHudBefore={clock=true,tally=true,meter=false};state.clock=false;state.tally=false;N.Release()
assert(state.clock and state.tally and not state.meter)
-- Check the material path and typography, rather than just the style enum.
local methods=getmetatable(UIParent).__index
local oldBackdrop,oldLoaded=methods.SetBackdrop,IsAddOnLoaded
methods.SetBackdrop=function(self,value) self.testBackdrop=value end
IsAddOnLoaded=function(name) return name=="AzerothSurvivorsUI" end
local skin=CreateFrame("Frame",nil,UIParent);FieldKitTheme.Surface(skin,"card",true)
assert(skin.fieldkitSkin.nativeBorder==nil,"Border child can occlude labels")
assert(string.find(skin.fieldkitSkin.nativeMaterial.testBackdrop.edgeFile,"AzerothSurvivorsUI",1,true),"Native border asset not selected")
local material=skin.fieldkitSkin.nativeMaterial
assert(material.testBackdrop.edgeSize==32 and material.testBackdrop.insets.top==16 and material.testBackdrop.insets.left==8,"Native atlas was squeezed into a thin border")
assert(material:GetFrameLevel()==skin:GetFrameLevel(),"Native backdrop child covers root text")
local label=skin:CreateFontString(nil,"OVERLAY");FieldKitTheme.Font(label,12,FieldKitTheme.text)
local path,size,flags=label:GetFont();assert(path=="Fonts\\FRIZQT__.TTF" and size==12 and flags=="OUTLINE","Native font not applied")
d.cardOpacity=25;FieldKitTheme.RefreshOpacity();assert(skin.fieldkitSkin.nativeFillAlpha==.25 and skin.fieldkitSkin.nativeBackdrop)
FieldKitTheme.SetZone("elwynn");assert(not skin.fieldkitSkin.nativeBackdrop and FieldKitTheme.Style(skin)==3)
FieldKitTheme.SetZone("classic");path,size,flags=label:GetFont();assert(path=="Fonts\\FRIZQT__.TTF" and flags=="OUTLINE" and skin.fieldkitSkin.nativeBackdrop)
IsAddOnLoaded=nil
local fallback=CreateFrame("Frame",nil,UIParent);FieldKitTheme.Surface(fallback,"card",true)
assert(fallback.fieldkitSkin.nativeMaterial.testBackdrop.edgeFile=="Interface\\Tooltips\\UI-Tooltip-Border","Missing UI addon had no fallback")
methods.SetBackdrop=oldBackdrop;IsAddOnLoaded=oldLoaded
d.schema=1;d.linkLeftCards=true;d.linkRightCards=true
d.frameAnchors.FieldKitMeterFrame={"TOPLEFT","TOPLEFT",99,-177}
FieldKit.InitializeSettings({});N.SeparateDefaults()
assert(not d.linkLeftCards and not d.linkRightCards,"Existing-save default grouping not migrated")
assert(d.frameAnchors.FieldKitMeterFrame[3]==99,"Migration overwrote dragged card")
d.linkLeftCards=true;FieldKit.InitializeSettings({});assert(d.linkLeftCards,"Migration repeated after explicit opt-in")
local button=FieldKitTheme.Button(UIParent,nil,"Readable",0,0,140,16)
assert(button:GetHeight()>=28 and button.fieldkitLabel:GetHeight()<=button:GetHeight()-8,"Button lacks internal text padding")
d.linkLeftCards=false;d.linkRightCards=false
SlashCmdList.FieldKit("");FieldKitUI.ResetPositions()
assert(d.frameAnchors.FieldKitMeterFrame[4]==-150 and d.frameAnchors.FieldKitTakenFrame[4]==-610,"Position reset revived overlapping inherited defaults")
FieldKitUI.UndoPositions();assert(d.frameAnchors.FieldKitMeterFrame[3]==99,"Position reset Undo lost dragged anchor")
print("PASS unthemed native ownership: counters/candy, jewelry, meter, progression, boss/target identity, elapsed/paused clock, opt-outs, saved restoration and both themes x all variants")

-- Footer proxies preserve the original left/right click handlers and restore
-- their parents when an illustrated theme owns the meter again.
d.meterTabs=true;FieldKitMeterFrame:Show();FieldKitMeterFrame.mashCollapsed=false
N.MeterFooter()
local proxy=N.meterProxy
assert(proxy:IsShown() and proxy.reset:GetWidth()==112)
local original=FieldKitMeterFrame.fieldkitTabs.buttons[2]
local callback=original:GetScript("OnClick");local seen,button
original:SetScript("OnClick",function() seen=this;button=arg1 end)
proxy.buttons[2]:Click("RightButton")
assert(seen==original and button=="RightButton","Proxy lost detach/right-click context")
original:SetScript("OnClick",callback)
N.RestoreMeterFooter()
assert(FieldKitMeterFrame.fieldkitTabs:GetParent()==FieldKitMeterFrame and not proxy:IsShown())
-- Real geometry exercises independent-card collisions, including material
-- outsets. A user's saved anchor is not overwritten by automatic reflow.
for _,name in ipairs(FieldKitCardLayout.names) do getglobal(name):Hide() end
for _,name in ipairs({"Minimap","AzerothSurvivorsUnitFrameTarget"}) do local f=getglobal(name);if f then f:Hide() end end
local a,b=FieldKitMeterFrame,FieldKitTakenFrame
a:Show();b:Show();a.left=100;a.top=700;b.left=100;b.top=700
a:SetWidth(280);a:SetHeight(100);b:SetWidth(280);b:SetHeight(100)
FieldKitNativeLayout.lastMoved=a;d.zoneThemeOverlap=false;d.linkLeftCards=false;d.linkRightCards=false
local saved=d.frameAnchors.FieldKitTakenFrame
assert(FieldKitNativeLayout.Apply()>0,"Overlapping independent cards did not yield")
assert(d.frameAnchors.FieldKitTakenFrame==saved,"Automatic displacement overwrote saved anchor")
local point,relative,rp,x,y=b:GetPoint()
assert(point=="TOPLEFT" and relative==UIParent and (x~=100 or y~=-100))
d.zoneThemeOverlap=true;assert(FieldKitNativeLayout.Apply()==nil);d.zoneThemeOverlap=false
-- The public native gauge constructor is optional and its own frame is reused.
FieldKitBossTimeline.Ensure()
local calls=0
AZS_BuildBossChargeBar=function(frame) calls=calls+1;return function(share,text) assert(share==.25 and text=="Boss 25%") end end
assert(FieldKitBossTimeline.NativeGauge(380,.25,"Boss 25%"))
assert(FieldKitBossTimeline.NativeGauge(380,.25,"Boss 25%") and calls==1)
AZS_BuildBossChargeBar=nil
assert(not FieldKitBossTimeline.NativeGauge(380,.25,"Boss 25%"))
print("PASS native material geometry, footer click forwarding/restoration, independent collision reflow and optional reusable native gauge")
