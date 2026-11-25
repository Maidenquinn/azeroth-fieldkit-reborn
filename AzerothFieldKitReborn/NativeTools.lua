-- Passive, bounded views over exposed native state. All modules are optional;
-- no casting, targeting, level spending, native HUD hiding or external process.
FieldKitNativeTools={frames={},recent={},warnings={},lastBoss={},rows=9}
local T=FieldKitNativeTools
local N=FieldKitNative
local function Count(value) local n=FieldKit.Number(value,nil,0,10000);return n and math.floor(n) end
function T.Create(create,fit,move)
 T.fit=fit;T.move=move
 local defs={{"FieldKitEffectsFrame","Effects",-430,-110},{"FieldKitReviveFrame","Revive",0,160},
  {"FieldKitEncounterFrame","Run reminders",430,-180},{"FieldKitBossListFrame","Campaign bosses",-UIParent:GetWidth()/2+480,UIParent:GetHeight()/2-120}}
 for i,def in ipairs(defs) do
  local f=create(def[1],def[2],i==4 and 8 or (i==1 and T.rows or 3));T.frames[i]=f
  f:SetWidth(300);move(f,def[3],def[4],true);f:Hide()
 end
 local list=T.frames[4]
 list:SetWidth(320);list.bossListOffset=0
 list.note=list:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 list.note:SetPoint("BOTTOMLEFT",list,"BOTTOMLEFT",12,7);list.note:SetHeight(30);list.note:SetJustifyH("LEFT");FieldKitTheme.Font(list.note,11,FieldKitTheme.muted)
 if list.EnableMouseWheel then list:EnableMouseWheel(true) end
 list:SetScript("OnMouseWheel",function()
  local max=math.max(0,(list.bossListCount or 0)-table.getn(list.rows))
  list.bossListOffset=math.max(0,math.min(max,(list.bossListOffset or 0)-(arg1 or 0)))
  T.BossList()
 end)
 local collapse=getglobal("FieldKitBossListFrameCollapse")
 local onCollapse=collapse and collapse:GetScript("OnClick")
 if onCollapse then collapse:SetScript("OnClick",function() onCollapse();T.BossList() end) end
 for _,row in ipairs(list.rows) do
  row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetWidth(14);row.icon:SetHeight(14);row.icon:SetPoint("LEFT",row,"LEFT",0,0)
  row:SetScript("OnEnter",function()
   if list.azsMoving or not this.bossListEntry then return end
   local e=this.bossListEntry
   GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText(e.label,1,.85,.55);GameTooltip:AddLine(e.value,1,1,1,true)
   if e.unknown then GameTooltip:AddLine(FieldKit_L("Unknown"),.8,.8,.8,true) end
   if FieldKitReborn.IsEndless() then GameTooltip:AddLine(FieldKit_L("Endless: the game does not provide the upcoming boss sequence."),.7,.7,.7,true) end
   FieldKitLocale.ShowTooltip()
  end)
  row:SetScript("OnLeave",function() FieldKitLocale.HideTooltip() end)
 end
 for _,row in ipairs(T.frames[1].rows) do
  row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetWidth(14);row.icon:SetHeight(14)
  row.icon:SetPoint("LEFT",row,"LEFT",0,0)
  row:SetScript("OnEnter",function()
   if not this.nativeDetail or (T.frames[1] and T.frames[1].azsMoving) then return end
   GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText(this.nativeDetail,1,.85,.55)
   GameTooltip:AddLine(FieldKit_L("Native remaining time; grouped durations show the soonest expiration."),.8,.8,.8,true);FieldKitLocale.ShowTooltip()
  end)
  row:SetScript("OnLeave",function() FieldKitLocale.HideTooltip() end)
 end
 local warnings=CreateFrame("Frame","FieldKitNativeWarnings",UIParent);T.warningFrame=warnings
 warnings:SetWidth(440);warnings:SetHeight(108);move(warnings,0,240,true)
 FieldKitTheme.Surface(warnings,"card",true);FieldKitTheme.ReadableFloor(warnings);warnings.rows={}
 for i=1,3 do
  local row=FieldKitTheme.Label(warnings,nil,12,8+(i-1)*32,416,30,14,FieldKitTheme.gold)
  table.insert(warnings.rows,row)
 end
 warnings:SetScript("OnEnter",function()
  GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:SetText(FieldKit_L("Native warnings"),1,.85,.55)
  for _,data in ipairs(T.warnings) do GameTooltip:AddLine(data.text,.9,.9,.85,true) end
  FieldKitLocale.ShowTooltip()
 end)
 warnings:SetScript("OnLeave",function() FieldKitLocale.HideTooltip() end)
 warnings:Hide();N.Watch()
