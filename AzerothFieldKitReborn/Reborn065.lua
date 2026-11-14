-- Optional 0.6.5 presentation adapters. No attack timing or immunity is inferred.
FieldKitReborn065={}
local Q=FieldKitReborn065
function Q.Control(id)
 if not id or type(AZS_GetDebuffs)~="function" then return nil end
 local ok,list=pcall(AZS_GetDebuffs,id)
 if not ok or type(list)~="table" then return nil end
 local names={"Stun immune","Stunned","Rooted"}
 for _,name in ipairs(names) do
  for i=1,math.min(64,table.getn(list)) do
   local d=list[i]
   if type(d)=="table" and (d.name==name or d.name==FieldKitReborn.Localize(name)) then
    local remaining=FieldKit.Number(d.remaining,nil,0)
    if d.permanent==true or (remaining and remaining>0) then
     return {name=FieldKitReborn.Localize(name),remaining=remaining,icon=d.icon}
    end
   end
  end
 end
end
function Q.ControlText(id)
 local state=Q.Control(id)
 if not state then return nil end
 return state.name..(state.remaining and (" · "..string.format("%.1fs",state.remaining)) or "")
end
function Q.BossStatus(frame,id,enraged)
 if FieldKit.rebornLegacyFixture then return end
 local text=Q.ControlText(id)
 local label=frame.compact and frame.compact:IsShown() and frame.compact.tag or frame.tag
 if not label then return end
 if not text and frame.fieldkitControlWidths then
  frame.compact.name:SetWidth(frame.fieldkitControlWidths[1]);frame.compact.tag:SetWidth(frame.fieldkitControlWidths[2]);frame.fieldkitControlWidths=nil
 end
 if text then
  if enraged then text=FieldKit_L("ENRAGED").." · "..text end
  if label~=frame.tag and not frame.fieldkitControlWidths then frame.fieldkitControlWidths={frame.compact.name:GetWidth(),label:GetWidth()} end
  label:SetWidth(label==frame.tag and math.max(100,frame:GetWidth()-120) or 170);label:SetText(text)
  if label~=frame.tag and frame.compact.name then frame.compact.name:SetWidth(120) end
 elseif label==frame.tag then label:SetWidth(90) end
end
-- Forward the real native cast element (including its handlers and protected
-- cast styling) rather than manufacturing a second cast/immunity timer.
function Q.NativeCastbar()
 local native=getglobal("AzerothSurvivorsUnitFrameTarget")
 return (native and native.Castbar) or getglobal("TargetFrameSpellBar")
end
function Q.RestoreCastbar()
 local f=Q.castbar
 if f and Q.castOwner then
  if f:GetParent()==Q.castOwner then FieldKitThemeHUD.RestoreOne(f) else FieldKitThemeHUD.saved[f]=nil end
 end
 Q.castbar=nil;Q.castOwner=nil
end
function Q.MoveCastbar(owner)
 local f=Q.NativeCastbar()
 if not f or not owner then Q.RestoreCastbar();return end
 local native=getglobal("AzerothSurvivorsUnitFrameTarget")
 local parent=f:GetParent()
 if parent~=native and parent~=UIParent and parent~=Q.castOwner then return end
 if Q.castbar and Q.castbar~=f then Q.RestoreCastbar() end
 FieldKitThemeHUD.Save(f);Q.castbar=f;Q.castOwner=owner
 f:SetParent(owner);FieldKitThemeHUD.Anchor(f,"TOP",owner,"BOTTOM",0,-6,true)
 f:SetWidth(math.max(160,math.min(284,owner:GetWidth()-24)))
end
-- Native death log is a versioned compatibility source, not a claimed public
-- AZS_Get* API. Read only in the ended run, and bound every exposed field.
function Q.KillingBlow()
 local phase=FieldKitNative.Read("AZS_GetPhase")
 if phase~="dead" then return nil end
 local data=type(AZS_DEATH)=="table" and AZS_DEATH.hits
 if type(data)~="table" then return nil end
 local n=table.getn(data);if n<1 or n>256 then return nil end
 local hit=data[n]
 if type(hit)~="table" or FieldKit.Number(hit.health)~=0 then return nil end
 local amount=FieldKit.Number(hit.amount,nil,0);if not amount then return nil end
 local over=FieldKit.Number(hit.over,nil,0)
 local spell=FieldKit.Number(hit.spell,nil,0)
 local name,icon
 if spell and spell>0 and type(GetSpellInfo)=="function" then
  local ok,a,b,c=pcall(GetSpellInfo,spell);if ok then name=a;icon=c end
 elseif spell==0 then name=FieldKit_L("Melee");icon="Interface\\Icons\\Ability_MeleeDamage" end
 return {name=FieldKitNative.Text(name or FieldKit_L("Unidentified source")),icon=FieldKitReborn.Icon(icon),
  source=FieldKitNative.Text(hit.from or FieldKit_L("Unidentified source")),amount=amount,overkill=over,
  total=over and amount+over or amount}
end
function Q.OpenDeathLog()
 local callback=SlashCmdList and SlashCmdList.AZSDEATHLOG
 if type(callback)~="function" then return false end
 local ok=pcall(callback,"")
 if ok and FieldKitUI and FieldKitUI.frame and FieldKitUI.frame:IsShown() then FieldKitUI.frame:Hide() end
 return ok
end
function Q.DeathTip(owner)
 GameTooltip:SetOwner(owner,"ANCHOR_TOP");GameTooltip:SetText(FieldKit_L("Native death log"))
 local h=Q.KillingBlow()
 if h then
  GameTooltip:AddLine(h.name.." · "..h.source,1,.82,.3,true)
  GameTooltip:AddLine(FieldKit_L("Damage")..": "..tostring(h.total),1,1,1)
  if h.overkill then GameTooltip:AddLine(FieldKit_L("Overkill")..": "..tostring(h.overkill),1,.4,.3) end
 else GameTooltip:AddLine(FieldKit_L("Open the game's last blows and killing-blow card."),.8,.8,.8,true) end
 GameTooltip:Show()
end

-- Preserve complete native proc descriptions for jewelry tooltips. Compact
-- numeric rows remain separate so long trigger text cannot bloat HUD cards.
function Q.JewelryDetails(text)
 local out={};text=FieldKitNative.Text(text,2048)
 local at=1
 while at<=string.len(text) and table.getn(out)<16 do
  local finish=string.find(text," · ",at, true) or string.len(text)+1
  local part=string.gsub(string.gsub(string.sub(text,at,finish-1),"^%s+",""),"%s+$","")
  if part~="" then table.insert(out,part) end
  at=finish+4
 end
 return out
end
