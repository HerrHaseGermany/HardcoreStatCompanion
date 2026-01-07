-- Standalone configuration window toggled via /hsc.
-- Provides the same overlay-related settings as the Blizzard Options panel.

local function Clamp01(v)
  if v < 0 then return 0 end
  if v > 1 then return 1 end
  return v
end

local function EnsureMainFrame()
  if HardcoreStatCompanion_MainFrame then
    return HardcoreStatCompanion_MainFrame
  end

  local frame = CreateFrame('Frame', 'HardcoreStatCompanion_MainFrame', UIParent, 'BackdropTemplate')
  frame:SetSize(640, 560)
  frame:SetPoint('CENTER')
  frame:SetBackdrop({
    bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
    edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
    tile = true,
    tileSize = 64,
    edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 },
  })
  frame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
  frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
  frame:Hide()

  local title = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
  title:SetPoint('TOPLEFT', frame, 'TOPLEFT', 16, -12)
  title:SetText('Hardcore Stat Companion')

  local close = CreateFrame('Button', nil, frame, 'UIPanelCloseButton')
  close:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 2, 2)

  HSC_MakeFrameDraggable(frame)

  return frame
end

local function CreateCheckbox(parent, label, tooltip)
  local cb = CreateFrame('CheckButton', nil, parent, 'UICheckButtonTemplate')
  cb.Text:SetText(label)
  cb.tooltipText = tooltip
  return cb
end

local function CreateSlider(parent, label)
  local slider = CreateFrame('Slider', nil, parent, 'OptionsSliderTemplate')
  slider:SetMinMaxValues(0, 100)
  slider:SetValueStep(1)
  slider.Text:SetText(label)
  slider.Low:SetText('0%')
  slider.High:SetText('100%')
  return slider
end

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