end
function T.ShowRows(frame,rows,total)
 frame.lastRows=rows -- real entries only; the themed panel reads these, not a hidden frame
 if table.getn(rows)==0 and not FieldKit.layoutEditing then frame:Hide();return end
 if table.getn(rows)==0 then rows={{label=FieldKit_L("Preview"),value="?"}} end
 FieldKit_Text(frame.total,total or "")
 -- Never resize while the player is dragging: FitRows during StartMoving drops OnDragStop on 1.12.
 local moving=frame.azsMoving and true or false
 if not moving then frame:SetWidth(FieldKitCardLayout.Width(frame,300)) end
 local count=math.min(table.getn(rows),table.getn(frame.rows))
 for i=1,count do
  local row,entry=frame.rows[i],rows[i]
  row.nativeDetail=entry.label;row.label:ClearAllPoints();row.value:ClearAllPoints()
  row.label:SetPoint("LEFT",row,"LEFT",entry.icon and 18 or 3,0)
  row.label:SetWidth(math.max(30,frame:GetWidth()-150));row.label:SetHeight(14)
  row.value:SetPoint("RIGHT",row,"RIGHT",-3,0);row.value:SetWidth(120);row.value:SetHeight(14);row.value:SetJustifyH("RIGHT")
  row.label:SetText(entry.label);row.value:SetText(entry.value or "?")
  row:SetValue(entry.fraction or 0);row:SetStatusBarColor(.25,.5,.65,.5)
  if row.icon then
   if entry.icon then row.icon:SetTexture(entry.icon);row.icon:Show() else row.icon:Hide() end
  end
  row:Show()
 end
 if not moving then T.fit(frame,count) end
 frame:Show()
end
-- Campaign order and states are native data, never inferred from spawn times.
function T.BossListRows()
 local out,defeated,nextSeen={},0,false
 if not N.Fresh("AZSBOSSES") then return out,defeated,false end
 local source=type(AZS_SCHEDULE)=="table" and AZS_SCHEDULE or {}
 local ordered={}
 for i=1,math.min(64,table.getn(source)) do local b=source[i]
  if type(b)=="table" and type(b.name)=="string" and string.find(b.name,"%S") then
   table.insert(ordered,{boss=b,order=FieldKit.Number(b.index,nil,1) or i,original=i})
  end
 end
 table.sort(ordered,function(a,b) if a.order==b.order then return a.original<b.original end;return a.order<b.order end)
 local charge=not FieldKitReborn.IsEndless() and FieldKitReborn.BossProgress() or nil
 local encounter,supported=FieldKitReborn.NextEncounter()
 if supported and encounter and encounter.endless then
  table.insert(out,{label=encounter.name,value=T.BossValue(encounter),fraction=encounter.progress or 0,
   state=encounter.state,index=encounter.ordinal,unknown=encounter.unknown,tint={.65,.35,.85}})
 end
 for _,item in ipairs(ordered) do local b=item.boss;local state=b.state;local status="Status not provided";local fraction=0;local tint={.65,.68,.7}
  if state=="dead" or state=="slain" then status="Defeated";defeated=defeated+1;fraction=1;tint={.3,.7,.3}
  elseif state=="up" then status="In combat";tint={.85,.3,.2}
  elseif state=="due" then
   if not nextSeen and not FieldKitReborn.IsEndless() and (not supported or (encounter and not encounter.active and (not encounter.ordinal or encounter.ordinal==item.order))) then status="Next";nextSeen=true;fraction=charge or 0;tint={.65,.35,.85}
   else status="Upcoming" end
  end
  local value=FieldKit_L(status)
  if status=="Next" and supported and encounter then value=value.." · "..T.BossValue(encounter)
  elseif status=="Next" and charge~=nil then value=value..string.format(" · %.0f%%",math.floor(charge*100)) end
  table.insert(out,{label=tostring(item.order)..". "..N.Text(FieldKitReborn.DisplayName(b.name)),value=value,fraction=fraction,tint=tint,
   icon=FieldKitReborn.EnemyIcon(b.name),state=state,index=item.order})
 end
 return out,defeated,table.getn(out)>0,table.getn(ordered)
