-- Context-free visual examples. Never write samples to native tables, meters,
-- saved gameplay data or party sharing. Only explicit placement/reset saves HUD
-- geometry. All example frames are separate from the live renderer's frame pool.
FieldKitPreview={frames={},roots={},included={},selected=2}
local P=FieldKitPreview
local T=FieldKitTheme
function P.Text(text)
 local value=FieldKit_L(text)
 if value==text and FieldKitReborn and FieldKitReborn.DisplayName then value=FieldKitReborn.DisplayName(text) end
 return value
end

function P.Initialize(createBar,createBoss,place)
 P.createBar=createBar;P.createBoss=createBoss;P.place=place
 P.names={};P.labels={}
 for i=1,table.getn(FieldKitCardLayout.names) do
  P.names[i]=FieldKitCardLayout.names[i];P.labels[i]=FieldKitCardLayout.labels[i]
  P.included[i]=i<9 or i>12
 end
 P.bossIndex=table.getn(P.names)+1;P.playerIndex=P.bossIndex+1;P.targetIndex=P.bossIndex+2
 table.insert(P.names,"FieldKitBossFrame1");table.insert(P.labels,"Bosses");P.included[P.bossIndex]=true
 table.insert(P.names,"FieldKitPlayerBar");table.insert(P.labels,"Player health format")
 table.insert(P.names,"FieldKitTargetHealth");table.insert(P.labels,"Target health format")
 -- Health formats are available in the inspector. Existing player-bar dragging
 -- remains live; target text follows the native target frame.
end

function P.Group(index)
 if FieldKitRebornDB.linkLeftCards and (index<=4) then return FieldKitHudStack.root end
 if FieldKitRebornDB.linkRightCards and (index==5 or index==6) then return FieldKitCardLayout.root end
end

-- A proxy group owns sample positioning only. The live group's geometry is not
-- stretched to fit examples. Commit its native anchor after the user drags it.
function P.Root(source)
 local name=source:GetName();local root=P.roots[name]
 if not root then
  root=CreateFrame("Frame",nil,UIParent);P.roots[name]=root
  root.source=source;root:SetMovable(true);root:SetClampedToScreen(true)
 end
 root:SetWidth(source:GetWidth());root:SetHeight(source:GetHeight())
 if not root.moving then root:SetScale(1);root.fieldkitCompositionScale=nil end
 if not root.moving then
  local a,b,c,x,y=source:GetPoint(1)
  if a then root:ClearAllPoints();root:SetPoint(a,b,c,x,y) end
 end
 return root
end

function P.Commit(proxy,source)
 local a,b,c,x,y=proxy:GetPoint(1)
 if a and (not b or b==UIParent or b=="UIParent") then
  local scale=proxy.fieldkitCompositionScale or 1
  local anchor={a,c or a,x*scale,y*scale}
  if FieldKitPositions.Valid(anchor) then
   FieldKitRebornDB.frameAnchors[source:GetName()]=anchor;P.place(source)
   if source==FieldKitMoneyFrame then FieldKitRebornDB.moneyDetached=true end
  end
 end
end

function P.Drag(frame,start)
 if P.mode~="place" or frame.index>=P.playerIndex then return end
 local source=P.Group(frame.index) or getglobal(P.names[frame.index])
 local proxy=P.Group(frame.index) and frame:GetParent() or frame
 if start then proxy.moving=true;proxy:StartMoving()
 elseif proxy.moving then
  proxy:StopMovingOrSizing();proxy.moving=nil;P.Commit(proxy,source)
 end
end

