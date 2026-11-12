-- Synthetic v0.4.2-style flat SavedVariables: no interfaceProfiles.
-- Run in the mocked Lua 5.1 client after VARIABLES_LOADED.
assert(type(FieldKitRebornDB)=="table")
assert(FieldKitRebornDB.interfaceProfiles==nil or type(FieldKitRebornDB.interfaceProfiles)=="table")
assert(FieldKitRebornDB.cardOpacity==37)
assert(FieldKitRebornDB.moneyFrame==false)
assert(FieldKitRebornDB.combatTextX==-217)
assert(FieldKitRebornDB.chatWidth==560)
assert(FieldKitRebornDB.language=="fr")
assert(FieldKitRebornDB.frameAnchors.FieldKitLeftStack[3]==83)
assert(FieldKitRebornDB.pos.FieldKitMoneyFrame[1]==-14)
assert(FieldKitRebornDB.activeHudProfile==nil)
assert(FieldKitProfiles.Save(1))
assert(FieldKitRebornDB.activeHudProfile==1)
FieldKitRebornDB.cardOpacity=93
FieldKitRebornDB.moneyFrame=true
FieldKitRebornDB.combatTextX=11
FieldKitRebornDB.chatWidth=400
FieldKitRebornDB.frameAnchors.FieldKitLeftStack[3]=4
assert(FieldKitProfiles.Load(1))
assert(FieldKitRebornDB.cardOpacity==37)
assert(FieldKitRebornDB.moneyFrame==false)
assert(FieldKitRebornDB.combatTextX==-217)
assert(FieldKitRebornDB.chatWidth==560)
assert(FieldKitRebornDB.frameAnchors.FieldKitLeftStack[3]==83)
assert(FieldKitRebornDB.pos.FieldKitMoneyFrame[1]==-14)