end
function T.BossList()
 local frame=T.frames[4];if not frame then return end
 frame.bossListActive=not FieldKit.rebornLegacyFixture and FieldKitRebornDB.bossListCard and (N.Active() or N.Read("AZS_GetPhase")=="ready" or FieldKit.layoutEditing)
 if frame.mashCollapsed and frame.fieldkitDockHidden then frame.note:Hide();frame:Hide();return end
 if FieldKit.rebornLegacyFixture or not FieldKitRebornDB.bossListCard or (not N.Active() and N.Read("AZS_GetPhase")~="ready" and not FieldKit.layoutEditing) then frame:Hide();return end
 if frame.bossListSerial~=N.serial then frame.bossListSerial=N.serial;frame.bossListOffset=0 end
 local all,dead,known,campaignCount=T.BossListRows();local total=table.getn(all)
 local offset=math.max(0,math.min(frame.bossListOffset or 0,math.max(0,total-table.getn(frame.rows))));frame.bossListOffset=offset;frame.bossListCount=total
 local rows={};for i=offset+1,math.min(total,offset+table.getn(frame.rows)) do table.insert(rows,all[i]) end
 if total==0 then rows={{label=FieldKit_L("Boss list not provided"),value=""}} end
 local note=FieldKitReborn.IsEndless() and FieldKit_L("Endless: the game does not provide the upcoming boss sequence.") or ""
 frame.fieldkitFooterHeight=note~="" and 36 or 0
 local summary=known and (tostring(dead).." / "..tostring(campaignCount or total)) or ""
 if FieldKitReferenceHUD and FieldKitReferenceHUD.BossListCard(frame,rows,summary,note) then return end
 T.ShowRows(frame,rows,summary)
 for i,row in ipairs(frame.rows) do
  row.bossListEntry=rows[i]
  local e=rows[i]
  if e then
   local vw=e.value~="" and math.min(120,math.max(60,row.value:GetStringWidth()+10)) or 0
   row.value:SetWidth(vw);row.label:SetWidth(math.max(40,frame:GetWidth()-vw-40))
   if FieldKitReferenceHUD and FieldKitReferenceHUD.Fit then FieldKitReferenceHUD.Fit(row.label,12,10);FieldKitReferenceHUD.Fit(row.value,12,10) end
   if e.tint then row:SetStatusBarColor(e.tint[1],e.tint[2],e.tint[3],.35) end
  end
 end
 frame.note:SetWidth(frame:GetWidth()-24);frame.note:SetText(note)
 if note~="" and not frame.mashCollapsed then frame.note:Show() else frame.note:Hide() end
 FieldKitTheme.Update(frame)
end
-- Active player buffs from the client: icon, name (hidden tooltip), stacks and time left when exposed.
function T.Buffs(rows)
 if not FieldKit.rebornLegacyFixture then
  for _,b in ipairs(FieldKitReborn.PlayerBuffs()) do
   local value=b.remaining and N.Clock(b.remaining) or ""
   if b.count and b.count>1 then value=tostring(b.count).."x"..(value~="" and (" · "..value) or "") end
   table.insert(rows,{label=N.Text(b.name),value=value,icon=b.icon})
  end
  return true
 end
 if type(GetPlayerBuff)~="function" or type(GetPlayerBuffTexture)~="function" then return false end
 if not T.scan and type(CreateFrame)=="function" then
  local ok,tip=pcall(CreateFrame,"GameTooltip","FieldKitBuffScan",nil,"GameTooltipTemplate")
  if ok and tip then T.scan=tip;tip:SetOwner(UIParent,"ANCHOR_NONE") end
 end
 for i=0,31 do
  local index=GetPlayerBuff(i,"HELPFUL")
  if not index or index<0 then break end
  local texture=GetPlayerBuffTexture(index)
  if texture then
   local name
   if T.scan and T.scan.SetPlayerBuff then
    T.scan:ClearLines();T.scan:SetPlayerBuff(index)
    local line=getglobal("FieldKitBuffScanTextLeft1");name=line and line:GetText()
   end
   local count=type(GetPlayerBuffApplications)=="function" and FieldKit.Number(GetPlayerBuffApplications(index),nil,0)
   local remaining=type(GetPlayerBuffTimeLeft)=="function" and FieldKit.Number(GetPlayerBuffTimeLeft(index),nil,0)
   local value=""
   if count and count>1 then value=tostring(count).."x" end
   if remaining and remaining>0 then value=(value~="" and (value.." · ") or "")..N.Clock(remaining) end
   table.insert(rows,{label=(name and name~="") and N.Text(name) or FieldKit_L("Effect"),value=value,icon=N.Text(texture,240),buffIndex=index})
  end
 end
 return true
