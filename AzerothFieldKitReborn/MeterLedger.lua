-- Live meter ledger: native meter snapshots + local hit/crit/kill books.
-- Reset uses AZS_CreateMeterCheckpoint when available; hit stats never invent totals.
FieldKitMeterLedger={}
local L=FieldKitMeterLedger
local BURST=1
local books,kills,burstWin,byId,byIcon={},{},{},{},{}
-- Ambiguous aliases are marked false instead of silently taking the last spell.
local lastBlow={}
local checkpoint,runKey,cursor,subscribed
-- Hit/crit source of truth (.39): the native combat-text feed (AZS_GetCombatTextEvents)
-- carries the combat log's `critical` flag for direct AND periodic hits. The 1.12 chat
-- shim writes periodic lines as "X suffers N ... from your Spell." with no crit form,
-- so a chat-only ledger can never see a periodic crit (Consecration ticks).
-- When the feed exists, it alone counts hits; chat lines are a fallback, never both.
local FEED_PAGES=8
local feedSeq
L.feed={batches=0,gaps=0,missed=0,events=0,kills=0}
-- Kill attribution (Lot 0). With the feed, a kill is credited only on a feed hit
-- whose target is identified (anchorId = the target's guid) and whose overkill is
-- strictly positive: the feed holds only the hero's own hits (CombatText.lua's
-- "mine" affiliation: hero, pets, summons), so killer and victim are both known.
-- Observed on 0.7.4: non-lethal hits carry overkill 0 (never -1), lethal ones > 0.
-- overkill 0 cannot tell "not lethal" from "exactly lethal": no kill is invented.
-- Chat death lines ("X dies.", "You have slain X!") name victims only and are
-- ignored while the feed exists. killedGuid de-duplicates a second lethal hit on
-- the same corpse; entries expire after KILL_KEEP seconds (bounded memory).
local KILL_KEEP=10
local killedGuid,killSweepAt={},0
local TAKEN_NAMES={
 ["boss melee"]="Boss melee",["boss spell"]="Boss spells",["elite"]="Elites",
 ["mob melee"]="Monster melee",["mob spell"]="Monster spells",["area"]="Ground effects"}

L.views={"damage","healing","boss","taken","party","kills"}
L.labels={"Damage","Healing","Boss damage","Damage taken","Party DPS","Kills"}

local function Text(s,limit)
 if type(s)~="string" or not string.find(s,"%S") then return nil end
 return FieldKitNative and FieldKitNative.Text and FieldKitNative.Text(s,limit or 160) or string.sub(s,1,limit or 160)
end

local function Num(v,lo,hi)
 local n=FieldKit.MeterNumber(v,nil,lo,hi);return n
end

local function Strip(msg)
 if type(msg)~="string" then return "" end
 msg=string.gsub(msg,"|c%x%x%x%x%x%x%x%x","")
 msg=string.gsub(msg,"|r","")
 msg=string.gsub(msg,"|H.-|h(.-)|h","%1")
 return msg
end

local function IconOf(name)
 if FieldKitLoadout and FieldKitLoadout.Icon then return FieldKitLoadout.Icon(name) end
 return nil
end

-- Collapse rank / locale rank suffixes so Consecration R39 and R40 share one book.
local function SpellBase(name)
 name=Text(name,120);if not name then return nil end
 name=string.gsub(name,"%s*%(%s*[Rr]an[kg]o?%s*%d+%s*%)%s*$","")
 name=string.gsub(name,"%s+R%d+%s*$","")
 name=string.gsub(name,"%s+$","")
 if name=="" then return nil end
 return name
end

local function Book(name)
 name=SpellBase(name);if not name then return nil end
 local b=books[name]
 if not b then b={hits=0,crits=0,amount=0,maxHit=0,maxCrit=0,burst=0,blind=0,maxBlind=0};books[name]=b end
 return b,name
end

local function BurstAdd(name,amount,t)
 local w=burstWin[name]
 if not w or t-w.t0>BURST then burstWin[name]={t0=t,sum=amount};w=burstWin[name]
 else w.sum=w.sum+amount end
 local b=Book(name);if b and w.sum>(b.burst or 0) then b.burst=w.sum end
end

local function IndexSpell(key,spellId,icon)
 if not key then return end
 if spellId~=nil then
  local id=tostring(spellId)
  if byId[id]==nil then byId[id]=key elseif byId[id]~=key then byId[id]=false end
 end
 if type(icon)~="string" or icon=="" then icon=IconOf(key) end
 if type(icon)=="string" and icon~="" then
  if byIcon[icon]==nil then byIcon[icon]=key elseif byIcon[icon]~=key then byIcon[icon]=false end
 end
end

local function RememberBlow(victim,spell,spellId,icon)
 victim=Text(victim,80);spell=Text(spell,120)
 if not victim or not spell or spell=="" then return end
 if type(icon)~="string" or icon=="" then icon=IconOf(spell) end
 lastBlow[victim]={name=spell,spellId=spellId,icon=icon}
end

