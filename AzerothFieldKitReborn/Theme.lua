-- Chroniques d'Azeroth visual family, adapted from the maintainer's Azeroth Stats.
-- Fixed bundled assets only; no dependency on another installed addon.
FieldKitTheme={media="Interface\\AddOns\\AzerothFieldKitReborn\\media\\",
 background={.063,.09,.106},panel={.094,.129,.149},gold={.85,.71,.42},
 bronze={.54,.44,.27},text={.94,.91,.83},muted={.65,.70,.70},
 green={.61,.77,.57},red={.91,.40,.37}}
local T=FieldKitTheme
T.surfaces={}
T.fonts={};T.controls={};T.zone="classic"
function T.Solid(texture,color,alpha)
 texture:SetTexture("Interface\\Buttons\\WHITE8X8")
 texture:SetVertexColor(color[1],color[2],color[3],alpha or 1)
end
function T.SetZone(zone)
 if not FieldKitZoneRegistry or not FieldKitZoneRegistry[zone] then zone="classic" end
 if T.zone==zone then return end
 T.zone=zone
 for key,value in pairs(FieldKitZoneRegistry[zone]) do
  if type(value)=="table" and type(T[key])=="table" then
   for i=1,3 do T[key][i]=value[i] end
  end
 end
 T.Refresh()
end

-- Display preferences affect only our material layers, never frame/text alpha.
function T.Style(frame)
 if T.zone~="classic" then return 3 end
 if not FieldKit.rebornLegacyFixture then
  if frame and frame.fieldkitSkin and frame.fieldkitSkin.hud and FieldKitRebornDB and FieldKitRebornDB.cardStyle==2 then return 2 end
  return 4
 end
 if not frame or not frame.fieldkitSkin or not frame.fieldkitSkin.hud then return 1 end
 return FieldKitRebornDB and FieldKitRebornDB.cardStyle==2 and 2 or 1
end
function T.Opacity(frame)
 if frame and frame.GetName and frame:GetName()=="FieldKitPanel" then return FieldKit.Number(FieldKitRebornDB and FieldKitRebornDB.settingsPanelOpacity,100,0,100)/100 end
 if not frame or not frame.fieldkitSkin or not frame.fieldkitSkin.hud then return 1 end
 return FieldKit.Number(FieldKitRebornDB and FieldKitRebornDB.cardOpacity,100,0,100)/100
end
-- Panel opacity only: repaint the fill of the HUD cards. The border slices, labels and controls are not touched.
function T.RefreshOpacity()
 local n=0
 for i=1,table.getn(T.surfaces) do
  local frame=T.surfaces[i]
  if frame.fieldkitSkin and frame.fieldkitSkin.hud and frame.fieldkitSkin.kind~="button" then T.State(frame,frame.fieldkitActive);n=n+1 end
 end
 return n
end
function T.Refresh()
 T.gen=T.gen+1 -- zone colours / assets may have changed: every surface repaints once
 for i=1,table.getn(T.surfaces) do
  local frame=T.surfaces[i];T.State(frame,frame.fieldkitActive);T.Update(frame)
 end
 for i=1,table.getn(T.fonts) do
  local r=T.fonts[i];T.Font(r.label,r.size,r.color,r.heading,r.face)
 end
 for i=1,table.getn(T.controls) do T.PaintControl(T.controls[i]) end
end

