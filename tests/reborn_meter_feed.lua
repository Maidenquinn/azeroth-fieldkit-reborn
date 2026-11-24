fire(FieldKitFrame,"VARIABLES_LOADED")
-- .39 Paladin audit: the native combat-text feed is the single hit/crit source.
-- Fixture events mirror AzerothSurvivorsAPI/CombatText.lua (game 0.7.4): seq, kind,
-- amount, critical, periodic, spellId, abilityName, sourceGuid, sourceName, targetName.
-- Mock data only; this is not live game validation.
FieldKitRebornDB.meterFrame=true;FieldKitRebornDB.meterSpellTips=true
local L=FieldKitMeterLedger
local ME,PET="Player-0001","Creature-0042"
UnitGUID=function(unit) if unit=="player" then return ME end end

local ring,seq,stream={},0,"s1"
local function Hit(name,amount,crit,periodic,spellId,src,srcName,target)
 seq=seq+1
 table.insert(ring,{seq=seq,kind="damage",amount=amount,critical=crit,periodic=periodic,spellId=spellId,
  abilityName=name,sourceGuid=src or ME,sourceName=srcName or "Maidenhead",targetName=target or "Raptor"})
end
local served=0
AZS_GetCombatTextEvents=function(cur,limit)
 local after=0
 if cur~=nil then local _,_,n=string.find(cur,"^ct:(%d+)$");after=tonumber(n) or 0 end
 local events,last={},after
 for i=1,table.getn(ring) do
  local e=ring[i]
  if e.seq>after and table.getn(events)<256 then table.insert(events,e);last=e.seq end
 end
 served=served+1
 return {apiVersion=1,cursor="ct:"..last,events=events,hasMore=last<seq,gap=false},nil
end

L.ClearHits()
-- 1. Consecration ticks reported without crits: a real 0%, crit data known.
for i=1,10 do Hit("Consécration",705,false,true,26573) end
L.PollCombatText(true)
local st=L.Stats("Consécration")
assert(st and st.hits==10 and st.crits==0 and st.critKnown==true and st.critPct==0,"Consecration non-crit ticks")
assert(st.maxHit==705 and st.maxCrit==0,"non-crit record")

-- 2. A simulated critical periodic tick is counted (the chat shim could never show it).
Hit("Consécration",1410,true,true,26573)
L.PollCombatText(true)
st=L.Stats("Consécration")
assert(st.hits==11 and st.crits==1 and st.maxCrit==1410 and st.maxHit==705,"periodic critical tick lost")
assert(math.abs(st.critPct-100/11)<1e-6,"crit rate")

-- 3. Feed present: chat lines are not parsed by the driver (no double count).
local driver=FieldKitMeterLedgerDriver
assert(driver and driver.scripts and driver.scripts.OnEvent,"ledger driver")
local pe,pa=event,arg1
event="CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE";arg1="Raptor suffers 705 Holy damage from your Consécration."
driver.scripts.OnEvent()
event,arg1=pe,pa
assert(L.Stats("Consécration").hits==11,"chat line double counted while the feed is authoritative")

-- 4. Paging: more than one 256-event page is drained in one poll, nothing re-read.
for i=1,600 do Hit("Consécration",700,(i-math.floor(i/4)*4==0),true,26573) end
L.PollCombatText(true)
st=L.Stats("Consécration")
assert(st.hits==611 and st.crits==151,"multi-page feed drain ("..st.hits.."/"..st.crits..")")
L.PollCombatText(true)
assert(L.Stats("Consécration").hits==611,"cursor re-read events")

-- 5. ClearHits keeps the cursor: a reset never re-imports already counted hits.
L.ClearHits()
L.PollCombatText(true)
assert(L.Stats("Consécration")==nil,"reset re-read the previous second of hits")

-- 6. Very large hits stay exact, crit and non-crit records separate.
Hit("Flamestrike",4200000000,false,false,2120)
Hit("Flamestrike",3500000000,true,false,2120)
Hit("Flamestrike",2147483649,false,false,2120)
L.PollCombatText(true)
st=L.Stats("Flamestrike")
assert(st.maxHit==4200000000 and st.maxCrit==3500000000 and st.amount==9847483649,"large damage values")

