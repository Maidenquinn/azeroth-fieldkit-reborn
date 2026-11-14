-- Independent unthemed cards yield to visible neighbours, not a linked stack.
-- Collision bounds include the native material's outer metal and shadow.
-- Automatic displacement is never saved over a player's preferred anchor.
FieldKitNativeLayout={}
local L=FieldKitNativeLayout
local function Gap() return 1/(UIParent:GetEffectiveScale() or 1) end
function L.Rect(f,protected)
 if not f or not f.GetLeft or not f.GetTop or not f:IsShown() or (f.IsVisible and not f:IsVisible()) or f:GetAlpha()<=0 then return nil end
 local x,y=FieldKit.Number(f:GetLeft()),FieldKit.Number(f:GetTop())
 if not x or not y then return nil end
 local scale=(f.GetEffectiveScale and f:GetEffectiveScale() or 1)/(UIParent:GetEffectiveScale() or 1)
 local left,top,right,bottom=0,0,0,0
 if not protected then
  left,top,right,bottom=10,18,10,18
 end
 return {frame=f,x=x*scale-left*scale,y=UIParent:GetHeight()-y*scale-top*scale,
  w=(f:GetWidth()+left+right)*scale,h=(f:GetHeight()+top+bottom)*scale,l=left*scale,t=top*scale,scale=scale}
end
function L.Overlap(a,b)
 local GAP=Gap()
 return a.x<b.x+b.w+GAP and a.x+a.w+GAP>b.x and a.y<b.y+b.h+GAP and a.y+a.h+GAP>b.y
end
local function Free(r,placed,w,h)
 if r.x<2 or r.y<2 or r.x+r.w>w-2 or r.y+r.h>h-2 then return false end
 for _,p in ipairs(placed) do if L.Overlap(r,p) then return false end end
 return true
end
local function Fit(r,placed,w,h)
 local GAP=Gap()
 if Free(r,placed,w,h) then return false end
 local best,score=nil,nil
 local function Try(x,y)
  local c={x=x,y=y,w=r.w,h=r.h}
  if Free(c,placed,w,h) then
   local s=math.abs(x-r.x)*1.15+math.abs(y-r.y)
   if not score or s<score then best=c;score=s end
  end
 end
 local x=math.max(2,math.min(r.x,w-r.w-2));local y=math.max(2,math.min(r.y,h-r.h-2))
 Try(x,y)
 for _,p in ipairs(placed) do
  Try(x,p.y+p.h+GAP);Try(x,p.y-r.h-GAP)
  Try(p.x+p.w+GAP,y);Try(p.x-r.w-GAP,y)
 end
 if not best then return false end -- no room: keep the card available to drag
 r.frame:ClearAllPoints();r.frame:SetPoint("TOPLEFT",UIParent,"TOPLEFT",(best.x+r.l)/r.scale,-(best.y+r.t)/r.scale)
 r.x=best.x;r.y=best.y;return true
end
function L.Apply()
 local d=FieldKitRebornDB
 if FieldKit.rebornLegacyFixture or not d or d.zoneThemeOverlap or d.linkLeftCards or d.linkRightCards or (FieldKitZoneThemes and FieldKitZoneThemes.active) then return end
 local frames={};local added={}
 local function Add(f)
  if f and not added[f] then table.insert(frames,f);added[f]=true end
 end
 if L.lastMoved and FieldKitCardLayout.ValidName(L.lastMoved:GetName()) then Add(L.lastMoved) end
 for _,name in ipairs(FieldKitCardLayout.names) do Add(getglobal(name)) end
 for _,f in ipairs(frames) do if f.azsMoving or f.fieldkitHudDragging then return end end
 local placed={};local w,h=UIParent:GetWidth(),UIParent:GetHeight()
 for _,name in ipairs({"Minimap","AzerothSurvivorsUnitFrameTarget"}) do
  local r=L.Rect(getglobal(name),true);if r then table.insert(placed,r) end
 end
 local player=getglobal("AzerothSurvivorsUnitFramePlayer")
 if player and player.Health then local r=L.Rect(player.Health,true);if r then table.insert(placed,r) end end
 local moved=0
 for _,f in ipairs(frames) do
  local r=L.Rect(f)
  if r then if Fit(r,placed,w,h) then moved=moved+1 end;table.insert(placed,r) end
 end
 return moved
end
