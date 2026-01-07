local function EnsureTable(root, key)
  root[key] = root[key] or {}
  return root[key]
end

function HSC_Settings_Initialize()
  -- Account-wide SavedVariables container:
  -- HardcoreStatCompanionDB.global.settings stores UI/settings state shared across characters.
  local global = EnsureTable(HardcoreStatCompanionDB, 'global')
  global.settings = global.settings or {}

  local settings = global.settings

  -- Core UI toggles.
  if settings.showOnScreenStatistics == nil then
    settings.showOnScreenStatistics = true
  end
  if settings.statisticsBackgroundOpacity == nil then
    settings.statisticsBackgroundOpacity = 0.3
  end
  if settings.statisticsScale == nil then
    settings.statisticsScale = 1.0
  end
  if type(settings.statisticsTextColor) ~= 'table' then
    settings.statisticsTextColor = { r = 1, g = 1, b = 1, a = 1 }
  end
  if settings.lockOnScreenPanelPosition == nil then
    settings.lockOnScreenPanelPosition = false
  end
  if type(settings.onScreenPanelPosition) ~= 'table' then
    settings.onScreenPanelPosition = nil
  end
  if settings.minimapButtonEnabled == nil then
    settings.minimapButtonEnabled = true
  end
  if settings.minimapButtonAngle == nil then
    settings.minimapButtonAngle = 225
  end
  -- Manual adjustment timestamps (epoch seconds). Used only for display/auditing.
  if settings.deathCountAdjustLastAtTotal == nil then
    settings.deathCountAdjustLastAtTotal = nil
  end
  if settings.deathCountAdjustLastAtClass == nil then
    settings.deathCountAdjustLastAtClass = nil
  end

  -- Per-row visibility toggles for the on-screen panel.
  -- These defaults apply only to a fresh install; existing installs keep their saved values.
  local rowDefaults = {
    showMainStatisticsPanelAccountTotalDeaths = true,
    showMainStatisticsPanelClassDeaths = true,
    showMainStatisticsPanelAccountMaxLevel = true,
    showMainStatisticsPanelClassMaxLevel = true,
    showMainStatisticsPanelLowestHealth = true,
    showMainStatisticsPanelThisLevel = false,
    showMainStatisticsPanelSessionHealth = true,
    showMainStatisticsPanelPetDeaths = false,
    showMainStatisticsPanelEnemiesSlain = true,
    showMainStatisticsPanelElitesSlain = false,
    showMainStatisticsPanelRareElitesSlain = false,
    showMainStatisticsPanelWorldBossesSlain = false,
    showMainStatisticsPanelDungeonBosses = false,
    showMainStatisticsPanelDungeonsCompleted = false,
    showMainStatisticsPanelHealthPotionsUsed = false,
    showMainStatisticsPanelManaPotionsUsed = false,
    showMainStatisticsPanelBandagesUsed = false,
    showMainStatisticsPanelTargetDummiesUsed = false,
    showMainStatisticsPanelGrenadesUsed = false,
    showMainStatisticsPanelPartyMemberDeaths = false,
    showMainStatisticsPanelHighestCritValue = false,
    showMainStatisticsPanelHighestHealCritValue = false,
    showMainStatisticsPanelCloseEscapes = false,
    showMainStatisticsPanelDuelsTotal = false,
    showMainStatisticsPanelDuelsWon = false,
    showMainStatisticsPanelDuelsLost = false,
    showMainStatisticsPanelDuelsWinPercent = false,
    showMainStatisticsPanelPlayerJumps = false,
    showMainStatisticsPanelMapTimesOpened = false,
  }

  for key, defaultValue in pairs(rowDefaults) do
    if settings[key] == nil then
      settings[key] = defaultValue
    end
  end

  -- Default display order for rows on the on-screen panel (user-customizable).
  local defaultRowOrder = {
    'showMainStatisticsPanelAccountTotalDeaths',
    'showMainStatisticsPanelClassDeaths',
    'showMainStatisticsPanelAccountMaxLevel',
    'showMainStatisticsPanelClassMaxLevel',
    'showMainStatisticsPanelLowestHealth',
    'showMainStatisticsPanelThisLevel',
    'showMainStatisticsPanelSessionHealth',
    'showMainStatisticsPanelPetDeaths',
    'showMainStatisticsPanelEnemiesSlain',
    'showMainStatisticsPanelElitesSlain',
    'showMainStatisticsPanelRareElitesSlain',
    'showMainStatisticsPanelWorldBossesSlain',
    'showMainStatisticsPanelDungeonBosses',
    'showMainStatisticsPanelDungeonsCompleted',
    'showMainStatisticsPanelHealthPotionsUsed',
    'showMainStatisticsPanelManaPotionsUsed',
    'showMainStatisticsPanelBandagesUsed',
    'showMainStatisticsPanelTargetDummiesUsed',
    'showMainStatisticsPanelGrenadesUsed',
    'showMainStatisticsPanelPartyMemberDeaths',
    'showMainStatisticsPanelHighestCritValue',
    'showMainStatisticsPanelHighestHealCritValue',
    'showMainStatisticsPanelCloseEscapes',
    'showMainStatisticsPanelDuelsTotal',
    'showMainStatisticsPanelDuelsWon',
    'showMainStatisticsPanelDuelsLost',
    'showMainStatisticsPanelDuelsWinPercent',
    'showMainStatisticsPanelPlayerJumps',
    'showMainStatisticsPanelMapTimesOpened',
  }

  if type(settings.mainPanelRowOrder) ~= 'table' then
    settings.mainPanelRowOrder = defaultRowOrder
  else
    local seen = {}
    for _, key in ipairs(settings.mainPanelRowOrder) do
      seen[key] = true
    end
    for _, key in ipairs(defaultRowOrder) do
      if not seen[key] then
        settings.mainPanelRowOrder[#settings.mainPanelRowOrder + 1] = key
      end
    end
  end

  -- Migrations / cleanups for older SavedVariables keys.
  if settings.showMainStatisticsPanelMapTimesOpened == nil and settings.showMainStatisticsPanelMapKeyPressesWhileMapBlocked ~= nil then
    settings.showMainStatisticsPanelMapTimesOpened = settings.showMainStatisticsPanelMapKeyPressesWhileMapBlocked
    settings.showMainStatisticsPanelMapKeyPressesWhileMapBlocked = nil
  end

  if settings.showMainStatisticsPanelAccountMaxLevel == nil and settings.showMainStatisticsPanelLevel ~= nil then
    settings.showMainStatisticsPanelAccountMaxLevel = settings.showMainStatisticsPanelLevel
  end
  if settings.showMainStatisticsPanelClassMaxLevel == nil then
    settings.showMainStatisticsPanelClassMaxLevel = false
  end

  if type(settings.mainPanelRowOrder) == 'table' then
    for i = #settings.mainPanelRowOrder, 1, -1 do
      if settings.mainPanelRowOrder[i] == 'showMainStatisticsPanelLevel' then
        settings.mainPanelRowOrder[i] = 'showMainStatisticsPanelAccountMaxLevel'
      end
    end

    local deduped = {}
    local seen = {}
    for _, key in ipairs(settings.mainPanelRowOrder) do
      if not seen[key] then
        seen[key] = true
        deduped[#deduped + 1] = key
      end
    end
    settings.mainPanelRowOrder = deduped
  end

  if type(settings.mainPanelRowOrder) == 'table' then
    local cleaned = {}
    for _, key in ipairs(settings.mainPanelRowOrder) do
      if key ~= 'showMainStatisticsPanelTotalHP' and key ~= 'showMainStatisticsPanelTotalMana' then
        cleaned[#cleaned + 1] = key
      end
    end
    settings.mainPanelRowOrder = cleaned
  end

  -- Expose settings as a global for other modules.
  HSC_SETTINGS = settings
end
