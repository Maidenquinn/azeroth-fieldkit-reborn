-- Read-only original/Reborn rank compatibility. Reborn's native run UI reads
-- dt as its difficulty tier. Missing data is never assumed to mean Normal.
local ranks={"I","II","III","IV","V"}
local function ValidRank(value)
 local n=FieldKit.Number(value)
 if n and n==math.floor(n) and n>=0 and n<=5 then return n end
end
local function WorldLabel()
 if type(GetRealZoneText)=="function" then
  local ok,text=pcall(GetRealZoneText)
  if ok and type(text)=="string" and text~="" and string.len(text)<=160 then return text end
 end
end
function FieldKit.GetHeroicLevel()
 if type(AZS_GetPhase)~="function" or not AZS_GetPhase() or type(AZS_ZONE)~="table" then return nil end
 local level=ValidRank(AZS_ZONE.heroic)
 if FieldKit.rebornLegacyFixture then return level end
 -- Reborn's native Run.lua/Tracker.lua also expose the difficulty tier as dt.
 if level==nil then level=ValidRank(AZS_ZONE.dt) end
 local db=FieldKitRebornDB;local phase=AZS_GetPhase();local time=type(AZS_RUN)=="table" and FieldKit.Number(AZS_RUN.t,nil,0)
 local world=WorldLabel()
 if level~=nil then
  if db and world and time and type(AZS_ZONE.zone)=="string" and AZS_ZONE.zone~="" then
   db.runDifficultyContext={rank=level,world=world,zone=AZS_ZONE.zone,time=time}
  end
  return level
 end
 -- /reload can replay RUN without ZONE. Reuse only observed presentation data
 -- for this same world and a clock that did not restart. Never default to Normal.
 local c=db and db.runDifficultyContext
 if type(c)=="table" and ValidRank(c.rank) and world==c.world and time and FieldKit.Number(c.time,nil,0) and time>=c.time-1
  and (phase=="playing" or phase=="paused" or phase=="choosing" or phase=="dead" or phase=="victory")
  and (not AZS_ZONE.zone or AZS_ZONE.zone==c.zone) then c.time=time;return c.rank end
 if db then db.runDifficultyContext=nil end
end
function FieldKit.GetHeroicLabel()
 local level=FieldKit.GetHeroicLevel()
 if level==nil then return nil end
 if level==0 then return FieldKit_L("Normal difficulty") end
 return FieldKit_L("Heroic").." "..(ranks[level] or tostring(level))
end

-- Keep targetable mechanics readable when the optional ordinary-mob filter is
-- active. These exact EN/FR client names do not trigger targeting or combat.
function FieldKit.IsCriticalObjective(name)
 return name=="Explosive Orb" or name=="Orbe explosif"
end

-- New star bonuses can be smaller than 1%. Keep tenths, omit a trailing .0,
-- and avoid displaying a negative zero after rounding a very small value.
function FieldKit.FormatPercent(value,signed)
 local percent=FieldKit.Number(value,0)*100
 if math.abs(percent)<.05 then percent=0 end
 local text=string.format(signed and "%+.1f%%" or "%.1f%%",percent)
 return (string.gsub(text,"%.0%%$","%%"))
end
function FieldKit.FormatBonus(value)
 local amount=FieldKit.Number(value,0)
 if math.abs(amount)<.05 then amount=0 end
 return (string.gsub(string.format("%.1f",amount),"%.0$",""))
end
