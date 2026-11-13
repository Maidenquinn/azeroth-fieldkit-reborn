-- Size the outer material before building its slices. The fill is a separate
-- child above that material, inset within the same Elwynn/Naxx gold chrome.
local R=FieldKitReborn
function R.ThinMeter(name)
 local f=CreateFrame("Frame",name,FieldKitThemeHUD.header)
 f:SetWidth(360);f:SetHeight(30);FieldKitTheme.Surface(f,"card",true)
 f.fill=CreateFrame("StatusBar",nil,f);f.fill:SetFrameLevel(f:GetFrameLevel()+1)
 f.fill:SetMinMaxValues(0,100);f.fill:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
 f.label=FieldKitTheme.Label(f.fill,nil,6,0,348,22,14,FieldKitTheme.text,true)
 f.label:ClearAllPoints();f.label:SetPoint("CENTER",f,"CENTER",0,0);f.label:SetJustifyH("CENTER");f.label:SetJustifyV("MIDDLE")
 return f
end
function R.SizeMeter(f,width)
 local w=math.max(200,math.min(480,width));local h=30
 f:SetWidth(w);f:SetHeight(h);FieldKitTheme.Update(f)
 f.fill:ClearAllPoints();f.fill:SetPoint("TOPLEFT",f,"TOPLEFT",8,-7);f.fill:SetWidth(w-16);f.fill:SetHeight(h-14)
 f.label:SetWidth(w-24);f.label:SetHeight(h-10);FieldKitTheme.Font(f.label,14,FieldKitTheme.text,true)
end
function R.ProgressBar()
 local H=FieldKitThemeHUD
 if not R.progressFrame then R.progressFrame=R.ThinMeter("FieldKitRebornBossProgress") end
 if not R.hordeFrame then R.hordeFrame=R.ThinMeter("FieldKitRebornHorde") end
 local width=math.min(420,H.header:GetWidth()-28);R.SizeMeter(R.progressFrame,width);R.SizeMeter(R.hordeFrame,width)
 local share=R.BossProgress();local f=R.progressFrame
 f:ClearAllPoints();f:SetPoint("TOP",H.header,"BOTTOM",0,-6)
 if share then
  local boss=FieldKitNativeTools.NextBoss();local name=boss and boss.name or FieldKit_L("Next boss")
  f.fill:SetStatusBarColor(.45,.32,.12,.95);f.fill:SetValue(0);f.fill:SetValue(share*100);f.label:SetText(name..string.format(" · %.0f%%",math.floor(share*100)));f:Show();H.next:SetText(name)
 else f:Hide();H.next:SetText(FieldKit_L("No upcoming boss")) end
 local run=type(AZS_RUN)=="table" and AZS_RUN or {}
 local alive=FieldKit.Number(run.en,nil,0);local cap=FieldKit.Number(run.enm,nil,1)
 local h=R.hordeFrame;h:ClearAllPoints();h:SetPoint("TOP",share and f or H.header,"BOTTOM",0,-5)
 if alive then
  local value=cap and math.min(1,alive/cap) or 0
  h.fill:SetValue(0);h.fill:SetValue(value*100);h.fill:SetStatusBarColor(value>=.75 and .7 or .48,value>=.75 and .15 or .38,.12,.95)
  h.label:SetText(FieldKit_L("Horde").."  "..string.format("%.0f",alive)..(cap and (" / "..string.format("%.0f",cap)) or ""));h:Show()
 else h:Hide() end
