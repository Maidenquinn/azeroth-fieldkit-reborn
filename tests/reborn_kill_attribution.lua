fire(FieldKitFrame,"VARIABLES_LOADED")
-- Lot 0: kill attribution by target identity. Events mirror AzerothSurvivorsAPI/CombatText.lua
-- (0.7.4): the feed holds only the hero's own hits ("mine": hero, pets, summons); anchorId is
-- the target's guid; overkill is 0 on a non-lethal hit and > 0 on a lethal one (observed in
-- 0.7.4 combat data). Mock data only; this is not live game validation.
FieldKitRebornDB.meterFrame=true
local L=FieldKitMeterLedger
local ME,IMP,INFERNAL="Player-0001","Creature-Pet-0042","Creature-Summon-0077"
UnitGUID=function(unit) if unit=="player" then return ME end end
local driver=FieldKitMeterLedgerDriver

local ring,seq={},0
local function Hit(name,target,guid,over,src,srcName,spellId)
 seq=seq+1
 table.insert(ring,{seq=seq,at=GetTime(),kind="damage",amount=1000,overkill=over or 0,critical=false,periodic=false,
  spellId=spellId or 100,abilityName=name,targetName=target,anchorId=guid,
  sourceGuid=src or ME,sourceName=srcName or "Maidenhead"})
end
AZS_GetCombatTextEvents=function(cur)
 local after=0
 if cur~=nil then local _,_,n=string.find(cur,"^ct:(%d+)$");after=tonumber(n) or 0 end
 local events,last={},after
 for i=1,table.getn(ring) do
  local e=ring[i]
  if e.seq>after and table.getn(events)<256 then table.insert(events,e);last=e.seq end
 end
 return {apiVersion=1,cursor="ct:"..last,events=events,hasMore=last<seq,gap=false},nil
end
local function Chat(ev,msg)
 local pe,pa=event,arg1
 event=ev;arg1=msg;driver.scripts.OnEvent()
 event,arg1=pe,pa
end
local function Poll() L.PollCombatText(true) end
L.ClearHits();Poll()

-- 1. Same-name enemies: the kill goes to the blow that killed THAT guid, not the last
-- blow on any "Raptor".
Hit("Avenger's Shield","Raptor","Creature-R1",0)
Hit("Consecration","Raptor","Creature-R2",0)
Hit("Avenger's Shield","Raptor","Creature-R1",350,nil,nil,31935)
Chat("CHAT_MSG_COMBAT_HOSTILE_DEATH","Raptor dies.")
assert(L.KillsFor("Avenger's Shield")==1 and L.KillsFor("Consecration")==0,"same-name enemies: kill went to the wrong spell")

-- 2. Non-lethal hits (overkill 0) and an exactly-lethal hit are indistinguishable:
-- no kill is invented, whatever the chat says.
Hit("Consecration","Raptor","Creature-R2",0)
Chat("CHAT_MSG_COMBAT_HOSTILE_DEATH","Raptor dies.")
Chat("CHAT_MSG_COMBAT_HOSTILE_DEATH","You have slain Raptor!")
Poll()
assert(L.KillsFor("Consecration")==0,"kill invented from overkill 0 or from a chat death line")

-- 3. Several lethal hits on the same corpse (AoE ticks in one server tick): one kill.
Hit("Consecration","Wolf","Creature-W1",40)
Hit("Avenger's Shield","Wolf","Creature-W1",900)
Poll()
-- The first lethal hit (Consecration) owns the kill; the later one on the corpse adds nothing
-- (Avenger's Shield stays at its single kill from scenario 1).
assert(L.KillsFor("Consecration")==1 and L.KillsFor("Avenger's Shield")==1,"duplicate lethal hit counted twice")
assert(L.feed.kills==2,"feed kill counter")

-- 4. Co-op: a teammate's kill never reaches the hero's feed; its death line credits nothing,
-- even if the hero hit that enemy before.
Hit("Consecration","Ghoul","Creature-G1",0)
Chat("CHAT_MSG_COMBAT_HOSTILE_DEATH","Ghoul dies.")
Poll()
assert(L.KillsFor("Consecration")==1,"teammate kill credited to the hero")

-- 5. Pets and summons: credited to their own "Owner: Spell" book, never to the hero's spell.
Hit("Firebolt","Bat","Creature-B1",12,IMP,"Imp",3110)
Hit("Attack","Bat","Creature-B2",5,INFERNAL,"Infernal")
Poll()
assert(L.KillsFor("Imp: Firebolt")==1,"pet kill")
assert(L.KillsFor("Infernal: Melee")==1,"summon melee kill")
assert(L.KillsFor("Firebolt")==0,"pet kill credited to the hero")

-- 6. Unknown target identity: no guid, empty guid, or non-numeric overkill → no kill.
Hit("Exorcism","Spirit",nil,500)
Hit("Exorcism","Spirit","",500)
Hit("Exorcism","Spirit","Creature-S1","lethal")
Hit("Exorcism","Spirit","Creature-S2",-1)
Poll()
assert(L.KillsFor("Exorcism")==0,"kill invented without a target identity or a lethal overkill")
assert(L.Stats("Exorcism").hits==4,"hits still counted")

-- 7. Kills view lists the credited spells (count, never damage).
local view=L.Read("kills")
local seen={}
for i=1,table.getn(view) do seen[view[i].name]=view[i].dmg end
assert(seen["Avenger's Shield"]==1 and seen["Consecration"]==1 and seen["Imp: Firebolt"]==1,"kills view")

-- 8. Run change: books and de-duplication reset; a guid reused in the next run counts again.
L.ClearHits()
assert(L.KillsFor("Avenger's Shield")==0 and L.feed.kills==0,"reset kept kills")
Hit("Avenger's Shield","Wolf","Creature-W1",77)
Poll()
assert(L.KillsFor("Avenger's Shield")==1,"guid reused after a run change not credited")

-- 9. Bounded memory: corpses expire from the de-duplication set (no growth over a long run).
for i=1,300 do Hit("Consecration","Mob","Creature-M"..i,10) end
Poll()
NOW=NOW+60
Hit("Consecration","Mob","Creature-Late",10)
Poll()
assert(L.KillsFor("Consecration")==301,"mass kills")
-- The same guid after expiry would be credited again: only possible for a new creature,
-- since a dead target receives no further damage; asserted to document the bound.
Hit("Consecration","Mob","Creature-M1",10)
Poll()
assert(L.KillsFor("Consecration")==302,"expired guid not released")

-- 10. Legacy client without the feed: the name-based chat fallback is unchanged.
AZS_GetCombatTextEvents=nil
L.ClearHits()
L.ParseChat("Your Execute hits Razzashi Raptor for 513.")
Chat("CHAT_MSG_COMBAT_HOSTILE_DEATH","Razzashi Raptor dies.")
assert(L.KillsFor("Execute")==1,"legacy chat fallback changed")

UnitGUID=nil
L.ClearHits()
print("PASS kill attribution: guid identity, overkill>0 only, same-name enemies, co-op, pets/summons, unknown targets, duplicates, run change, bounded memory, legacy fallback")