function HSC_UI_StatisticsWindow_Initialize()
  local frame = EnsureMainFrame()

  local content = CreateFrame('Frame', nil, frame)
  content:SetPoint('TOPLEFT', frame, 'TOPLEFT', 16, -40)
  content:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -16, 16)

  local header = content:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
  header:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, 0)
  header:SetText('On-screen panel')

  local showPanel = CreateCheckbox(content, 'Show on-screen statistics panel', nil)
  showPanel:SetPoint('TOPLEFT', header, 'BOTTOMLEFT', 0, -8)
  showPanel:SetChecked(HSC_SETTINGS.showOnScreenStatistics)
  showPanel:SetScript('OnClick', function(self)
    HSC_SETTINGS.showOnScreenStatistics = self:GetChecked() and true or false
    RefreshOverlay()
  end)

  local opacity = CreateSlider(content, 'Background opacity')
  opacity:SetPoint('TOPLEFT', showPanel, 'BOTTOMLEFT', 0, -28)
  opacity:SetPoint('TOPRIGHT', content, 'TOPRIGHT', 0, 0)
  opacity:SetValue((HSC_SETTINGS.statisticsBackgroundOpacity or 0.3) * 100)
  opacity:SetScript('OnValueChanged', function(self, value)
    HSC_SETTINGS.statisticsBackgroundOpacity = Clamp01((value or 30) / 100)
    RefreshOverlay()
  end)

  local rowsHeader = content:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
  rowsHeader:SetPoint('TOPLEFT', opacity, 'BOTTOMLEFT', 0, -18)
  rowsHeader:SetText('Rows')

  local rowsScroll = CreateFrame('ScrollFrame', nil, content, 'UIPanelScrollFrameTemplate')
  rowsScroll:SetPoint('TOPLEFT', rowsHeader, 'BOTTOMLEFT', 0, -8)
  rowsScroll:SetPoint('BOTTOMRIGHT', content, 'BOTTOMRIGHT', -26, 24)

  local rowsContent = CreateFrame('Frame', nil, rowsScroll)
  rowsContent:SetSize(1, 1)
  rowsScroll:SetScrollChild(rowsContent)

  local rowsByKey = {
    showMainStatisticsPanelAccountMaxLevel = { key = 'showMainStatisticsPanelAccountMaxLevel', label = 'Max level (account)' },
    showMainStatisticsPanelClassMaxLevel = { key = 'showMainStatisticsPanelClassMaxLevel', label = 'Max level (current class)' },
    showMainStatisticsPanelLowestHealth = { key = 'showMainStatisticsPanelLowestHealth', label = 'Lowest Health' },
    showMainStatisticsPanelThisLevel = { key = 'showMainStatisticsPanelThisLevel', label = 'Level Lowest' },
    showMainStatisticsPanelSessionHealth = { key = 'showMainStatisticsPanelSessionHealth', label = 'Session Lowest' },
    showMainStatisticsPanelAccountTotalDeaths = { key = 'showMainStatisticsPanelAccountTotalDeaths', label = 'Account deaths (all characters)' },
    showMainStatisticsPanelPetDeaths = { key = 'showMainStatisticsPanelPetDeaths', label = 'Pet deaths' },
    showMainStatisticsPanelPartyMemberDeaths = { key = 'showMainStatisticsPanelPartyMemberDeaths', label = 'Party member deaths' },
    showMainStatisticsPanelEnemiesSlain = { key = 'showMainStatisticsPanelEnemiesSlain', label = 'Enemies slain' },
    showMainStatisticsPanelElitesSlain = { key = 'showMainStatisticsPanelElitesSlain', label = 'Elites slain' },
    showMainStatisticsPanelRareElitesSlain = { key = 'showMainStatisticsPanelRareElitesSlain', label = 'Rare elites slain' },
    showMainStatisticsPanelWorldBossesSlain = { key = 'showMainStatisticsPanelWorldBossesSlain', label = 'World bosses slain' },
    showMainStatisticsPanelDungeonBosses = { key = 'showMainStatisticsPanelDungeonBosses', label = 'Dungeon bosses killed' },
    showMainStatisticsPanelDungeonsCompleted = { key = 'showMainStatisticsPanelDungeonsCompleted', label = 'Dungeons completed' },
    showMainStatisticsPanelHighestCritValue = { key = 'showMainStatisticsPanelHighestCritValue', label = 'Highest crit (damage)' },
    showMainStatisticsPanelHighestHealCritValue = { key = 'showMainStatisticsPanelHighestHealCritValue', label = 'Highest crit (healing)' },
    showMainStatisticsPanelHealthPotionsUsed = { key = 'showMainStatisticsPanelHealthPotionsUsed', label = 'Healing potions used' },
    showMainStatisticsPanelManaPotionsUsed = { key = 'showMainStatisticsPanelManaPotionsUsed', label = 'Mana potions used' },
    showMainStatisticsPanelBandagesUsed = { key = 'showMainStatisticsPanelBandagesUsed', label = 'Bandages applied' },
    showMainStatisticsPanelTargetDummiesUsed = { key = 'showMainStatisticsPanelTargetDummiesUsed', label = 'Target dummies used' },
    showMainStatisticsPanelGrenadesUsed = { key = 'showMainStatisticsPanelGrenadesUsed', label = 'Grenades used' },
    showMainStatisticsPanelCloseEscapes = { key = 'showMainStatisticsPanelCloseEscapes', label = 'Close escapes' },
    showMainStatisticsPanelDuelsTotal = { key = 'showMainStatisticsPanelDuelsTotal', label = 'Duels (total)' },
    showMainStatisticsPanelDuelsWon = { key = 'showMainStatisticsPanelDuelsWon', label = 'Duels (won)' },
    showMainStatisticsPanelDuelsLost = { key = 'showMainStatisticsPanelDuelsLost', label = 'Duels (lost)' },
    showMainStatisticsPanelDuelsWinPercent = { key = 'showMainStatisticsPanelDuelsWinPercent', label = 'Duels (win %)' },
    showMainStatisticsPanelPlayerJumps = { key = 'showMainStatisticsPanelPlayerJumps', label = 'Player jumps' },
    showMainStatisticsPanelMapTimesOpened = { key = 'showMainStatisticsPanelMapTimesOpened', label = 'Map opened' },
    showMainStatisticsPanelClassDeaths = { key = 'showMainStatisticsPanelClassDeaths', label = 'Class deaths (current class)' },
  }

  local orderedKeys = (HSC_SETTINGS and HSC_SETTINGS.mainPanelRowOrder) or {}
  local last = nil
  local contentHeight = 0
  for _, key in ipairs(orderedKeys) do
    local row = rowsByKey[key]
    if row then
      local cb = CreateCheckbox(rowsContent, row.label, nil)
      if last then
        cb:SetPoint('TOPLEFT', last, 'BOTTOMLEFT', 0, -6)
      else
        cb:SetPoint('TOPLEFT', rowsContent, 'TOPLEFT', 0, 0)
      end
      cb:SetChecked(HSC_SETTINGS[row.key] and true or false)
      cb:SetScript('OnClick', function(self)
        HSC_SETTINGS[row.key] = self:GetChecked() and true or false
        RefreshOverlay()
      end)
      last = cb
      contentHeight = contentHeight + cb:GetHeight() + 6
    end
  end
  rowsContent:SetHeight(math.max(1, contentHeight))

  local hint = content:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  hint:SetPoint('BOTTOMLEFT', content, 'BOTTOMLEFT', 0, 0)
  hint:SetText('Tip: use /hsc to toggle this window. Drag the on-screen panel to reposition it.')
end

function HSC_UI_StatisticsWindow_Toggle()
  local frame = EnsureMainFrame()
  if frame:IsShown() then
    frame:Hide()
  else
    frame:Show()
  end
end
