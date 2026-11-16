-- Screen-space editing of the actual HUD, without suspending its theme.
-- No automatic movement on login: snapping only follows an explicit drop
-- while this editor is open. All stored anchors keep their existing format.
FieldKitAlignment={active=false}
local G=FieldKitAlignment
local function Scale(f) return math.max(.01,FieldKit.Number(f and f:GetEffectiveScale(),1)) end
function G.Rect(f)
 if not f or not f.GetLeft or not f.GetTop or not f:IsShown() or (f.IsVisible and not f:IsVisible()) or (f.GetAlpha and f:GetAlpha()<=0) then return nil end
 local x,y=FieldKit.Number(f:GetLeft()),FieldKit.Number(f:GetTop())
 if not x or not y then return nil end
 local s=Scale(f)/Scale(UIParent)
 local R=FieldKitReferenceHUD;local n=R and R.active and R.AlignmentInsets and R.AlignmentInsets(f) or {0,0,0,0}
 return {x=(x+n[1])*s,y=(y-n[2])*s,w=(f:GetWidth()-n[1]-n[3])*s,h=(f:GetHeight()-n[2]-n[4])*s,scale=s,anchorX=x*s,anchorY=y*s}
end
function G.Frames()
 local out,seen={},{}
 local function Add(f) if f and not seen[f] then seen[f]=true;table.insert(out,f) end end
 local C=FieldKitZoneThemes
 if C and C.active then
  for _,e in ipairs(C.Elements()) do
   if e.name=="FieldKitThemeBosses" then for i=1,4 do Add(getglobal("FieldKitBossFrame"..i)) end
   else Add(getglobal(e.name)) end
  end
 else
  for _,name in ipairs(FieldKitCardLayout.names) do Add(getglobal(name)) end
  for _,name in ipairs({"FieldKitLeftStack","FieldKitRightStack","ChatFrame1","FieldKitPlayerBar","FieldKitPlayerBuffs","FieldKitBossTimelineFrame"}) do Add(getglobal(name)) end
  for i=1,4 do Add(getglobal("FieldKitBossFrame"..i)) end
  for _,s in pairs((FieldKitNativeHUD and FieldKitNativeHUD.nativeLayouts) or {}) do Add(s.frame) end
 end
 return out
end
-- Pure geometry shared by drop snapping and the live alignment guides.
function G.Resolve(r,peers,w,h,step,tolerance,grid)
 local dx,dy,bx,by=nil,nil,nil,nil
 local function X(target,source)
  local d=target-source
  if math.abs(d)<=tolerance and (not dx or math.abs(d)<math.abs(dx)) then dx=d;bx=target end
 end
 local function Y(target,source)
  local d=target-source
  if math.abs(d)<=tolerance and (not dy or math.abs(d)<math.abs(dy)) then dy=d;by=target end
 end
 local xs={r.x,r.x+r.w/2,r.x+r.w};local ys={r.y,r.y-r.h/2,r.y-r.h}
 if grid and step>0 then
  -- The visible lattice is authoritative: a closer peer edge/centre must
  -- never pull a guide between its lines. Snap the card's visible top-left.
  X(w/2+math.floor((r.x-w/2)/step+.5)*step,r.x)
  Y(h/2+math.floor((r.y-h/2)/step+.5)*step,r.y)
 else
  for _,v in ipairs(xs) do for _,t in ipairs({0,w/2,w}) do X(t,v) end end
  for _,v in ipairs(ys) do for _,t in ipairs({0,h/2,h}) do Y(t,v) end end
  for _,p in ipairs(peers) do
   for _,v in ipairs(xs) do for _,t in ipairs({p.x,p.x+p.w/2,p.x+p.w}) do X(t,v) end end
   for _,v in ipairs(ys) do for _,t in ipairs({p.y,p.y-p.h/2,p.y-p.h}) do Y(t,v) end end
  end
 end
 local x=math.max(0,math.min(math.max(0,w-r.w),r.x+(dx or 0)))
 local y=math.max(math.min(h,r.h),math.min(h,r.y+(dy or 0)))
 -- Screen clamping can defeat an otherwise valid target. Do not draw a
 -- guide claiming the card can land there when the clamp prevents it.
 if dx and math.abs(x-r.x-dx)>.000001 then bx=nil end
 if dy and math.abs(y-r.y-dy)>.000001 then by=nil end
 return x-r.x,y-r.y,bx,by
