fire(FieldKitFrame,"VARIABLES_LOADED")
local C,H=FieldKitZoneThemes,FieldKitThemeHUD
local bar=CreateFrame("Frame","AzerothSurvivorsActionBar1",UIParent)
local player=CreateFrame("Frame","AzerothSurvivorsUnitFramePlayer",UIParent)
local resources=CreateFrame("Frame","AzerothSurvivorsSurvivorsResources",UIParent)
bar:Show();player:Show();resources:Show();player:SetAlpha(.7);player:EnableMouse(true)
local click=0;local callback=function() click=click+1 end
for i=1,12 do
 local b=CreateFrame("Button","AzerothSurvivorsActionBar1Button"..i,bar)
 b.icon=b:CreateTexture(nil,"ARTWORK");b.cooldown=CreateFrame("Frame",nil,b)
 b:SetScript("OnClick",callback);b:Show()
end
local button=AzerothSurvivorsActionBar1Button1
local nativeState={clock=true,tally=true,build=true,banners=true,bosses=true,meter=true,levels=true}
AZS_IsHudShown=function(key) return nativeState[key] end
AZS_SetHudShown=function(key,on) nativeState[key]=on end
AZS_ZONE={zone="zangarmarsh",zname="Marécage de Zangar",heroic=0}
FieldKitRebornDB.zoneThemeMode="auto"
for _,variant in ipairs({"minimal","complete","alternative"}) do
 FieldKitRebornDB.zoneThemeVariant=variant
 C.Set("zoneThemes",true)
 assert(C.Resolve()=="elwynn" and C.active and FieldKitReferenceHUD.active)
 assert(H.zone:GetText()=="Marécage de Zangar","Skin replaced the native map identity")
 assert(button:GetParent()==H.dock and button:GetScript("OnClick")==callback)
 assert(player:GetParent()==H.Hidden() and resources:GetParent()==H.Hidden() and bar:GetParent()==H.Hidden())
 assert(nativeState.clock==false and nativeState.meter==false and nativeState.build==false)
 button:Click();assert(click>0)
 C.Set("zoneThemes",false)
 assert(button:GetParent()==bar and player:GetParent()==UIParent and resources:GetParent()==UIParent)
 assert(player:GetAlpha()==.7 and player:IsMouseEnabled())
 assert(nativeState.clock==true and nativeState.meter==true and nativeState.build==true)
end
AZS_ZONE.zone="future-map";FieldKitRebornDB.zoneThemes=true;assert(C.Resolve()=="elwynn")
AZS_RUN.ph=nil;assert(C.Resolve()==nil,"Auto theme must not activate outside a run")
print("PASS Reborn themes on expansion maps: all three layouts, native action callbacks, native HUD suppression and full restoration")