end
function T.Effects()
 local frame=T.frames[1];if not FieldKitRebornDB.effectsFrame then frame.lastRows={};frame:Hide();return end
 local rows,available={},false
 local defs={{"effectTotems","AZS_GetTotems","AZSTOTEMS"},{"effectSummons","AZS_GetSummonGroups","AZSPETS"},{"effectTimers","AZS_GetTimers","AZSTIMERS"}}
 for _,def in ipairs(defs) do
  if FieldKitRebornDB[def[1]] and N.Has(def[2]) then
   available=true
   local lines=N.Fresh(def[3]) and N.Read(def[2])
   if type(lines)=="table" then
    for i=1,math.min(64,table.getn(lines)) do
     local entry=lines[i]
     if type(entry)=="table" and type(entry.name)=="string" then
      local text,remaining= nil,FieldKit.Number(entry.remaining,nil,0)
      if def[1]=="effectTimers" then
       text=entry.ready==true and FieldKit_L("Ready") or N.Clock(remaining)
      else
       local count=Count(entry.count)
       if count and count>0 then
        local cap=Count(entry.cap)
        text=tostring(count)..(cap and " / "..cap or "").." · "..(remaining and N.Clock(remaining) or (def[1]=="effectSummons" and Count(entry.permanent)==count and FieldKit_L("Permanent") or "?"))
       end
      end
      if text then table.insert(rows,{label=N.Text(FieldKitReborn.DisplayName(entry.name,entry.spell)),value=text,icon=type(entry.icon)=="string" and N.Text(entry.icon,240) or nil}) end
     end
    end
   end
  end
 end
 if FieldKitRebornDB.effectBuffs and T.Buffs(rows) then available=true end
 if not available then rows={{label=FieldKit_L("Effects API unavailable"),value="?"}} end
 if table.getn(rows)>T.rows then
  local extra=table.getn(rows)-(T.rows-1)
  while table.getn(rows)>=T.rows do table.remove(rows) end
  table.insert(rows,{label=string.format(FieldKit_L("%d more effects (adjust filters)"),extra),value=""})
 end
 T.ShowRows(frame,rows)
end
function T.Revive()
 local frame=T.frames[2];if not FieldKitRebornDB.reviveFrame then frame:Hide();return end
 local data=N.Fresh("AZSREVIVE") and N.Read("AZS_GetRevive")
 local rows={}
 if type(data)=="table" then
  if data.down==1 then
   local share=FieldKit.Number(data.share,nil,0,1)
   table.insert(rows,{label=FieldKit_L("You are down"),value=share and string.format("%.0f%%",share*100) or "?",fraction=share})
   if type(data.by)=="string" and data.by~="" then table.insert(rows,{label=FieldKit_L("Revived by"),value=N.Text(data.by,100)}) end
  elseif type(data.reviving)=="string" and data.reviving~="" then
   local share=FieldKit.Number(data.rshare,nil,0,1)
   table.insert(rows,{label=N.Text(data.reviving),value=share and string.format("%.0f%%",share*100) or "?",fraction=share})
  end
 end
 T.ShowRows(frame,rows)
