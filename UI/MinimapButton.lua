-- Minimap button: left-click toggles the overlay, right-click opens options, drag to move.

local function RefreshOverlay()
  if HardcoreStatCompanionStatsFrame and HardcoreStatCompanionStatsFrame.UpdateRowVisibility then
    HardcoreStatCompanionStatsFrame.UpdateRowVisibility()
  end
  if HardcoreStatCompanionStatsFrame and HardcoreStatCompanionStatsFrame.ApplyStatsBackgroundOpacity then
    HardcoreStatCompanionStatsFrame.ApplyStatsBackgroundOpacity()
  end
  if HardcoreStatCompanionStatsFrame and HardcoreStatCompanionStatsFrame.CheckAddonEnabled then
    HardcoreStatCompanionStatsFrame.CheckAddonEnabled()
  end
end

local function OpenOptions()
  if Settings and Settings.OpenToCategory then
    Settings.OpenToCategory('Hardcore Stat Companion')
    return
  end

  if InterfaceOptionsFrame_OpenToCategory and HardcoreStatCompanionOptionsPanel then
    InterfaceOptionsFrame_OpenToCategory(HardcoreStatCompanionOptionsPanel)
    InterfaceOptionsFrame_OpenToCategory(HardcoreStatCompanionOptionsPanel)
  end
end

local function SetAngle(angle)
  if not HSC_SETTINGS then return end
  HSC_SETTINGS.minimapButtonAngle = angle
end

local function GetAngle()
  return (HSC_SETTINGS and HSC_SETTINGS.minimapButtonAngle) or 225
end

local function UpdatePosition(button)
  local angle = GetAngle()
  local rad = math.rad(angle)
  local radius = 80
  local x = math.cos(rad) * radius
  local y = math.sin(rad) * radius
  button:SetPoint('CENTER', Minimap, 'CENTER', x, y)
end

function HSC_UI_MinimapButton_Initialize()
  if HardcoreStatCompanion_MinimapButton then
    return
  end

  local button = CreateFrame('Button', 'HardcoreStatCompanion_MinimapButton', Minimap)
  button:SetFrameStrata('MEDIUM')
  button:SetSize(32, 32)
  button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
  button:RegisterForDrag('LeftButton')

  local icon = button:CreateTexture(nil, 'BACKGROUND')
  icon:SetSize(18, 18)
  icon:SetPoint('CENTER', 0, 1)
  icon:SetTexture('Interface\\Icons\\INV_Misc_Book_09')
  button.icon = icon

  local overlay = button:CreateTexture(nil, 'OVERLAY')
  overlay:SetSize(54, 54)
  overlay:SetPoint('TOPLEFT')
  overlay:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder')

  button:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')

  local function ApplyEnabledState()
    if HSC_SETTINGS and HSC_SETTINGS.minimapButtonEnabled == false then
      button:Hide()
    else
      button:Show()
      button:ClearAllPoints()
      UpdatePosition(button)
    end
  end

  button:SetScript('OnEnter', function(self)
    if GameTooltip then
      GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
      GameTooltip:SetText('Hardcore Stat Companion')
      GameTooltip:AddLine('Left-click: Toggle on-screen panel', 1, 1, 1)
      GameTooltip:AddLine('Right-click: Open options', 1, 1, 1)
      GameTooltip:AddLine('Drag: Move button', 1, 1, 1)
      GameTooltip:Show()
    end
  end)

  button:SetScript('OnLeave', function()
    if GameTooltip then
      GameTooltip:Hide()
    end
  end)

  button:SetScript('OnClick', function(_, mouseButton)
    if mouseButton == 'LeftButton' then
      if not HSC_SETTINGS then return end
      HSC_SETTINGS.showOnScreenStatistics = not HSC_SETTINGS.showOnScreenStatistics
      RefreshOverlay()
    elseif mouseButton == 'RightButton' then
      OpenOptions()
    end
  end)

  button:SetScript('OnDragStart', function(self)
    self.isDragging = true
  end)

  button:SetScript('OnDragStop', function(self)
    self.isDragging = false
  end)

  button:SetScript('OnUpdate', function(self)
    if not self.isDragging then return end
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    cx, cy = cx / scale, cy / scale
    local dx, dy = cx - mx, cy - my
    local angle = math.deg(math.atan2(dy, dx))
    SetAngle(angle)
    self:ClearAllPoints()
    UpdatePosition(self)
  end)

  ApplyEnabledState()
  HardcoreStatCompanion_MinimapButton = button
  button.ApplyEnabledState = ApplyEnabledState
end
