fire(FieldKitFrame,"VARIABLES_LOADED")
SlashCmdList.FieldKit("")
local C,M,G=FieldKitZoneThemes,FieldKitThemeMinimap,FieldKitAlignment
C.allowUnfinishedThemes=true;FieldKit.zoneThemeReady=true
function Minimap:SetMaskTexture(path) self.mask=path end
function Minimap:GetMaskTexture() return self.mask or "Textures\\MinimapMask" end
function Minimap:SetScale(v) self.localScale=v end
function Minimap:GetScale() return self.localScale or 1 end
Minimap:SetParent(UIParent);Minimap:SetWidth(140);Minimap:SetHeight(140);Minimap:SetScale(.75)
Minimap:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-12,-20)
for _,zone in ipairs({"elwynn","naxx"}) do for _,variant in ipairs({"minimal","complete","alternative"}) do
 FieldKitRebornDB.zoneThemeMode=zone;FieldKitRebornDB.zoneThemeVariant=variant
 C.Set("zoneThemes",true);assert(C.active and M.active)
 assert(Minimap:GetScale()==1,'Native local scale must not multiply the art owner scale')
 local parent=Minimap:GetParent();local key=C.currentLayout
 G.Start();assert(C.active and C.currentLayout==key and Minimap:GetParent()==parent,'Editor suspended or detached the themed HUD')
 G.Refresh();G.Stop();assert(C.active and Minimap:GetParent()==parent)
 C.Set("zoneThemes",false);assert(not M.active and Minimap:GetScale()==.75,'Original native map scale not restored')
end end
print('PASS live alignment on six theme layouts and exact native minimap scale restoration')