-- HP examples use their actual format helper and the player's bar dimensions.
-- The wrapper adds a sample label; the health bar, shield and buff strip remain
-- distinct regions. Target text deliberately has no independent placement action.
function P.HealthFrame()
 local f=CreateFrame("Frame",nil,UIParent);f:SetWidth(280);f:SetHeight(108)
 f.title=T.Label(f,"Preview — sample data",0,0,280,24,12,T.gold)
 f.healthInfo=T.Label(f,"",0,23,280,18,12,T.text)
 f.targetInfo=T.Label(f,"",0,78,280,18,11,T.muted)
 local bar=CreateFrame("StatusBar",nil,f);f.health=bar
 bar:SetPoint("TOPLEFT",f,"TOPLEFT",0,-48);bar:SetHeight(9)
 bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");bar:SetStatusBarColor(.1,.9,.1)
 bar:SetMinMaxValues(0,12200);bar:SetValue(6705)
 f.hp=bar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");f.hp:SetPoint("BOTTOM",bar,"TOP",0,3)
 f.shield=bar:CreateTexture(nil,"OVERLAY");f.shield:SetPoint("TOPLEFT",bar,"TOPLEFT",0,0);f.shield:SetHeight(9);f.shield:SetTexture(.55,.85,1,.75)
 f.buffs={}
 for i=1,3 do
  local icon=f:CreateTexture(nil,"ARTWORK");icon:SetWidth(18);icon:SetHeight(18)
  icon:SetPoint("TOPLEFT",bar,"BOTTOMLEFT",(i-1)*20,-5);icon:SetTexture("Interface\\Icons\\Spell_Holy_WordFortitude");f.buffs[i]=icon
 end
 return f
end

function P.Frame(index)
 if P.frames[index] then return P.frames[index] end
 local f
 if index>=P.playerIndex then f=P.HealthFrame()
 elseif index==P.bossIndex then
  f=P.createBoss(1,true)
  -- The native boss name/HP text may be hidden by live-HUD visibility
  -- controllers. Own a separate overlay with independent fixture values.
  f.previewOverlay=CreateFrame("Frame",nil,f)
  f.previewOverlay:SetAllPoints(f)
  f.previewOverlay:SetFrameLevel(f:GetFrameLevel()+15)
  f.previewName=T.Label(f.previewOverlay,"",104,9,210,18,12,T.gold)
  f.previewHealth=T.Label(f.previewOverlay,"",104,57,210,18,12,T.text)
  f.previewDetail=T.Label(f.previewOverlay,"",104,75,210,15,11,T.muted)
 else
  f=P.createBar("FieldKitPreviewCard"..index,P.labels[index],8)
  f.mashCollapseButton:Hide();f.mashCollapsed=false;FieldKit.CreateMeterColumns(f)
  -- Dedicated sample labels: native meter row visibility and layout are controlled
  -- by the live HUD, so preview data must not depend on that row pool.
  f.sampleLines={}
  for n=1,8 do
   local line=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
   line:SetJustifyH("LEFT");line:SetTextColor(.92,.84,.63)
   line:SetPoint("TOPLEFT",f,"TOPLEFT",10,-27-(n-1)*18)
   line:SetHeight(16);T.Font(line,11,{.92,.84,.63});f.sampleLines[n]=line
  end
  if index==5 then
   for _,row in ipairs(f.rows) do row.sampleBonus=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.sampleBonus:SetPoint("TOPLEFT",row,"TOPLEFT",3,-15);row.sampleBonus:SetHeight(12);row.sampleBonus:SetTextColor(.3,1,.4) end
  end
 end
 f.index=index;f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton")
 f:SetScript("OnDragStart",function() P.Drag(f,true) end)
 f:SetScript("OnDragStop",function() P.Drag(f,false) end)
 f:SetFrameStrata("DIALOG");f:SetFrameLevel(130)
 if index==P.bossIndex then
  -- Reborn does not raise these pre-existing child frames with their parent.
  f.chrome:SetFrameLevel(132);f.bar:SetFrameLevel(133)
  local border=getglobal("FieldKitPreviewBossTextureFrame")
  if border then border:SetFrameLevel(135) end
  f.previewOverlay:SetFrameLevel(145)
 end
 P.frames[index]=f;return f
end

