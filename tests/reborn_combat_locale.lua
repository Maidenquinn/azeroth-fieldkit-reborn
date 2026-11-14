fire(FieldKitFrame,"VARIABLES_LOADED")
AZS_L={["Aimed Shot"]="Visée",["Auto Shot"]="Tir automatique"}
local d=FieldKitRebornDB
 d.combatText=true;d.combatTextWorld=false;d.combatTextGroup=true
 d.combatTextMin=0;d.combatTextMax=10;d.combatTextNames=true;d.combatTextCounts=true
local f=FieldKitCombatText
local function shown(text)
 for _,fs in ipairs(f.children) do if fs:IsShown() and fs:GetText()==text then return true end end
 return false
end
fire(f,"CHAT_MSG_SPELL_SELF_DAMAGE","Your Aimed Shot hits Wolf for 100.")
fire(f,"CHAT_MSG_SPELL_SELF_DAMAGE","Your Aimed Shot hits Wolf for 200.")
fire(f,"CHAT_MSG_SPELL_SELF_DAMAGE","Your Auto Shot crits Wolf for 230.")
fire(f,"CHAT_MSG_SPELL_SELF_DAMAGE","Your Unknown Spell hits Wolf for 17.")
update(f,.3)
assert(shown("Visée 300 x2"),"Grouped chat hits retain an English spell name")
assert(shown("Tir automatique 230"),"Chat critical hit is not localised")
assert(shown("Unknown Spell 17"),"Unknown native names must survive")
AZS_L["Aimed Shot"]="Aimed Shot";update(f,.1)
assert(shown("Aimed Shot 300 x2"),"Live locale refresh changed the grouped hit")
AZS_L["Aimed Shot"]="Visée"
d.combatTextNames=false;update(f,.1)
assert(shown("300 x2"),"Names-off setting no longer works")
update(f,3);d.combatTextNames=true;d.combatTextIgnore="Aimed Shot"
fire(f,"CHAT_MSG_SPELL_SELF_DAMAGE","Your Aimed Shot hits Wolf for 999.")
update(f,.3)
assert(not shown("Visée 999"),"Raw saved ignore filter stopped working")
d.combatTextIgnore="";d.combatTextWorld=true
local events={{eventId="fr1",presentedAt=GetTime(),kind="damage",amount=1357,
 abilityName="Aimed Shot",anchorId="fr-anchor",anchorStatus="ready",sourceKind="player"}}
function AZS_GetCombatTextCapabilities() return {frameHandler=true} end
function AZS_GetCombatTextEvents()
 local batch={apiVersion=1,streamId="fr",worldId="w",clockSeconds=GetTime(),cursor="1",events=events,hasMore=false,droppedCount=0}
 events={};return batch,nil
end
function AZS_ProjectCombatTextAnchors(ids)
 local entries={}
 for _,id in ipairs(ids) do table.insert(entries,{anchorId=id,state="onScreen",x=320,y=480,cameraDistance=10}) end
 return {apiVersion=1,worldId="w",streamId="fr",frameCurrent=true,entries=entries},nil
end
local handler
function AZS_RegisterCombatTextFrameHandler(fn) handler=fn;return true end
update(f,.3);assert(handler);handler();update(f,.3)
assert(shown("Visée 1357"),"World API damage is not localised")
events={{eventId="fr-miss",presentedAt=GetTime(),kind="miss",abilityName="Aimed Shot",result={key="miss",text="Miss"},anchorId="fr-anchor",anchorStatus="ready",sourceKind="player"}}
FieldKit_SetLanguage("fr");handler();update(f,.3)
assert(shown("> Visée: Raté"),"World miss uses raw English result text")
assert(FieldKitReborn.DisplayName("My pet: Aimed Shot")=="My pet: Visée")
print("PASS floating combat locale: chat/world, grouped amounts, critical, unknown names, locale refresh, names-off and raw filters")