end
-- Three/four equal cells with an icon and a large sans-serif value. Labels live
-- in tooltips, so currencies never produce a row of tiny mixed-language prose.
function R.CounterBand()
 local V,H=FieldKitReferenceHUD,FieldKitThemeHUD;local d=V.layout;if not d or not d.counts then return end
 local x0,y0,x1,height
 for i=1,3 do local a=d.counts[i];if a then
  x0=math.min(x0 or a[1]-44,a[1]-44);y0=math.min(y0 or a[2],a[2]);x1=math.max(x1 or a[1]+a[3],a[1]+a[3]);height=math.max(height or a[4],a[4])
 end end
 if not x0 then return end
 R.counterCells=R.counterCells or {}
 for i=1,4 do if not R.counterCells[i] then
  local f=CreateFrame("Frame",nil,H.counterRoot);local index=i;R.counterCells[i]=f;f:EnableMouse(true)
  f.icon=f:CreateTexture(nil,"ARTWORK");f.icon:SetWidth(20);f.icon:SetHeight(20);f.icon:SetPoint("LEFT",f,"LEFT",10,0)
  f.label=FieldKitTheme.Label(f,nil,0,0,90,26,18,FieldKitTheme.text,false,"AzerothSans.ttf")
  f.label:ClearAllPoints();f.label:SetPoint("LEFT",f.icon,"RIGHT",8,0);f.label:SetJustifyV("MIDDLE")
  f:SetScript("OnEnter",function()
   GameTooltip:SetOwner(this,"ANCHOR_TOP");GameTooltip:SetText(this.counterTitle or "?");GameTooltip:AddLine(this.counterValue or "?",1,.82,0);GameTooltip:Show()
  end)
  f:SetScript("OnLeave",function() GameTooltip:Hide() end)
 end end
 R.eventFrame=R.counterCells[4]
 if not R.counterCover then R.counterCover=H.counterRoot:CreateTexture(nil,"ARTWORK") end
 FieldKitTheme.Solid(R.counterCover,FieldKitTheme.background)
 local origin=H.counterRoot.referenceRect or {0,0};local width=x1-x0
 R.counterCover:ClearAllPoints();R.counterCover:SetPoint("TOPLEFT",H.counterRoot,"TOPLEFT",x0-origin[1],origin[2]-y0);R.counterCover:SetWidth(width);R.counterCover:SetHeight(height);R.counterCover:Show()
 local run=type(AZS_RUN)=="table" and AZS_RUN or {};local event=R.EventCurrency();local n=event and 4 or 3;local cell=width/n
 local values={run.kills,run.gold,run.chest,event and event.count}
 local names={FieldKit_L("Kills"),FieldKit_L("Gold"),FieldKit_L("Chest price"),event and event.name}
 local icons={"Interface\\TargetingFrame\\UI-TargetingFrame-Skull","Interface\\MoneyFrame\\UI-MoneyIcons",FieldKitTheme.media.."WorldMarkers\\cache.tga",event and event.icon}
 for i=1,3 do V.counts[i]:Hide();V.counterButtons[i]:Hide();V.countIcons[i]:Hide() end
 for i,f in ipairs(R.counterCells) do
  if i<=n then
   f:ClearAllPoints();f:SetPoint("TOPLEFT",H.counterRoot,"TOPLEFT",x0-origin[1]+(i-1)*cell,origin[2]-y0);f:SetWidth(cell);f:SetHeight(height)
   f.label:SetWidth(cell-40);f.label:SetHeight(height);FieldKitTheme.Font(f.label,18,FieldKitTheme.text,false,"AzerothSans.ttf")
   f.icon:SetTexture(icons[i]);f.icon:SetTexCoord(0,i==2 and .25 or 1,0,1)
   local value=FieldKit.Number(values[i],nil,0);f.label:SetText(V.Amount(value));f.counterTitle=names[i];f.counterValue=value and string.format("%.0f",value) or "?";f:Show()
  else f:Hide() end
 end
 if FieldKitRebornDB.moneyFrame then H.counterRoot:Show() else H.counterRoot:Hide() end