-- Keep headings and body type consistent; the native face is a safe fallback.
function T.Font(label,size,color,heading,face)
 local path=T.media..(face or (heading and "NotoSerif-Regular.ttf" or "AzerothSans.ttf"))
 size=size or 14
 local baseSize=size
 local flags=""
 if T.zone=="classic" and not FieldKit.rebornLegacyFixture and not face then path="Fonts\\FRIZQT__.TTF";flags="OUTLINE" end
 local fit=label.fieldkitFit
 if fit and fit.path==path and fit.baseSize==size and fit.width==label:GetWidth() and fit.height==label:GetHeight() and (label:GetText()==fit.full or label:GetText()==fit.display) then size=fit.renderSize end
 local oldPath,oldSize,oldFlags;if label.GetFont then oldPath,oldSize,oldFlags=label:GetFont() end
 local ok,result=true,true
 if oldPath~=path or oldSize~=size or (oldFlags or "")~=flags then ok,result=pcall(label.SetFont,label,path,size,flags) end
 if not ok or result==false then label:SetFont(heading and "Fonts\\FRIZQT__.TTF" or "Fonts\\ARIALN.TTF",size or 14,"") end
 color=color or T.text;label:SetTextColor(color[1],color[2],color[3])
 if not label.fieldkitFontRecord then
  label.fieldkitFontRecord={label=label,color=color};table.insert(T.fonts,label.fieldkitFontRecord)
 else label.fieldkitFontRecord.color=color end
 local r=label.fieldkitFontRecord;r.size=baseSize;r.heading=heading;r.face=face
end

-- Reproduce the native tooltip layout, not a miniature of its 512x64 atlas.
-- Its 32px edge has 8/16px transparent padding; the plate therefore extends
-- 10px horizontally and 18px vertically beyond the content. The matching
-- frame level is essential: a child at parent+1 would cover the labels.
function T.NativePaint(frame,active,fill)
 local skin=frame.fieldkitSkin;local button=skin.kind=="button"
 local native=type(IsAddOnLoaded)=="function" and IsAddOnLoaded("AzerothSurvivorsUI")
 local opacity=button and 1 or (fill and fill.alpha or T.Opacity(frame))
 skin.nativeBackdrop=true;skin.nativeFillAlpha=opacity
 skin.grain:SetAlpha(0);skin.selected:Hide()
 for _,part in ipairs(skin.parts) do part.texture:Hide() end
 if button and native then
  if not skin.nativeButtons then
   skin.nativeButtons={}
   for i=1,3 do local t=frame:CreateTexture(nil,"BORDER");t:SetTexture("Interface\\AddOns\\AzerothSurvivorsUI\\Assets\\nameplate_backdrop");skin.nativeButtons[i]=t end
  end
  local w,h=math.max(3,frame:GetWidth()),math.max(3,frame:GetHeight());local cap=math.min(h/2,w/3)
  for i=1,3 do
   local t=skin.nativeButtons[i];t:ClearAllPoints();t:SetPoint("TOPLEFT",frame,"TOPLEFT",i==1 and 0 or (i==2 and cap or w-cap),0)
   t:SetWidth(i==2 and math.max(1,w-2*cap) or cap);t:SetHeight(h)
   local cuts={0,.125,.875,1};t:SetTexCoord(cuts[i],cuts[i+1],0,1)
   t:SetVertexColor(active and 1 or .85,active and .9 or .85,active and .7 or .85);t:Show()
  end
  T.Solid(skin.base,active and {.17,.14,.08} or {.075,.075,.085});skin.base:SetAlpha(1)
 else
  skin.base:SetAlpha(0)
  if not skin.nativeMaterial then
   local bg=CreateFrame("Frame",nil,frame);skin.nativeMaterial=bg;bg:EnableMouse(false)
  end
  local bg=skin.nativeMaterial;bg:SetFrameLevel(frame:GetFrameLevel());bg:ClearAllPoints()
  local x,y=native and 10 or 6,native and 18 or 6
  if button then x=0;y=0 end
  bg:SetPoint("TOPLEFT",frame,"TOPLEFT",-x,y);bg:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",x,-y)
  local key=(native and "native" or "stock")..(button and "button" or "panel")
  if skin.nativeAssetKey~=key then
   skin.nativeAssetKey=key
   bg:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile=native and "Interface\\AddOns\\AzerothSurvivorsUI\\Assets\\border-tooltip" or "Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=button and 8 or (native and 32 or 16),tile=true,tileSize=16,insets={left=native and 8 or 4,right=native and 8 or 4,top=native and 16 or 4,bottom=native and 16 or 4}})
  end
  local color=fill and fill.color or {.09,.09,.1}
  bg:SetBackdropColor(color[1],color[2],color[3],opacity*.94)
  bg:SetBackdropBorderColor(.753,.753,.753,1);bg:Show()
 end
 frame.fieldkitActive=active and true or false
 if frame.fieldkitChoice then T.ChoiceLook(frame,frame.fieldkitSelected==true,active and true or false) end
