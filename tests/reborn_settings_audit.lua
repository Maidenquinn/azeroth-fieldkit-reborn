fire(FieldKitFrame,"VARIABLES_LOADED")
AZS_ZONE={zone="zangarmarsh",heroic=0};AZS_RUN={ph="playing",t=30,sh=25,en=5,enm=120}
SlashCmdList.FieldKit("")
local U,C,H,R,d=FieldKitUI,FieldKitZoneThemes,FieldKitThemeHUD,FieldKitReferenceHUD,FieldKitRebornDB
local function Option(label)
 for _,section in ipairs(U.sections) do for _,item in ipairs(section.items) do if item.label==label then return item end end end
 error("Missing setting: "..label)
end
local checks=0
FieldKitSettingsAudit={cases=0,variants={"off","minimal","complete","alternative"}}
for _,variant in ipairs({"off","minimal","complete","alternative"}) do
 C.Set("zoneThemes",false);d.zoneThemeVariant=variant=="off" and "complete" or variant
 if variant~="off" then C.Set("zoneThemes",true) end
 -- Run the actual registered user setters, not copies of their implementation.
 for _,section in ipairs(U.sections) do
  U.Select(section.id)
  for _,item in ipairs(section.items) do
   if item.get and item.set then
    local original=item.get();local values={}
    if item.kind=="check" then values={true,false}
    elseif item.kind=="choice" then for n=1,#item.values do table.insert(values,n) end
    elseif item.kind=="slider" then
     local minimum=item.minimum and item.minimum() or item.min
     if minimum and item.max then values={minimum,item.max} end
    end
    for _,value in ipairs(values) do
     local ok,err=pcall(item.set,value);assert(ok,variant.." / "..section.id.." / "..item.label..": "..tostring(err))
     local result=item.get()
     if item.kind=="check" then assert((result and true or false)==value,item.label.." checkbox not wired")
     else assert(result==value,item.label.." expected "..tostring(value).." got "..tostring(result)) end
     checks=checks+1
    end
    item.set(original)
   end
  end
 end
 Option("Settings panel size").set(70);local small=U.frame:GetScale()
 Option("Settings panel size").set(100);assert(U.frame:GetScale()>small)
 Option("Settings panel opacity").set(25)
 assert(U.frame:GetAlpha()==1,"Opacity faded the text/controls")
 if variant=="off" then assert(U.frame.fieldkitSkin.base:GetAlpha()==.25)
 else for _,t in ipairs(U.frame.referenceTiles) do assert(t:GetAlpha()==.25,"Themed shell ignores opacity") end end
 Option("Health bar under the character").set(true);C.Refresh(true)
 assert(FieldKitPlayerBar:GetParent()==UIParent and FieldKitPlayerBar:GetAlpha()>0 and FieldKitPlayerBar:IsShown(),"HP bar masked by "..variant)
 Option("Health bar under the character").set(false);C.Refresh(true);assert(not FieldKitPlayerBar:IsShown())
 Option("Health bar under the character").set(true)
 if variant~="off" then
  TARGET="Enemy";CreateFrame("Frame","AzerothSurvivorsUnitFrameTarget",UIParent)
  Option("Enemy target health numbers").set(false);C.Refresh(true);assert(not FieldKitThemeTarget.hp:IsShown())
  Option("Enemy target health numbers").set(true);C.Refresh(true);assert(FieldKitThemeTarget.hp:IsShown())
  Option("Gold and chest price").set(false);C.Refresh(true);assert(not H.counterRoot:IsShown())
  Option("Gold and chest price").set(true);C.Refresh(true);assert(H.counterRoot:IsShown())
 end
end
-- New navigation pages must survive the same normalization used on /reload.
for _,id in ipairs({"worldmarkers","chat","chatcolors","chatcopy","interface"}) do
 d.uiPage=id;FieldKit.InitializeSettings({});assert(d.uiPage==id,"Reload forgets "..id)
end
Option("Settings panel size").set(80);Option("Settings panel opacity").set(35)
assert(FieldKitProfiles.Save(1));Option("Settings panel size").set(90);Option("Settings panel opacity").set(60)
assert(FieldKitProfiles.Load(1));assert(d.settingsPanelScale==90 and d.settingsPanelOpacity==60,"HUD profile changed the application shell")
print("PASS settings audit: "..checks.." registered setter cases across themes off/minimal/complete/alternative; shell size/opacity, centre HP, target numbers, counters, reload navigation and profile independence")
FieldKitSettingsAudit.cases=checks
