-- Runtime boundary: validate data and centralize the few native setting writes.
-- This module runs first. It performs no I/O, networking or native writes at load.
-- FieldKit is an addon-owned namespace; AZS_* tables remain owned by the client.
FieldKit = { version = "0.1.0-reborn.41", folder = "AzerothFieldKitReborn" }

-- Native level-up/chest choices own the action controls during this phase.
-- Read the official phase; do not inspect or modify native screen frames.
function FieldKit.IsChoiceScreen()
 if type(AZS_GetPhase)~="function" then return false end
 local ok,phase=pcall(AZS_GetPhase)
 return ok and phase=="choosing"
end

-- The only outbound capability: explicitly opted-in meter sharing, one fixed
-- addon prefix, PARTY distribution, printable 230-byte packets, max 4 per second.
-- A successful call means queued by the API, never proof of peer delivery.
function FieldKit.PartyTransportAvailable() return type(SendAddonMessage)=="function" end
function FieldKit.SendPartyDetail(payload)
 if not FieldKitRebornDB or not FieldKitRebornDB.partyDetailSync then return false,"disabled" end
 if type(AZS_GetPhase)~="function" or not AZS_GetPhase() then return false,"no run" end
 local peer=false;for i=1,4 do if UnitExists("party"..i) then peer=true end end
 if not peer then return false,"no party" end
 if not FieldKit.PartyTransportAvailable() then return false,"unavailable" end
 if type(payload)~="string" or string.len(payload)>230 or not string.find(payload,"^[QR]:") or string.find(payload,"[^ -~]") then return false,"invalid" end
 local now=FieldKit.Number(GetTime())
 if not now then return false,"clock" end
 if FieldKit.partyDetailSentAt and now-FieldKit.partyDetailSentAt<.25 then return false,"throttled" end
 FieldKit.partyDetailSentAt=now
 local ok=pcall(SendAddonMessage,"AFKRDETAIL1",payload,"PARTY")
 return ok,ok and "queued" or "api error"
end

-- Return a finite numeric value, optionally clamped. Strings are parsed as numbers,
-- never evaluated as Lua. A missing/invalid value returns the caller's fallback.
function FieldKit.Number(value, fallback, minimum, maximum)
 local n=tonumber(value)
 if not n or n~=n or n>1e18 or n< -1e18 then return fallback end
 if minimum then n=math.max(minimum,n) end
 if maximum then n=math.min(maximum,n) end
 return n
end
-- Native meters count in unsigned 128 bits. Keep them as finite Lua doubles;
-- do not widen the normal settings/geometry validator or convert to integers.
function FieldKit.MeterNumber(value,fallback,minimum,maximum)
 local n=tonumber(value)
 if not n or n~=n or math.abs(n)>3.5e38 then return fallback end
 if minimum then n=math.max(minimum,n) end
 if maximum then n=math.min(maximum,n) end
 return n
end

-- Display-only number formats (.41). Values are never changed, only written.
-- Tiers are the game's own (AzerothSurvivors/Core.lua AZS.Short: k..Dc, the same
-- letters in every language; native meter rows are 128-bit and pass 2^64 in long
-- endless runs). FieldKit keeps its approved style: exact and grouped below 10 000,
-- then one decimal and a spaced unit, with the language's decimal separator.
-- Ud (1e36) only keeps 2^128 (3.4e38) inside the column.
local TIERS={{1e36,"Ud"},{1e33,"Dc"},{1e30,"No"},{1e27,"Oc"},{1e24,"Sp"},{1e21,"Sx"},
 {1e18,"Qi"},{1e15,"Qa"},{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"k"}}
local function Separators()
 local language=type(FieldKit_Language)=="function" and FieldKit_Language() or "en"
 local spaced=language=="fr" or language=="pl" or language=="cs" or language=="ru" or language=="uk"
 local comma=spaced or language=="de" or language=="es" or language=="pt" or language=="ro" or language=="tr"
 return comma and "," or ".",spaced and " " or (comma and "." or ",")
end
local function Group(digits,group)
 local out=""
 while string.len(digits)>3 do
  out=group..string.sub(digits,-3)..out
  digits=string.sub(digits,1,-4)
 end
 return digits..out
end
-- nil, text, NaN or infinity -> "?": a missing value is never turned into a number.
function FieldKit.Compact(value)
 local n=type(value)=="number" and value or nil
 if not n or n-n~=0 then return "?" end -- NaN and both infinities (no math.huge in Lua 5.0)
 local dec,group=Separators()
 local a=math.abs(n);local sign=n<0 and "-" or ""
 if a<9999.5 then return sign..Group(string.format("%.0f",a),group) end
 for i=1,table.getn(TIERS) do
  -- A hair under a tier reads as that tier: 999 960 is "1.0 M", never "1000.0 k".
  if a>=TIERS[i][1]*0.99995 or i==table.getn(TIERS) then
   local text=string.format("%.1f",a/TIERS[i][1])
   return sign..string.gsub(text,"%.",dec).." "..TIERS[i][2]
  end
 end
