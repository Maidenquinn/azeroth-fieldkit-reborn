-- Reborn loads SavedVariables after addon chunks. Restore only an explicit
-- editor anchor; styling/copy remain disabled and no editor is reopened.
FieldKitRebornDB={chatStyle=false,chatMove=false,chatCopy=false,chatPositioned=true,chatAnchor={x=210,y=150}}
ChatFrame1=CreateFrame("Frame","ChatFrame1",UIParent)
ChatFrame1:SetWidth(440);ChatFrame1:SetHeight(180);ChatFrame1:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",30,90)
fire(FieldKitFrame,"VARIABLES_LOADED")
local oldThis,oldArg=this,arg1;this=FieldKitChatWatcher;arg1=.3;FieldKitChatWatcher:GetScript("OnUpdate")();this=oldThis;arg1=oldArg
local a={ChatFrame1:GetPoint()};assert(a[1]=="BOTTOMLEFT" and a[4]==210 and a[5]==150)
local d=FieldKitRebornDB
assert(not d.chatStyle and not d.chatCopy and not d.chatMove and not FieldKitAlignment.active)
assert(not FieldKitChatMoveHandle:IsShown())
assert(FieldKitProfiles.Save(1))
d.chatPositioned=false;d.chatAnchor=nil;FieldKit.ApplyChatStyle()
a={ChatFrame1:GetPoint()};assert(a[4]==30 and a[5]==90)
assert(FieldKitProfiles.Save(2));assert(FieldKitProfiles.Load(1))
a={ChatFrame1:GetPoint()};assert(a[4]==210 and a[5]==150)
assert(FieldKitProfiles.Load(2));a={ChatFrame1:GetPoint()};assert(a[4]==30 and a[5]==90)
print("PASS native chat editor anchor: reload restoration, normal lock retained and physical profile isolation")