end
function T.NextBoss()
 if not FieldKit.rebornLegacyFixture then
  local encounter,supported=FieldKitReborn.NextEncounter()
  if supported then return encounter end
  local run=type(AZS_RUN)=="table" and AZS_RUN or {}
  if FieldKitReborn.IsEndless() then
   local progress=FieldKitReborn.BossProgress()
   local name=type(run.nbn)=="string" and string.find(run.nbn,"%S") and N.Text(FieldKitReborn.DisplayName(run.nbn)) or FieldKit_L("Next boss")
   return {name=name,key="endless:"..tostring(run.bs or ""),progress=progress,endless=true,unavailable=progress==nil}
  end
  -- Schedule order/state identifies the next encounter; its legacy `at` and
  -- `left` fields do not determine a Reborn spawn.
  for _,boss in ipairs(type(AZS_SCHEDULE)=="table" and AZS_SCHEDULE or {}) do
   if type(boss)=="table" and boss.state=="due" and type(boss.name)=="string" and boss.name~="" then
    return {name=N.Text(FieldKitReborn.DisplayName(boss.name)),key=tostring(boss.index or boss.name),progress=FieldKitReborn.BossProgress()}
   end
  end
  return nil
 end
 local lines=N.Read("AZS_GetUpcomingBosses");local chosen
 if type(lines)=="table" then
  for i=1,math.min(64,table.getn(lines)) do
   local boss=lines[i]
   if type(boss)=="table" and type(boss.name)=="string" then
    local left=FieldKit.Number(boss.left)
    if left and left>=0 and (not chosen or left<chosen.left) then chosen={name=N.Text(FieldKitReborn.DisplayName(boss.name)),left=left,key=tostring(boss.index or boss.name)} end
   end
  end
 end
 -- Native endless countdown, when present; never extrapolate a schedule.
 if not chosen and type(AZS_RUN)=="table" and (FieldKit.Number(AZS_RUN.endl)==1 or (type(AZS_RUN.nbn)=="string" and AZS_RUN.nbn~="")) then
  local left=FieldKit.Number(AZS_RUN.nb,nil,0)
  if left then
   local bossName=type(AZS_RUN.nbn)=="string" and AZS_RUN.nbn~="" and AZS_RUN.nbn or FieldKit_L("Next boss")
   local stamp=FieldKit.Number(AZS_RUN_UPDATED)
   if N.Read("AZS_GetPhase")=="playing" and stamp then left=math.max(0,left-math.max(0,GetTime()-stamp)) end
   if not T.endless or T.endless.name~=bossName or left>T.endless.left+2 then T.endlessCycle=(T.endlessCycle or 0)+1 end
   T.endless={name=bossName,left=left}
   chosen={name=N.Text(FieldKitReborn.DisplayName(bossName)),left=left,key="endless:"..tostring(T.endlessCycle)}
  end
 end
 return chosen
end
function T.BossValue(boss)
 if not boss then return "" end
 if FieldKit.rebornLegacyFixture then return N.Clock(boss.left) end
 if boss.active then return FieldKit_L("In combat") end
 if boss.left~=nil then return N.Clock(boss.left) end
 return boss.progress and string.format("%.0f%%",math.floor(boss.progress*100)) or FieldKit_L("Progress not provided")
end
function T.Reminders()
 local frame=T.frames[3];local rows={}
 local boss=(FieldKitRebornDB.nextBossCard or FieldKitRebornDB.nextBossAlert) and T.NextBoss()
 if FieldKitRebornDB.nextBossCard and boss then table.insert(rows,{label=boss.name,value=T.BossValue(boss)}) end
 if FieldKitRebornDB.storedLevelsBadge then
  local count=Count(N.Read("AZS_GetStoredLevels"))
  if count and count>0 then table.insert(rows,{label=FieldKit_L("Stored level-ups"),value=tostring(count)}) end
 end
 local approaching=boss and not boss.active and (boss.left and boss.left>0 and boss.left<=FieldKitRebornDB.bossWarningLead
  or not FieldKit.rebornLegacyFixture and boss.progress and boss.progress>=(100-FieldKitRebornDB.bossWarningLead)/100)
 if approaching and FieldKitRebornDB.nextBossAlert and N.Read("AZS_GetPhase")=="playing" then
  local key=tostring(N.serial)..":"..boss.key
  if not T.lastBoss[key] then
   T.lastBoss[key]=true
   T.bossKeys=T.bossKeys or {};table.insert(T.bossKeys,key)
   if table.getn(T.bossKeys)>128 then T.lastBoss[table.remove(T.bossKeys,1)]=nil end
   local text=FieldKit.rebornLegacyFixture and string.format(FieldKit_L("%s arrives in %ds"),boss.name,math.ceil(boss.left))
    or (boss.name.." · "..T.BossValue(boss))
   T.Push(text,"next:"..key)
  end
 end
 if FieldKitRebornDB.nextBossCard or FieldKitRebornDB.storedLevelsBadge then T.ShowRows(frame,rows) else frame:Hide() end
end
-- At most three short warnings; native message ids/content are not executable.
function T.Push(text,key,kind)
 local now=GetTime();text=N.Text(text,240)
 for _,seen in ipairs(T.recent) do if (seen.key==key or seen.text==text) and now-seen.at<5 then return end end
 table.insert(T.recent,{text=text,key=key,at=now});while table.getn(T.recent)>32 do table.remove(T.recent,1) end
 table.insert(T.warnings,{text=text,at=now,kind=kind or (string.find(key,"^next:") and "next" or "native")});while table.getn(T.warnings)>3 do table.remove(T.warnings,1) end
