-- On-screen statistics overlay.
-- Reads settings from HSC_SETTINGS and values from HSC_CharacterStats.

function HSC_UI_MainScreenStatistics_Initialize()
  local statsFrame = CreateFrame('Frame', 'HardcoreStatCompanionStatsFrame', UIParent)
  statsFrame:SetSize(200, 120)
  statsFrame:SetClampedToScreen(true)

  -- Position: center by default for new installs; persisted after the user drags the frame.
  local function ApplySavedPosition()
    statsFrame:ClearAllPoints()
    local panel = HSC_PANEL_SETTINGS or HSC_SETTINGS
    local pos = panel and panel.onScreenPanelPosition
    if type(pos) == 'table' and pos.point and pos.relativePoint and pos.x and pos.y then
      statsFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
      statsFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
    end
  end

  local function SavePosition()
    local panel = HSC_PANEL_SETTINGS or HSC_SETTINGS
    if not panel then return end
    local point, _, relativePoint, x, y = statsFrame:GetPoint(1)
    if not point or not relativePoint or not x or not y then return end
    panel.onScreenPanelPosition = {
      point = point,
      relativePoint = relativePoint,
      x = x,
      y = y,
    }
  end

  ApplySavedPosition()

  local statsBackground = statsFrame:CreateTexture(nil, 'BACKGROUND')
  statsBackground:SetAllPoints(statsFrame)

  local function ApplyStatsBackgroundOpacity()
    local alpha = (HSC_SETTINGS and HSC_SETTINGS.statisticsBackgroundOpacity) or 0.3
    if alpha < 0 then alpha = 0 end
    if alpha > 1 then alpha = 1 end
    statsBackground:SetColorTexture(0, 0, 0, alpha)
  end

  local function ApplyScale()
    local scale = (HSC_SETTINGS and HSC_SETTINGS.statisticsScale) or 1
    scale = tonumber(scale) or 1
    if scale < 0.5 then scale = 0.5 end
    if scale > 2 then scale = 2 end
    statsFrame:SetScale(scale)
  end

  ApplyStatsBackgroundOpacity()
  ApplyScale()

  -- Drag locking is controlled by settings (lockOnScreenPanelPosition).
  local function ApplyLockState()
    local locked = HSC_SETTINGS and HSC_SETTINGS.lockOnScreenPanelPosition
    if locked then
      statsFrame:SetMovable(false)
      statsFrame:EnableMouse(false)
      statsFrame:RegisterForDrag()
    else
      statsFrame:SetMovable(true)
      statsFrame:EnableMouse(true)
      statsFrame:RegisterForDrag('LeftButton')

      statsFrame:SetScript('OnDragStart', function(self)
        if self:IsMovable() then
          self:StartMoving()
        end
      end)

      statsFrame:SetScript('OnDragStop', function(self)
        self:StopMovingOrSizing()
        SavePosition()
      end)
    end
  end

  ApplyLockState()

  local function MakeRow(y, labelText)
    local label = statsFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    label:SetPoint('TOPLEFT', statsFrame, 'TOPLEFT', 10, y)
    label:SetText(labelText)
    label:SetFont('Fonts\\FRIZQT__.TTF', 14)

    local value = statsFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    value:SetPoint('TOPRIGHT', statsFrame, 'TOPRIGHT', -10, y)
    value:SetText('')
    value:SetFont('Fonts\\FRIZQT__.TTF', 14)

    return label, value
  end

  local rowsBySetting = {
    showMainStatisticsPanelAccountMaxLevel = { setting = 'showMainStatisticsPanelAccountMaxLevel', label = 'Max Level Account:', accountKey = 'maxLevelOverall', format = 'num' },
    showMainStatisticsPanelClassMaxLevel = { setting = 'showMainStatisticsPanelClassMaxLevel', label = 'Max Level Class:', accountKey = 'maxLevelClass', format = 'num' },
    showMainStatisticsPanelLowestHealth = { setting = 'showMainStatisticsPanelLowestHealth', label = 'Lowest Health:', statKey = 'lowestHealth', format = 'pct1' },
    showMainStatisticsPanelThisLevel = { setting = 'showMainStatisticsPanelThisLevel', label = 'Level Lowest:', statKey = 'lowestHealthThisLevel', format = 'pct1' },
    showMainStatisticsPanelSessionHealth = { setting = 'showMainStatisticsPanelSessionHealth', label = 'Session Lowest:', statKey = 'lowestHealthThisSession', format = 'pct1' },
    showMainStatisticsPanelPetDeaths = { setting = 'showMainStatisticsPanelPetDeaths', label = 'Pet deaths:', statKey = 'petDeaths', format = 'num' },
    showMainStatisticsPanelEnemiesSlain = { setting = 'showMainStatisticsPanelEnemiesSlain', label = 'Enemies slain:', statKey = 'enemiesSlain', format = 'num' },
    showMainStatisticsPanelElitesSlain = { setting = 'showMainStatisticsPanelElitesSlain', label = 'Elites slain:', statKey = 'elitesSlain', format = 'num' },
    showMainStatisticsPanelRareElitesSlain = { setting = 'showMainStatisticsPanelRareElitesSlain', label = 'Rare elites:', statKey = 'rareElitesSlain', format = 'num' },
    showMainStatisticsPanelWorldBossesSlain = { setting = 'showMainStatisticsPanelWorldBossesSlain', label = 'World bosses:', statKey = 'worldBossesSlain', format = 'num' },
    showMainStatisticsPanelDungeonBosses = { setting = 'showMainStatisticsPanelDungeonBosses', label = 'Dungeon bosses:', statKey = 'dungeonBossesKilled', format = 'num' },
    showMainStatisticsPanelDungeonsCompleted = { setting = 'showMainStatisticsPanelDungeonsCompleted', label = 'Dungeons done:', statKey = 'dungeonsCompleted', format = 'num' },
    showMainStatisticsPanelHighestCritValue = { setting = 'showMainStatisticsPanelHighestCritValue', label = 'Highest crit:', statKey = 'highestCritValue', format = 'num' },
    showMainStatisticsPanelHighestHealCritValue = { setting = 'showMainStatisticsPanelHighestHealCritValue', label = 'Heal crit:', statKey = 'highestHealCritValue', format = 'num' },
    showMainStatisticsPanelHealthPotionsUsed = { setting = 'showMainStatisticsPanelHealthPotionsUsed', label = 'Healing pots:', statKey = 'healthPotionsUsed', format = 'num' },
    showMainStatisticsPanelManaPotionsUsed = { setting = 'showMainStatisticsPanelManaPotionsUsed', label = 'Mana pots:', statKey = 'manaPotionsUsed', format = 'num' },
    showMainStatisticsPanelBandagesUsed = { setting = 'showMainStatisticsPanelBandagesUsed', label = 'Bandages:', statKey = 'bandagesApplied', format = 'num' },
    showMainStatisticsPanelTargetDummiesUsed = { setting = 'showMainStatisticsPanelTargetDummiesUsed', label = 'Dummies:', statKey = 'targetDummiesUsed', format = 'num' },
    showMainStatisticsPanelGrenadesUsed = { setting = 'showMainStatisticsPanelGrenadesUsed', label = 'Grenades:', statKey = 'grenadesUsed', format = 'num' },
    showMainStatisticsPanelPartyMemberDeaths = { setting = 'showMainStatisticsPanelPartyMemberDeaths', label = 'Party deaths:', statKey = 'partyMemberDeaths', format = 'num' },
    showMainStatisticsPanelCloseEscapes = { setting = 'showMainStatisticsPanelCloseEscapes', label = 'Close calls:', statKey = 'closeEscapes', format = 'num' },
    showMainStatisticsPanelDuelsTotal = { setting = 'showMainStatisticsPanelDuelsTotal', label = 'Duels:', statKey = 'duelsTotal', format = 'num' },
    showMainStatisticsPanelDuelsWon = { setting = 'showMainStatisticsPanelDuelsWon', label = 'Duels won:', statKey = 'duelsWon', format = 'num' },
    showMainStatisticsPanelDuelsLost = { setting = 'showMainStatisticsPanelDuelsLost', label = 'Duels lost:', statKey = 'duelsLost', format = 'num' },
    showMainStatisticsPanelDuelsWinPercent = { setting = 'showMainStatisticsPanelDuelsWinPercent', label = 'Duels win %:', statKey = 'duelsWinPercent', format = 'pct1' },
    showMainStatisticsPanelPlayerJumps = { setting = 'showMainStatisticsPanelPlayerJumps', label = 'Jumps:', statKey = 'playerJumps', format = 'num' },
    showMainStatisticsPanelMapTimesOpened = { setting = 'showMainStatisticsPanelMapTimesOpened', label = 'Map:', statKey = 'mapTimesOpened', format = 'num' },
    showMainStatisticsPanelClassDeaths = { setting = 'showMainStatisticsPanelClassDeaths', label = 'Class deaths:', accountKey = 'classDeaths', format = 'num' },
    showMainStatisticsPanelAccountTotalDeaths = { setting = 'showMainStatisticsPanelAccountTotalDeaths', label = 'Account deaths:', accountKey = 'totalDeaths', format = 'num' },
  }

  local statsElements = {}
  local lastOrderSignature = nil
  local function ComputeOrderSignature()
    local panel = HSC_PANEL_SETTINGS or HSC_SETTINGS
    if not panel or type(panel.mainPanelRowOrder) ~= 'table' then
      return nil
    end
    return table.concat(panel.mainPanelRowOrder, '|')
  end

  local function BuildElements()
    for _, element in ipairs(statsElements) do
      element.label:Hide()
      element.value:Hide()
    end
    statsElements = {}

    local panel = HSC_PANEL_SETTINGS or HSC_SETTINGS
    local order = (panel and panel.mainPanelRowOrder) or {}
    for _, settingKey in ipairs(order) do
      local row = rowsBySetting[settingKey]
      if row then
        local rowLabel, rowValue = MakeRow(0, row.label)
        statsElements[#statsElements + 1] = {
          label = rowLabel,
          value = rowValue,
          setting = row.setting,
          statKey = row.statKey,
          accountKey = row.accountKey,
          valueKey = row.valueKey,
          format = row.format,
        }
      end
    end
    lastOrderSignature = ComputeOrderSignature()
  end
  BuildElements()

  -- Format a row value from either a per-character stat, an account stat, or a computed field.
  local function FormatValue(element, context)
    if element.statKey then
      local value = HSC_CharacterStats:GetStat(element.statKey)
      if element.format == 'pct1' then
        return string.format('%.1f%%', tonumber(value) or 0)
      end
      return HSC_FormatNumberWithCommas(value or 0)
    end

    if element.accountKey then
      if element.accountKey == 'maxLevelClass' then
        local value = HSC_CharacterStats:GetAccountMaxLevelForCurrentClass()
        return HSC_FormatNumberWithCommas(value or 0)
      end
      if element.accountKey == 'classDeaths' then
        local _, classFile = UnitClass('player')
        local value = HSC_CharacterStats:GetAccountClassDeaths(classFile)
        return HSC_FormatNumberWithCommas(value or 0)
      end
      local value = HSC_CharacterStats:GetAccountStat(element.accountKey, 0)
      return HSC_FormatNumberWithCommas(value or 0)
    end

    return ''
  end

  local function ApplyTextColor()
    local c = (HSC_SETTINGS and HSC_SETTINGS.statisticsTextColor) or {}
    local r = tonumber(c.r) or 1
    local g = tonumber(c.g) or 1
    local b = tonumber(c.b) or 1
    local a = tonumber(c.a)
    if a == nil then a = 1 end

    for _, element in ipairs(statsElements) do
      if element.label and element.label.SetTextColor then
        element.label:SetTextColor(r, g, b, a)
      end
      if element.value and element.value.SetTextColor then
        element.value:SetTextColor(r, g, b, a)
      end
    end
  end

  local function UpdateRowVisibility()
    local panel = HSC_PANEL_SETTINGS or HSC_SETTINGS
    local yOffset = -5
    local visibleRows = 0

    for _, element in ipairs(statsElements) do
      local isVisible = (panel and panel[element.setting]) or false

      if isVisible then
        element.label:ClearAllPoints()
        element.value:ClearAllPoints()
        element.label:SetPoint('TOPLEFT', statsFrame, 'TOPLEFT', 10, yOffset)
        element.value:SetPoint('TOPRIGHT', statsFrame, 'TOPRIGHT', -10, yOffset)
        element.label:Show()
        element.value:Show()
        yOffset = yOffset - 15
        visibleRows = visibleRows + 1
      else
        element.label:Hide()
        element.value:Hide()
      end
    end

    local newHeight = math.max(20, visibleRows * 15 + 10)
    statsFrame:SetSize(200, newHeight)
  end

  local function CheckAddonEnabled()
    if not HSC_SETTINGS or not HSC_SETTINGS.showOnScreenStatistics then
      statsFrame:Hide()
    else
      statsFrame:Show()
      ApplyStatsBackgroundOpacity()
      ApplyScale()
      UpdateRowVisibility()
      ApplyTextColor()
    end
  end

  local function UpdateStatistics()
    for _, element in ipairs(statsElements) do
      element.value:SetText(FormatValue(element))
    end
  end

  local eventFrame = CreateFrame('Frame')
  eventFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
  eventFrame:RegisterEvent('UNIT_HEALTH')
  eventFrame:RegisterEvent('UNIT_MAXHEALTH')
  eventFrame:RegisterEvent('PLAYER_LEVEL_UP')
  eventFrame:SetScript('OnEvent', function(_, event, unit)
    if (event == 'UNIT_HEALTH' or event == 'UNIT_MAXHEALTH') and unit ~= 'player' then
      return
    end
    UpdateStatistics()
    CheckAddonEnabled()
  end)

  -- Public hooks used by OptionsPanel and stat tracker to refresh and re-apply state.
  HardcoreStatCompanionStatsFrame = statsFrame
  HardcoreStatCompanionStatsFrame.UpdateRowVisibility = function()
    local signature = ComputeOrderSignature()
    if signature ~= lastOrderSignature then
      BuildElements()
      UpdateStatistics()
      ApplyTextColor()
    end
    UpdateRowVisibility()
  end
  HardcoreStatCompanionStatsFrame.ApplyStatsBackgroundOpacity = ApplyStatsBackgroundOpacity
  HardcoreStatCompanionStatsFrame.CheckAddonEnabled = CheckAddonEnabled
  HardcoreStatCompanionStatsFrame.ApplyLockState = ApplyLockState
  HardcoreStatCompanionStatsFrame.ApplyScale = ApplyScale
  HardcoreStatCompanionStatsFrame.ApplyTextColor = ApplyTextColor
  HardcoreStatCompanionStatsFrame.ApplySavedPosition = ApplySavedPosition
  HardcoreStatCompanionStatsFrame.Refresh = function()
    UpdateStatistics()
    CheckAddonEnabled()
  end

  UpdateStatistics()
  CheckAddonEnabled()
end
