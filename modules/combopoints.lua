StupidComboEnergyNS = StupidComboEnergyNS or {}
local SCE = StupidComboEnergyNS
SCE._moduleLoaded = SCE._moduleLoaded or {}
SCE._moduleLoaded.combopoints = true

-- Don't cache SCE.CP or SCE.clamp at load time - they may not be defined yet

local function setComboPoints(cp)
  local CP = SCE.CP  -- Access at call time
  local clamp = SCE.clamp or function(x, lo, hi) if x < lo then return lo end if x > hi then return hi end return x end
  
  if not CP or not CP.segs then return end

  local db = StupidComboEnergyDB or {}
  local mode = db.cpColorMode or "unified"
  local showOnlyActive = (db.showOnlyActiveCombo == "1" and db.hideComboWhenEmpty == "1")
  local function pickColors(idx, cpCount)
    if mode == "finisher" then
      if cpCount >= 5 then
        return db.cpFillFinisher or db.cpFill, db.cpFillFinisher2 or db.cpFill2
      end
      return db.cpFillBase or db.cpFill, db.cpFillBase2 or db.cpFill2
    elseif mode == "split" then
      if cpCount >= 5 then
        return db.cpFillFinisher or db.cpFill, db.cpFillFinisher2 or db.cpFill2
      end
      if idx <= 2 then
        return db.cpFillBase or db.cpFill, db.cpFillBase2 or db.cpFill2
      end
      return db.cpFillMid or db.cpFill, db.cpFillMid2 or db.cpFill2
    end
    return db.cpFill, db.cpFill2
  end

  cp = clamp(cp or 0, 0, 5)
  SCE.comboPoints = cp
  for i = 1, 5 do
    local seg = CP.segs[i]
    if seg then
      if showOnlyActive and i > cp then
        seg:Hide()
      else
        seg:Show()
      end
      local c1, c2 = pickColors(i, cp)
      if SCE.setBarColor then
        SCE.setBarColor(seg, db.cpStyle, c1, c2)
      elseif seg.SetStatusBarColor then
        seg:SetStatusBarColor(c1[1], c1[2], c1[3], c1[4] or 1)
      end
      if i <= cp then
        seg:SetValue(1)
      else
        seg:SetValue(0)
      end
    end
  end

  if CP.separators then
    local sepStyle = db.cpSeparatorStyle or "gap"
    for i = 1, 4 do
      local sep = CP.separators[i]
      if sep then
        if sepStyle == "gap" then
          sep:Hide()
        elseif showOnlyActive then
          if i < cp then
            sep:Show()
          else
            sep:Hide()
          end
        else
          sep:Show()
        end
      end
    end
  end
end

SCE.setComboPoints = setComboPoints

if SCE.debugMsg then
  SCE.debugMsg("Loaded module: combopoints.lua")
end