end
-- Draw six copies of a clean existing socket from the atlas. Cover the complete
-- baked seven-socket row first; the ornament/XP/footer artwork is unchanged.
function R.PrepareSixSlots(d)
 local H,V=FieldKitThemeHUD,FieldKitReferenceHUD;local a=d.actions;local dock=d.rects.dock
 local source=d.sourceActions or a
 local sx=source[1]-dock[1]+2*source[4];local sy=source[2]-dock[2];local size=a[3]
 if not R.sixPlate then R.sixPlate=CreateFrame("Frame",nil,H.dock);R.sixPlate.fill=R.sixPlate:CreateTexture(nil,"ARTWORK");R.sixPlate.fill:SetAllPoints(R.sixPlate);R.sixPlate:EnableMouse(false) end
 local plate=R.sixPlate;plate:SetFrameLevel(H.dock:GetFrameLevel()+4);plate:ClearAllPoints();plate:SetPoint("TOPLEFT",H.dock,"TOPLEFT",a[1]-dock[1]-3,dock[2]-a[2]+3);plate:SetWidth(6*a[4]+size+6);plate:SetHeight(size+6);FieldKitTheme.Solid(plate.fill,FieldKitTheme.background);plate:Show()
 R.sixSlots=R.sixSlots or {}
 for i=1,6 do
  local f=R.sixSlots[i]
  if not f then f=CreateFrame("Frame",nil,H.dock);f.tiles={};f:EnableMouse(false);R.sixSlots[i]=f end
  f:SetFrameLevel(H.dock:GetFrameLevel()+5);f:ClearAllPoints();f:SetPoint("TOPLEFT",H.dock,"TOPLEFT",a[1]-dock[1]+a[4]/2+(i-1)*a[4],dock[2]-a[2]);f:SetWidth(size);f:SetHeight(size);f:Show()
  local artKey=V.key..tostring(d.compactDock~=nil)
  if f.layoutKey~=artKey then
   local count=0
   for _,t in ipairs(d.tiles.dock or {}) do
    local x0=math.max(sx,t[2]);local y0=math.max(sy,t[3]);local x1=math.min(sx+size,t[2]+t[4]);local y1=math.min(sy+size,t[3]+t[5])
    if x1>x0 and y1>y0 then
     count=count+1;local tex=f.tiles[count];if not tex then tex=f:CreateTexture(nil,"BACKGROUND");f.tiles[count]=tex end
     local u0=(t[9] or 0)/t[6];local us=(t[10] or t[4])/t[4]/t[6];local v0=(t[8] or 0)/t[7]
     tex:SetTexture(FieldKitTheme.media.."ReferenceHUD\\"..t[1]);tex:ClearAllPoints();tex:SetPoint("TOPLEFT",f,"TOPLEFT",x0-sx,sy-y0);tex:SetWidth(x1-x0);tex:SetHeight(y1-y0)
     tex:SetTexCoord(u0+(x0-t[2])*us,u0+(x1-t[2])*us,v0+(y0-t[3])/t[7],v0+(y1-t[3])/t[7]);tex:Show()
    end
   end
   for j=count+1,table.getn(f.tiles) do f.tiles[j]:Hide() end;f.layoutKey=artKey
  end
 end
end
function R.PlaceSteed()
 local b=getglobal("AZSDashButton");if not b then return end
 local H=FieldKitThemeHUD;H.Save(b);b:SetParent(H.dock);b:ClearAllPoints();b:SetPoint("BOTTOMLEFT",H.dock,"BOTTOMRIGHT",8,24);b:SetFrameLevel(H.dock:GetFrameLevel()+12)
 -- Retain the real utility's original round skin, charges, tooltip and key.
 local pending=type(AZS_DASH)=="table" and not AZS_DASH.seen and AZS_DASH.off~=1
 if pending then
  if not R.steedPending then
   local f=CreateFrame("Frame",nil,H.dock);R.steedPending=f;f:SetWidth(46);f:SetHeight(46);f:EnableMouse(true)
   f.icon=f:CreateTexture(nil,"ARTWORK");f.icon:SetAllPoints(f);f.icon:SetVertexColor(.45,.45,.45)
   f.label=FieldKitTheme.Label(f,nil,0,0,46,20,16,FieldKitTheme.gold,false);f.label:ClearAllPoints();f.label:SetPoint("BOTTOM",f,"BOTTOM",0,0);f.label:SetText("?")
   f:SetScript("OnEnter",function()
    GameTooltip:SetOwner(this,"ANCHOR_TOP");GameTooltip:SetText(FieldKit_L("Mount state unavailable"));GameTooltip:AddLine(FieldKit_L("Waiting for the game's charge update."),.8,.8,.8,true);GameTooltip:Show()
   end)
   f:SetScript("OnLeave",function() GameTooltip:Hide() end)
  end
  local f=R.steedPending;f:ClearAllPoints();f:SetPoint("BOTTOMLEFT",H.dock,"BOTTOMRIGHT",8,24);f:SetFrameLevel(H.dock:GetFrameLevel()+12)
  f.icon:SetTexture(b.icon and b.icon:GetTexture() or "Interface\\Icons\\INV_Misc_QuestionMark");f:Show()
 elseif R.steedPending then R.steedPending:Hide() end
end
function R.RefreshPresentationDetails()
 local H=FieldKitThemeHUD;R.ProgressBar();R.CounterBand()
 local showMode=FieldKitReferenceHUD.ModeShown()
 if showMode then H.mode:Show() else H.mode:Hide();if FieldKitReferenceHUD.heroic then FieldKitReferenceHUD.heroic:Hide() end end
 local r,g,b=R.HealthColor(UnitHealth("player"),UnitHealthMax("player"));if H.health and r then H.health:SetStatusBarColor(r,g,b) end
 R.CacheEnemyIcons()
end