end
-- The full value for tooltips: every digit, grouped. Above 2^53 a double no longer
-- holds every unit, so the value is marked approximate rather than shown as exact.
function FieldKit.Exact(value)
 local n=type(value)=="number" and value or nil
 if not n or n-n~=0 then return "?" end -- NaN and both infinities (no math.huge in Lua 5.0)
 local _,group=Separators()
 local a=math.abs(n);local text=Group(string.format("%.0f",a),group)
 if a>9007199254740992 then text="~"..text end
 return (n<0 and "-" or "")..text
end
-- Drop shadow for data text over coloured bars and spell effects (guarded: a custom
-- client without the method keeps the plain text).
function FieldKit.TextShadow(fs)
 if fs and fs.SetShadowOffset then fs:SetShadowOffset(1,-1);if fs.SetShadowColor then fs:SetShadowColor(0,0,0,1) end end
end
-- Status bars take a fraction: the client rejects unbounded native ranges ("Min or
-- Max out of range" on endless boss health, FieldKit.lua ShowBossFrame, 0.7.4), and
-- that uncaught error stopped the whole HUD loop (lairs, meter, map). The native
-- amounts stay untouched; bar.fieldkitFraction keeps the drawn fraction.
function FieldKit.SetBarFraction(bar,value,maximum)
 local v,m=tonumber(value),tonumber(maximum)
 local f=0
 if v and m and m>0 and v-v==0 and m-m==0 then f=v/m end
 if f~=f or f<0 then f=0 elseif f>1 then f=1 end
 bar:SetMinMaxValues(0,1);bar:SetValue(f);bar.fieldkitFraction=f
 return f
end

-- Catch missing CVars in custom clients. Reading an unknown CVar may throw.
function FieldKit.GetCVar(key)
 if type(GetCVar)~="function" then return nil end
 local ok,value=pcall(GetCVar,key)
 if ok then return value end
end

-- Only display CVars may be written. Camera range is clamped at its call site;
-- damage switches only accept 0/1. There is no arbitrary CVar slash command.
local displayCVars={cameraDistanceMaxFactor=true,CombatDamage=true,PetMeleeDamage=true,PetSpellDamage=true}
function FieldKit.SetCVar(key,value)
 if not displayCVars[key] or type(SetCVar)~="function" then return false end
 local n=FieldKit.Number(value)
 if not n then return false end
 if key=="cameraDistanceMaxFactor" then
  if n<1 or n>50/15+.001 then return false end
 elseif n~=0 and n~=1 then return false end
 return pcall(SetCVar,key,tostring(value))
end

-- Restrict native HUD changes to known visual replacement sections.
-- Callers must keep their corresponding DB.hud*Hidden flag for restoration.
-- localClock: AS 0.136+ under-minimap clock (for addons that draw their own).
function FieldKit.SetHudShown(part,shown)
 if part~="banners" and part~="build" and part~="bosses" and part~="tally" and part~="meter" and part~="localClock" and part~="clock" and part~="levels" then return false end
 if type(shown)~="boolean" or type(AZS_SetHudShown)~="function" then return false end
 return pcall(AZS_SetHudShown,part,shown)
end

-- Bound persisted name learning. At capacity retain old knowledge and ignore new
-- names; never evict a boss classification just because more enemies appeared.
function FieldKit.RememberClassification(cache,name,class)
 if type(cache)~="table" or type(name)~="string" or
  string.len(name)>160 then return end
 -- Existing entries are updated in O(1). A full count is only needed when
 -- inserting a previously unseen name; never evict older classifications.
 if cache[name]==nil then
  local count=0
  for _ in pairs(cache) do
   count=count+1
   if count>=2048 then return end
  end
 end
 cache[name]=class
end

-- Optional level-up/jewelry overlay registration, restricted to our own named
-- HUD. Never register UIParent, native frames, foreign addons or arbitrary names.
function FieldKit.SetFrameOnTop(name,enabled)
 if type(name)~="string" or type(enabled)~="boolean" then return false end
 if name~="FieldKitPartyDetailsFrame" and (not FieldKitCardLayout or not FieldKitCardLayout.ValidName(name)) then return false end
 if type(AZS_SetOnTopOfScreens)~="function" then return false end
 local ok,result=pcall(AZS_SetOnTopOfScreens,name,enabled)
 if not ok or result==false then return false end
 if type(AZS_IsOnTopOfScreens)=="function" then
  local read,value=pcall(AZS_IsOnTopOfScreens,name)
  return read and ((value and true or false)==enabled)
 end
 return true
end

function FieldKit.FrameOverlayAvailable() return type(AZS_SetOnTopOfScreens)=="function" end