-- Local deterministic examples, with familiar categories and non-player names.
-- Values are presentation fixtures, not a hypothetical damage attribution.
function P.Rows(index)
 local hp=FieldKit_FormatHealth(6705,12200,FieldKitRebornDB.partyHealthMode)
 if P.names[index]=="FieldKitPlayerCard" then return {{"Player","Example"},{"Health",hp,.55},{"Mana","65 / 100",.65}} end
 if P.names[index]=="FieldKitBossListFrame" then return {{"Boss 1","Defeated"},{"Boss 2","Next"},{"Boss 3","Upcoming"}} end
 if index==1 then return {{FieldKit_L("Heroic").." II","Example"},{"Bolstering","Example"},{"Next boss","1:24"}} end
 if index==2 then
  local mode=FieldKitMeters.Mode()
  if mode==2 then return {{"Healing",42000,1400,.7},{"Regeneration",18000,600,.3}} end
  return {{"Fireball",42000,1400,.7},{"Melee",12000,400,.2},{"Periodic damage",6000,200,.1}}
 end
 if index==3 then return {{"Monster melee",720,24,.6},{"Boss spells",360,12,.3},{"Elites",120,4,.1}} end
 if index==4 then return {{"Guardian","awake"},{"Guardian","2:14"},{"Guardian","asleep"},{"Guardian","0:32"}} end
 if index==5 and FieldKitRebornDB.loadoutTab==2 then return {{"Fireball","Rank 3","+8% / -16%"},{"Melee","Rank 3","+4%"}} end
 if index==5 then return {{"Amulet","Example"},{"Trinket 1","Example"},{"Trinket 2","Example"},{"Ring 1","Example"},{"Ring 2","Example"}} end
 if index==6 then return {{"Damage","+120%"},{"Haste","+30%"},{"Crit Chance","25%"},{"Lifesteal","3%"}} end
 if index==7 then return {{"Gold","640"},{"Chest price","86"},{FieldKit_L("Next").." · "..FieldKit_L("Chest price"),"720"}} end
 if index==8 then return {{"Player A",42000,1400,.4},{"Player B",31500,1050,.3},{"Player C",21000,700,.2},{"Player D",10500,350,.1}} end
 if index>=9 and index<=12 then return {{"Health",hp,.55},{"Mana","65 / 100",.65},{"Damage / DPS","42000 / 1400"}} end
 if index==13 then
  local rows={}
  if FieldKitRebornDB.effectTotems then table.insert(rows,{"Totems","2  /  12s"}) end
  if FieldKitRebornDB.effectSummons then table.insert(rows,{"Summons","3  /  24s"}) end
  if FieldKitRebornDB.effectTimers then table.insert(rows,{"Effects","8s"}) end
  if table.getn(rows)==0 then table.insert(rows,{"Filters","No categories selected"}) end
  return rows
 end
 if index==14 then return {{"You are down","Player B"},{"Revived by","65%",.65}} end
 if index==15 then return {{"Next boss","1:24"},{"Stored level-ups","3"}} end
 local rows={}
 if FieldKitRebornDB.mechanicWarnings then table.insert(rows,{"Mechanic banner messages","Move away"}) end
 if FieldKitRebornDB.bossBannerWarnings then table.insert(rows,{"Boss banner messages","Next boss"}) end
 if table.getn(rows)==0 then table.insert(rows,{"Filters","No categories selected"}) end
 return rows
end

