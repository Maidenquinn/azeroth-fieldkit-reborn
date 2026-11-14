fire(FieldKitFrame,"VARIABLES_LOADED")
FieldKitRebornDB.replaceTally=false -- isolate themed restoration from the independent counter owner
local R,H,C,V=FieldKitReborn,FieldKitThemeHUD,FieldKitZoneThemes,FieldKitReferenceHUD
AZS_ZONE={zone="zangarmarsh",zname="Zangarmarsh",class="hunter",heroic=0}
AZS_RUN={ph="playing",t=20,rift=5,kills=10,gold=4,chest=20}
AZS_SCHEDULE={{state="due",name="Hungarfen",at=240}}
AZS_GetUpcomingBosses=function() return {{name="Hungarfen",left=220,index=1}} end
AZS_EVENT={key="hallows_end",n=12};AZS_EventCurrency=function() return "Bonbons","Interface\\Icons\\Candy",{1,.5,.1} end
local bar=CreateFrame("Frame","AzerothSurvivorsActionBar1",UIParent)
for i=1,12 do
 local b=CreateFrame("Button","AzerothSurvivorsActionBar1Button"..i,bar)
 b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetTexture("Interface\\Icons\\Spell"..i)
 b.backdrop=b:CreateTexture(nil,"BACKGROUND");b.IconBorder=b:CreateTexture(nil,"ARTWORK")
 b.cooldown=CreateFrame("Frame",nil,b);b.OverlayFrame=CreateFrame("Frame",nil,b);b:Show()
end
local dash=CreateFrame("Button","AZSDashButton",UIParent);dash.icon=dash:CreateTexture(nil,"ARTWORK")
dash.icon:SetTexture("Interface\\Icons\\Ability_Mount_RidingHorse");dash.key=dash:CreateFontString(nil,"OVERLAY");dash.key:SetText("Maj");dash:Show()
local clicks=0;dash:SetScript("OnClick",function() clicks=clicks+1 end)
local swarm=CreateFrame("Frame","AzerothSurvivorsMinimapStatusButton",Minimap)
local mapName=CreateFrame("Frame","AZSMapInfo",UIParent)
local chatParent=CreateFrame("Frame",nil,UIParent)
local chatUp=CreateFrame("Button","ChatFrame1ButtonFrameUpButton",chatParent)
HasAction=function(slot) return slot<=2 end
FieldKitLoadout.items={[13]={name="Reborn pendant",icon="Interface\\Icons\\CorrectPendant",bonuses={}}}
GetInventoryItemTexture=function() return "Interface\\Icons\\WrongPersistentItem" end
FieldKitRebornDB.zoneThemeMode="auto";C.Set("zoneThemes",true)
assert(R.ActionButton(12)==dash and dash:GetParent()==H.dock)
dash:Click();assert(clicks==1)
assert(AzerothSurvivorsActionBar1Button12:GetParent()==bar,"A seventh spell was moved")
local b=AzerothSurvivorsActionBar1Button1
assert(b.icon:GetAlpha()==0 and b.backdrop:GetAlpha()==0 and b.IconBorder:GetAlpha()==0)
assert(R.squareActions[b].icon:GetTexture()=="Interface\\Icons\\Spell1" and R.squareActions[b]:IsShown())
assert(not R.squareActions[AzerothSurvivorsActionBar1Button3]:IsShown())
assert(swarm:GetParent()==H.Hidden() and mapName:GetParent()==H.Hidden())
assert(chatUp:GetParent()==H.Hidden(),"Reborn's stock chat arrow leaked beside the themed controls")
assert(V.frames.Accessories.rows[2].icon:GetTexture()=="Interface\\Icons\\CorrectPendant")
assert(R.eventFrame:GetParent()==H.counterRoot and R.eventFrame.label:GetText()=="12")
assert(H.next:GetText()=="Hungarfen" and R.progressFrame:IsShown())
AZS_DASH={seen=false,off=0};R.PlaceSteed();assert(R.steedPending:IsShown() and R.steedPending.label:GetText()=="?")
assert(R.steedPending:GetScript("OnClick")==nil,"Unknown charges must not fabricate a usable ability")
AZS_DASH.seen=true;R.PlaceSteed();assert(not R.steedPending:IsShown())
assert(R.progressFrame.label:GetText()=="Hungarfen · 5%")
local target=CreateFrame("Frame","AzerothSurvivorsUnitFrameTarget",UIParent)
local unitExists=UnitExists;UnitExists=function(unit) return unit=="target" or unitExists(unit) end
AZS_RUN.en=30;AZS_RUN.enm=120;R.ProgressBar();FieldKitThemeTarget.Update("complete")
local _,anchor=FieldKitThemeTarget.frame:GetPoint()
assert(anchor==R.hordeFrame,"The target frame covered the horde gauge")
AZS_RUN.en=nil;R.ProgressBar();FieldKitThemeTarget.Update("complete")
local _,anchor=FieldKitThemeTarget.frame:GetPoint()
assert(anchor==R.progressFrame,"The target frame covered the boss progress gauge")
UnitExists=unitExists;FieldKitThemeTarget.Stop()
local run="run1";AZS_API_RunId=function() return run end
AZS_GEN={creatureIcons={[42]="NativeBogGiant"}}
AZS_WorldUnits=function() return {{name="Bog Giant",guid="native-guid",entry=42,player=false}} end
assert(R.EnemyIcon("Bog Giant",{})=="Interface\\Icons\\NativeBogGiant")
AZS_WorldUnits=function() return {} end
assert(R.EnemyIcon("Bog Giant",{})=="Interface\\Icons\\NativeBogGiant","Dead mob icon was lost")
assert(R.EnemyIcon("Unknown",{})=="Interface\\Icons\\INV_Misc_QuestionMark")
R.NoteEnemy(nil,"Bog Giant",99) -- unknown entries cannot erase evidence
assert(R.EnemyIcon("Bog Giant",{})=="Interface\\Icons\\NativeBogGiant")
run="run2";assert(R.EnemyIcon("Bog Giant",{})=="Interface\\Icons\\Achievement_Reputation_Ogre","Known catalog appearance lost after run boundary")
C.Set("zoneThemes",false)
assert(b.icon:GetAlpha()==1 and b.IconBorder:GetAlpha()==1 and not R.squareActions[b]:IsShown())
assert(dash:GetParent()==UIParent and swarm:GetParent()==Minimap and mapName:GetParent()==UIParent)
assert(chatUp:GetParent()==chatParent)
print("PASS Reborn square spell icons, six spells plus real Steed, correct run item icons, integrated candy/progress bar, native minimap cleanup and observed enemy icons")