-- The feed cursor survives a book reset: rewinding it to nil would re-read the
-- last second of already counted hits into the fresh books.
function L.ClearHits()
 books={};kills={};burstWin={};byId={};byIcon={};lastBlow={}
 killedGuid={};killSweepAt=0
 L.feed={batches=0,gaps=0,missed=0,events=0,kills=0}
end

function L.Reset()
 local caps=FieldKitReborn.Capabilities()
 if caps and type(caps.features)=="table" and caps.features.atomicCheckpoints==false then L.ClearHits();return false end
 local prev=checkpoint
 L.ClearHits()
 if type(AZS_ReleaseMeterCheckpoint)=="function" and prev then pcall(AZS_ReleaseMeterCheckpoint,prev) end
 checkpoint=nil
 if type(AZS_GetMeterContext)~="function" or type(AZS_CreateMeterCheckpoint)~="function" then return false end
 local ok,ctx=pcall(AZS_GetMeterContext)
 if not ok or type(ctx)~="table" or type(ctx.runId)~="string" then return false end
 local ok2,cp=pcall(AZS_CreateMeterCheckpoint,ctx.runId)
 if ok2 and type(cp)=="table" and type(cp.checkpointId)=="string" then
  checkpoint=cp.checkpointId;return true
 end
 if ok2 and type(cp)=="string" then checkpoint=cp;return true end
 return false
end

local function RunKey()
 local zone=type(AZS_ZONE)=="table" and tostring(AZS_ZONE.zone or "") or ""
 local t=type(AZS_RUN)=="table" and tonumber(AZS_RUN.t) or 0
 return zone..":"..tostring(math.floor((t or 0)/30))
end

function L.Boundary()
 if type(AZS_API_RunId)=="function" then
  local id=AZS_API_RunId()
  if id~=L.rebornRunId then L.ClearHits();checkpoint=nil;L.rebornRunId=id end
 end
 local zone=type(AZS_ZONE)=="table" and tostring(AZS_ZONE.zone or "") or ""
 local key=RunKey()
 local phase=type(AZS_GetPhase)=="function" and AZS_GetPhase() or nil
 if not phase or phase=="ready" then
  if runKey then L.ClearHits();checkpoint=nil;runKey=nil end
  return
 end
 if runKey~=key then
  local oldZone=runKey and string.sub(runKey,1,(string.find(runKey,":") or 1)-1) or ""
  if runKey and oldZone~=zone then L.ClearHits();checkpoint=nil end
  runKey=key
 end
end

-- crit: true / false as reported; nil = the source cannot tell (a chat periodic line).
-- Unclassified hits are counted but never enter the crit rate or the non-crit record.
function L.NoteHit(name,amount,crit,spellId,icon)
 amount=Num(amount,0);if not amount or amount<=0 then return end
 local b,key=Book(name);if not b then return end
 b.hits=b.hits+1;b.amount=b.amount+amount
 if crit==nil then
  b.blind=(b.blind or 0)+1
  if amount>(b.maxBlind or 0) then b.maxBlind=amount end
 elseif crit then
  b.crits=b.crits+1
  if amount>b.maxCrit then b.maxCrit=amount end
 else
  if amount>b.maxHit then b.maxHit=amount end
 end
 BurstAdd(key,amount,GetTime())
 IndexSpell(key,spellId,icon)
end

function L.NoteKill(name,spellId,icon)
 local b,key=Book(name);if not key then return end
 kills[key]=(kills[key] or 0)+1
 IndexSpell(key,spellId,icon)
end

-- Same credit path as AZS Spell Meter: last damaging spell on that target.
function L.NoteDeath(victim)
 victim=Text(victim,80);if not victim then return end
 local blow=lastBlow[victim]
 if not blow or not blow.name then return end
 L.NoteKill(blow.name,blow.spellId,blow.icon)
 lastBlow[victim]=nil
end

function L.KillsFor(name,spellId,icon)
 local st=L.Stats(name,spellId,icon or IconOf(name))
 return st and (st.kills or 0) or 0
end

local function ResolveBook(name,spellId,icon)
 -- Prefer the actual combat-log spell name. Artwork is not a unique identifier:
 -- Pyroclasm and Pyrotechnic Explosion (and many ranks) can share textures.
 name=SpellBase(name)
 if name and books[name] then return books[name],name end
 -- Never substitute an unrelated spell just because its icon happens to match.
 -- Alias fallback is allowed only when no explicit spell name was provided,
 -- or when the caller uses a localized name unavailable in combat logs.
 if spellId~=nil then
  local key=byId[tostring(spellId)]
  if key and books[key] then return books[key],key end
 end
 -- Icon-only lookups are for tooltips with no textual spell identity.
 -- A named but unmatched source must not inherit another spell's record.
 if not name and type(icon)=="string" and icon~="" then
  local key=byIcon[icon]
  if key and books[key] then return books[key],key end
 end
 return nil
end