function P.Render(index)
 local f=P.Frame(index);local source=getglobal(P.names[index])
 if index>=P.playerIndex then
  local player=index==P.playerIndex
  local mode=player and FieldKitRebornDB.playerHealthMode or FieldKitRebornDB.targetHealthMode
  f.health:SetWidth(player and FieldKitPlayerBar:GetWidth() or 180)
  f.health:SetMinMaxValues(0,12200);f.health:SetValue(6705)
  f.hp:SetText(FieldKit_FormatHealth(6705,12200,mode));FieldKit_Text(f.title,"Preview — sample data")
  f.healthInfo:SetText((player and FieldKit_L("Player") or FieldKit_L("Target")).."  ·  "..FieldKit_FormatHealth(6705,12200,mode))
  f.targetInfo:SetText(player and FieldKit_L("Shield").."  2,440  ·  "..FieldKit_L("Buffs").."  3" or FieldKit_L("Target").."  55%")
  f.shield:SetWidth(f.health:GetWidth()*.2)
  if player and FieldKitRebornDB.playerShield then f.shield:Show() else f.shield:Hide() end
  for _,icon in ipairs(f.buffs) do if player and FieldKitRebornDB.playerBuffs then icon:Show() else icon:Hide() end end
 elseif index==P.bossIndex then
  f.name:SetText(FieldKit_L("Boss").." · "..FieldKit_L("Preview"))
  f.hp:SetText(FieldKit_FormatHealth(6705,12200,FieldKitRebornDB.bossHealthMode))
  f.bar:SetMinMaxValues(0,12200);f.bar:SetValue(6705);f.level:SetText("7")
  f.previewName:SetText(FieldKit_L("Boss").." · "..FieldKit_L("Preview").."  "..FieldKit_L("Level").." 7")
  f.previewHealth:SetText(FieldKit_FormatHealth(6705,12200,FieldKitRebornDB.bossHealthMode).."  (55%)")
  f.previewDetail:SetText(FieldKit_L("Shield").."  1,250  ·  3 debuffs")
  FieldKit_Text(f.tag,"Preview — sample data")
  local data=FieldKit_PortraitCatalog.feralas and FieldKit_PortraitCatalog.feralas["Brute gordunni"]
  f.portrait:SetTexture(data and "Interface\\AddOns\\AzerothFieldKitReborn\\Portraits\\"..data.key..".tga" or "Interface\\Icons\\INV_Misc_QuestionMark")
  local icons={"Spell_Shadow_ShadowWordPain","Ability_Rogue_Rupture","Spell_Frost_FrostShock"}
  for i=1,table.getn(f.debuffs) do
   local d=f.debuffs[i]
   if icons[i] then d:SetTexture("Interface\\Icons\\"..icons[i]);d:Show();d.time:SetText((i*3).."s");d.time:Show();d.count:SetText(i);d.count:Show()
   else d:Hide();d.time:Hide();d.count:Hide() end
  end
  -- Only one text renderer owns the fixture. Native boss fields and the old
  -- supplementary caption otherwise duplicate/cover the overlay and debuffs.
  f.name:Hide();f.hp:Hide();f.tag:Hide();f.previewDetail:Hide()
  local width=f:GetWidth()-120
  f.previewName:SetWidth(width);f.previewName:SetHeight(18)
  f.previewHealth:ClearAllPoints();f.previewHealth:SetPoint("TOPLEFT",f.previewOverlay,"TOPLEFT",104,-35)
  f.previewHealth:SetWidth(width);f.previewHealth:SetHeight(20);f.previewHealth:SetJustifyH("CENTER")
 else
  local rows=P.Rows(index);local size=FieldKitRebornDB.cardSizes[P.names[index]]
  local width=math.max(280,size and size.width or source:GetWidth())
  if index==2 or index==8 or index==3 then width=math.max(width,FieldKit.MeterWidth(FieldKitRebornDB.meterValues)) end
  -- All inspector cards use independent sample text. Live row widgets may be
  -- hidden/repositioned by HUD layout and must never suppress fixture data.
  local useSamples=true
  f:SetWidth(width);f:SetHeight(math.max(36+18*table.getn(rows),size and size.height or 0,94))
  for n=1,table.getn(f.sampleLines or {}) do
   local line=f.sampleLines[n]
   local d=useSamples and rows[n] or nil
   if d then
    line:SetWidth(width-20)
    local detail=P.Text(tostring(d[2]))
    if type(d[2])=="number" then
     detail=tostring(d[2])
     if type(d[3])=="number" then detail=detail.."  /  "..tostring(d[3]).." "..FieldKit_L(index==2 and FieldKitMeters.Mode()==2 and "hps" or "dps") end
    end
    line:SetText(P.Text(d[1]).."    "..detail)
    line:Show()
   else line:Hide() end
  end
  FieldKit_Text(f.title,"Preview");f.title:SetWidth(width*.28)
  FieldKit_Text(f.total,P.labels[index]);f.total:SetWidth(width*.6)
  for i=1,table.getn(f.rows) do
   local row=f.rows[i];local d=rows[i]
   if d then
    row:ClearAllPoints();row:SetPoint("TOPLEFT",f,"TOPLEFT",6,-22-(i-1)*math.min(32,(f:GetHeight()-28)/table.getn(rows)))
    row:SetPoint("TOPRIGHT",f,"TOPRIGHT",-6,-22-(i-1)*math.min(32,(f:GetHeight()-28)/table.getn(rows)))
    if row.sampleBonus then row.sampleBonus:SetWidth(width-24);row.sampleBonus:SetText(type(d[3])=="string" and d[3] or "+8%") end
    row:SetHeight(12);row.label:SetText(FieldKit_L(d[1]));row.value:Show()
    if type(d[2])=="number" then
     row.meterMode=nil
     FieldKit.UpdateMeterColumns(row,{name=d[1],dmg=d[2],dps=d[3],share=d[4]},FieldKitRebornDB.meterValues,width,index==2 and FieldKitMeters.Mode()==2 and FieldKit_L("hps") or nil)
    else
     if row.meterColumns then for j=1,3 do row.meterColumns[j]:Hide() end end
     row.meterMode=nil;row.label:ClearAllPoints();row.label:SetPoint("LEFT",row,"LEFT",3,0);row.label:SetWidth(width*.48);row.value:SetWidth(width*.45);row.value:SetText(FieldKit_L(d[2]));row.value:SetJustifyH("RIGHT")
    end
    row:SetValue(d[4] or (type(d[3])=="number" and d[3]) or 0)
    row:SetStatusBarColor(index==3 and .8 or .25,index==3 and .2 or .5,index==3 and .2 or .8,.55)
   end
   -- Lua's `useSamples and nil or rows[i]` always yields rows[i]. Keep the
   -- isolated row values current, but never paint a second copy of the text.
   row:Hide()
  end
  T.Update(f)
  -- Keep fixture labels above the native card artwork after theme updates.
  for n=1,table.getn(f.sampleLines) do
   if n<=table.getn(rows) then f.sampleLines[n]:Show() end
  end
 end
 -- Sample label is inside every frame's bounds. It cannot be cropped offscreen.
 if P.mode=="inspect" then
  f:SetParent(P.inspector);f:SetClampedToScreen(false)
  f:ClearAllPoints();f:SetPoint("TOPLEFT",P.inspector,"TOPLEFT",12,-144)
  local scale=math.min(1,(P.inspector:GetWidth()-24)/f:GetWidth(),260/f:GetHeight())
  f:SetScale(scale)
 else
  if not f.moving then f:SetScale(1);f.fieldkitCompositionScale=nil end
  local group=P.Group(index);local parent=group and P.Root(group) or UIParent
  f:SetParent(parent);f:SetClampedToScreen(not group)
  if not f.moving and not parent.moving then
   f:ClearAllPoints()
   if group then
    local a,b,c,x,y=source:GetPoint(1)
    if b==group then f:SetPoint(a,parent,c,x,y) else f:SetPoint("TOPLEFT",parent,"TOPLEFT",0,0) end
   else
    local a,b,c,x,y=source:GetPoint(1)
    if a then f:SetPoint(a,b,c,x,y) else f:SetPoint("CENTER",UIParent,"CENTER",0,0) end
   end
  end
 end
 f:Show()
