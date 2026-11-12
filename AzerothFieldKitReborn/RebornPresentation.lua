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
 for _,f in ipairs(R.counterCells or {}) do f:Hide() end
 if R.counterCover then R.counterCover:Hide() end
 if R.hordeFrame then R.hordeFrame:Hide() end
 if R.sixPlate then R.sixPlate:Hide() end
 if R.steedPending then R.steedPending:Hide() end
 for _,f in ipairs(R.sixSlots or {}) do f:Hide() end
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