-- 7. Pets / summons keep their own book; a hero spell of the same name is not merged.
Hit("Firebolt",88,false,false,3110,PET,"Imp")
Hit("Firebolt",50,true,false,133)
Hit("Attack",120,true,false,nil,PET,"Imp")
L.PollCombatText(true)
assert(L.Stats("Imp: Firebolt").hits==1 and L.Stats("Imp: Firebolt").maxHit==88,"pet spell book")
assert(L.Stats("Firebolt").hits==1 and L.Stats("Firebolt").crits==1,"hero spell merged with pet")
assert(L.Stats("Imp: Melee").maxCrit==120,"pet melee book")

-- 8. Rank change: one book; a spellId join never steals another spell's record.
Hit("Consécration (Rang 39)",100,false,true,26573)
Hit("Consécration (Rang 40)",200,true,true,27173)
Hit("Bouclier du vengeur",300,false,false,31935)
L.PollCombatText(true)
st=L.Stats("Consécration")
assert(st.hits==2 and st.crits==1,"rank change split the book")
assert(L.Stats("Localized Consecration",27173).hits==2,"spellId join")
assert(L.Stats("Unknown Spell")==nil and L.Stats("Unknown Spell",999999)==nil,"unknown source must stay unknown")
assert(L.Stats("Bouclier du vengeur").hits==1,"distinct spell collision")

-- 9. Kills (Lot 0): only a lethal feed hit (overkill > 0 on an identified target) credits;
-- a chat death line never credits by name while the feed exists, but drains it early.
Hit("Consécration",700,false,true,26573,nil,nil,"Wolf")
Hit("Bouclier du vengeur",900,true,false,31935,nil,nil,"Wolf")
ring[table.getn(ring)].overkill=150;ring[table.getn(ring)].anchorId="Creature-Wolf-1"
event="CHAT_MSG_COMBAT_HOSTILE_DEATH";arg1="Wolf dies."
driver.scripts.OnEvent()
event,arg1=pe,pa
assert(L.KillsFor("Bouclier du vengeur")==1 and L.KillsFor("Consécration")==0,"lethal feed hit not credited")

-- 10. Lost events are counted (forward seq jump), never invented as hits.
local before=L.Stats("Consécration").hits
seq=seq+5
Hit("Consécration",700,false,true,26573)
L.PollCombatText(true)
assert(L.feed.missed==5,"missed events not reported ("..tostring(L.feed.missed)..")")
assert(L.Stats("Consécration").hits==before+1,"missed events invented")

-- 11. No feed (legacy client): chat fallback. A periodic line without "(Critical)"
-- is UNKNOWN, not a non-crit: absence of data is not absence of crits.
AZS_GetCombatTextEvents=nil
L.ClearHits()
L.ParseChat("Raptor suffers 705 Holy damage from your Consecration.")
L.ParseChat("Raptor suffers 705 Holy damage from your Consecration.")
st=L.Stats("Consecration")
assert(st.hits==2 and st.crits==0 and st.critKnown==false and st.maxHit==0 and st.maxUnclassified==705,"chat periodic tick classified as non-crit")
L.ParseChat("Raptor suffers 1410 Holy damage from your Consecration. (Critical)")
st=L.Stats("Consecration")
assert(st.critKnown==true and st.crits==1 and st.critPct==100 and st.critUnknown==2,"chat periodic crit")
L.ParseChat("Your Judgement hits Raptor for 100.")
assert(L.Stats("Judgement").critKnown==true and L.Stats("Judgement").critPct==0,"direct non-crit is a known 0%")
event="CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE";arg1="Raptor suffers 9 Holy damage from your Consecration."
driver.scripts.OnEvent()
event,arg1=pe,pa
assert(L.Stats("Consecration").hits==4,"chat fallback must count when the feed is absent")

-- 12. Tooltip: unknown crit data shows "-", never "0%".
L.ClearHits()
L.ParseChat("Raptor suffers 705 Holy damage from your Consecration.")
local lines={}
local add=GameTooltip.AddLine
GameTooltip.AddLine=function(self,text) table.insert(lines,tostring(text)) end
L.AppendStats("Consecration",nil,nil,nil)
GameTooltip.AddLine=add
local tip=table.concat(lines,"\n")
assert(string.find(tip,FieldKit_L("Crit rate")..": -",1,true),"unknown crit rate shown as a number")
assert(not string.find(tip,"(0%)",1,true),"unknown crit data rendered as 0%")
assert(string.find(tip,"705",1,true),"unclassified max hit hidden")

UnitGUID=nil
L.ClearHits()
print("PASS combat feed is the single hit source: periodic crits, paging, reset, >2^31, pets, ranks, kills, gaps, chat fallback unknown-vs-zero")