end

-- Deterministic screen-space packing for examples only. Live anchors are read
-- as preferences; resolving collisions must never save a new gameplay layout.
function P.Pack(items,width,height,reserved,scale)
 local gap=12;local placed={reserved};local result={}
 for _,r in ipairs(reserved.extras or {}) do table.insert(placed,r) end
 local function free(x,y,w,h)
  if x<gap or y<gap or x+w>width-gap or y+h>height-gap then return false end
  for _,r in ipairs(placed) do
   if x<r.x+r.w+gap and x+w+gap>r.x and y<r.y+r.h+gap and y+h+gap>r.y then return false end
  end
  return true
 end
 for _,item in ipairs(items) do
  local w,h=item.w*scale,item.h*scale
  local xs,ys={gap,math.max(gap,width-gap-w),math.max(gap,math.min(width-gap-w,item.x))},
   {gap,math.max(gap,height-gap-h),math.max(gap,math.min(height-gap-h,item.y))}
  for _,r in ipairs(placed) do
   table.insert(xs,r.x+r.w+gap);table.insert(xs,r.x-w-gap)
   table.insert(ys,r.y+r.h+gap);table.insert(ys,r.y-h-gap)
  end
  local best,distance
  for _,x in ipairs(xs) do for _,y in ipairs(ys) do
   if free(x,y,w,h) then
    local d=(x-item.x)^2+(y-item.y)^2
    if not distance or d<distance then best={x=x,y=y,w=w,h=h,item=item};distance=d end
   end
  end end
  if not best then return end
  table.insert(placed,best);table.insert(result,best)
 end
 return result
