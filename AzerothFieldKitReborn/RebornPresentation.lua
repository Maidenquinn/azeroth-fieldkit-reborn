-- Reborn-only presentation. Native frames keep their scripts and data owners.
local R=FieldKitReborn
function R.SkinAction(button,slot)
 local H=FieldKitThemeHUD
 local icon=button.icon or getglobal(button:GetName().."IconTexture")
 if not icon then return end
 R.squareActions=R.squareActions or {}
 local f=R.squareActions[button]
 if not f then
  f=CreateFrame("Frame",nil,button);f:EnableMouse(false)
  f.icon=f:CreateTexture(nil,"ARTWORK");f.icon:SetAllPoints(f);f.icon:SetTexCoord(.07,.93,.07,.93)
  R.squareActions[button]=f
 end
 f:ClearAllPoints();f:SetAllPoints(button);f:SetFrameLevel(button:GetFrameLevel()+1)
 f.icon:SetTexture(icon:GetTexture())
 if icon.GetVertexColor then local r,g,b,a=icon:GetVertexColor();f.icon:SetVertexColor(r,g,b,a or 1) end
 H.Save(icon);icon:SetAlpha(0)
 for _,key in ipairs({"backdrop","IconBorder","shadow","ring","glow","Flash"}) do
  local region=button[key]
  if region and region.SetAlpha then H.Save(region);region:SetAlpha(0) end
 end
 if button.OverlayFrame then H.Save(button.OverlayFrame);button.OverlayFrame:SetFrameLevel(button:GetFrameLevel()+3) end
 if button.cooldown then button.cooldown:SetFrameLevel(button:GetFrameLevel()+2) end
 if slot==12 and button.key then
  H.Save(button.key);button.key:ClearAllPoints();button.key:SetPoint("BOTTOM",button,"TOP",0,2)
 end
 local occupied=slot==12 or type(HasAction)~="function" or HasAction(slot)
 if occupied and icon:GetTexture() then f:Show() else f:Hide() end
end
function R.RestoreSquareActions()
 for _,frame in pairs(R.squareActions or {}) do frame:Hide() end
 if R.progressFrame then R.progressFrame:Hide() end
 if R.eventFrame then R.eventFrame:Hide() end
end
function R.ProgressBar()
 local H=FieldKitThemeHUD
 if not R.progressFrame then
  local f=CreateFrame("StatusBar","FieldKitRebornBossProgress",H.header);R.progressFrame=f
  f:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");f:SetStatusBarColor(.65,.26,.85)
  f:SetMinMaxValues(0,1);FieldKitTheme.Surface(f,"card")
  f.label=FieldKitTheme.Label(f,nil,6,2,260,22,14,FieldKitTheme.text,true)
  f.label:SetJustifyH("CENTER")
 end
 local share=R.BossProgress();local f=R.progressFrame
 if not share then f:Hide();H.next:SetText(FieldKit_L("No upcoming boss"));return end
 local boss=FieldKitNativeTools.NextBoss();local name=boss and boss.name or FieldKit_L("Next boss")
 local width=math.min(420,H.header:GetWidth()-28)
 f:ClearAllPoints();f:SetPoint("TOP",H.header,"BOTTOM",0,-6);f:SetWidth(width);f:SetHeight(26)
 f.label:SetWidth(width-12);f:SetValue(share)
 f.label:SetText(name..string.format(" · %.0f%%",math.floor(share*100)))
 H.next:SetText(name);f:Show()
