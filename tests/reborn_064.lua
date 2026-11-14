fire(FieldKitFrame,"VARIABLES_LOADED")
local L,W,C,R,d=FieldKitMeterLedger,FieldKitMeterWindow,FieldKitZoneThemes,FieldKitReferenceHUD,FieldKitRebornDB
AZS_ZONE={zone="zangarmarsh",heroic=0};AZS_RUN={ph="playing",t=140,hp=100,hpm=100}
AZS_STATS={dmg=1.5,cd=.8,crit=.3,dots=1.25,doth=.15,dotd=.2,gdmg=.25,gcrit=.1,gcd=-.05,ghp=40}
AZS_GEAR={{slot="amulet",name="Native amulet",icon="INV_Jewelry_Necklace_01",text="+25% damage · +10% crit · +5% haste",amount=3}}
local state="ready";local selected;local reads=0
AZS_GetMeterContext=function() return {runId="r064",localOwnerId="hero:Tester"} end
AZS_GetMeterCapabilities=function() return {features={nativeRecentWindows=true,atomicCheckpoints=true},healingPerspectives={"performed"}} end
AZS_GetMeterSnapshot=function(q)
 selected=q
 if state=="error" then return nil,{code="UNSUPPORTED_QUERY"} end
 local recent=q.windowSeconds>0;local healing=q.metric=="healing"
 local value=healing and 45 or 150;local lifetime=healing and 450 or 1500
 local rate={status=recent and state or "ready",value=recent and 10 or 100,approximate=true,reason=state=="unavailable" and "history_not_retained" or nil}
 return {status="ready",totals={displayAmount=lifetime,periodAmount=lifetime,windowAmount=value,recentRate=rate,displayRate=rate},
  sources={a={name="Fire",abilityKey="fire"},b={name="Frost",abilityKey="frost"}},
  rows={{sourceKey="a",displayAmount=lifetime*.6,windowAmount=value*.6,displayRate={status="ready",value=6}},
        {sourceKey="b",displayAmount=lifetime*.4,windowAmount=value*.4,displayRate={status="ready",value=4}}}}
end
AZS_GetMeter=function() reads=reads+1;return {{name="Cumulative fallback",dmg=9999}},9999,99 end
AZS_GetHealing=AZS_GetMeter
SlashCmdList.FieldKit("")
local function option(label)
 for _,s in ipairs(FieldKitUI.sections) do for _,i in ipairs(s.items) do if i.label==label then return i end end end
 error(label)
end
local recentOption,secondsOption=option("Recent damage and healing"),option("Recent window")
d.meterRecent=true
for seconds=5,120 do
 d.meterWindowSeconds=seconds
 local rows,total,rate,known=L.Read("damage")
 assert(known and selected.windowSeconds==seconds and total==150 and rate==10)
 assert(rows[1].dmg==90 and rows[2].dmg==60 and rows[1].share==.6 and rows[1].windowSeconds==seconds)
 assert(rows[1].hits==nil and rows[1].maxCrit==nil,"Run hit statistics leaked into recent view")