end
function T.Banner(banner)
 if not FieldKitRebornDB or not FieldKitRebornDB.nativeWarnings or not N.Active() or type(banner)~="table" or type(banner.text)~="string" then return end
 local kind=banner.kind
 local party=kind=="downed" or kind=="frienddown" or kind=="revived"
 local allowed
 if banner.boss==true or kind=="boss" then allowed=FieldKitRebornDB.bossBannerWarnings
 elseif party then allowed=FieldKitRebornDB.partyBannerWarnings~=false
 elseif kind=="mechanic" then allowed=FieldKitRebornDB.mechanicWarnings
 else allowed=not FieldKit.rebornLegacyFixture and FieldKitRebornDB.otherBannerWarnings~=false end
 if allowed then T.Push(banner.text,"banner:"..tostring(banner.id)) end
end
function T.ReleaseBanners()
 local d=FieldKitRebornDB
 if d and type(d.nativeBannerBefore)=="boolean" then
  if FieldKit.SetHudShown("banners",d.nativeBannerBefore) then d.nativeBannerBefore=nil end
 end
end
function T.Subscription()
 local d=FieldKitRebornDB
 local enabled=d.nativeWarnings and N.Active() and type(AZS_RegisterBannerHandler)=="function"
 if enabled then
  if not T.subscribed then local ok,result=pcall(AZS_RegisterBannerHandler,T.Banner);T.subscribed=ok and result~=false end
 elseif T.subscribed and type(AZS_UnregisterBannerHandler)=="function" then
  local ok=pcall(AZS_UnregisterBannerHandler,T.Banner);if ok then T.subscribed=false end
 end
 -- Hide native banners only while their replacement can receive events.
 if enabled and T.subscribed and not FieldKit.rebornLegacyFixture then
  if type(d.nativeBannerBefore)~="boolean" and type(AZS_IsHudShown)=="function" then
   local ok,value=pcall(AZS_IsHudShown,"banners");if ok and type(value)=="boolean" then d.nativeBannerBefore=value end
  end
  if type(d.nativeBannerBefore)=="boolean" then
   local shown=d.keepNativeBanners and true or false
   local ok,current=pcall(AZS_IsHudShown,"banners")
   if not ok or current~=shown then FieldKit.SetHudShown("banners",shown) end
  end
 else T.ReleaseBanners() end
end

function T.Warnings()
 local frame=T.warningFrame
 local d=FieldKitRebornDB
 local size=d.cardSizes.FieldKitNativeWarnings
 local now=GetTime()
 T.portalNotice,T.goblinNotice,T.riftNotice=false,false,false
 for i=table.getn(T.warnings),1,-1 do
  local item=T.warnings[i]
  if now-item.at>=4 or (item.kind=="native" and not d.nativeWarnings) or (item.kind=="next" and not d.nextBossAlert)
    or (item.kind=="portal" and (not d.goblinPortalAlert or N.Portal.state~="present"))
    or (item.kind=="rift" and (not d.riftPortalAlert or N.Portal.rift.state~="present")) then table.remove(T.warnings,i)
  elseif item.kind=="portal" then T.portalNotice,T.goblinNotice=true,true
  elseif item.kind=="rift" then T.portalNotice,T.riftNotice=true,true end
 end
 local count=table.getn(T.warnings)
 local compact=count==1 and T.portalNotice and not FieldKit.layoutEditing
 frame.fieldkitMinimumHeight=108;frame.fieldkitExpandedHeight=math.max(108,size and size.height or 108)
 local width=FieldKitCardLayout.Width(frame,440)
 frame:SetWidth(compact and math.min(width,300) or width)
 frame:SetHeight(compact and 44 or frame.fieldkitExpandedHeight)
 for _,row in ipairs(frame.rows) do row:SetWidth(frame:GetWidth()-24) end
 FieldKitTheme.Update(frame)
 if count==0 then
  if FieldKit.layoutEditing and (FieldKitRebornDB.nativeWarnings or FieldKitRebornDB.nextBossAlert) then
   FieldKit_Text(frame.rows[1],"Preview");frame.rows[1]:Show();frame.rows[1]:SetAlpha(1)
   frame.rows[2]:Hide();frame.rows[3]:Hide();frame:Show()
  else frame:Hide() end
  return
 end
 for i=1,3 do
  local data=T.warnings[i];local row=frame.rows[i]
  if data then row:SetText(data.text);row:SetAlpha(math.min(1,4-(now-data.at)));row:Show() else row:Hide() end
 end
 frame:Show()
end

