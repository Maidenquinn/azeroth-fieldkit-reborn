-- Fixed locale metadata and font choices. No native language/CVar is modified.
local T=FieldKitLocale
T.languages={
 {"auto","Automatic"},{"en","English"},{"pl","Polski"},{"cs","Čeština"},
 {"de","Deutsch"},{"pt","Português (Brasil)"},{"es","Español"},{"fr","Français"},
 {"ro","Română"},{"tr","Türkçe"},{"ru","Русский"},{"uk","Українська"},
 {"zh","简体中文"},{"ja","日本語"},{"ko","한국어"}
}
T.aliases={enUS="en",enGB="en",plPL="pl",csCZ="cs",deDE="de",ptBR="pt",ptPT="pt",
 esES="es",esMX="es",frFR="fr",roRO="ro",trTR="tr",ruRU="ru",ukUA="uk",
 zhCN="zh",jaJP="ja",koKR="ko"}
T.codes={auto=true,en=true,fr=true}
for _,row in ipairs(T.languages) do T.codes[row[1]]=true end
T.fr["Automatic"]="Automatique"
T.fr["Profile "]="Profil "
T.fr["Cancel"]="Annuler"
T.fr["PROF"]="PROF"
T.fr["HUD preview"]="Aperçu du HUD"
T.fr["World map"]="Carte du monde"
T.fr["Extensions"]="Extensions"
T.fr["Choose the language used by FieldKit. Automatic follows the game language. Game-provided names keep the game language."]="Choisissez la langue de FieldKit. Automatique suit la langue du jeu. Les noms fournis par le jeu conservent sa langue."
-- Reindex after both historical French extensions. English keys win collisions.
T.en={}
for key,value in pairs(T.fr) do if not T.fr[value] and not T.en[value] then T.en[value]=key end end
function T.Valid(code) return type(code)=="string" and T.codes[code]==true end
function T.GameLanguage()
 local code=T.aliases[AZS_LOCALE or ""]
 if not code and type(GetCVar)=="function" then local ok,value=pcall(GetCVar,"azsLanguage");if ok then code=T.aliases[value] end end
 if not code and type(GetLocale)=="function" then local ok,value=pcall(GetLocale);if ok then code=T.aliases[value] end end
 return code or "en"
end
function T.Selected()
 local code=FieldKitRebornDB and FieldKitRebornDB.language
 return T.Valid(code) and code or "auto"
end
-- Bundled OFL faces cover CJK plus Latin/Cyrillic in mixed addon/game text.
-- Menus use each language's own face even before it has been selected.
-- Revised glyph resources use a new path so an already-open client cannot reuse
-- a cached font atlas that predates the corrected translations after /reload.
T.scriptFonts={zh="Interface\\AddOns\\AzerothFieldKitReborn\\media\\FieldKitSans-zh-r2.ttf",
 ja="Interface\\AddOns\\AzerothFieldKitReborn\\media\\FieldKitSans-ja-r2.ttf",
 ko="Interface\\AddOns\\AzerothFieldKitReborn\\media\\FieldKitSans-ko-r2.ttf"}
function T.FontPath(path,code)
 if not code then
  code=FieldKit_Language()
  local native=T.GameLanguage()
  if not T.scriptFonts[code] and (T.scriptFonts[native] or native=="ru" or native=="uk") then code=native end
 end
 if T.scriptFonts[code] then return T.scriptFonts[code] end
 if code=="ru" or code=="uk" or code=="pl" or code=="cs" or code=="ro" or code=="tr" then
  if string.find(path or "","Serif",1,true) then return "Interface\\AddOns\\AzerothFieldKitReborn\\media\\FieldKitSerif.ttf" end
  return "Interface\\AddOns\\AzerothFieldKitReborn\\media\\FieldKitLatin.ttf"
 end
 -- Distinct resource names also avoid retaining an older cached font after /reload.
 if string.find(path or "","AzerothSans.ttf",1,true) then return "Interface\\AddOns\\AzerothFieldKitReborn\\media\\FieldKitLatin.ttf" end
 if string.find(path or "","NotoSerif-Regular.ttf",1,true) then return "Interface\\AddOns\\AzerothFieldKitReborn\\media\\FieldKitSerif.ttf" end
 return path
