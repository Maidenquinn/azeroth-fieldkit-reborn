fire(FieldKitFrame,"VARIABLES_LOADED")
local d,R,C,U=FieldKitRebornDB,FieldKitReferenceHUD,FieldKitZoneThemes,FieldKitUI
ChatFrame1=CreateFrame("ScrollingMessageFrame","ChatFrame1",UIParent)
local c=ChatFrame1;local messages={}
local width,height=c.SetWidth,c.SetHeight
c.AddMessage=function(self,text,r,g,b,id)
 table.insert(messages,{text,r,g,b,id});if #messages>3 then table.remove(messages,1) end
 return "ok",nil,"native-return"
end
c.Clear=function() messages={} end
c.GetNumMessages=function() return #messages end
c.GetMessageInfo=nil -- installed Reborn does not provide retrospective reading
c.SetWidth=function(self,n) width(self,n);self:Clear() end
c.SetHeight=function(self,n) height(self,n);self:Clear() end
c:SetWidth(499);c:SetHeight(176)
AZS_ZONE={zone="elwynn",class="hunter"};AZS_RUN={ph="playing",t=30}
AZS_GetPhase=function() return "playing" end
d.chatStyle=false;d.chatCopy=false;C.Set("zoneThemes",true)
FieldKit.SyncChat()
c:AddMessage("wrapped native message A",1,.8,0)
c:AddMessage("wrapped native message B",.2,.7,.8)
-- A watcher tick must keep the render journal while the theme owns native chat,
-- even when the optional custom appearance checkbox is disabled.
FieldKit.SyncChat()
assert(FieldKit.ResizeChatPreservingHistory(360,160))
assert(#messages==2 and messages[1][1]=="wrapped native message A")
local sections={{title="Interface",items={}}};FieldKit_AddSettingsSections(sections)
local function Item(label)
 for _,item in ipairs(sections[1].items) do if item.label==label then return item end end
 error("Missing chat control: "..label)
end
d.chatStyle=false;Item("Chat width").set(550)
Item("Chat height").set(280)
assert(d.chatStyle and c:GetWidth()==550 and c:GetHeight()==280)
assert(#messages==2 and messages[2][1]=="wrapped native message B")
local _,parent,_,x,y=c:GetPoint();local p=R.chatPlan
assert(parent==R.chat and x==p.textX and y==-p.textY)
assert(y<=0 and -y+c:GetHeight()<=p.rect[4],"Chat crosses the card's top/bottom")
assert(x>=0 and x+c:GetWidth()<=p.rect[3],"Chat crosses the card's left/right")
d.chatStyle=false;Item("Chat font family").set(3);assert(d.chatStyle and d.chatFontFace==3)
C.Set("zoneThemes",false);Item("Chat width").set(620);Item("Chat height").set(240)
assert(c:GetWidth()==620 and c:GetHeight()==240 and #messages==2,"Native chat controls ignored without theme")
local first,middle,last=c:AddMessage("native message C");assert(first=="ok" and middle==nil and last=="native-return")
c:AddMessage("native message D");assert(#messages==3)
assert(FieldKit.ResizeChatPreservingHistory(590,220),"Full native ring buffer made chat permanently unresizable")
assert(#messages==3 and messages[1][1]=="wrapped native message B" and messages[3][1]=="native message D")
local selected=1
local button=U.Choice(UIParent,"FieldKitRebornChatDropdownTest","Font",0,0,320,{"Original","Arial","Morpheus"},function() return selected end,function(v) selected=v end,function() end)
local menu=button.menu;local scroll=menu.scroll;local content=menu.content
-- Model native template children born at level 1 under a high-level menu.
local bar=CreateFrame("Slider",nil,scroll)
menu.GetChildren=function() return scroll end
scroll.GetChildren=function() return content,bar end
content.GetChildren=function() return unpack(button.choiceButtons) end
U.PopupLayer(menu,300)
assert(scroll:GetFrameLevel()>menu:GetFrameLevel() and content:GetFrameLevel()>scroll:GetFrameLevel())
assert(bar:GetFrameLevel()>scroll:GetFrameLevel() and bar:GetFrameStrata()=="TOOLTIP")
for _,b in ipairs(button.choiceButtons) do
 assert(b:GetFrameStrata()=="TOOLTIP" and b:GetFrameLevel()>content:GetFrameLevel())
 assert(b.fieldkitLabel:GetText()~="")
end
button.GetEffectiveScale=function() return .7 end
button:Click();assert(menu:IsShown() and menu:GetScale()==.7);button.choiceButtons[2]:Click()
assert(selected==2 and not menu:IsShown())
print("PASS Reborn native/themed chat dimensions, opt-in from controls, wrapped-text bounds, history without getter, dropdown labels/clicks/template layers")