function L.Stats(name,spellId,icon)
 local b,key=ResolveBook(name,spellId,icon)
 if not b then return nil end
 local hits=b.hits or 0
 local crits=b.crits or 0
 local blind=b.blind or 0
 local seen=hits-blind
 return {
  hits=hits,crits=crits,
  -- critKnown=false: hits exist but none says whether it crit (not "0% crit").
  critKnown=seen>0,critObserved=seen,critUnknown=blind,
  critPct=seen>0 and (100*crits/seen) or 0,
  maxHit=b.maxHit or 0,maxCrit=b.maxCrit or 0,maxUnclassified=b.maxBlind or 0,
  avg=hits>0 and (b.amount/hits) or 0,
  burst=b.burst or 0,
  amount=b.amount or 0,
  kills=kills[key] or 0,
 }
end

function L.FeedAvailable()
 return type(AZS_GetCombatTextEvents)=="function"
end

-- Feed hits are already the hero's own (combat log "mine" affiliation). A pet or
-- summon keeps the chat-era "Owner: Spell" book so its record never merges into
-- the hero's spell of the same name.
local function FeedName(e)
 local name=type(e.abilityName)=="string" and e.abilityName~="" and e.abilityName or "Melee"
 if name=="Attack" then name="Melee" end
 local me=type(UnitGUID)=="function" and UnitGUID("player") or nil
 if me and e.sourceGuid~=nil and e.sourceGuid~=me and type(e.sourceName)=="string" and e.sourceName~="" then
  name=e.sourceName..": "..name
 end
 return name
end

local function SweepKilled(now)
 killSweepAt=now
 for guid,at in pairs(killedGuid) do
  if now-at>KILL_KEEP then killedGuid[guid]=nil end
 end
end

local function IngestCombatEvent(e,countHits)
 if type(e)~="table" or e.kind~="damage" or not countHits then return end
 local name=FeedName(e)
 local crit=nil
 if e.critical==true then crit=true elseif e.critical==false then crit=false end
 L.NoteHit(name,e.amount,crit,e.spellId,e.icon)
 local over=tonumber(e.overkill)
 local guid=e.anchorId
 if over and over>0 and type(guid)=="string" and guid~="" and not killedGuid[guid] then
  local now=tonumber(e.at) or GetTime()
  killedGuid[guid]=now
  L.NoteKill(name,e.spellId,e.icon)
  L.feed.kills=L.feed.kills+1
  if now-killSweepAt>=1 then SweepKilled(now) end
 end
end

-- Reads every page the feed holds (bounded), so a dense AoE second is not cut
-- at 256 events. Lost events are counted, never estimated or invented.
function L.PollCombatText(countHits)
 if not L.FeedAvailable() then return end
 local pages=0
 while pages<FEED_PAGES do
  pages=pages+1
  local ok,batch,err=pcall(AZS_GetCombatTextEvents,cursor)
  if not ok then return end
  if not batch and type(err)=="table" and err.code=="STREAM_CHANGED" then
   cursor=nil;feedSeq=nil
   ok,batch=pcall(AZS_GetCombatTextEvents,nil);if not ok or not batch then return end
  end
  if type(batch)~="table" then return end
  if countHits then
   L.feed.batches=L.feed.batches+1
   if batch.gap then L.feed.gaps=L.feed.gaps+1 end
   local dropped=tonumber(batch.droppedCount)
   if dropped and dropped>0 then L.feed.missed=L.feed.missed+dropped end
  end
  if batch.cursor~=nil then cursor=batch.cursor end
  local events=batch.events
  local n=type(events)=="table" and math.min(256,table.getn(events)) or 0
  for i=1,n do
   local e=events[i]
   local s=type(e)=="table" and tonumber(e.seq) or nil
   if s then
    -- A reload/new stream restarts numbering: only a forward jump is a loss.
    if countHits and feedSeq and s>feedSeq+1 and not batch.droppedCount then L.feed.missed=L.feed.missed+(s-feedSeq-1) end
    feedSeq=s
   end
   if countHits then L.feed.events=L.feed.events+1 end
   IngestCombatEvent(e,countHits)
  end
  if not batch.hasMore or n==0 then return end
 end
end

-- Extra minions that log as friendly NPCs rather than UnitName("pet").
local SUMMONS={
 ["Imp"]=true,["Felhunter"]=true,["Voidwalker"]=true,["Succubus"]=true,
 ["Felguard"]=true,["Infernal"]=true,["Inferno"]=true,["Doomguard"]=true,
 ["Dread Lord"]=true,["Pit Lord"]=true,["Wolf"]=true,["Raptor"]=true,
 ["Spirit Wolf"]=true,["Treant"]=true,["Water Elemental"]=true,
}

local function CleanOwner(owner)
 if not owner then return nil end
 owner=string.gsub(owner,"^%s+","")
 owner=string.gsub(owner," %(Critical%)$","")
 owner=string.gsub(owner,"%.$","")
 owner=string.gsub(owner,"%s+$","")
 owner=string.gsub(owner,"^Your ","")
 if owner=="" then return nil end
 return owner
end

local function IsMine(owner)
 owner=CleanOwner(owner)
 if not owner then return nil end
 if type(UnitExists)=="function" and UnitExists("pet") and type(UnitName)=="function" and owner==UnitName("pet") then
  return owner
 end
 if SUMMONS[owner] then return owner end
 return nil
end

