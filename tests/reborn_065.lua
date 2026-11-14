fire(FieldKitFrame,"VARIABLES_LOADED")
local Q=FieldKitReborn065
AZS_RUN={ph="playing",t=10};AZS_ZONE={zone="firelands"}
local debuffs={}
AZS_GetDebuffs=function(id) assert(id==17);return debuffs end
assert(Q.ControlText(17)==nil,"Unknown control state was invented")
debuffs={{name="Boss windup",remaining=2}};assert(Q.ControlText(17)==nil,"A windup was labelled Stunned")
debuffs={{name="Rooted",remaining=1.25}};assert(Q.ControlText(17)=="Rooted · 1.2s")
local card=CreateFrame("Frame",nil,UIParent);card:SetWidth(420);card.tag=card:CreateFontString(nil,"OVERLAY")
Q.BossStatus(card,17,true);assert(string.find(card.tag:GetText(),"ENRAGED",1,true) and string.find(card.tag:GetText(),"Rooted",1,true),"Control text erased enrage")
debuffs={{name="Stunned",remaining=0}};assert(Q.ControlText(17)==nil,"Expired control retained")
debuffs={{name="Stun immune",remaining=3}};assert(Q.ControlText(17)=="Stun immune · 3.0s","Immunity was guessed from a fixed eight seconds")
debuffs={{name="Stun immune"}};assert(Q.ControlText(17)==nil,"Missing expiry invented")
AZS_GetDebuffs=function() error("unavailable") end;assert(Q.ControlText(17)==nil)
local native=CreateFrame("Frame","AzerothSurvivorsUnitFrameTarget",UIParent)
local cast=CreateFrame("StatusBar",nil,native);native.Castbar=cast;cast:SetWidth(211);cast:SetPoint("CENTER",native,"CENTER",3,4)
local callback=function() end;cast:SetScript("OnUpdate",callback)
local owner=CreateFrame("Frame",nil,UIParent);owner:SetWidth(340)
Q.MoveCastbar(owner);assert(cast:GetParent()==owner and cast:GetScript("OnUpdate")==callback)
Q.RestoreCastbar();assert(cast:GetParent()==native and cast:GetWidth()==211)
local point,relative,rp,x,y=cast:GetPoint();assert(point=="CENTER" and relative==native and x==3 and y==4)
cast:SetParent(native);Q.MoveCastbar(owner)
local third=CreateFrame("Frame",nil,UIParent);cast:SetParent(third);Q.RestoreCastbar();assert(not FieldKitThemeHUD.saved[cast],"Stale ownership could steal a third-party castbar later")
Q.MoveCastbar(owner);assert(cast:GetParent()==third,"Third-party cast owner was stolen")
local calls=0;SlashCmdList.AZSDEATHLOG=function() calls=calls+1 end
SlashCmdList.FieldKit("");assert(calls==0,"Building the settings opened a native modal")
local action
for _,section in ipairs(FieldKitUI.sections) do for _,item in ipairs(section.items) do if item.kind=="action" and item.label=="Native death log" then action=item.action end end end
assert(action);action();assert(calls==1 and not FieldKitUI.frame:IsShown(),"Native log opened behind the settings panel");calls=0
assert(Q.OpenDeathLog() and calls==1);SlashCmdList.AZSDEATHLOG=nil;assert(not Q.OpenDeathLog())
AZS_DEATH={hits={{spell=123,from="Boss",health=0,amount=150,over=25}}}
GetSpellInfo=function() return "Fatal spell",nil,"Interface\\Icons\\Spell_Fire_Fireball" end
assert(Q.KillingBlow()==nil,"Old death log exposed in a live run")
AZS_RUN.ph="dead";local h=Q.KillingBlow();assert(h.name=="Fatal spell" and h.amount==150 and h.total==175 and h.overkill==25 and h.icon)
AZS_DEATH.hits[1].health=1;assert(Q.KillingBlow()==nil)
AZS_DEATH.hits[1].health=0;AZS_DEATH.hits[1].over=nil;assert(Q.KillingBlow().overkill==nil)
AZS_DEATH=nil;assert(Q.KillingBlow()==nil)
-- Observed icons are capped by distinct names, not retained per dead GUID.
AZS_API_RunId=function() return "long" end;AZS_GEN={creatureIcons={[1]="Ability_MeleeDamage"}}
for i=1,2000 do FieldKitReborn.NoteEnemy(nil,"Enemy "..i,1) end
assert(FieldKitReborn.enemyCount<=512)
AZS_API_RunId=function() return "next" end;FieldKitReborn.EnsureEnemyRun();assert(FieldKitReborn.enemyCount==0)
assert(FieldKitReborn.Icon("achievment_Boss_Madnessofdeathwing")=="Interface\\Icons\\Achievement_Boss_Nefarion")
print("PASS 0.6.5 native control states/no guessed timers, castbar ownership/restore, death log boundaries and long-run icon cap")
