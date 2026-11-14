-- Read-only 0.6.4 meter-window presentation. No locally reconstructed totals.
FieldKitMeterWindow={states={}}
local W=FieldKitMeterWindow
function W.Seconds(view)
 local db=FieldKitRebornDB
 if not db or not db.meterRecent or (view~="damage" and view~="healing") then return 0 end
 return math.floor(FieldKit.Number(db.meterWindowSeconds,15,5,120))
end
function W.Set(recent,seconds)
 local db=FieldKitRebornDB;if not db then return end
 db.meterRecent=recent and true or false
 db.meterWindowSeconds=math.floor(FieldKit.Number(seconds,db.meterWindowSeconds or 15,5,120))
 W.states={}
 if FieldKitPartyDetails then FieldKitPartyDetails.Close() end
 if FieldKitMeterSuite then FieldKitMeterSuite.Update(true) end
 if FieldKitZoneThemes then FieldKitZoneThemes.Refresh(true) end
end
function W.Accept(view,snapshot,err)
 if W.Seconds(view)==0 then W.states[view]=nil;return true end
 local totals=type(snapshot)=="table" and snapshot.totals
 local rate=type(totals)=="table" and totals.recentRate
 local state={status="unavailable",reason=type(err)=="table" and err.code or nil}
 if type(rate)=="table" then
  state.status=rate.status;state.reason=rate.reason;state.approximate=rate.approximate
 end
 W.states[view]=state
 local valid=type(rate)=="table" and rate.status=="ready" and FieldKit.Number(rate.value)~=nil
  and FieldKit.Number(totals.windowAmount)~=nil and type(snapshot.rows)=="table"
 if valid then
  for i=1,math.min(512,table.getn(snapshot.rows)) do
   local row=snapshot.rows[i]
   if type(row)~="table" or FieldKit.Number(row.windowAmount)==nil then valid=false;break end
  end
 end
 if not valid and state.status=="ready" then state.status="unavailable" end
 return valid
end
function W.Caption(view)
 local seconds=W.Seconds(view)
 return seconds>0 and string.format(FieldKit_L("Last %ds"),seconds) or ""
end
function W.Title(view,title)
 local seconds=W.Seconds(view)
 return FieldKit_L(title)..(seconds>0 and (" · "..seconds.."s") or "")
end
function W.Empty(view,fallback)
 if W.Seconds(view)==0 then return FieldKit_L(fallback) end
 local s=W.states[view]
 if s and s.status=="ready" then return FieldKit_L(fallback) end
 return FieldKit_L(s and s.status=="warming_up" and "Building recent history" or "Recent history unavailable")
end
function W.Tip(view)
 if W.Seconds(view)==0 then return end
 GameTooltip:AddLine(W.Caption(view),1,.82,.3)
 local s=W.states[view]
 if s and s.approximate then GameTooltip:AddLine(FieldKit_L("Native rate approximated from one-second samples."),.8,.8,.8,true) end
 GameTooltip:AddLine(FieldKit_L("Recent history is rebuilt after reload. Hit and crit records cover the full run and are omitted here."),.7,.7,.7,true)
 GameTooltip:AddLine(FieldKit_L("Recent results start no earlier than the latest reset."),.7,.7,.7,true)
end