local function Attribute(owner,spell)
 local mine=IsMine(owner)
 if mine and spell then return mine..": "..spell end
 return nil
end

function L.ParseChat(msg)
 msg=Strip(msg)
 if msg=="" or string.len(msg)>512 then return end
 local amount,spell,victim,crit,owner
 local _
 local periCrit=string.find(msg,"%(Critical%)") and true or false
 _,_,spell,victim,amount=string.find(msg,"^Your (.+) crits (.+) for ([%d,]+)")
 if amount then crit=true
 else
  _,_,spell,victim,amount=string.find(msg,"^Your (.+) hits (.+) for ([%d,]+)")
 end
 if not amount then
  _,_,spell,victim,amount=string.find(msg,"^Your (.+) critically hits (.+) for ([%d,]+)")
  if amount then crit=true end
 end
 if amount and spell then
  amount=string.gsub(amount,",","")
  L.NoteHit(spell,amount,crit and true or false,nil,IconOf(spell))
  RememberBlow(victim,spell,nil,IconOf(spell))
  return
 end
 -- DoT / periodic: "X suffers N ... damage from your Spell" (+ optional Critical).
 -- Without "(Critical)" the line does not say the tick was NOT a crit: the Reborn
 -- shim has no periodic crit wording at all, so it is recorded as unclassified.
 local periState=nil;if periCrit then periState=true end
 _,_,victim,amount,spell=string.find(msg,"^(.+) suffers ([%d,]+) .-damage from your (.+)$")
 if amount and spell then
  amount=string.gsub(amount,",","")
  spell=string.gsub(spell," %(Critical%)$","")
  spell=string.gsub(spell,"%.$","")
  L.NoteHit(spell,amount,periState,nil,IconOf(spell))
  RememberBlow(victim,spell,nil,IconOf(spell))
  return
 end
 -- Pet / summon DoT: "X suffers N ... damage from Pet's Spell"
 _,_,victim,amount,owner,spell=string.find(msg,"^(.+) suffers ([%d,]+) .-damage from (.+)'s (.+)$")
 if amount and owner and spell then
  spell=string.gsub(spell," %(Critical%)$","")
  spell=string.gsub(spell,"%.$","")
  local labeled=Attribute(owner,spell)
  if labeled then
   amount=string.gsub(amount,",","")
   L.NoteHit(labeled,amount,periState,nil,IconOf(spell) or IconOf(labeled))
   RememberBlow(victim,labeled,nil,IconOf(spell) or IconOf(labeled))
  end
  return
 end
 -- Pet / summon spell: "Imp's Firebolt hits/crits X for N"
 _,_,owner,spell,victim,amount=string.find(msg,"^(.+)'s (.+) crits (.+) for ([%d,]+)")
 if amount then crit=true
 else
  _,_,owner,spell,victim,amount=string.find(msg,"^(.+)'s (.+) hits (.+) for ([%d,]+)")
 end
 if amount and owner and spell then
  local labeled=Attribute(owner,spell)
  if labeled then
   amount=string.gsub(amount,",","")
   L.NoteHit(labeled,amount,crit and true or false,nil,IconOf(spell) or IconOf(labeled))
   RememberBlow(victim,labeled,nil,IconOf(spell) or IconOf(labeled))
  end
  return
 end
 -- Pet melee: "Wolf hits/crits X for N"
 _,_,owner,victim,amount=string.find(msg,"^(.+) crits (.+) for ([%d,]+)")
 if amount then crit=true
 else
  _,_,owner,victim,amount=string.find(msg,"^(.+) hits (.+) for ([%d,]+)")
 end
 if amount and owner then
  local mine=IsMine(owner)
  if mine then
   amount=string.gsub(amount,",","")
   local labeled=mine..": Melee"
   L.NoteHit(labeled,amount,crit and true or false,nil,IconOf("Melee") or IconOf(labeled))
   RememberBlow(victim,labeled,nil,IconOf("Melee") or IconOf(labeled))
  end
  return
 end
 _,_,spell=string.find(msg,"^Your (.+) kills ")
 if spell then L.NoteKill(spell,nil,IconOf(spell));return end
end

function L.ParseDeath(msg)
 msg=Strip(msg)
 if msg=="" then return end
 local _,_,name=string.find(msg,"^(.+) dies%.?$")
 if not name then _,_,name=string.find(msg,"^You have slain (.+)!") end
 if name then
  name=string.gsub(name,"!$","")
  L.NoteDeath(name)
 end
end

local function Snapshot(metric,scope,period,groupBy,ownerId,healPerspective,view)
 if type(AZS_GetMeterSnapshot)~="function" or type(AZS_GetMeterContext)~="function" then return nil end
 local ok,ctx=pcall(AZS_GetMeterContext)
 if not ok or type(ctx)~="table" or type(ctx.runId)~="string" then return nil end
 local q={apiVersion=1,runId=ctx.runId,metric=metric,scope=scope or "self",period=period or "run",groupBy=groupBy or "source",windowSeconds=0}
 if view then q.windowSeconds=FieldKitMeterWindow.Seconds(view) end
 if metric=="healing" then q.healingPerspective=healPerspective or "received" end
 if ownerId then q.ownerId=ownerId;q.scope=scope or "owner" end
 if checkpoint then q.checkpointId=checkpoint end
 local ok2,snap,err=pcall(AZS_GetMeterSnapshot,q)
 if view and not FieldKitMeterWindow.Accept(view,ok2 and snap or nil,err) then return nil end
 if not ok2 or type(snap)~="table" then return nil end
 if snap.status~="ready" and snap.status~="ready_empty" then return nil end
 return snap