end

function P.Compose()
 if not P.all then return end
 local width,height=UIParent:GetWidth(),UIParent:GetHeight()
 local ui=FieldKitUI;local dock=ui.dock
 local ds=math.min(1,(width-24)/560,(height-24)/172)
 dock:SetScale(ds);dock:ClearAllPoints();dock:SetPoint("TOP",UIParent,"TOP",0,-12/ds)
 dock:SetFrameStrata("TOOLTIP");dock:SetFrameLevel(200)
 for _,button in ipairs({ui.done,ui.groupLeft,ui.groupRight,ui.sizes,ui.otherUI}) do
  button:SetFrameStrata("TOOLTIP");button:SetFrameLevel(210);T.Update(button)
 end
 local reserved={x=(width-560*ds)/2,y=12,w=560*ds,h=172*ds}
 reserved.extras={}
 local parentScale=UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
 for i=1,2 do
  local a=getglobal("FieldKitCombatAnchor"..i)
  if a and a:IsShown() then
   if a.fieldkitMoving then return end
   local x,top=a:GetLeft(),a:GetTop()
   if x and top then
    local s=a:GetEffectiveScale()/parentScale
    table.insert(reserved.extras,{x=x*s,y=height-top*s,w=a:GetWidth()*s,h=a:GetHeight()*s})
   end
  end
 end
 local items,seen={},{}
 for i=1,table.getn(P.names) do
  local f=P.frames[i]
  if i<P.playerIndex and P.included[i] and f and f:IsShown() then
   local group=P.Group(i);local block=group and P.roots[group:GetName()] or f
   if block.moving or f.moving then return end
   if not seen[block] then
    seen[block]=true
    local s=block.GetEffectiveScale and block:GetEffectiveScale() or 1
    local parentScale=UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    local x,y=block:GetLeft(),block:GetTop()
    x=x and x*s/parentScale or width/2-block:GetWidth()/2
    y=y and height-y*s/parentScale or height/2-block:GetHeight()/2
    table.insert(items,{frame=block,x=x,y=y,w=block:GetWidth(),h=block:GetHeight()})
   end
  end
 end
 -- Keep preferred positions when possible. Only the presentation shrinks when
 -- all included examples cannot fit at full size on the current viewport.
 local key=width..":"..height..":"..ds
 for _,r in ipairs(reserved.extras) do key=key..":"..r.x..":"..r.y..":"..r.w..":"..r.h end
 for _,item in ipairs(items) do
  key=key..":"..tostring(item.frame)..":"..math.floor(item.x*100)..":"..math.floor(item.y*100)..":"..item.w..":"..item.h
 end
 local cached=P.composition
 local packed,scale
 if cached and cached.key==key then packed=cached.rects;scale=cached.scale
 else
  for step=0,15 do
   scale=1-step*.05;packed=P.Pack(items,width,height,reserved,scale)
   if packed then break end
  end
 end
 if not packed then return end
 for _,r in ipairs(packed) do
  local f=r.item.frame
  f:SetScale(scale);f.fieldkitCompositionScale=scale
  f:ClearAllPoints();f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",r.x/scale,-r.y/scale)
 end
 P.composition={key=key,rects=packed,reserved=reserved,scale=scale,width=width,height=height}
