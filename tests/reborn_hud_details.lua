fire(FieldKitFrame,"VARIABLES_LOADED")
local R,H,C=FieldKitReborn,FieldKitThemeHUD,FieldKitZoneThemes
AZS_ZONE={zone="zangarmarsh",zname="Marécage de Zangar",class="hunter",heroic=0}
AZS_RUN={ph="playing",t=300}
AZS_SCHEDULE={{name="First",state="slain",at=240},{name="Second",state="due",at=480}}
assert(R.BossProgress()==.25)
AZS_RUN.rift=5;assert(R.BossProgress()==.05)
AZS_RUN.rift=0;assert(R.BossProgress()==0)
AZS_NextBossProgress=function() return .63,"Native" end;assert(R.BossProgress()==.63)
AZS_NextBossProgress=nil;AZS_RUN.rift=5
AZS_GetUpcomingBosses=function() return {{name="Second",left=180,index=2}} end
AZS_EVENT={key="hallows_end",n=105}
AZS_EventCurrency=function(key) if key=="hallows_end" then return "Bonbons","Interface\\Icons\\Achievement_Halloween_Candy_01",{1,.5,.1} end end
local targetParent=CreateFrame("Frame",nil,UIParent)
local target=CreateFrame("Button","AzerothSurvivorsUnitFrameTarget",targetParent)
local gauge=CreateFrame("Frame","AzerothSurvivorsSurvivorsBossBar",UIParent)
target:Show();gauge:Show();TARGET="Enemy"
local clicked=false;target:SetScript("OnClick",function(self,button) assert(self==target and button=="LeftButton");clicked=true end)
local hp=130
UnitHealth=function(unit) return unit=="player" and hp or 600 end
UnitHealthMax=function(unit) return unit=="player" and 508 or 1000 end
FieldKitRebornDB.zoneThemeMode="auto";C.Set("zoneThemes",true)
assert(string.find(H.next:GetText(),"5%%"))
R.UpdateRunDetails();assert(not string.find(H.next:GetText(),"5%%.*5%%"),"Duplicate progress suffix")
assert(R.eventFrame:IsShown() and string.find(R.eventFrame.label:GetText(),"105 Bonbons",1,true))
assert(gauge:GetParent()==H.Hidden() and target:GetParent()==H.Hidden())
assert(FieldKitThemeTarget.frame:IsShown());FieldKitThemeTarget.frame:Click();assert(clicked)
local color
H.health.SetStatusBarColor=function(self,r,g,b) color={r,g,b} end
for _,sample in ipairs({{508,.12,.76,.18},{300,1,.85,.12},{130,1,.48,.08},{30,.9,.12,.12}}) do
 hp=sample[1];R.UpdateRunDetails();assert(color[1]==sample[2] and color[2]==sample[3] and color[3]==sample[4])
end
AZS_EVENT={};R.UpdateRunDetails();assert(not R.eventFrame:IsShown())
C.Set("zoneThemes",false)
assert(target:GetParent()==targetParent and gauge:GetParent()==UIParent)
AZS_GEN={classes={{key="hunter",token="HUNTER"}},spells={HUNTER={{key="auto_shot",name="Auto Shot",icon="Ability_Whirlwind"}}}}
AZS_SPELLS={{key="auto_shot",spell=75,rank=1}}
AZS_SPELLTIPS={auto_shot="Deals 120 damage. Your damage bonus: +56%."}
FieldKitLoadout.scanAt=0;FieldKitLoadout.Scan()
local e=FieldKitLoadout.spells[1];assert(e.nativeText==AZS_SPELLTIPS.auto_shot)
local lines={};GameTooltip.AddLine=function(self,text) table.insert(lines,text) end
FieldKitLoadout.Tip(UIParent,e)
assert(lines[2]==e.nativeText)
for _,line in ipairs(lines) do assert(line~="Bonus details not provided") end
AZS_SPELLTIPS.auto_shot="Deals 180 damage. Your damage bonus: +80%."
NOW=NOW+2;assert(FieldKitLoadout.Scan())
assert(FieldKitLoadout.spells[1].nativeText==AZS_SPELLTIPS.auto_shot)
print("PASS Reborn boss progress, event currency, native gauge/target takeover and restoration, target click, four HP colors and live spell details")