end
-- Drawing and snapping must use exactly the same bounded lattice spacing.
function G.Step(w,h,scale,spacing)
 return math.max(spacing/scale,math.max(w,h)/300)
end
function G.Delta(f)
 local r=G.Rect(f);if not r then return end
 local peers={}
 local function Related(p)
  local a=p;for i=1,20 do if a==f then return true end;a=a and a.GetParent and a:GetParent();if not a then break end end
  a=f;for i=1,20 do if a==p then return true end;a=a and a.GetParent and a:GetParent();if not a then break end end
  return false
 end
 for _,p in ipairs(G.Frames()) do if not Related(p) then local q=G.Rect(p);if q then table.insert(peers,q) end end end
 local d=FieldKitRebornDB;local us=Scale(UIParent)
 local w,h=UIParent:GetWidth(),UIParent:GetHeight()
 return G.Resolve(r,peers,w,h,G.Step(w,h,us,d.alignmentStep),8/us,d.alignmentGrid)
end
function G.Snap(f)
 if not G.active or not FieldKitRebornDB.alignmentSnap then return false end
 local r=G.Rect(f);if not r then return false end
 local dx,dy=G.Delta(f);if not dx or (dx==0 and dy==0) then return false end
 f:ClearAllPoints();f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",(r.anchorX+dx)/r.scale,(r.anchorY+dy)/r.scale)
 return true
end
local function Line(parent,x,y,w,h,alpha,centre)
 local t=parent:CreateTexture(nil,"OVERLAY");t:SetTexture("Interface\\Buttons\\WHITE8X8")
 t:SetVertexColor(centre and 1 or .55,centre and .75 or .7,centre and .25 or .8,alpha)
 t:SetWidth(w);t:SetHeight(h);t:SetPoint("BOTTOMLEFT",parent,"BOTTOMLEFT",x,y);return t
end
function G.Draw()
 if not G.overlay then return end
 local d=FieldKitRebornDB;local w,h=UIParent:GetWidth(),UIParent:GetHeight();local us=Scale(UIParent)
 local stamp=table.concat({w,h,us,d.alignmentStep,tostring(d.alignmentGrid)},":")
 if G.stamp==stamp then return end;G.stamp=stamp
 -- Reuse regions after viewport/spacing changes; never accumulate textures.
 for _,t in ipairs(G.lines or {}) do t:Hide() end
 G.lines=G.lines or {};local n=0
 local function Put(x,y,lx,ly,centre)
  n=n+1;local t=G.lines[n]
  if not t then t=Line(G.overlay,0,0,1,1,.2,false);G.lines[n]=t end
  t:ClearAllPoints();t:SetPoint("BOTTOMLEFT",G.overlay,"BOTTOMLEFT",x,y);t:SetWidth(lx);t:SetHeight(ly)
  t:SetVertexColor(centre and 1 or .55,centre and .75 or .7,centre and .25 or .8,centre and .55 or .18);t:Show()
 end
 local pixel=1/us;local step=G.Step(w,h,us,d.alignmentStep)
 if d.alignmentGrid then
  -- Bounded on extreme resolutions as well as hostile SavedVariables.
  for i=-math.floor(w/2/step),math.floor(w/2/step) do Put(w/2+i*step,0,pixel,h,i==0) end
  for i=-math.floor(h/2/step),math.floor(h/2/step) do Put(0,h/2+i*step,w,pixel,i==0) end
 else Put(w/2,0,pixel,h,true);Put(0,h/2,w,pixel,true) end