end

local function SortKey()
 local db=FieldKitRebornDB
 local key=db and db.meterSortKey or "dmg"
 if key~="name" and key~="kills" and key~="dmg" and key~="dps" and key~="share" then key="dmg" end
 return key,db and db.meterSortAsc and true or false
end

local function HiddenSet(view)
 local db=FieldKitRebornDB
 if type(db)~="table" or type(db.meterHiddenRows)~="table" then return nil end
 local set=db.meterHiddenRows[view]
 return type(set)=="table" and set or nil
end

function L.ToggleHide(view,name)
 if type(view)~="string" or type(name)~="string" or name=="" then return end
 if not FieldKitRebornDB then return end
 FieldKitRebornDB.meterHiddenRows=FieldKitRebornDB.meterHiddenRows or {}
 local set=FieldKitRebornDB.meterHiddenRows[view]
 if type(set)~="table" then set={};FieldKitRebornDB.meterHiddenRows[view]=set end
 if set[name] then set[name]=nil else set[name]=true end
end

function L.ClearHidden(view)
 if not FieldKitRebornDB or type(FieldKitRebornDB.meterHiddenRows)~="table" then return end
 if view then FieldKitRebornDB.meterHiddenRows[view]=nil
 else FieldKitRebornDB.meterHiddenRows={} end
end

local function SortLines(out)
 local key,asc=SortKey()
 table.sort(out,function(a,b)
  local av,bv
  if key=="name" then av=a.name or "";bv=b.name or "";if av==bv then return false end;if asc then return av<bv end;return av>bv end
  if key=="kills" then av=a.kills or 0;bv=b.kills or 0
  elseif key=="dps" then av=a.dps or 0;bv=b.dps or 0
  elseif key=="share" then av=a.share or 0;bv=b.share or 0
  else av=a.dmg or 0;bv=b.dmg or 0 end
  if av==bv then return (a.name or "")<(b.name or "") end
  if asc then return av<bv end
  return av>bv
 end)
end

local function FinishLines(view,out,total,rate,known,truncated)
 local hidden=HiddenSet(view)
 local shown={}
 if hidden then
  for i=1,table.getn(out) do
   local line=out[i]
   if not (line.name and hidden[line.name]) then table.insert(shown,line) end
  end
 else shown=out end
 for _,line in ipairs(shown) do
  -- Owner rows are player names; source rows are spell/item/creature labels.
  if not FieldKit.rebornLegacyFixture and not (view=="party" and not line.sourceKey and line.ownerId) then
   line.displayName=FieldKitReborn.DisplayName(line.displayName or line.name,line.displaySpellId or line.spellId)
  end
 end
 SortLines(shown)
 return shown,total,rate,known,truncated
end

-- Native meters key each rank separately (ability:foo:r39). abilityKey / talentKey /
-- itemKey join ranks; fall back to stripping :rN[:pulse] from the sourceKey.
local function SourceFamily(src,sourceKey)
 if type(src)=="table" then
  if type(src.abilityKey)=="string" and src.abilityKey~="" then return "ability:"..src.abilityKey end
  if type(src.talentKey)=="string" and src.talentKey~="" then return "talent:"..src.talentKey end
  if type(src.itemKey)=="string" and src.itemKey~="" then return "item:"..src.itemKey end
 end
 if type(sourceKey)~="string" or sourceKey=="" then return sourceKey end
 local fam=string.gsub(sourceKey,":r%d+","")
 fam=string.gsub(fam,":pulse$","")
 fam=string.gsub(fam,":empowered$","")
 return fam
end

local function SourceIcon(src)
 if type(src)~="table" or type(src.icon)~="table" then return nil end
 if src.icon.status=="ready" and type(src.icon.path)=="string" then return src.icon.path end
 return nil
end