end

-- Compose selected grouped examples with their sample heights, including modules
-- disabled in the real HUD. Native grouping anchors and visibility stay intact.
function P.Stack(first,last,source)
 local root=source and P.roots[source:GetName()]
 if not root then return end
 local y,width=0,1
 for i=first,last do
  local f=P.frames[i]
  if P.included[i] and f and f:IsShown() then
   if not root.moving then f:ClearAllPoints();f:SetPoint("TOPLEFT",root,"TOPLEFT",0,-y) end
   y=y+f:GetHeight()+6;width=math.max(width,f:GetWidth())
  end
 end
 root:SetWidth(width);root:SetHeight(math.max(1,y-6))
end

function P.Refresh()
 if not P.mode then return end
 -- Keep the entire composition steady while a scaled proxy is held. A native
 -- renderer tick must not reset its scale or move the other examples back.
 if P.mode=="place" then
  for _,f in pairs(P.frames) do if f.moving then FieldKitPreviewVisibility.Update();return end end
  for _,root in pairs(P.roots) do if root.moving then FieldKitPreviewVisibility.Update();return end end
 end
 for i=1,table.getn(P.names) do
  if (P.all and i<P.playerIndex and P.included[i]) or (not P.all and i==P.selected) then P.Render(i)
  elseif P.frames[i] then P.frames[i]:Hide() end
 end
 if P.all then
  if FieldKitRebornDB.linkLeftCards then P.Stack(1,4,FieldKitHudStack.root) end
  if FieldKitRebornDB.linkRightCards then P.Stack(5,6,FieldKitCardLayout.root) end
  P.Compose()
 end
 FieldKitPreviewVisibility.Update()
 if P.inspector then
  local health=P.selected>=P.playerIndex
  FieldKit_Text(P.inspector.place,health and "Preview only" or "Place this window")
  FieldKit_Text(P.inspector.reset,health and "No position to reset" or P.Group(P.selected) and "Ungroup to reset" or "Reset this window position")
  if health then P.inspector.place:Disable() else P.inspector.place:Enable() end
  if health or P.Group(P.selected) then P.inspector.reset:Disable() else P.inspector.reset:Enable() end
  if P.inspector.help then
   FieldKit_Text(P.inspector.help,health and "Health preview only; drag the active player bar directly" or "Examples only. No combat data is recorded or shared.")
  end
 end
end

-- Stop is idempotent and also finishes a drag interrupted by Escape/Done.
function P.Stop()
 for _,f in pairs(P.frames) do
  if f.moving then P.Drag(f,false) end
  f:Hide()
 end
 for _,root in pairs(P.roots) do
  if root.moving then root:StopMovingOrSizing();root.moving=nil;P.Commit(root,root.source) end
 end
 P.mode=nil;P.all=nil;FieldKitPreviewVisibility.Clear()
 if P.inspector then
  P.inspector.choice.menu:Hide();P.inspector:StopMovingOrSizing();P.inspector:Hide()
 end
end

function P.Start(all)
 P.Stop();if FieldKitZoneThemes then FieldKitZoneThemes.Suspend() end;P.mode="place";P.all=all;P.Refresh()
end

function P.Reset()
 if P.Group(P.selected) then return end
 if P.selected>=P.playerIndex then return end
 local source=getglobal(P.names[P.selected]);local d=source and source.azsDefault
 if not d then return end
 FieldKitRebornDB.frameAnchors[source:GetName()]=nil;FieldKitRebornDB.pos[source:GetName()]={d[1],d[2]}
 if source==FieldKitMoneyFrame then FieldKitRebornDB.moneyDetached=true end
 P.place(source);P.Refresh()
