fire(FieldKitFrame,"VARIABLES_LOADED")
local world="Hellfire Peninsula"
GetRealZoneText=function() return world end
AZS_RUN={ph="playing",t=240};AZS_ZONE={zone="hellfire",dt=0,diff="Normal"}
assert(FieldKit.GetHeroicLevel()==0 and FieldKit.GetHeroicLabel()=="Normal difficulty","Native dt=0 was treated as unknown")
AZS_ZONE={};AZS_RUN.t=241
FieldKit.InitializeSettings({}) -- persisted context normalized during reload
assert(FieldKit.GetHeroicLevel()==0,"Continuing run lost known difficulty after ZONE omitted from replay")
AZS_ZONE={zone="hellfire",dt=3,diff="Heroic III"};assert(FieldKit.GetHeroicLevel()==3)
AZS_ZONE={};AZS_RUN.ph="paused";AZS_RUN.t=244;assert(FieldKit.GetHeroicLevel()==3)
world="Zangarmarsh";assert(FieldKit.GetHeroicLevel()==nil,"Difficulty leaked to another world")
world="Hellfire Peninsula";AZS_ZONE={zone="hellfire",dt=2};assert(FieldKit.GetHeroicLevel()==2)
AZS_ZONE={};AZS_RUN.t=2;assert(FieldKit.GetHeroicLevel()==nil,"Difficulty leaked across a restarted clock")
AZS_ZONE={zone="hellfire",dt=2};assert(FieldKit.GetHeroicLevel()==2)
AZS_ZONE={};FieldKitNative.Packet("AZSZONE");assert(FieldKit.GetHeroicLevel()==nil,"New zone packet did not invalidate context")
AZS_ZONE={zone="hellfire",dt=0};assert(FieldKit.GetHeroicLevel()==0)
AZS_ZONE={};AZS_RUN.ph="ready";assert(FieldKit.GetHeroicLevel()==nil,"Old rank reused at a new ready screen")
AZS_ZONE={zone="hellfire",dt=2.5};assert(FieldKit.GetHeroicLevel()==nil)
AZS_ZONE={zone="hellfire",dt=9};assert(FieldKit.GetHeroicLevel()==nil)
print("PASS native difficulty dt/heroic and continuing-run reload; no Normal default, cross-zone, new ready, clock restart or packet leakage")

AZS_ZONE={zone="hellfire",dt=0};AZS_RUN={ph="ready",t=0}
FieldKit.CaptureDifficulty()
AZS_ZONE={};AZS_RUN={ph="playing",t=1};FieldKitRebornDB.runDifficultyContext=nil
assert(FieldKit.GetHeroicLevel()==0,"One-shot difficulty captured before HUD update was lost")