end

-- Explicit dimensions avoid this client's custom-backdrop tiling/stretch quirks.
function T.Update(frame)
 if not frame.fieldkitSkin then return end
 -- Unresolved anchors may report zero during construction. Native texture
 -- quads with a zero dimension can fall back to their intrinsic atlas size.
 local w,h=math.max(3,frame:GetWidth()),math.max(3,frame:GetHeight())
 local skin=frame.fieldkitSkin
 if skin.nativeMaterial then skin.nativeMaterial:SetFrameLevel(frame:GetFrameLevel()) end
 local style=T.Style(frame)
 if skin.width==w and skin.height==h and skin.style==style then return end
 skin.width=w;skin.height=h;skin.style=style
 if style==4 and skin.nativeButtons then T.NativePaint(frame,frame.fieldkitActive,frame.fieldkitFill) end
 local c=math.min(T.Style(frame)==3 and 12 or (skin.kind=="window" and 24 or (skin.kind=="card" and 16 or 8)),w/3,h/3)
 -- The corners of the zone material are cut diagonally (transparent triangles): a full-size fill would show as a dark halo
 -- outside the gold border. In the reference style the fill covers only the INSIDE of the frame (inside the corner cut).
 local inset=style==4 and 5 or (style==3 and c or 0)
 skin.base:ClearAllPoints();skin.base:SetPoint("TOPLEFT",frame,"TOPLEFT",inset,-inset);skin.base:SetWidth(math.max(1,w-2*inset));skin.base:SetHeight(math.max(1,h-2*inset))
 skin.grain:ClearAllPoints();skin.grain:SetPoint("TOPLEFT",frame,"TOPLEFT",inset,-inset);skin.grain:SetWidth(math.max(1,w-2*inset));skin.grain:SetHeight(math.max(1,h-2*inset))
 skin.inset=inset
 local xs,ys={0,c,w-c},{0,c,h-c}
 if style==2 then
  -- Four one-pixel solid edges; remaining ornate slices stay hidden.
  local edges={{0,0,w,1},{0,h-1,w,1},{0,0,1,h},{w-1,0,1,h}}
  for i=1,4 do
   local t=skin.parts[i].texture;local e=edges[i]
   t:ClearAllPoints();t:SetPoint("TOPLEFT",frame,"TOPLEFT",e[1],-e[2]);t:SetWidth(e[3]);t:SetHeight(e[4])
  end
  return
 end
 for i=1,table.getn(skin.parts) do
  local p=skin.parts[i];local x,y=p.x,p.y
  p.texture:ClearAllPoints();p.texture:SetPoint("TOPLEFT",frame,"TOPLEFT",xs[x],-ys[y])
  p.texture:SetWidth(x==2 and math.max(1,w-2*c) or c)
  p.texture:SetHeight(y==2 and math.max(1,h-2*c) or c)
 end
end