local function CreatePortalCard(rift)
 local name=rift and "FieldKitRiftPortal" or "FieldKitGoblinPortal"
 local f=CreateFrame("Frame",name,UIParent)
 f:SetFrameStrata("LOW")
 f:SetWidth(240);f:SetHeight(44)
 FieldKitTheme.Surface(f,"card",true);FieldKitTheme.ReadableFloor(f)
 f.icon=f:CreateTexture(nil,"ARTWORK")
 f.icon:SetTexture(rift and "Interface\\Icons\\Spell_Arcane_PortalIronForge" or "Interface\\Icons\\INV_Misc_Coin_02")
 f.icon:SetWidth(24);f.icon:SetHeight(24);f.icon:SetPoint("LEFT",f,"LEFT",10,0)
 f.title=FieldKitTheme.Label(f,not rift and "Goblin portal available" or nil,42,4,188,18,12,FieldKitTheme.gold)
 f.detail=FieldKitTheme.Label(f,nil,42,23,188,16,11,FieldKitTheme.muted)
 if rift then f.progress=FieldKitTheme.Label(f,nil,42,23,188,16,11,FieldKitTheme.muted) end
 T.move(f,UIParent:GetWidth()/2-142,UIParent:GetHeight()/2-(rift and 297 or 239))
 if rift then T.riftFrame=f else T.portalFrame=f end
 return f
end

local function RiftLabel(marks)
 if table.getn(marks.o)==0 then return "Rift portal sealed" end
 if table.getn(marks.p)==0 then return "Rift portal open" end
 return "Open and sealed rifts"
end

local function RenderPortal(f,yards,title,progress)
 local detail=yards and string.format(FieldKit_L("Horizontal: %d yd"),math.floor(yards+0.5))
 if title and f.portalTitle~=title then
  f.portalTitle=title
  FieldKit_Text(f.title,title)
  if title=="Rift portal sealed" then f.icon:SetVertexColor(.8,.65,1)
  else f.icon:SetVertexColor(1,1,1) end
 end
 if f.portalDetail~=detail or f.portalProgress~=progress or not f:IsShown() then
  f.portalDetail,f.portalProgress=detail,progress
  f.detail:SetText(detail or "")
  if detail then f.detail:Show() else f.detail:Hide() end
  if f.progress then
   f.progress:SetText(progress or "")
   f.progress:ClearAllPoints()
   f.progress:SetPoint("TOPLEFT",f,"TOPLEFT",42,detail and -40 or -23)
   if progress then f.progress:Show() else f.progress:Hide() end
  end
  f:SetHeight(detail and progress and 60 or ((detail or progress) and 44 or 32))
  FieldKitTheme.Update(f)
 end
 if not f:IsShown() then f:Show() end
end

local function Visibility(state,enabled,phase)
 if not enabled then return "indicator_off" end
 if state~="present" then return state end
 if phase~="playing" and phase~="paused" then return "phase_hidden" end
 return "ready"
end

local function HidePortal(f)
 if f and f:IsShown() then f:Hide() end
end

function T.PortalView()
 local d,p=FieldKitRebornDB,N.Portal
 local phase=p.phase
 local goblin=Visibility(p.state,d.goblinPortalIndicator,phase)
 local rift=Visibility(p.rift.state,d.riftPortalIndicator,phase)
 local showGoblin,showRift=goblin=="ready",rift=="ready"
 local gYards,rYards
 if showGoblin or showRift then gYards,rYards=p.Distances(showGoblin,showRift) end
 if showGoblin then RenderPortal(T.portalFrame or CreatePortalCard(false),gYards)
 else p.distanceReason=goblin;HidePortal(T.portalFrame) end
 if showRift then
  local progress
  if p.got and p.need and p.need>0 and p.got<=p.need then
   progress=string.format(FieldKit_L("Crystals: %d/%d"),p.got,p.need)
  end
  RenderPortal(T.riftFrame or CreatePortalCard(true),rYards,RiftLabel(p.marks),progress)
 else p.rift.distanceReason=rift;HidePortal(T.riftFrame) end
 T.portalEvaluatedAt=GetTime()
 T.portalEvaluatedPacket=p.packets
end