local function RowsFromSnap(snap,seconds)
 local out,total={},0
 if type(snap)~="table" then return out,0,nil,false end
 local sources=type(snap.sources)=="table" and snap.sources or {}
 local actors=type(snap.actors)=="table" and snap.actors or {}
 local rows=snap.rows
 if type(rows)~="table" then return out,0,nil,true end
 local nRows=table.getn(rows)
 local merged,order={},{}
 for i=1,math.min(512,nRows) do
  local row=rows[i]
  if type(row)=="table" then
   local amount=Num(seconds and seconds>0 and row.windowAmount or (row.displayAmount or row.periodAmount),0) or 0
   local src=row.sourceKey and sources[row.sourceKey] or nil
   local name
   if type(src)=="table" then name=Text(src.name,120) end
   if not name and row.sourceKey then name=FieldKit_L("Unidentified source") end
   if not name and row.ownerId and actors[row.ownerId] then name=Text(actors[row.ownerId].name,120) end
   if not name then name=Text(row.sourceKey or row.ownerId,120) or "?" end
   name=SpellBase(name) or name
   local rate=row.displayRate and Num(row.displayRate.value,0) or nil
   local proc=(row.nativeProc or row.procClassification=="proc") and 1 or 0
   local fam=SourceFamily(src,row.sourceKey) or row.ownerId or ("row:"..tostring(i))
   -- Keep proc / non-proc as separate meter rows (blue proc bars), merge ranks only.
   local bucket=fam.."#"..(proc==1 and "p" or "n")
   local line=merged[bucket]
   if not line then
    line={name=name,dmg=0,dps=0,dpsKnown=false,share=nil,proc=proc,sourceKey=row.sourceKey,ownerId=row.ownerId,icon=SourceIcon(src) or IconOf(name),spellId=nil,windowSeconds=seconds}
    merged[bucket]=line;table.insert(order,bucket)
   end
   line.dmg=line.dmg+amount
   if rate then line.dps=(line.dps or 0)+rate;line.dpsKnown=true end
   if amount>=(line._top or 0) then
    line._top=amount;line.name=name;line.sourceKey=row.sourceKey;line.ownerId=row.ownerId
    line.displaySpellId=type(src)=="table" and type(src.spellIds)=="table" and src.spellIds[1] or nil
     line.spellId=line.displaySpellId
    local ic=SourceIcon(src);if ic then line.icon=ic end
   end
   if proc==1 then line.proc=1 end
   total=total+amount
  end
 end
 for i=1,table.getn(order) do
  local line=merged[order[i]]
  if not line.dpsKnown then line.dps=nil else line.dps=line.dps end
  line._top=nil
  table.insert(out,line)
 end
 if type(snap.totals)=="table" then
  local t=Num(seconds and seconds>0 and snap.totals.windowAmount or (snap.totals.displayAmount or snap.totals.periodAmount),0)
  if t then total=t end
 end
 for i=1,table.getn(out) do if total and total>0 then out[i].share=out[i].dmg/total end end
 table.sort(out,function(a,b) return (a.dmg or 0)>(b.dmg or 0) end)
 return out,total,snap.totals and snap.totals.displayRate and Num(snap.totals.displayRate.value,0) or nil,true,nRows>512
end

local function AttachKillStats(lines)
 for i=1,table.getn(lines) do
  local line=lines[i]
  if type(line)=="table" and type(line.name)=="string" then
   local icon=line.icon or IconOf(line.name)
   line.icon=icon
   local st=not (line.windowSeconds and line.windowSeconds>0) and L.Stats(line.name,line.spellId,icon) or nil
   if st then
    line.kills=st.kills or 0
    line.hits=st.hits;line.crits=st.crits;line.critPct=st.critPct;line.critKnown=st.critKnown
    line.maxHit=st.maxHit;line.maxCrit=st.maxCrit;line.avg=st.avg;line.burst=st.burst
   else
    line.kills=line.kills or 0
   end
  end
 end
 return lines
end

local function RunSeconds()
 local t=type(AZS_GetRunTime)=="function" and tonumber(AZS_GetRunTime()) or nil
 if not t or t<1 then
  t=type(AZS_RUN)=="table" and tonumber(AZS_RUN.t) or nil
 end
 if not t or t<1 then t=1 end
 return t
end

