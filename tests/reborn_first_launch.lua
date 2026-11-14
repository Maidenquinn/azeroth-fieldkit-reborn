fire(FieldKitFrame,"VARIABLES_LOADED")
local d=FieldKitRebornDB
assert(d.nativeCardScale==85 and d.bossTimeline and d.replaceTally and d.zoneThemeVariant=="complete")
assert(not d.takenFrame and not d.lairNextBoss and d.windowsLocked)
assert(d.shownStats.dmg and d.shownStats.haste and d.shownStats.crit and d.shownStats.lch and not d.shownStats.gold)
assert(d.cardSizes.FieldKitMeterFrame.width==380 and d.cardSizes.FieldKitStatsFrame.width==280)
assert(not d.zoneThemes and not d.chatStyle and not d.chatCopy and not d.chatShowCopyButton)
local P=FieldKitProfiles
d.known.Preserved="elite";d.cardOpacity=47;d.nativeCardScale=105
d.frameAnchors.FieldKitStatsFrame={"TOPLEFT","TOPLEFT",155,-233}
assert(P.Save(2))
local slot=d.interfaceProfiles[2];local active=d.activeHudProfile
for pass=1,3 do for _,themed in ipairs({false,true}) do
 assert(P.PreviewDefaults(themed),"First-launch simulation failed")
 assert(P.preview.defaults and d.nativeCardScale==85 and d.cardOpacity==100 and d.zoneThemes==themed)
 assert(d.cardSizes.FieldKitMeterFrame.width==380 and d.moneyDetached)
 for i=5,table.getn(FieldKitStatsFrame.rows) do assert(not FieldKitStatsFrame.rows[i].label:IsShown(),"Unselected statistics escaped below the frame") end
 for _,b in ipairs(FieldKitGearFrame.loadoutTabs) do assert(b.fieldkitLabel:GetWidth()==b:GetWidth()-20,"Loadout tab label kept constructor width") end
 assert(d.interfaceProfiles[2]==slot and d.activeHudProfile==active and d.known.Preserved=="elite")
 assert(not P.SaveActive() and not P.Save(1),"Preview leaked into saved profile")
 d.cardOpacity=9;d.frameAnchors.FieldKitStatsFrame={"CENTER","CENTER",0,0}
 assert(P.CancelPreview())
 assert(d.cardOpacity==47 and d.nativeCardScale==105 and d.frameAnchors.FieldKitStatsFrame[3]==155)
 assert(d.interfaceProfiles[2]==slot and d.activeHudProfile==active)
end end
-- The preview toolbar must yield to reward choices, and repeated preference
-- transactions must not persist the temporary zero-alpha mask in a skin owner.
local toolbar=CreateFrame("Frame","FieldKitFirstLaunchBar",UIParent)
toolbar:SetAlpha(.8);toolbar:EnableMouse(true);toolbar:Show()
local phaseAPI=AZS_GetPhase
AZS_GetPhase=function() return "choosing" end
FieldKitScreenLayers.ApplyChoice()
assert(toolbar:GetAlpha()==0 and not toolbar:IsMouseEnabled(),"Preview toolbar covered native reward choices")
for _,themed in ipairs({true,false,true,false}) do
 assert(P.PreviewDefaults(themed))
 assert(toolbar:GetAlpha()==0,"Preference transaction uncovered the preview toolbar")
 assert(P.CancelPreview())
end
AZS_GetPhase=function() return "playing" end
FieldKitScreenLayers.ApplyChoice()
assert(toolbar:GetAlpha()==.8 and toolbar:IsMouseEnabled(),"Preview toolbar did not restore after choices")
assert(not next(FieldKitScreenLayers.choiceMasked),"Choice state leaked after restoration")
FieldKit.ApplyHUDProfileLive();update(FieldKitFrame,.3)
assert(FieldKitMeterFrame:GetAlpha()>0,"Meter stayed invisible after choice/theme transitions")
AZS_GetPhase=phaseAPI
assert(P.PreviewDefaults(false));fire(FieldKitFrame,"PLAYER_LOGOUT")
assert(not P.preview and d.cardOpacity==47 and d.known.Preserved=="elite","Logout persisted temporary defaults")
print("PASS first-launch defaults, six independent empty-DB simulations, theme off/on, profile/known-state isolation, cancellation and logout restoration")
