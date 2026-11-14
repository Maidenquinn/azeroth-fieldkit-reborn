fire(FieldKitFrame,"VARIABLES_LOADED")
local R,D=FieldKitReborn,FieldKitPartyDetails
NOW=100;AZS_RUN={ph="playing",t=20};AZS_BUFFS_UPDATED=100
AZS_L={['Rapid Fire']='Tir rapide',['Divine Shield']='Bouclier divin',['Surge of Strength']='Afflux de force'}
AZS_BUFFS={{spell=3045,left=9},{spell=642,left=1}}
GetSpellInfo=function(id) if id==3045 then return 'Rapid Fire',nil,'RapidIcon' else return 'Divine Shield',nil,'ShieldIcon' end end
UnitAura=function(unit,index,filter)
 assert(unit=='player' and filter=='HELPFUL')
 if index==1 then return 'Rapid Fire',nil,'RapidIcon',1,nil,10,109,nil,nil,nil,3045 end
 if index==2 then return 'Surge of Strength',nil,'StrengthIcon',3,nil,10,103,nil,nil,nil,999 end
end
FieldKitNative.Watch();FieldKitNative.Packet('AZSBUFFS')
local buffs=R.PlayerBuffs();assert(table.getn(buffs)==3,'Proc omitted or duplicate spell buff')
assert(buffs[1].name=='Tir rapide' and buffs[2].name=='Afflux de force' and buffs[2].count==3 and buffs[2].remaining==3)
local rows={};FieldKitNativeTools.Buffs(rows)
assert(rows[2].label=='Afflux de force' and string.find(rows[2].value,'3x',1,true))
NOW=104;buffs=R.PlayerBuffs();assert(table.getn(buffs)==1 and buffs[1].name=='Tir rapide','Expired native effects remained')
-- Full aura snapshots remain usable while the retained spell-buff packet is fenced.
local fresh=FieldKitNative.Fresh;FieldKitNative.Fresh=function() return false end
assert(table.getn(R.PlayerBuffs())==1)
FieldKitNative.Fresh=fresh
D.Build();D.data={name='Tester',own=true,mode=1,damage=100,dps=10,rows={{name='Spell',dmg=100,hits=2,crits=1,maxCrit=70}}};D.Render()
local function Check(cap)
 assert(cap:IsMouseEnabled() and cap.cap:IsShown() and cap.cap:GetText()~='')
 assert(cap.cap:GetParent()==D.headerLabels and cap.cap:GetWidth()==cap:GetWidth() and cap.cap:GetHeight()==18)
 assert(cap.fontString==nil,'Header delegated to native Button font renderer')
end
Check(D.spell)
for _,cap in ipairs(D.hitCaptions) do Check(cap) end
assert(D.headerLabels:GetFrameLevel()>D.spell:GetFrameLevel() and not D.headerLabels:IsMouseEnabled())
D.data.mode=2;D.Render()
for _,cap in ipairs(D.captions) do Check(cap) end
for _,cap in ipairs(D.hitCaptions) do assert(not cap.cap:IsShown()) end
D.data.mode=1;D.Render();for _,cap in ipairs(D.hitCaptions) do Check(cap) end
click(D.hitCaptions[2]);assert(D.sortKey=='maxCrit','Detached header text broke sorting')
AZS_ZONE={zone='naxx',zname='Naxxramas',heroic=0}
AZS_UNITS={{kind='boss',id=901,name='Le Recousu',hp=700,hpm=1000}}
FieldKitRebornDB.zoneThemeMode='elwynn';FieldKitRebornDB.bossFrame=true
for _,variant in ipairs({'minimal','complete','alternative'}) do
 FieldKitRebornDB.zoneThemeVariant=variant;FieldKitZoneThemes.Set('zoneThemes',true)
 local c=FieldKitBossFrame1.compact
 c.bar:SetFrameStrata('LOW');c.bar:SetAlpha(0);c.bar:Hide()
 update(FieldKitFrame,.3)
 assert(c:IsShown() and c.bar:IsShown() and c.bar:GetAlpha()==1)
 assert(c.bar:GetFrameStrata()==c:GetFrameStrata() and c.bar:GetFrameLevel()>c:GetFrameLevel(),'Boss HP behind themed material')
 assert(c.bar:GetValue()==700 and c.bar:GetHeight()>0 and c.hp:IsShown() and c.hp:GetHeight()>0 and c.hp:GetText()~='','Boss HP data/geometry missing')
 FieldKitZoneThemes.Set('zoneThemes',false)
end
print('PASS live proc + retained spell buff merge, French native labels, deduplication, expiry/freshness, and explicit independent damage/healing header geometry, visibility and sorting')
