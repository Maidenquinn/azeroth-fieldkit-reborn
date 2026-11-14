-- Native jewelry additions are deltas, not percentages of the final stat.
-- Never divide them by totals or infer per-item shares from the aggregate.
FieldKitRebornStats={}
local S=FieldKitRebornStats
function S.DotValue(value)
 local n=FieldKit.Number(value);if not n then return "?" end
 if math.abs(n)<.0005 then n=0 end
 local text=string.gsub(string.format("%.3f",n),"0+$","")
 return string.gsub(text,"%.$","")
end
local defs={
 {"hp","Health",false},{"dmg","Damage",true},{"cd","Cooldown",true},
 {"crit","Crit Chance",true},{"cm","Crit Dmg",true},{"arm","Armor",true},
 {"area","Area",true},{"cnt","Targets",false},{"echo","Echo",true},
 {"spd","Speed",true},{"reg","Regen",false},{"pick","Pickup",false},
 {"lch","Lifesteal",true},{"heal","Kill Heal",false},{"thn","Thorns",true},
 {"liv","Lives",false},{"xp","Experience",true},{"gold","Gold",true},
 {"luck","Luck",true},{"bp","Buff Power",true},{"dots","DoT Stacks",false},
 {"doth","DoT Haste",true},{"auto","Melee",true},{"pet","Pet Damage",true}}
function S.Lines(key)
 local out={};local data=type(AZS_STATS)=="table" and AZS_STATS or {}
 if FieldKit.rebornLegacyFixture or (type(AZS_GetPhase)=="function" and not AZS_GetPhase()) then return out end
 if key=="haste" then key="cd" end
 for _,def in ipairs(defs) do
  if not key or key==def[1] then
   local value=FieldKit.Number(data["g"..def[1]])
   if value then
    local text=def[3] and FieldKit.FormatPercent(value,true) or ((value>=0 and "+" or "")..(def[1]=="dots" and S.DotValue(value) or FieldKit.FormatBonus(value)))
    table.insert(out,FieldKit_L("From worn jewelry").." · "..FieldKit_L(def[2])..": "..text)
   end
  end
 end
 for _,def in ipairs({{"dots","DoT Stacks",false},{"doth","DoT Haste",true},{"dotd","Vs Afflicted",true}}) do
  if not key or key==def[1] then
   local value=FieldKit.Number(data[def[1]])
   if value then table.insert(out,FieldKit_L(def[2])..": "..(def[3] and FieldKit.FormatPercent(value,true) or S.DotValue(value))) end
  end
 end
 return out
end
function S.Tip(owner,key)
 local lines=S.Lines(key)
 if table.getn(lines)==0 then return false end
 GameTooltip:SetOwner(owner,"ANCHOR_LEFT")
 GameTooltip:SetText(FieldKit_L("Jewelry and DoT bonuses"),1,.82,.3)
 for _,line in ipairs(lines) do GameTooltip:AddLine(line,.85,.9,.8,true) end
 GameTooltip:AddLine(FieldKit_L("Native jewelry additions; already included in character totals."),.7,.7,.7,true)
 if not key or key=="dots" then GameTooltip:AddLine(FieldKit_L("DoT stacking is a character stat, not the current stacks on a target."),.7,.7,.7,true) end
 GameTooltip:Show();return true
end