function L.Read(view)
 L.Boundary()
 view=view or "damage"
 FieldKitMeterWindow.states[view]=nil
 local healPersp=(FieldKitRebornDB and FieldKitRebornDB.meterHealDone) and "performed" or "received"
 if view=="healing" and not FieldKit.rebornLegacyFixture and not FieldKitReborn.SupportsHealing(healPersp) then
  return {},nil,nil,false,false
 end
 if view=="kills" then
  local out,total={},0
  local localized={};local snap=Snapshot("damage","self","run","source");if snap then local native=RowsFromSnap(snap);for _,row in ipairs(native) do if row.icon then if localized[row.icon] and localized[row.icon]~=row.name then localized[row.icon]=false else localized[row.icon]=row.name end end end end
  for name,count in pairs(kills) do
   table.insert(out,{name=name,displayName=localized[IconOf(name)] or FieldKit_L(name),dmg=count,dps=nil,share=nil,proc=0,kills=count,icon=IconOf(name)})
   total=total+count
  end
  for i=1,table.getn(out) do if total>0 then out[i].share=out[i].dmg/total end end
  return FinishLines(view,out,total,nil,true,false)
 end
 if view=="taken" then
  if type(AZS_TAKEN)~="table" then return {},nil,nil,false,false end
  local out,sum={},0
  local t=RunSeconds()
  for i=1,math.min(32,table.getn(AZS_TAKEN)) do
   local row=AZS_TAKEN[i]
   if type(row)=="table" then
    local src=row.source or row[1];local dmg=Num(row.dmg or row[2],0)
    if type(src)=="string" and dmg then
     -- Same as AZS Spell Meter: per-source DPS = amount / run clock.
     table.insert(out,{name=TAKEN_NAMES[src] or Text(src,80) or src,displayName=FieldKit_L(TAKEN_NAMES[src] or Text(src,80) or src),dmg=dmg,dps=dmg/t,source=src,share=nil,icon=not FieldKit.rebornLegacyFixture and FieldKitReborn.EnemyIcon(src,row) or nil})
     sum=sum+dmg
    end
   end
  end
  for i=1,table.getn(out) do if sum>0 then out[i].share=out[i].dmg/sum end end
  return FinishLines(view,out,sum,sum>0 and (sum/t) or 0,true,false)
 end
 if view=="party" then
  local ownerId=FieldKitRebornDB and FieldKitRebornDB.meterPartyOwner
  if type(ownerId)=="string" and ownerId~="" then
   local snap=Snapshot("damage","owner","run","source",ownerId)
   if snap then
    local lines,total,rate,known,truncated=RowsFromSnap(snap)
    return FinishLines(view,AttachKillStats(lines),total,rate,known,truncated)
   end
   return FinishLines(view,{},nil,nil,false,false)
  end
  local snap=Snapshot("damage","party","run","owner")
  if snap then
   local lines,total,rate,known,truncated=RowsFromSnap(snap)
   -- ownerId stays on its row through sorting; native order is not rank order.
   return FinishLines(view,lines,total,rate,known,truncated)
  end
  if type(AZS_GetPartyMeter)=="function" then
   local ok,lines,total,dps=pcall(AZS_GetPartyMeter)
   if ok and type(lines)=="table" then
    local out={}
    for i=1,math.min(16,table.getn(lines)) do
     local row=lines[i]
     if type(row)=="table" and type(row.name)=="string" then
      table.insert(out,{name=Text(row.name,80),dmg=Num(row.dmg,0),dps=Num(row.dps,0),share=Num(row.share,0,1),proc=0,ownerId=row.ownerId or row.id})
     end
    end
    return FinishLines(view,out,Num(total,0),Num(dps,0),true,false)
   end
  end
  return {},nil,nil,false,false
 end
 local metric=view=="healing" and "healing" or "damage"
 local period=view=="boss" and "encounter" or "run"
 local snap=Snapshot(metric,"self",period,"source",nil,view=="healing" and healPersp or nil,view)
 if snap then
  local lines,total,rate,known,truncated=RowsFromSnap(snap,FieldKitMeterWindow.Seconds(view))
  return FinishLines(view,AttachKillStats(lines),total,rate,known,truncated)
 end
 -- A cumulative getter cannot substitute for a requested recent window.
 if FieldKitMeterWindow.Seconds(view)>0 then return {},nil,nil,false,false end
 -- Legacy getters (same 512-row bound as the previous FieldKitMeters.Read).
 local map={damage="AZS_GetMeter",healing="AZS_GetHealing",boss="AZS_GetBossMeter"}
 local fn=getglobal(map[view] or "AZS_GetMeter")
 if type(fn)~="function" then return {},nil,nil,false,false end
 local ok,lines,total,rate=pcall(fn)
 if not ok or type(lines)~="table" then return {},nil,nil,false,false end
 local out={}
 local nLines=table.getn(lines)
 for i=1,math.min(512,nLines) do
  local row=lines[i]
  if type(row)=="table" and type(row.name)=="string" then
   table.insert(out,{name=Text(row.name,120) or FieldKit_L("Unidentified source"),dmg=Num(row.dmg,0),dps=Num(row.dps,0),share=Num(row.share,0,1),proc=row.proc==1 and 1 or 0,icon=row.icon})
  end
 end
 return FinishLines(view,AttachKillStats(out),Num(total,0),Num(rate,0),true,nLines>512)
end

function L.AppendStats(name,spellId,icon,dmg,recent)
 if not FieldKitRebornDB or FieldKitRebornDB.meterSpellTips==false then return false end
 if type(name)=="string" then
  name=string.gsub(name,"^%d+%.%s*","")
  name=string.gsub(name,"%s*%(.*%)$","")
  name=string.gsub(name,"^%s+","")
  name=string.gsub(name,"%s+$","")
 end
 local st=not recent and L.Stats(name,spellId,icon) or nil
 if not st and not dmg then return false end
 GameTooltip:AddLine(" ")
 if dmg then GameTooltip:AddLine(FieldKit_L("Total")..": "..FieldKit.Exact(math.floor(dmg+.5)),1,1,1) end
 if st then
  if st.critKnown==false then
   -- Hits seen, crit flag never reported: unknown, not 0%.
   GameTooltip:AddLine(FieldKit_L("Hits")..": "..tostring(st.hits).."   "..FieldKit_L("Crit rate")..": -",.9,.9,.9)
   if st.maxUnclassified>0 then GameTooltip:AddLine(FieldKit_L("Max hit")..": "..FieldKit.Exact(st.maxUnclassified),.85,.85,.85) end
  else
   GameTooltip:AddLine(string.format(FieldKit_L("Hits: %d   Crits: %d (%.0f%%)"),st.hits,st.crits,st.critPct),.9,.9,.9)
  end
  if st.maxHit>0 then GameTooltip:AddLine(FieldKit_L("Max hit").." (non-crit): "..FieldKit.Exact(st.maxHit),.85,.85,.85) end
  if st.maxCrit>0 then GameTooltip:AddLine(FieldKit_L("Max crit")..": "..FieldKit.Exact(st.maxCrit),1,.55,.2) end
  if st.avg>0 then GameTooltip:AddLine(FieldKit_L("Average")..": "..FieldKit.Exact(math.floor(st.avg+.5)),.85,.85,.85) end
  if st.burst>0 then GameTooltip:AddLine(FieldKit_L("Burst (1s)")..": "..FieldKit.Exact(st.burst),.7,.85,1) end
  if st.kills>0 then GameTooltip:AddLine(FieldKit_L("Kills")..": "..FieldKit.Exact(st.kills),.9,.75,.4) end
 elseif not recent then
  GameTooltip:AddLine(FieldKit_L("No hit sample yet for this spell"),.6,.6,.6)
 end
 return true