end
T.ownedFonts=setmetatable({},{__mode="k"})
function T.ApplyFont(object,code)
 if not object or not object.GetFont or not object.SetFont then return end
 if object.fieldkitFontRecord and FieldKitTheme then
  local r=object.fieldkitFontRecord;FieldKitTheme.Font(object,r.size,r.color,r.heading,r.face);return
 end
 local record=T.ownedFonts[object]
 if not record then
  local ok,path,size,flags=pcall(object.GetFont,object)
  if not ok or type(path)~="string" then return end
  record={path=path,size=size or 14,flags=flags or ""};T.ownedFonts[object]=record
 end
 local path=T.FontPath(record.path,code)
 local old,size,flags=object:GetFont()
 if old~=path or size~=record.size or (flags or "")~=record.flags then pcall(object.SetFont,object,path,record.size,record.flags) end
end
function T.RefreshFonts()
 if FieldKitTheme then FieldKitTheme.Refresh() end
 for object in pairs(T.ownedFonts) do T.ApplyFont(object,object.fieldkitLanguageFont) end
end
-- Borrow native tooltip rows only while FieldKit owns the hover. Do not change
-- global font objects or install native scripts; restore on leave/owner change.
function T.RestoreTooltipFonts()
 local state=T.tooltipFonts;T.tooltipFonts=nil
 if state then for _,row in ipairs(state.rows) do
  local path,size,flags=row[1]:GetFont()
  if path==row[5] and size==row[3] and (flags or "")==row[4] then pcall(row[1].SetFont,row[1],row[2],row[3],row[4]) end
 end end
 if T.tooltipWatcher then T.tooltipWatcher:Hide() end
end
function T.ShowTooltip()
 if not GameTooltip then return end
 T.RestoreTooltipFonts()
 local state={rows={},owner=GameTooltip.GetOwner and GameTooltip:GetOwner()}
 local name=GameTooltip.GetName and GameTooltip:GetName() or "GameTooltip"
 for i=1,40 do for _,side in ipairs({"Left","Right"}) do
  local label=getglobal(name.."Text"..side..i)
  if label and label.GetFont and label.SetFont then
   local old,size,flags=label:GetFont()
   local path=old and T.FontPath(old)
   if path and old~=path then
    table.insert(state.rows,{label,old,size or 12,flags or "",path})
    pcall(label.SetFont,label,path,size or 12,flags or "")
   end
  end
 end end
 if table.getn(state.rows)>0 then
  T.tooltipFonts=state
  if not T.tooltipWatcher then
   T.tooltipWatcher=CreateFrame("Frame",nil,UIParent)
   T.tooltipWatcher:SetScript("OnUpdate",function()
    local current=T.tooltipFonts
    if not current or not GameTooltip:IsShown() or
      (GameTooltip.GetOwner and GameTooltip:GetOwner()~=current.owner) then T.RestoreTooltipFonts() end
   end)
  end
  T.tooltipWatcher:Show()
 end
 GameTooltip:Show()
end
function T.HideTooltip()
 if GameTooltip then GameTooltip:Hide() end
 T.RestoreTooltipFonts()
end
-- Standalone legacy settings use the same complete list, without a UI dependency.
function FieldKit_CreateLanguageOption(page,y)
 local label=page:CreateFontString(nil,"OVERLAY","GameFontNormal")
 label:SetPoint("TOPLEFT",page,"TOPLEFT",0,y);FieldKit_Text(label,"Language")
 for i,row in ipairs(T.languages) do
  local code,name=row[1],row[2]
  local button=CreateFrame("Button",nil,page,"UIPanelButtonTemplate")
  button:SetWidth(155);button:SetHeight(25);button:SetPoint("TOPLEFT",page,"TOPLEFT",math.mod(i-1,3)*160,y-24-math.floor((i-1)/3)*29)
  button:SetText(name);button:SetScript("OnClick",function() FieldKit_SetLanguage(code) end)
  local function Refresh()
   button:SetText((T.Selected()==code and "> " or "")..FieldKit_L(name))
   if button.GetFontString then T.ApplyFont(button:GetFontString(),code=="auto" and FieldKit_Language() or code) end
  end
  FieldKit_RefreshLanguage(Refresh);Refresh()
 end
 return y-190
end