end

-- One reusable inspector, intentionally independent of module enable flags.
-- Closing it never changes a preference or closes the normal settings panel.
function P.Open(index)
 if type(index)=="string" then
  local found
  for i,name in ipairs(P.names) do if name==index then found=i;break end end
  if not found then return false end
  index=found
 end
 if FieldKit.layoutEditing then FieldKitUI.SetLayoutEditing(false,true) end
 P.Stop();if FieldKitZoneThemes then FieldKitZoneThemes.Suspend() end;P.selected=index or P.selected
 if not P.inspector then
  local f=CreateFrame("Frame","FieldKitPreviewInspector",UIParent);P.inspector=f
  f:SetWidth(440);f:SetHeight(510);f:SetFrameStrata("DIALOG");f:SetFrameLevel(125)
  f:SetMovable(true);f:SetClampedToScreen(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton");T.Surface(f,"window")
  f:SetScript("OnDragStart",function() f:StartMoving() end);f:SetScript("OnDragStop",function() f:StopMovingOrSizing() end)
  T.Label(f,"Preview — sample data",12,12,390,28,18,T.gold,true)
  f.help=T.Label(f,"Examples only. No combat data is recorded or shared.",12,43,410,32,12,T.muted)
  local x=CreateFrame("Button",nil,f,"UIPanelCloseButton");f.close=x;x:SetWidth(24);x:SetHeight(24);x:SetPoint("TOPRIGHT",f,"TOPRIGHT",-4,-4);x:SetScript("OnClick",P.Stop)
  f.choice=FieldKitUI.Choice(f,"FieldKitPreviewChoice","Test display",12,90,416,P.labels,function() return P.selected end,function(v) P.selected=v;if v<=table.getn(FieldKitCardLayout.names) then FieldKitCardLayout.selected=v;FieldKitUI.Refresh() end;P.Refresh() end,P.Refresh)
  f.include=CreateFrame("CheckButton",nil,f,"UICheckButtonTemplate");f.include:SetWidth(24);f.include:SetHeight(24);f.include:SetPoint("TOPLEFT",f,"TOPLEFT",12,-414)
  T.Label(f,"Include in interface composition",42,414,380,24,12)
  f.include:SetScript("OnClick",function() if P.selected<P.playerIndex then P.included[P.selected]=this:GetChecked() and true or false else this:SetChecked(false) end end)
  f.place=T.Button(f,nil,"Place this window",12,448,202,26,function() if P.selected<P.playerIndex then FieldKitUI.SetLayoutEditing(true,false);P.Start(false) end end)
  f.reset=T.Button(f,nil,"Reset this window position",12,480,416,24,P.Reset)
  f.all=T.Button(f,nil,"Compose interface",226,448,202,26,function() FieldKitUI.SetLayoutEditing(true,false) end)
  local elapsed=0
  f:SetScript("OnUpdate",function() elapsed=elapsed+(arg1 or 0);if elapsed<.15 then return end;elapsed=0
   if P.mode=="inspect" then P.Refresh();f.choice.Refresh();f.include:SetChecked(P.included[P.selected]) end
  end)
  f:SetScript("OnHide",function() if P.mode=="inspect" then P.Stop() end end)
  if type(UISpecialFrames)=="table" then table.insert(UISpecialFrames,"FieldKitPreviewInspector") end
 end
 local f=P.inspector
 for _,control in ipairs({f.close,f.choice,f.include,f.place,f.reset,f.all}) do control:SetFrameLevel(140);T.Update(control) end
 f:ClearAllPoints();f:SetPoint("TOPLEFT",FieldKitUI.frame,"TOPRIGHT",8,0)
 f:SetScale(math.min(1,UIParent:GetWidth()/480,UIParent:GetHeight()/540));f:Show()
 P.mode="inspect";P.all=false;f.choice.Refresh();f.include:SetChecked(P.included[P.selected]);P.Refresh()
end
