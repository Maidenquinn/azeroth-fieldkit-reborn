fire(FieldKitFrame,"VARIABLES_LOADED")
local N,C,d=FieldKitNativeHUD,FieldKitZoneThemes,FieldKitRebornDB
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
assert(string.find(skin.fieldkitSkin.nativeBorder.testBackdrop.edgeFile,"AzerothSurvivorsUI",1,true),"Native border asset not selected")
local label=skin:CreateFontString(nil,"OVERLAY");FieldKitTheme.Font(label,12,FieldKitTheme.text)
local path,size,flags=label:GetFont();assert(path=="Fonts\\FRIZQT__.TTF" and size==12 and flags=="OUTLINE","Native font not applied")
d.cardOpacity=25;FieldKitTheme.RefreshOpacity();assert(skin.fieldkitSkin.base:GetAlpha()==.25 and skin.fieldkitSkin.nativeBorder:IsShown())
FieldKitTheme.SetZone("elwynn");assert(not skin.fieldkitSkin.nativeBorder:IsShown() and FieldKitTheme.Style(skin)==3)
FieldKitTheme.SetZone("classic");path,size,flags=label:GetFont();assert(path=="Fonts\\FRIZQT__.TTF" and flags=="OUTLINE" and skin.fieldkitSkin.nativeBorder:IsShown())
IsAddOnLoaded=nil
local fallback=CreateFrame("Frame",nil,UIParent);FieldKitTheme.Surface(fallback,"card",true)
assert(fallback.fieldkitSkin.nativeBorder.testBackdrop.edgeFile=="Interface\\Tooltips\\UI-Tooltip-Border","Missing UI addon had no fallback")
methods.SetBackdrop=oldBackdrop;IsAddOnLoaded=oldLoaded
print("PASS unthemed native ownership: counters/candy, jewelry, meter, progression, boss/target identity, elapsed/paused clock, opt-outs, saved restoration and both themes x all variants")
