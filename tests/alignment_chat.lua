-- Edit access must not opt the user into chat styling or message collection.
fire(FieldKitFrame,"VARIABLES_LOADED")
SlashCmdList.FieldKit("")
local G,d=FieldKitAlignment,FieldKitRebornDB
ChatFrame1=CreateFrame("Frame","ChatFrame1",UIParent)
ChatFrame1:SetWidth(440);ChatFrame1:SetHeight(180);ChatFrame1:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",30,90)
ChatFrame1.left=30;ChatFrame1.bottom=90
function ChatFrame1:IsMovable() return self.movable==true end
function ChatFrame1:SetMovable(v) self.movable=v end
local function fireOn(f,event) local old=this;this=f;f:GetScript(event)();this=old end
-- Upgrade old profiles before editing can turn on independent chat placement.
d.chatStyle=false;d.chatMove=false;assert(FieldKitProfiles.Save(1));assert(FieldKitProfiles.Save(2))
for i=1,2 do local p=d.interfaceProfiles[i];p.values.chatPositioned=nil;p.nilValues.chatPositioned=nil end
G.Start()
for i=1,2 do assert(d.interfaceProfiles[i].values.chatPositioned==false) end
G.Stop()
for _,styled in ipairs({false,true}) do for _,unlocked in ipairs({false,true}) do
 d.chatStyle=styled;d.chatMove=unlocked;d.chatCopy=false;d.chatPositioned=false
 FieldKit.ApplyChatStyle();local shown=styled and unlocked
 local before={ChatFrame1:GetPoint()}
 assert((FieldKitChatMoveHandle and FieldKitChatMoveHandle:IsShown() or false)==shown)
 local width,height=ChatFrame1:GetWidth(),ChatFrame1:GetHeight()
 G.Start();assert(FieldKitChatMoveHandle:IsShown())
 assert(d.chatStyle==styled and d.chatMove==unlocked and not d.chatCopy)
 fireOn(FieldKitChatMoveHandle,'OnDragStart');assert(ChatFrame1.azsMoving and ChatFrame1:IsMovable())
 -- Repeated native chat watcher passes cannot end an editor drag with style off.
 FieldKit.ApplyChatStyle();FieldKit.ApplyChatStyle();assert(ChatFrame1.azsMoving)
 ChatFrame1.left=210;ChatFrame1.bottom=150
 G.Stop() -- Finish a held drag before removing temporary editing access.
 assert(not ChatFrame1.azsMoving and not ChatFrame1:IsMovable())
 assert(d.chatAnchor.x==210 and d.chatAnchor.y==150 and d.chatPositioned)
 assert(d.chatStyle==styled and d.chatMove==unlocked and not d.chatCopy)
 assert(FieldKitChatMoveHandle:IsShown()==shown)
 assert(ChatFrame1:GetWidth()==width and ChatFrame1:GetHeight()==height)
 FieldKit.ApplyChatStyle()
 if not styled then
  local a={ChatFrame1:GetPoint()};assert(a[1]=='BOTTOMLEFT' and a[4]==210 and a[5]==150)
  d.chatPositioned=false;d.chatAnchor=nil;FieldKit.ApplyChatStyle()
  a={ChatFrame1:GetPoint()};assert(a[1]==before[1] and a[4]==before[4] and a[5]==before[5],'Native position leaked after releasing ownership')
 end
end end
-- Preview editing also provides temporary access and yields it on Done.
d.chatStyle=false;d.chatMove=false
FieldKitUI.SetLayoutEditing(true,false);assert(FieldKitChatMoveHandle:IsShown())
FieldKitUI.SetLayoutEditing(false,false);assert(not FieldKitChatMoveHandle:IsShown())
-- A separate profile cannot inherit the editor or its moved native position.
d.chatPositioned=true;d.chatAnchor={x=210,y=150};assert(FieldKitProfiles.Save(1));d.chatPositioned=false;d.chatAnchor=nil;assert(FieldKitProfiles.Save(2))
assert(FieldKitProfiles.Load(1));assert(d.chatPositioned and d.chatAnchor.x==210)
assert(FieldKitProfiles.Load(2));assert(not d.chatPositioned and not d.chatAnchor)
-- Reset clears the independently positioned native anchor too.
d.chatPositioned=true;FieldKit.ResetChatPosition();assert(not d.chatPositioned)
print('PASS chat editor: temporary unlock independent of style/copy, watcher-safe drag, Done finishes and restores lock, native position retention, profile isolation and reset')