-- Build nine owned material slices once; do not skin native/game-owned frames.
function T.Surface(frame,kind,hud)
 if frame.fieldkitSkin then T.Update(frame);return end
 kind=kind or "card";frame:SetBackdrop({})
 -- Explicit scope prevents HUD transparency/style leaking into settings and popups.
 local skin={kind=kind,parts={},hud=hud==true};frame.fieldkitSkin=skin
 table.insert(T.surfaces,frame)
 local color=kind=="card" and T.panel or T.background
 skin.base=frame:CreateTexture(nil,"BACKGROUND");skin.base:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
 T.Solid(skin.base,color);skin.base:SetAlpha(1)
 skin.selected=frame:CreateTexture(nil,"OVERLAY");skin.selected:SetPoint("TOPLEFT",frame,"TOPLEFT",3,-3);skin.selected:SetWidth(3);skin.selected:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",3,3);T.Solid(skin.selected,T.gold);skin.selected:Hide()
 skin.grain=frame:CreateTexture(nil,"BACKGROUND");skin.grain:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
 skin.grain:SetTexture(T.media.."ChronicleGrain.tga");skin.grain:SetAlpha(.16)
 local cuts={0,.07,.93,1}
 for y=1,3 do for x=1,3 do
  local texture=frame:CreateTexture(nil,"BORDER")
  texture:SetTexCoord(cuts[x],cuts[x+1],cuts[y],cuts[y+1])
  if kind=="window" and x==2 and y==2 then texture:Hide() end
  table.insert(skin.parts,{texture=texture,x=x,y=y})
 end end
 T.State(frame,false);T.Update(frame)
end