end
-- Reflow the existing counter band into three/four columns; preserve its border.
function R.CounterBand()
 local V,H=FieldKitReferenceHUD,FieldKitThemeHUD
 local d=V.layout;if not d or not d.counts then return end
 local x0,y0,x1,h
 for i=1,3 do local a=d.counts[i]
  if a then
   x0=math.min(x0 or a[1]-30,a[1]-30);y0=math.min(y0 or a[2],a[2])
   x1=math.max(x1 or a[1]+a[3],a[1]+a[3]);h=math.max(h or a[4],a[4])
  end
 end
 if not x0 then return end
 if not R.eventFrame then
  local f=CreateFrame("Frame","FieldKitRebornEventCurrency",H.counterRoot);R.eventFrame=f
  f.icon=f:CreateTexture(nil,"ARTWORK");f.label=FieldKitTheme.Label(f,nil,24,0,130,22,13,FieldKitTheme.gold)
  f:EnableMouse(true)
  f:SetScript("OnEnter",function()
   local e=R.EventCurrency();if not e then return end
   GameTooltip:SetOwner(this,"ANCHOR_TOP");GameTooltip:SetText(e.name);GameTooltip:AddLine(string.format("%.0f",e.count),1,.82,0);GameTooltip:Show()
  end)
  f:SetScript("OnLeave",function() GameTooltip:Hide() end)
 end
 if not R.counterCover then R.counterCover=H.counterRoot:CreateTexture(nil,"ARTWORK");FieldKitTheme.Solid(R.counterCover,FieldKitTheme.background or {.03,.07,.04}) end
 local origin=H.counterRoot.referenceRect or {0,0};local width=x1-x0
 R.counterCover:ClearAllPoints();R.counterCover:SetPoint("TOPLEFT",H.counterRoot,"TOPLEFT",x0-origin[1],origin[2]-y0)
 R.counterCover:SetWidth(width);R.counterCover:SetHeight(h);R.counterCover:Show()
 local event=R.EventCurrency();local n=event and 4 or 3;local cell=width/n
 for i=1,3 do
  local label=V.counts[i];local button=V.counterButtons[i];local icon=V.countIcons[i]
  icon:SetDrawLayer("OVERLAY")
  label:ClearAllPoints();label:SetPoint("TOPLEFT",H.counterRoot,"TOPLEFT",x0-origin[1]+(i-1)*cell+25,origin[2]-y0)
  label:SetWidth(cell-28);label:SetHeight(h);FieldKitTheme.Font(label,13,FieldKitTheme.text,true);label:Show()
  button:ClearAllPoints();button:SetPoint("TOPLEFT",H.counterRoot,"TOPLEFT",x0-origin[1]+(i-1)*cell,origin[2]-y0);button:SetWidth(cell);button:SetHeight(h)
  icon:ClearAllPoints();icon:SetPoint("TOPLEFT",button,"TOPLEFT",3,-3);icon:SetWidth(18);icon:SetHeight(18)
  icon:SetTexture(i==1 and "Interface\\TargetingFrame\\UI-TargetingFrame-Skull" or (i==2 and "Interface\\MoneyFrame\\UI-MoneyIcons" or FieldKitTheme.media.."WorldMarkers\\cache.tga"))
  icon:SetTexCoord(0,i==2 and .25 or 1,0,1);icon:Show()
 end
 local f=R.eventFrame
 if event then
  f:ClearAllPoints();f:SetPoint("TOPLEFT",H.counterRoot,"TOPLEFT",x0-origin[1]+3*cell,origin[2]-y0)
  f:SetWidth(cell);f:SetHeight(h);f.icon:SetPoint("LEFT",f,"LEFT",3,0);f.icon:SetWidth(18);f.icon:SetHeight(18);f.icon:SetTexture(event.icon)
  f.label:SetText(string.format("%.0f",event.count));f.label:SetWidth(cell-28);f:Show()
 else f:Hide() end
end
function R.RefreshPresentationDetails()
 local H=FieldKitThemeHUD
 R.ProgressBar();R.CounterBand()
 local r,g,b=R.HealthColor(UnitHealth("player"),UnitHealthMax("player"))
 if H.health and r then H.health:SetStatusBarColor(r,g,b) end
 R.CacheEnemyIcons()
end
-- Entry->icon comes from the public world position API and the native catalog.
-- Names with conflicting observed icons remain unknown; instance ids are not entries.
function R.EnsureEnemyRun()
 local run=type(AZS_API_RunId)=="function" and AZS_API_RunId() or nil
 if run~=R.enemyRun then R.enemyIcons={};R.enemyCount=0;R.enemyRun=run;R.enemyScanAt=nil end
end
function R.NoteEnemy(guid,name,entry)
 R.EnsureEnemyRun()
 if type(name)~="string" or string.len(name)>160 then return end
 if not entry and type(AZS_UnitWorldPosition)=="function" and type(guid)=="string" then
  local ok,x,y,z,h,alive,gone,rank,id=pcall(AZS_UnitWorldPosition,guid);if ok then entry=id end
 end
 local catalog=type(AZS_GEN)=="table" and AZS_GEN.creatureIcons
 local icon=type(catalog)=="table" and R.Icon(catalog[tonumber(entry)])
 if not icon then return end
 R.enemyIcons=R.enemyIcons or {};R.enemyCount=R.enemyCount or 0
 for _,key in ipairs({name,R.Localize(name)}) do
  local old=R.enemyIcons[key]
  if old==nil and R.enemyCount<512 then R.enemyIcons[key]=icon;R.enemyCount=R.enemyCount+1
  elseif old and old~=icon then R.enemyIcons[key]=false end
 end
end
function R.CacheEnemyIcons()
 R.EnsureEnemyRun()
 if R.enemyScanAt and GetTime()<R.enemyScanAt then return end
 R.enemyScanAt=GetTime()+1
 if type(AZS_WorldUnits)~="function" then return end
 local ok,units=pcall(AZS_WorldUnits,0);if not ok or type(units)~="table" then return end
 for i=1,math.min(512,table.getn(units)) do local u=units[i]
  if type(u)=="table" and not u.player then R.NoteEnemy(u.guid,u.name,u.entry) end
 end
end
function R.EnemyIcon(name,row)
 R.CacheEnemyIcons()
 if type(row)=="table" and type(row.icon)=="string" and row.icon~="" then return R.Icon(row.icon) end
 if type(row)=="table" and row.entry then R.NoteEnemy(nil,name,row.entry) end
 return (R.enemyIcons and R.enemyIcons[name]) or "Interface\\Icons\\INV_Misc_QuestionMark"
end
local observer=CreateFrame("Frame");observer:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
observer:SetScript("OnEvent",function()
 if FieldKit.rebornLegacyFixture then return end
 if type(arg2)=="string" and string.find(arg2,"_DAMAGE") and type(UnitGUID)=="function" and arg6==UnitGUID("player") then
  R.NoteEnemy(arg3,arg4)
 end
end)
