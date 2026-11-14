fire(FieldKitFrame,"VARIABLES_LOADED")
local L,C,V=FieldKitLoadout,FieldKitZoneThemes,FieldKitReferenceHUD
local names={'Auto Shot','Aimed Shot','Freezing Trap','Rapid Fire','Concussive Shot',"Hunter's Mark"}
local translated={'Tir automatique','Visée','Piège de givre','Tir rapide','Trait de choc','Marque du chasseur'}
local keys={'auto_shot','aimed_shot','freezing_trap','rapid_fire','concussive_shot','hunters_mark'}
AZS_L={};AZS_SPELLS={};local sources,abilities={},{}
for i=1,6 do
 AZS_L[names[i]]=translated[i]
 AZS_SPELLS[i]={key=keys[i],spell=100+i,rank=i}
 sources[keys[i]]={abilityKey=keys[i],name=names[i],spellIds={100+i},icon={path='Interface\\Icons\\Spell'..i}}
 abilities[i]={sourceKey=keys[i],learned=true,rank=i}
end
AZS_GetMeterContext=function() return {runId='locale-test'} end
AZS_GetMeterLoadout=function() return {sources=sources,abilities=abilities} end
AZS_ZONE={zone='naxx',zname='Naxxramas',heroic=0};AZS_RUN={ph='playing',t=30}
GetSpellInfo=function(id) return names[id-100],nil,'Interface\\Icons\\Spell'..(id-100) end
HasAction=function(slot) return slot<=6 end
GetActionTexture=function(slot) return 'Interface\\Icons\\Spell'..slot end
L.tip:SetScript('OnShow',nil)
L.tip.SetAction=function(_,slot)
 local fs=getglobal('FieldKitLoadoutScanTextLeft1') or CreateFrame('FontString','FieldKitLoadoutScanTextLeft1')
 fs:SetText(names[slot])
end
L.tip.NumLines=function() return 1 end
AZS_GEAR={{slot='amulet',name='Varech',amount=3,text="+79.9% de chance · +66.6% d'or",icon='Gear1'},
 {slot='trinket',name='Talisman',text='+201.1% de dégâts critiques',icon='Gear2'}}
FieldKitNative.Watch();FieldKitNative.Packet('AZSSPELLS');FieldKitNative.Packet('AZSGEAR')
L.scanAt=0;L.Scan()
for i,e in ipairs(L.spells) do
 assert(e.name==translated[i],'Native raw name overwrote translation: '..keys[i])
 assert(L.Icon(names[i])==e.icon and L.Icon(translated[i])==e.icon,'Name alias icon lookup lost')
end
FieldKitRebornDB.zoneThemeMode='elwynn';FieldKitRebornDB.zoneThemeVariant='complete';FieldKitRebornDB.loadoutTab=1
C.Set('zoneThemes',true);C.Refresh()
local card=V.frames.Accessories;assert(card:IsShown())
for i=1,2 do local row=card.rows[i]
 assert(row.bonus and row.bonus:IsShown() and row.bonus:GetText()~='','Themed equipment bonus absent')
 local _,_,_,_,y=row.bonus:GetPoint()
 assert(-y>=row.label:GetHeight() and -y+row.bonus:GetHeight()<=row:GetHeight(),'Bonus overlaps name or next socket')
 assert(row.bonus:GetWidth()<=row:GetWidth())
 assert(row.bonus.referenceFullText==table.concat(row.entry.nativeDetails,' · '),'Native bonus text rewritten')
end
for i=1,6 do card.rows[i].value.SetJustifyV=function(self,value) self.testJustifyV=value end end
FieldKitRebornDB.loadoutTab=2;C.Refresh()
for i=1,6 do local row=card.rows[i]
 assert(row.entry.name==translated[i])
 assert(row.value.testJustifyV=='MIDDLE','Equipment rank alignment leaked into spell tab')
 assert(not row.bonus or not row.bonus:IsShown(),'Equipment bonus leaked into spell tab')
end
FieldKitRebornDB.loadoutTab=1;C.Refresh();assert(card.rows[1].bonus:IsShown())
AZS_GEAR={};L.scanAt=0;L.Scan();C.Refresh()
assert(not card.rows[1].bonus:IsShown(),'Empty equipment slot retained previous bonus')
print('PASS six hunter names localised after structured API, GetSpellInfo and action-tooltip overrides; English/French icon aliases; Elwynn native inline bonuses, bounded socket geometry and gear/spell/empty transitions')
