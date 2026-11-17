-- Complete selectable catalogs, native ownership, scripts and persistent choice.
FieldKit.rebornLegacyFixture=false;FieldKitProfiles.factoryPresets=nil
fire(FieldKitFrame,"VARIABLES_LOADED")
SlashCmdList.FieldKit("")
local L,U,C=FieldKitLocale,FieldKitUI,FieldKitZoneThemes
assert(table.getn(L.languages)==15)
local old=FieldKitRebornDB.language
assert(FieldKit_SetLanguage("../../unexpected")==false and FieldKitRebornDB.language==old)
local anchors=FieldKitRebornDB.frameAnchors
local positions=FieldKitRebornDB.zoneThemePositions
local styled=FieldKitRebornDB.chatStyle
local names={pl="Obrażenia",cs="Poškození",de="Schaden",pt="Dano",es="Daño",fr="Dégâts",
 ro="Daune",tr="Hasar",ru="Урон",uk="Шкода",zh="伤害",ja="ダメージ",ko="피해",en="Damage"}
for index,row in ipairs(L.languages) do
 local code=row[1]
 if code~="auto" then
  assert(FieldKit_SetLanguage(code) and FieldKit_Language()==code)
  assert(FieldKit_L("Damage")==names[code],code..": primary label")
  assert(FieldKit_L("A player called Aimed Shot")=="A player called Aimed Shot")
  assert(U.languageRow.choice.choiceButtons[index].fieldkitSelected)
  assert(U.languageRow.choice.fieldkitLabel:GetText()==row[2])
  assert(FieldKitRebornDB.frameAnchors==anchors and FieldKitRebornDB.zoneThemePositions==positions)
  assert(FieldKitRebornDB.chatStyle==styled,"Language changes must not enable chat styling")
  for _,theme in ipairs({false,"elwynn","naxx"}) do
   C.Set("zoneThemes",false)
   if theme then FieldKitRebornDB.zoneThemeMode=theme;C.Set("zoneThemes",true) end
   FieldKitNativeTools.Update();FieldKitLoadout.Update();C.Refresh(true)
  end
 end
end
C.Set("zoneThemes",false)
for native,code in pairs(L.aliases) do
 AZS_LOCALE=native;FieldKit_SetLanguage("auto")
 assert(FieldKit_Language()==code and FieldKitRebornDB.language=="auto")
end
AZS_LOCALE="not-a-language";GetLocale=function() return "frFR" end
FieldKit_SetLanguage("auto");assert(FieldKit_Language()=="fr")
AZS_LOCALE=nil;GetLocale=function() return "unknown" end
assert(FieldKit_Language()=="en")
-- A manual selection always wins over the game's locale, without changing it.
AZS_LOCALE="jaJP";FieldKit_SetLanguage("de")
assert(FieldKit_Language()=="de" and AZS_LOCALE=="jaJP")
local label=UIParent:CreateFontString(nil,"OVERLAY","GameFontNormal")
label:SetFont("Fonts\\FRIZQT__.TTF",14,"")
FieldKit_Text(label,"Damage")
assert(label.fontPath==L.scriptFonts.ja,"Native names need Japanese glyphs under a German UI")
AZS_LOCALE="enUS"
for code,path in pairs(L.scriptFonts) do
 FieldKit_SetLanguage(code);FieldKit_Text(label,"Damage")
 assert(label.fontPath==path,code..": unthemed font")
 for _,theme in ipairs({"classic","elwynn","naxx"}) do
  FieldKitTheme.zone=theme;FieldKitTheme.Font(label,14,nil,true)
  assert(label.fontPath==path,code..": themed font")
 end
end
for _,code in ipairs({"pl","cs","ro","tr","ru","uk"}) do
 FieldKit_SetLanguage(code);FieldKitTheme.Font(label,14)
 assert(string.find(label.fontPath,"FieldKitLatin.ttf",1,true),code..": Latin/Cyrillic font coverage")
end
FieldKitTheme.zone="classic";FieldKit_SetLanguage("en");FieldKitTheme.Font(label,14)
assert(label.fontPath=="Fonts\\FRIZQT__.TTF","Restore the normal theme face")
-- Native tooltips borrow a readable face for an addon hover, then restore it.
local tipLine=GameTooltip:CreateFontString("GameTooltipTextLeft1","OVERLAY","GameFontNormal")
tipLine:SetFont("Fonts\\FRIZQT__.TTF",13,"OUTLINE")
local tipOwner=UIParent
GameTooltip.GetOwner=function() return tipOwner end
FieldKit_SetLanguage("ja");L.ShowTooltip()
assert(tipLine.fontPath==L.scriptFonts.ja)
L.HideTooltip();assert(tipLine.fontPath=="Fonts\\FRIZQT__.TTF" and tipLine.fontSize==13)
L.ShowTooltip();tipOwner=FieldKitFrame;update(L.tooltipWatcher,.01)
assert(tipLine.fontPath=="Fonts\\FRIZQT__.TTF" and not L.tooltipWatcher:IsShown())
L.ShowTooltip();tipLine:SetFont("OtherAddon.ttf",16,"");L.HideTooltip()
assert(tipLine.fontPath=="OtherAddon.ttf","Do not undo another addon's intervening font change")
-- Native names follow the game; player identities and meter keys are never localized.
AZS_L={["Aimed Shot"]="Visée"};AZS_LOCALE="frFR"
FieldKit_SetLanguage("pl")
assert(FieldKitReborn.DisplayName("Aimed Shot")=="Visée")
assert(FieldKitReborn.DisplayName("Maidenhead")=="Maidenhead")
AZS_L["Surge of Strength"]="Afflux de force";AZS_LOCALE="enUS";FieldKit_SetLanguage("en")
assert(FieldKitReborn.DisplayName("Surge of Strength")=="Afflux de force","Never reverse a supplied game name through the English UI dictionary")
-- Known proc gaps use the matching locale catalog, including floating combat text.
AZS_L={};AZS_SPELL_NAMES={}
for native,code in pairs(L.aliases) do
 if code~="en" then
  AZS_LOCALE=native;FieldKit_SetLanguage(code)
  local expected=L[code]["Surge of Strength"]
  assert(type(expected)=="string")
  assert(FieldKitReborn.DisplayName("Surge of Strength")==expected,code..": proc fallback")
  assert(FieldKitCombat.NativeLabel("Surge of Strength")==expected,code..": combat proc fallback")
  assert(FieldKitReborn.DisplayName("Maidenhead: Surge of Strength")=="Maidenhead: "..expected,code..": keep owner identity")
 end
end
-- Explicit language preference survives configuration normalization, including auto.
for _,code in ipairs({"auto","pt","uk","ko","fr"}) do
 FieldKitRebornDB.language=code;FieldKit.InitializeSettings({})
 assert(FieldKitRebornDB.language==code)
end
FieldKitRebornDB.language="unsupported";FieldKit.InitializeSettings({})
assert(FieldKitRebornDB.language=="auto")
print("PASS 14 selectable languages + auto: picker, native names, themed/unthemed fonts, normalization")