end
function G.Refresh()
 if not G.active then return end
 G.Draw()
 local d=FieldKitRebornDB
 G.grid.fieldkitLabel:SetText(FieldKit_L("Alignment grid")..": "..FieldKit_L(d.alignmentGrid and "On" or "Off"))
 G.snap.fieldkitLabel:SetText(FieldKit_L("Snap to guides")..": "..FieldKit_L(d.alignmentSnap and "On" or "Off"))
 G.spacing.fieldkitLabel:SetText(tostring(d.alignmentStep).." px")
 for _,t in ipairs(G.guides) do t:Hide() end
 if not d.alignmentSnap then return end
 for _,f in ipairs(G.Frames()) do if f.azsMoving or f.fieldkitHudDragging then
  local _,_,x,y=G.Delta(f);local w,h=UIParent:GetWidth(),UIParent:GetHeight()
  if x then local t=G.guides[1];t:ClearAllPoints();t:SetPoint("BOTTOMLEFT",G.overlay,"BOTTOMLEFT",x,0);t:SetWidth(1/Scale(UIParent));t:SetHeight(h);t:Show() end
  if y then local t=G.guides[2];t:ClearAllPoints();t:SetPoint("BOTTOMLEFT",G.overlay,"BOTTOMLEFT",0,y);t:SetHeight(1/Scale(UIParent));t:SetWidth(w);t:Show() end
  break
 end end
end
function G.Stop()
 if not G.active then return end
 if FieldKit.FinishChatMove then FieldKit.FinishChatMove() end
 G.active=false
 G.overlay:Hide();G.toolbar:Hide()
 if FieldKit.RefreshChatMover then FieldKit.RefreshChatMover() end
 local lock=G.wasLocked;G.wasLocked=nil
 FieldKit.SetWindowsLocked(lock)
end
function G.Start()
 if G.active or not FieldKitRebornDB then return end
 FieldKitProfiles.Init()
 if FieldKit.layoutEditing then FieldKitUI.SetLayoutEditing(false,false) end
 G.wasLocked=FieldKitRebornDB.windowsLocked
 if FieldKitUI.frame then FieldKitUI.frame:Hide() end
 FieldKit.SetWindowsLocked(false);G.active=true
 if FieldKit.RefreshChatMover then FieldKit.RefreshChatMover() end
 if not G.overlay then
  local T=FieldKitTheme
  local o=CreateFrame("Frame","FieldKitAlignmentGrid",UIParent);G.overlay=o;o:SetAllPoints(UIParent);o:SetFrameStrata("HIGH");o:EnableMouse(false)
  G.guides={Line(o,0,0,1,1,.9,true),Line(o,0,0,1,1,.9,true)}
  local b=CreateFrame("Frame","FieldKitAlignmentToolbar",UIParent);G.toolbar=b
  b:SetWidth(740);b:SetHeight(112);b:SetPoint("TOP",UIParent,"TOP",0,-20);b:SetFrameStrata("DIALOG");T.Surface(b,"window")
  local title=T.Label(b,"Align HUD",16,10,600,24,18,T.gold,true);FieldKit_Text(title,"Align HUD")
  local hint=T.Label(b,"Grid on: snap to grid. Grid off: align edges and centres. Overlap rules still apply.",16,36,710,28,12,T.muted);FieldKit_Text(hint,"Grid on: snap to grid. Grid off: align edges and centres. Overlap rules still apply.")
  G.grid=T.Button(b,nil,"",16,72,190,26,function() FieldKitRebornDB.alignmentGrid=not FieldKitRebornDB.alignmentGrid;G.Refresh() end)
  G.snap=T.Button(b,nil,"",214,72,190,26,function() FieldKitRebornDB.alignmentSnap=not FieldKitRebornDB.alignmentSnap;G.Refresh() end)
  T.Button(b,nil,"-",412,72,30,26,function() FieldKitRebornDB.alignmentStep=math.max(8,FieldKitRebornDB.alignmentStep-8);G.Refresh() end)
  G.spacing=T.Button(b,nil,"",446,72,74,26,function() end)
  T.Button(b,nil,"+",524,72,30,26,function() FieldKitRebornDB.alignmentStep=math.min(64,FieldKitRebornDB.alignmentStep+8);G.Refresh() end)
  local done=T.Button(b,nil,"Done",580,72,144,26,G.Stop);FieldKit_Text(done,"Done")
  local elapsed=0;b:SetScript("OnUpdate",function() elapsed=elapsed+(arg1 or 0);if elapsed>=.05 then elapsed=0;G.Refresh() end end)
  b:SetScript("OnHide",G.Stop)
 end
 G.stamp=nil;G.overlay:Show();G.toolbar:Show();G.Refresh()
end