-- Selection/hover only changes the fixed material, never allocates another layer.
-- T.State is a pure function of: the art-only flag, active, navigation flag, the opacity (or the card's own fill alpha), the fill
-- colour, the style and the zone/colours generation (T.gen, bumped by T.SetZone / T.Refresh). Called ~1500 times per theme
-- refresh with the same inputs, it used to rewrite ~10 textures each time: it now returns at once when nothing changed. Choice
-- buttons keep the full path (their label colour is also set by others).
T.gen=T.gen or 0
function T.State(frame,active)
 local skin=frame.fieldkitSkin;if not skin then return end
 local fillNow=frame.fieldkitFill
 if not frame.fieldkitChoice then
  local m=skin.memo
  local opacityNow=skin.kind=="button" and 1 or T.Opacity(frame);if fillNow then opacityNow=fillNow.alpha end
  local color=fillNow and fillNow.color
  local artNow=frame.fieldkitArtOnly and true or false;local activeNow=active and true or false;local navNow=frame.fieldkitNavigation and true or false
  local styleNow=T.Style(frame)
  local nativeReady=type(IsAddOnLoaded)=="function" and IsAddOnLoaded("AzerothSurvivorsUI") and true or false
  if m and m.gen==T.gen and m.art==artNow and m.active==activeNow and m.nav==navNow and m.opacity==opacityNow and m.style==styleNow and m.nativeReady==nativeReady
   and m.hasFill==(fillNow~=nil) and (not color or (m.r==color[1] and m.g==color[2] and m.b==color[3])) then return end
  if not m then m={};skin.memo=m end
  m.gen=T.gen;m.art=artNow;m.active=activeNow;m.nav=navNow;m.opacity=opacityNow;m.style=styleNow;m.nativeReady=nativeReady;m.hasFill=(fillNow~=nil)
  if color then m.r,m.g,m.b=color[1],color[2],color[3] else m.r,m.g,m.b=nil,nil,nil end
 end
 -- frame.fieldkitFill = {color={r,g,b},alpha=a}: the card's own interior colour and opacity (the chat preferences), applied to the
 -- fill and to the centre slice only; the gold border slices keep their own opacity.
 local fill=frame.fieldkitFill
 if skin.nativeBackdrop then frame:SetBackdrop({});skin.nativeBackdrop=nil end
 if skin.nativeMaterial then skin.nativeMaterial:Hide() end
 for _,part in ipairs(skin.nativeButtons or {}) do part:Hide() end
 if T.Style(frame)==4 and not frame.fieldkitArtOnly then T.NativePaint(frame,active,fill);return end
 if frame.fieldkitArtOnly then skin.base:SetAlpha(0);skin.grain:SetAlpha(0);skin.selected:Hide();for _,part in ipairs(skin.parts) do part.texture:Hide() end;return end
 local alpha=(frame.fieldkitNavigation and not active) and 0 or 1
 local opacity=skin.kind=="button" and 1 or T.Opacity(frame)
 if fill then opacity=fill.alpha end
 T.Solid(skin.base,fill and fill.color or (skin.kind=="card" and T.panel or T.background))
 skin.base:SetAlpha(alpha*opacity);skin.grain:SetAlpha(T.Style(frame)==2 and 0 or .16*alpha*opacity)
 local plate=skin.kind=="window" and 4 or (skin.kind=="card" and 3 or (active and 2 or 1))
 for i=1,table.getn(skin.parts) do
  local t=skin.parts[i].texture
  if T.Style(frame)==2 then
   if i<=4 then
    t:Show();T.Solid(t,active and T.gold or T.bronze);t:SetAlpha(alpha)
   else t:Hide() end
   t.fieldkitPlate=nil
  else
   if skin.kind=="window" and i==5 then t:Hide() else t:Show() end
   local asset=T.Style(frame)==3 and (T.media.."ReferenceHUD\\"..T.zone.."_material_v3.tga") or (T.media.."ChroniclePlate"..plate..".tga")
   if T.Style(frame)==3 and i==5 then T.Solid(t,fill and fill.color or T.panel);t.fieldkitPlate=nil else if t.fieldkitPlate~=asset then t:SetTexture(asset);t.fieldkitPlate=asset end end
   local part=skin.parts[i];local cuts=T.Style(frame)==3 and {0,12/512,500/512,1} or {0,.07,.93,1}
   local row=part.y;if T.Style(frame)==3 and part.x==2 and part.y==1 then row=3 end
   t:SetTexCoord(cuts[part.x],cuts[part.x+1],cuts[row],cuts[row+1])
   if T.Style(frame)==3 and i==5 then local c=fill and fill.color or T.panel;t:SetVertexColor(c[1],c[2],c[3]) else t:SetVertexColor(1,1,1) end
   t:SetAlpha(alpha*(i==5 and opacity or 1))
  end
 end
 T.Solid(skin.selected,T.gold);skin.selected:Hide()
 frame.fieldkitActive=active and true or false
 if frame.fieldkitChoice and skin.kind=="button" then T.ChoiceLook(frame,frame.fieldkitSelected==true,active and true or false) end
end
-- Choice controls (exclusive groups and toggles marked fieldkitChoice): three clearly different states.
--  selected = golden fill, a gold outline, the accent bar and a bright label (persistent: it never depends on the pointer);
--  hover    = a discreet lightening only (never the selected look);
--  normal   = the dark fill, the standard border and a legible muted label.
-- `selected` comes from frame.fieldkitSelected, `hover` is the pointer (T.State's `active` argument), so hovering a selected
-- choice keeps it selected and leaving a hovered one gives back exactly its own state.
function T.ChoiceLook(frame,selected,hover)
 local skin=frame.fieldkitSkin
 if not skin.choice then
  skin.choice={}
  for i=1,4 do local t=frame:CreateTexture(nil,"OVERLAY");T.Solid(t,{1,.82,.35});t:Hide();skin.choice[i]=t end
 end
 local w,h=frame:GetWidth(),frame:GetHeight()
 if skin.choiceW~=w or skin.choiceH~=h then
  skin.choiceW=w;skin.choiceH=h
  local e={{2,2,w-4,2},{2,h-4,w-4,2},{2,2,2,h-4},{w-4,2,2,h-4}}
  for i=1,4 do local t=skin.choice[i];t:ClearAllPoints();t:SetPoint("TOPLEFT",frame,"TOPLEFT",e[i][1],-e[i][2]);t:SetWidth(math.max(1,e[i][3]));t:SetHeight(math.max(1,e[i][4])) end
 end
 local base=selected and {.34,.25,.05} or (hover and {.2,.19,.14} or nil)
 if base and not frame.fieldkitArtOnly then T.Solid(skin.base,base);skin.base:SetAlpha(1) end
 for i=1,4 do if selected and not frame.fieldkitArtOnly then skin.choice[i]:Show() else skin.choice[i]:Hide() end end
 if selected and not frame.fieldkitArtOnly then skin.selected:Show() end
 if frame.fieldkitLabel then
  if selected then frame.fieldkitLabel:SetTextColor(1,.94,.66) elseif hover then frame.fieldkitLabel:SetTextColor(.95,.85,.55) else frame.fieldkitLabel:SetTextColor(.8,.7,.45) end
 end
end

-- Retain legacy widget input/checked/value behavior; only its material changes.
function T.PaintControl(control)
 if control.kind=="slider" and control.frame.SetThumbTexture then
  control.frame:SetThumbTexture(T.zone~="classic" and (T.media.."ReferenceHUD\\"..T.zone.."_thumb_v3.tga") or "Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  if control.frame.GetThumbTexture then
   local thumb=control.frame:GetThumbTexture();if thumb then thumb:SetVertexColor(1,1,1);if T.zone~="classic" then thumb:SetWidth(26);thumb:SetHeight(26) end end
  end
 end
 T.State(control.frame,false)
end
function T.Control(frame,kind)
 if frame.fieldkitControl then return end
 frame.fieldkitControl={frame=frame,kind=kind};table.insert(T.controls,frame.fieldkitControl)
 T.Surface(frame,"button");T.PaintControl(frame.fieldkitControl)
end

-- Native legacy Button with its own visible label; no red template underneath.
function T.Button(parent,name,label,x,y,w,h,callback)
 local b=CreateFrame("Button",name,parent);b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y)
 b:SetWidth(w);b:SetHeight((not FieldKit.rebornLegacyFixture and T.zone=="classic" and w>=50) and math.max(28,h or 28) or (h or 28));T.Surface(b,"button",parent.fieldkitSkin and parent.fieldkitSkin.hud)
 b.fieldkitLabel=b:CreateFontString(nil,"OVERLAY","GameFontNormal")
 local padding=w<50 and 2 or 10
 b.fieldkitLabel:SetPoint("LEFT",b,"LEFT",padding,0);b.fieldkitLabel:SetWidth(w-2*padding);b.fieldkitLabel:SetHeight(math.max(12,b:GetHeight()-8))
 if b.fieldkitLabel.SetWordWrap then b.fieldkitLabel:SetWordWrap(false) end
 b.fieldkitLabel:SetJustifyH(w<50 and "CENTER" or "LEFT");b.fieldkitLabel:SetJustifyV("MIDDLE");T.Font(b.fieldkitLabel,w<50 and 11 or 13,T.gold)
 if b.SetFontString then b:SetFontString(b.fieldkitLabel) end
 b.callback=callback
 b:SetScript("OnClick",function() if this.callback then this.callback() end end)
 b:SetScript("OnEnter",function() T.State(this,true) end)
 b:SetScript("OnLeave",function() T.State(this,this.fieldkitSelected) end)
 FieldKit_Text(b,label or "");return b
end

-- Static painted glyph identifiers are shared across the addon family.
function T.Glyph(parent,index,x,y,size)
 local t=parent:CreateTexture(nil,"ARTWORK");t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y)
 t:SetWidth(size);t:SetHeight(size);t:SetTexture(T.media..string.format("ChronicleGlyph%02d.tga",index))
 return t
end

-- Bound only addon chrome. Game-provided names keep their existing native fonts.
function T.Label(parent,key,x,y,w,h,size,color,heading)
 local t=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
 t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y);t:SetWidth(w);t:SetHeight(h or 22)
 t:SetJustifyH("LEFT");t:SetJustifyV("MIDDLE");T.Font(t,size,color,heading)
 if key then FieldKit_Text(t,key) end
 return t
end
