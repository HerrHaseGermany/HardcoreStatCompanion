local function EnsureTable(root, key)
  root[key] = root[key] or {}
  return root[key]
end

local function GetCharacterKey()
  local guid = UnitGUID and UnitGUID('player')
  if guid and guid ~= '' then
    return guid
  end

  local name = UnitName('player') or 'Unknown'
  local realm = GetRealmName() or 'UnknownRealm'
  return realm .. '-' .. name
end

local function GetLegacyCharacterKey()
  local name = UnitName('player') or 'Unknown'
  local realm = GetRealmName() or 'UnknownRealm'
  return realm .. '-' .. name
end

local function EnsurePerCharacterStore(global)
  local perChar = EnsureTable(global, 'characters')

  -- Migrate legacy per-character key (realm-name) to GUID when possible.
  local guidKey = UnitGUID and UnitGUID('player')
  if guidKey and guidKey ~= '' then
    local legacyKey = GetLegacyCharacterKey()
    if legacyKey ~= guidKey then
      local legacy = perChar[legacyKey]
      if legacy then
        local dest = perChar[guidKey]
        if dest == nil then
          perChar[guidKey] = legacy
          perChar[legacyKey] = nil
        else
          dest.panelSettings = dest.panelSettings or {}
          local legacyPanel = legacy.panelSettings or {}
          for k, v in pairs(legacyPanel) do
            if dest.panelSettings[k] == nil then
              dest.panelSettings[k] = v
            end
          end
          -- Keep legacy entry so CharacterStats can safely migrate/merge stats later.
        end
      end
    end
  end

  local key = GetCharacterKey()
  return EnsureTable(perChar, key)
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

  -- Per-character panel settings: position + row choice/order.
  local characterStore = EnsurePerCharacterStore(global)
  characterStore.panelSettings = characterStore.panelSettings or {}
  local panelSettings = characterStore.panelSettings

  if type(panelSettings.onScreenPanelPosition) ~= 'table' then
    if type(settings.onScreenPanelPosition) == 'table' then
      panelSettings.onScreenPanelPosition = settings.onScreenPanelPosition
    else
      panelSettings.onScreenPanelPosition = nil
    end
  end

  -- Per-row visibility toggles for the on-screen panel (per character).
  -- Defaults apply only when no saved value exists for the character; existing installs seed from legacy global.
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
    if panelSettings[key] == nil then
      if settings[key] ~= nil then
        panelSettings[key] = settings[key]
      else
        panelSettings[key] = defaultValue
      end
    end
  end

  -- Default display order for rows on the on-screen panel (user-customizable, per character).
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

  if type(panelSettings.mainPanelRowOrder) ~= 'table' then
    if type(settings.mainPanelRowOrder) == 'table' then
      local copied = {}
      for i, v in ipairs(settings.mainPanelRowOrder) do
        copied[i] = v
      end
      panelSettings.mainPanelRowOrder = copied
    else
      panelSettings.mainPanelRowOrder = defaultRowOrder
    end
  else
    local seen = {}
    for _, key in ipairs(panelSettings.mainPanelRowOrder) do
      seen[key] = true
    end
    for _, key in ipairs(defaultRowOrder) do
      if not seen[key] then
        panelSettings.mainPanelRowOrder[#panelSettings.mainPanelRowOrder + 1] = key
      end
    end
  end

  -- Migrations / cleanups for older SavedVariables keys (per character).
  if panelSettings.showMainStatisticsPanelMapTimesOpened == nil and panelSettings.showMainStatisticsPanelMapKeyPressesWhileMapBlocked ~= nil then
    panelSettings.showMainStatisticsPanelMapTimesOpened = panelSettings.showMainStatisticsPanelMapKeyPressesWhileMapBlocked
    panelSettings.showMainStatisticsPanelMapKeyPressesWhileMapBlocked = nil
  end

  if panelSettings.showMainStatisticsPanelAccountMaxLevel == nil and panelSettings.showMainStatisticsPanelLevel ~= nil then
    panelSettings.showMainStatisticsPanelAccountMaxLevel = panelSettings.showMainStatisticsPanelLevel
  end
  if panelSettings.showMainStatisticsPanelClassMaxLevel == nil then
    panelSettings.showMainStatisticsPanelClassMaxLevel = false
  end

  if type(panelSettings.mainPanelRowOrder) == 'table' then
    for i = #panelSettings.mainPanelRowOrder, 1, -1 do
      if panelSettings.mainPanelRowOrder[i] == 'showMainStatisticsPanelLevel' then
        panelSettings.mainPanelRowOrder[i] = 'showMainStatisticsPanelAccountMaxLevel'
      end
    end

    local deduped = {}
    local seen = {}
    for _, key in ipairs(panelSettings.mainPanelRowOrder) do
      if not seen[key] then
        seen[key] = true
        deduped[#deduped + 1] = key
      end
    end
    panelSettings.mainPanelRowOrder = deduped
  end

  if type(panelSettings.mainPanelRowOrder) == 'table' then
    local cleaned = {}
    for _, key in ipairs(panelSettings.mainPanelRowOrder) do
      if key ~= 'showMainStatisticsPanelTotalHP' and key ~= 'showMainStatisticsPanelTotalMana' then
        cleaned[#cleaned + 1] = key
      end
    end
    panelSettings.mainPanelRowOrder = cleaned
  end

  -- Expose settings as a global for other modules.
  HSC_SETTINGS = settings
  HSC_PANEL_SETTINGS = panelSettings
end