end

function L.ShowTip(row)
 local name=row and (row.fieldkitSpell or (row.label and row.label:GetText()))
 if type(name)~="string" or name=="" then return false end
 name=string.gsub(name,"^%d+%.%s*","")
 GameTooltip:SetOwner(row,"ANCHOR_RIGHT")
 GameTooltip:SetText((row.fieldkitLine and row.fieldkitLine.displayName) or FieldKitReborn.DisplayName(name),1,.82,0)
 local line=row.fieldkitLine
 local dmg=line and line.dmg
 local icon=(line and line.icon) or IconOf(name)
 local spellId=line and line.spellId
 L.AppendStats(name,spellId,icon,dmg,line and line.windowSeconds and line.windowSeconds>0)
 FieldKitLocale.ShowTooltip()
 return true
end

-- Append Max Hit style lines onto native action / spell tooltips.
local function TipName()
 local fs=getglobal("GameTooltipTextLeft1")
 local t=fs and fs.GetText and fs:GetText()
 return type(t)=="string" and t~="" and t or nil
end

local function HookTooltipMethod(method)
 local orig=GameTooltip and GameTooltip[method]
 if type(orig)~="function" or GameTooltip["fieldkitHook_"..method] then return end
 GameTooltip["fieldkitHook_"..method]=true
 GameTooltip[method]=function(a1,a2,a3,a4,a5,a6)
  orig(a1,a2,a3,a4,a5,a6)
  if not FieldKitRebornDB or FieldKitRebornDB.meterSpellTips==false then return end
  local icon,spellId
  if method=="SetAction" and type(GetActionTexture)=="function" and a2 then
   local ok,tex=pcall(GetActionTexture,a2);if ok then icon=tex end
  end
  if L.AppendStats(TipName(),spellId,icon,nil) then FieldKitLocale.ShowTooltip() end
 end
end

local tipHooks=CreateFrame("Frame","FieldKitMeterTipHooks")
tipHooks:RegisterEvent("PLAYER_LOGIN")
tipHooks:RegisterEvent("ADDON_LOADED")
tipHooks:SetScript("OnEvent",function()
 if event=="ADDON_LOADED" and arg1 and arg1~="AzerothFieldKitReborn" then return end
 HookTooltipMethod("SetAction");HookTooltipMethod("SetSpell");HookTooltipMethod("SetTalent")
end)

-- One hit source at a time (no merge, no double count):
--  * AZS_GetCombatTextEvents present: it counts hits/crits and last blows; chat
--    damage and death lines are ignored. Kills come from lethal feed hits (see the
--    kill attribution note at the top). A death line only drains the feed early
--    (CombatText.lua sees each hit before Shims.lua writes its chat line) so the
--    kill shows without waiting for the next poll; it never credits by name.
--  * Feed absent (legacy clients): the chat lines count, as before, including the
--    name-based last-blow credit (documented limit: same-name enemies, co-op).
local driver=CreateFrame("Frame","FieldKitMeterLedgerDriver")
local elapsed=0
driver:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
driver:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
driver:RegisterEvent("CHAT_MSG_SPELL_PET_DAMAGE")
driver:RegisterEvent("CHAT_MSG_COMBAT_PET_HITS")
driver:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
driver:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE")
driver:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
driver:RegisterEvent("CHAT_MSG_COMBAT_HOSTILEPLAYER_DEATH")
driver:SetScript("OnEvent",function()
 if not FieldKitRebornDB or not FieldKitRebornDB.meterFrame then return end
 local feed=L.FeedAvailable()
 if event=="CHAT_MSG_COMBAT_HOSTILE_DEATH" or event=="CHAT_MSG_COMBAT_HOSTILEPLAYER_DEATH" then
  if feed then L.PollCombatText(true) else L.ParseDeath(arg1) end
  return
 end
 if not feed then L.ParseChat(arg1) end
end)
driver:SetScript("OnUpdate",function()
 if not FieldKitRebornDB or not FieldKitRebornDB.meterFrame then return end
 elapsed=elapsed+(arg1 or 0)
 if elapsed<.1 then return end;elapsed=0
 L.Boundary()
 if L.FeedAvailable() then L.PollCombatText(true) end
end)
