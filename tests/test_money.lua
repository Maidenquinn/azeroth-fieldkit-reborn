-- Persisted detached state observed in the user's actual saved addon settings.
assert(FieldKitCompactBar and FieldKitMoneyFrame)
assert(FieldKitRebornDB.pos.FieldKitMoneyFrame[1]==-2.5374755859375)
assert(FieldKitRebornDB.pos.FieldKitMoneyFrame[2]==-348.0493927001953)
assert(FieldKitMoneyFrame.point[1]=="BOTTOM" and FieldKitMoneyFrame.point[2]==FieldKitCompactBar)
-- Simulate the loss of a runtime anchor, not a change to saved settings.
FieldKitMoneyFrame:ClearAllPoints();FieldKitMoneyFrame:Hide()
update(FieldKitFrame,.1)
assert(FieldKitMoneyFrame:IsShown())
assert(FieldKitMoneyFrame.point and FieldKitMoneyFrame.point[1]=="BOTTOM" and FieldKitMoneyFrame.point[2]==FieldKitCompactBar)
-- Verify actual data, not only visibility.
AZS_RUN.gold=1234;AZS_RUN.chest=567;AZS_RUN.kills=89
update(FieldKitFrame,.2) -- Native snapshot polling matches the official 5 Hz limit.
assert(FieldKitMoneyFrame.gold.text=="1234" and FieldKitMoneyFrame.chest.text=="567")
assert(FieldKitMoneyFrame.kills.text=="89")
-- Moving the money bar deliberately detaches it; regular updates must respect that.
local oldPoint=FieldKitRebornDB.pos.FieldKitMoneyFrame
FieldKit.layoutEditing=true
this=FieldKitMoneyFrame;FieldKitMoneyFrame:GetScript("OnDragStart")()
FieldKitMoneyFrame:ClearAllPoints();FieldKitMoneyFrame:SetPoint("CENTER",UIParent,"CENTER",120,60)
update(FieldKitFrame,.1)
assert(FieldKitMoneyFrame.point[1]=="CENTER" and FieldKitMoneyFrame.point[4]==120)
this=FieldKitMoneyFrame;FieldKitMoneyFrame:GetScript("OnDragStop")()
FieldKit.layoutEditing=false
assert(FieldKitRebornDB.moneyDetached==true)
FieldKitMoneyFrame:ClearAllPoints();FieldKitMoneyFrame:SetPoint("CENTER",UIParent,"CENTER",100,50)
update(FieldKitFrame,.1)
assert(FieldKitMoneyFrame.point[1]=="CENTER" and FieldKitMoneyFrame.point[4]==100)
-- Restore only this bar, without resetting unrelated window positions or saved coordinates.
FieldKitRebornDB.pos.FieldKitStatsFrame={211,77};local px=FieldKitRebornDB.pos.FieldKitMoneyFrame[1]
SlashCmdList.FieldKit("money")
assert(not FieldKitRebornDB.moneyDetached and FieldKitMoneyFrame.point[2]==FieldKitCompactBar)
assert(FieldKitRebornDB.pos.FieldKitStatsFrame[1]==211 and FieldKitRebornDB.pos.FieldKitStatsFrame[2]==77)
assert(FieldKitRebornDB.pos.FieldKitMoneyFrame[1]==px)