end
local gear=FieldKitReborn.Gear();assert(#gear[2].bonuses==3)
assert(string.find(gear[2].bonuses[1],"25%%") and string.find(gear[2].bonuses[3],"5%%"))
assert(FieldKitRebornStats.DotValue(1.25)=="1.25" and FieldKitRebornStats.DotValue(.125)=="0.125" and FieldKitRebornStats.DotValue(nil)=="?")
local lines=FieldKitRebornStats.Lines("dmg");assert(#lines==1 and string.find(lines[1],"+25%%"))
lines=FieldKitRebornStats.Lines("haste");assert(string.find(lines[1],"Cooldown") and string.find(lines[1],"%-5%%"))
AZS_STATS.gdots=.125;assert(string.find(FieldKitRebornStats.Lines("dots")[1],"+0.125",1,true))
AZS_STATS.gcrit=nil;assert(#FieldKitRebornStats.Lines("crit")==0,"Missing contribution invented")
d.shownStats={dmg=true,haste=true,crit=true,dots=true,doth=true,dotd=true}
arg2="";fire(FieldKitFrame,"CHAT_MSG_ADDON","AZS")
local dots
for _,r in ipairs(FieldKitStatsFrame.rows) do if r.statKey=="dots" and r.label:IsShown() then dots=r end end
assert(dots and dots.value:GetText()=="1.25")
local captured={};local oldAdd=GameTooltip.AddLine
GameTooltip.AddLine=function(_,text) table.insert(captured,text) end
local function hover(frame)
 captured={};this=frame;frame:GetScript("OnEnter")();this=nil
 return table.concat(captured,"\n")
end
FieldKitMeterSuite.SetDetached("damage",false);FieldKitMeterSuite.SetDetached("healing",false)
for _,theme in ipairs({"elwynn","naxx"}) do
 for _,variant in ipairs({"off","minimal","complete","alternative"}) do
  C.Set("zoneThemes",false);d.zoneThemeMode=theme;d.zoneThemeVariant=variant=="off" and "complete" or variant
  d.statsCollapsed=false;d.gearCollapsed=false;d.meterHealDone=true
  if variant~="off" then C.Set("zoneThemes",true) end
  for _,seconds in ipairs({5,120}) do
   secondsOption.set(seconds);recentOption.set(true)
   for _,view in ipairs({"damage","healing"}) do
    FieldKitMeterSuite.SetView(view);state="ready";FieldKitMeterSuite.Update(true);C.Refresh(true)
    local _,total,rate,known=L.Read(view);assert(known and total==(view=="healing" and 45 or 150) and rate==10)
    FieldKitMeterSuite.SetDetached(view,true)
    local extra=getglobal("FieldKitMeterExtra_"..view)
    assert(extra:IsShown() and string.find(extra.title:GetText(),tostring(seconds).."s"))
    FieldKitMeterSuite.SetDetached(view,false);FieldKitMeterSuite.Update(true);C.Refresh(true)
    if variant=="off" or not R.layout.rects.Damage then
     if variant~="off" and not C.open.Damage then C.Open("Damage") end
     assert(string.find(FieldKitMeterFrame.title:GetText(),tostring(seconds).."s"))
    else
     local f=R.frames.Damage
     assert(f:IsShown() and string.find(f.title.referenceFullText or f.title:GetText(),tostring(seconds).."s"),theme..variant)
     assert(f.rows[1].fieldkitLine and f.rows[1].fieldkitLine.windowSeconds==seconds)
    end
    if variant=="off" or not R.layout.rects.Stats then
     if variant~="off" and not C.open.Stats then C.Open("Stats") end
     assert(string.find(hover(FieldKitStatsFrame),"From worn jewelry"))
     if variant~="off" and not R.layout.rects.Damage then C.Open("Damage") end
    else
     local statRow
     for _,r in ipairs(R.frames.Stats.rows) do if r:IsShown() and r.statKey=="dmg" then statRow=r end end
     assert(statRow and string.find(hover(statRow),"+25%%"),"Themed jewelry tooltip disconnected")
    end
    local D=FieldKitPartyDetails
    D.Build();D.data=D.Data(UnitName("player"),view=="healing" and 2 or 1);D.Render()
    assert(D.data.windowSeconds==seconds and D.data.damage==(view=="healing" and 45 or 150))
    assert(string.find(D.summary:GetText(),string.format(FieldKit_L("Last %ds"),seconds)))
    assert(not D.frame.rows[1].hitColumns[1]:IsShown(),"Modal mixed recent amount with full-run hit samples")
    for _,bad in ipairs({"warming_up","unavailable","error"}) do
     state=bad;local _,amount,_,available=L.Read(view)
     assert(not available and amount==nil and reads==0,"Recent view fell back to lifetime totals")
     FieldKitMeterSuite.Update(true);C.Refresh(true)
     local expected=bad=="warming_up" and "Building recent history" or "Recent history unavailable"
     local text=(variant=="off" or not R.layout.rects.Damage) and FieldKitMeterFrame.rows[1].label:GetText() or R.frames.Damage.rows[1].label:GetText()
     assert(text==expected,text.." / "..expected)
     D.data=D.Data(UnitName("player"),view=="healing" and 2 or 1);D.Render()
     assert(D.data.unavailable and D.data.windowSeconds==seconds and D.hint:GetText()==expected,"Modal history state disconnected")
    end
    state="ready"
   end
  end
  recentOption.set(false);L.Read("damage");assert(selected.windowSeconds==0)
 end
end
-- Explicit zero is known; malformed recent amounts cannot become lifetime amounts.
d.meterRecent=true;d.meterWindowSeconds=5
local zero={status="ready_empty",rows={},totals={windowAmount=0,recentRate={status="ready",value=0}}}
assert(W.Accept("damage",zero) and W.Empty("damage","No data yet")==FieldKit_L("No data yet"))
zero.rows={{displayAmount=500}};assert(not W.Accept("damage",zero))
d.language="fr";assert(W.Caption("damage")=="5 dernières secondes")
state="unavailable";L.Read("damage");assert(W.Empty("damage","No data yet")=="Historique récent indisponible")
d.language="en";state="ready"
GameTooltip.AddLine=oldAdd
local p=FieldKitProfiles
W.Set(true,17);assert(p.Save(1));W.Set(false,120);assert(p.Save(2));assert(p.Load(1))
assert(d.meterRecent and d.meterWindowSeconds==17)
assert(p.Load(2));assert(not d.meterRecent and d.meterWindowSeconds==120)
print("PASS 0.6.4 windows 5..120, amount/rate/share consistency, no cumulative fallback, both theme families x 4 variants, detached views, jewelry/DoT tooltips and profile isolation")