function T.PortalChanged(appeared,riftEvent)
 local d,p=FieldKitRebornDB,N.Portal
 if not T.warningFrame then return end
 local refresh=(T.goblinNotice and p.state~="present") or (T.riftNotice and p.rift.state~="present")
 if p.state~="present" then HidePortal(T.portalFrame) end
 if p.rift.state~="present" then HidePortal(T.riftFrame) end
 if appeared and d.goblinPortalAlert and not FieldKit.layoutEditing then
  T.Push(FieldKit_L("Goblin portal available"),"portal:goblin","portal")
  refresh=true
 end
 if riftEvent and d.riftPortalAlert and not FieldKit.layoutEditing then
  local label=riftEvent=="open" and "Rift portal open" or "Rift portal sealed"
  T.Push(FieldKit_L(label),"rift:"..riftEvent,"rift")
  refresh=true
 end
 if refresh then T.Warnings() end
end

function T.PortalDiagnostic()
 local p,d=N.Portal,FieldKitRebornDB
 local chat=DEFAULT_CHAT_FRAME
 local phase=N.Read("AZS_GetPhase")
 local function Stamp(at)
  return at and string.format("%.2f (%.2fs ago)",at,math.max(0,GetTime()-at)) or "none"
 end
 chat:AddMessage(string.format("FieldKit rift: run=%s zone=%s map=%s area=%s floor=%s phase=%s",
  tostring(p.runId),N.Text(tostring(p.zone),40),tostring(p.map),tostring(p.area),tostring(p.floor),tostring(phase)))
 chat:AddMessage(string.format("AZSRIFT: sync=%s st=%s got=%s need=%s latest=%s accepted=%s",
  p.reason,tostring(p.nativeState),tostring(p.got),tostring(p.need),Stamp(p.lastPacket),Stamp(p.receivedAt)))
 local refresh=T.portalEvaluatedAt and "evaluated" or "never_evaluated"
 if T.portalEvaluatedPacket~=p.packets then refresh="pending_evaluation" end
 if p.runId and AZS_RIFT~=p.source then refresh="native_table_not_observed" end
 chat:AddMessage(string.format("Refresh: %s lastHUD=%s lastPacket=%s packets=%d decodes=%d poseReads=%d",
  refresh,Stamp(T.portalEvaluatedAt),tostring(p.lastPacketReason),p.packets,p.decodes,p.poseReads))
 chat:AddMessage(string.format("Goblin=%s display=%s distance=%s | Rift=%s display=%s distance=%s",
  p.state,Visibility(p.state,d.goblinPortalIndicator,phase),tostring(p.distanceReason),
  p.rift.state,Visibility(p.rift.state,d.riftPortalIndicator,phase),tostring(p.rift.distanceReason)))
 if not p.marks then
  chat:AddMessage("Points p/o/v/c: unavailable (no valid marks)")
  return
 end
 chat:AddMessage(string.format("Points p=%d o=%d v=%d c=%d unknown=%d; c is diagnostic only",
  table.getn(p.marks.p),table.getn(p.marks.o),table.getn(p.marks.v),table.getn(p.marks.c),p.marks.unknown))
 for _,kind in ipairs({"p","o","v","c"}) do
  for i,point in ipairs(p.marks[kind]) do
   if i>4 then break end
   chat:AddMessage(string.format("  %s[%d] mx=%.6f my=%.6f",kind,i,point.x,point.y))
  end
 end
end

function T.Update()
 if not T.frames[1] then return end
 N.Watch();N.Portal.Check();T.PortalView();T.Subscription()
 if T.serial~=N.serial then T.serial=N.serial;T.warnings={};T.recent={};T.lastBoss={};T.bossKeys={};T.endless=nil;T.endlessCycle=0 end
 T.BossList()
 if not N.Active() and not FieldKit.layoutEditing then
  for i,frame in ipairs(T.frames) do if i~=4 then frame:Hide() end end
  T.frames[1].lastRows={}
  T.warnings={};T.warningFrame:Hide();return
 end
 T.Effects();T.Revive();T.Reminders();T.Warnings()
end

-- Local diagnostic, deliberately excluding chat, player names and account data.
function T.Diagnostic()
 local affixes=type(AZS_ZONE)=="table" and AZS_ZONE.affixes
 DEFAULT_CHAT_FRAME:AddMessage("FieldKit native: phase="..tostring(N.Read("AZS_GetPhase"))..
  " totems="..tostring(N.Has("AZS_GetTotems")).." summons="..tostring(N.Has("AZS_GetSummonGroups"))..
  " timers="..tostring(N.Has("AZS_GetTimers")).." revive="..tostring(N.Has("AZS_GetRevive"))..
  " overlay="..tostring(FieldKit.FrameOverlayAvailable()).." affixes="..N.Text(tostring(affixes),120))
end
