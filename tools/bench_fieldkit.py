"""Synthetic Lua-side cost benchmark (mock client, PUC Lua 5.1 via lupa).

Measures FieldKit's own work only: native snapshot construction and client
rendering are NOT included. Times are host-CPU dependent; compare scenarios
relative to each other, never as in-game frame times. Read-only, no game files.
Usage: python tools/bench_fieldkit.py
"""
from pathlib import Path
import json, sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
__file__ = str(Path(__file__).resolve().parent / 'test_reborn.py')
exec(Path(__file__).read_text(encoding='utf8').split('def native_locale')[0])

BENCH = r'''
fire(FieldKitFrame,"VARIABLES_LOADED")
FieldKitRebornDB.meterFrame=true
local L=FieldKitMeterLedger
local clock=os.clock
local function snap(n)
 local rows,sources={},{}
 for i=1,n do
  local key="ability:spell"..i..":r"..(i%40+1)
  sources[key]={name="Spell "..i,abilityKey="spell"..i,spellIds={1000+i},icon={status="ready",path="Interface\\Icons\\X"..i}}
  rows[i]={sourceKey=key,displayAmount=1e9-i,displayRate={value=1e6-i}}
 end
 return {status="ready",rows=rows,sources=sources,totals={displayAmount=5e11,displayRate={value=1e8}}}
end
local result={}
for _,n in ipairs({20,120,512}) do
 local s=snap(n)
 AZS_GetMeterContext=function() return {runId="r1"} end
 AZS_GetMeterSnapshot=function() return s end
 for i=1,n do L.NoteHit("Spell "..i,1000,false,1000+i) end
 collectgarbage("collect")
 local m0,t0=collectgarbage("count"),clock()
 local reads=200
 collectgarbage("stop")
 for i=1,reads do L.Read("damage") end
 local kb=(collectgarbage("count")-m0)/reads
 collectgarbage("restart")
 result["read_"..n]={msPerRead=1000*(clock()-t0)/reads,kbAllocatedPerRead=kb}
end
-- Combat feed: one poll draining 256..2048 events (dense AoE second).
local UnitGUIDOld=UnitGUID;UnitGUID=function() return "P" end
for _,n in ipairs({256,1024,2048}) do
 local events={}
 for i=1,n do events[i]={seq=i,kind="damage",amount=700,critical=(i%4==0),periodic=true,spellId=26573,abilityName="Consecration",sourceGuid="P",targetName="Mob"..(i%60)} end
 local page=0
 AZS_GetCombatTextEvents=function(cur)
  local from=page*256+1;local out={}
  for i=from,math.min(n,from+255) do out[table.getn(out)+1]=events[i] end
  page=page+1
  return {cursor="ct:"..(from+255),events=out,hasMore=from+255<n},nil
 end
 L.ClearHits();collectgarbage("collect")
 local m0,t0=collectgarbage("count"),clock()
 collectgarbage("stop")
 local reps=20
 for r=1,reps do page=0;L.PollCombatText(true) end
 local kb=(collectgarbage("count")-m0)/reps
 collectgarbage("restart")
 result["feed_"..n]={msPerPoll=1000*(clock()-t0)/reps,kbAllocatedPerPoll=kb,hitsCounted=L.Stats("Consecration").hits}
end
UnitGUID=UnitGUIDOld
BENCH_RESULT=result
'''


def main():
    l = runtime()
    l.execute(BENCH)
    res = l.globals().BENCH_RESULT
    out = {}
    for k in res:
        out[k] = {kk: round(float(vv), 4) for kk, vv in res[k].items()}
    print(json.dumps(dict(sorted(out.items())), indent=1))


if __name__ == '__main__':
    main()
