-- Per-character + account-wide stat tracking and persistence.
-- Per-character stats are stored in HardcoreStatCompanionDB.global.characters[characterKey].stats
-- characterKey is the character's GUID when available (fallback: realm-name).
-- Account-wide stats are stored in HardcoreStatCompanionDB.global.accountStats

local function GetCharacterKey()
  -- Prefer the per-character GUID so reusing a name starts fresh stats.
  -- Example: "Player-6113-048CAE15" (realm id can differ between clients).
  local guid = UnitGUID and UnitGUID('player')
  if guid and guid ~= '' then
    return guid
  end

  -- Fallback when GUID isn't available yet (early load).
  local name = UnitName('player') or 'Unknown'
  local realm = GetRealmName() or 'UnknownRealm'
  return realm .. '-' .. name
end

local function GetLegacyCharacterKey()
  local name = UnitName('player') or 'Unknown'
  local realm = GetRealmName() or 'UnknownRealm'
  return realm .. '-' .. name
end

local function EnsureTable(root, key)
  root[key] = root[key] or {}
  return root[key]
end

local defaults = {
  lowestHealth = 100,
  lowestHealthThisLevel = 100,
  lowestHealthThisSession = 100,
  petDeaths = 0,
  enemiesSlain = 0,
  elitesSlain = 0,
  rareElitesSlain = 0,
  worldBossesSlain = 0,
  dungeonBossesKilled = 0,
  dungeonsCompleted = 0,
  highestCritValue = 0,
  highestHealCritValue = 0,
  healthPotionsUsed = 0,
  manaPotionsUsed = 0,
  bandagesApplied = 0,
  targetDummiesUsed = 0,
  grenadesUsed = 0,
  partyMemberDeaths = 0,
  closeEscapes = 0,
  duelsTotal = 0,
  duelsWon = 0,
  duelsLost = 0,
  duelsWinPercent = 0,
  playerJumps = 0,
  mapTimesOpened = 0,
}

local stats = {
  defaults = defaults,
}

local uiState = {
  refreshPending = false,
}

-- Trigger a UI refresh on the next frame when tracked values change.
-- This keeps the overlay live-updating even when the change comes from hooks (not events the UI listens to).
local function RequestUIRefresh()
  if uiState.refreshPending then return end
  uiState.refreshPending = true

  local function DoRefresh()
    uiState.refreshPending = false
    if HardcoreStatCompanionStatsFrame and HardcoreStatCompanionStatsFrame.Refresh then
      HardcoreStatCompanionStatsFrame.Refresh()
    end
  end

  if C_Timer and C_Timer.After then
    C_Timer.After(0, DoRefresh)
  else
    DoRefresh()
  end
end

-- Clamp a percentage into [0,100] to keep display stats sane.
local function SafePct(n)
  n = tonumber(n) or 0
  if n < 0 then return 0 end
  if n > 100 then return 100 end
  return n
end

function stats:_GetStore()
  local global = EnsureTable(HardcoreStatCompanionDB, 'global')
  local perChar = EnsureTable(global, 'characters')
  -- Attempt migration before creating a new store for the GUID key.
  self:_MigrateLegacyCharacterKey()
  local key = GetCharacterKey()
  local store = EnsureTable(perChar, key)
  store.stats = store.stats or {}
  return store.stats
end

function stats:_MigrateLegacyCharacterKey()
  local global = EnsureTable(HardcoreStatCompanionDB, 'global')
  local perChar = EnsureTable(global, 'characters')

  local guidKey = UnitGUID and UnitGUID('player')
  if not guidKey or guidKey == '' then return end

  local legacyKey = GetLegacyCharacterKey()
  if legacyKey == guidKey then return end

  local legacy = perChar[legacyKey]
  if not legacy then return end

  local dest = perChar[guidKey]
  if dest == nil then
    perChar[guidKey] = legacy
    perChar[legacyKey] = nil
    return
  end

  -- If the GUID entry already exists (e.g. created earlier in this session), merge legacy stats into it.
  dest.stats = dest.stats or {}
  local legacyStats = legacy.stats or {}
  for k, v in pairs(legacyStats) do
    if dest.stats[k] == nil then
      dest.stats[k] = v
    end
  end
  perChar[legacyKey] = nil
end

function stats:_GetAccountStore()
  local global = EnsureTable(HardcoreStatCompanionDB, 'global')
  global.accountStats = global.accountStats or {}
  return global.accountStats
end

-- One-time migration for older per-character keys.
function stats:_MigrateStore(store)
  if not store then return end
  if store.mapTimesOpened == nil and store.mapKeyPressesWhileMapBlocked ~= nil then
    store.mapTimesOpened = store.mapKeyPressesWhileMapBlocked
    store.mapKeyPressesWhileMapBlocked = nil
  end
end

function stats:GetStat(key)
  local store = self:_GetStore()
  self:_MigrateStore(store)
  local value = store[key]
  if value == nil then
    return self.defaults[key]
  end
  return value
end

function stats:UpdateStat(key, value)
  local store = self:_GetStore()
  self:_MigrateStore(store)
  store[key] = value
  RequestUIRefresh()
end

function stats:IncrementStat(key, delta)
  delta = delta or 1
  local current = self:GetStat(key) or 0
  self:UpdateStat(key, current + delta)
end

-- Account-wide stat accessors (stored in HardcoreStatCompanionDB.global.accountStats).
function stats:GetAccountStat(key, defaultValue)
  local store = self:_GetAccountStore()
  local value = store[key]
  if value == nil then
    return defaultValue
  end
  return value
end

function stats:UpdateAccountStat(key, value)
  local store = self:_GetAccountStore()
  store[key] = value
  RequestUIRefresh()
end

function stats:IncrementAccountStat(key, delta)
  delta = delta or 1
  local current = self:GetAccountStat(key, 0) or 0
  self:UpdateAccountStat(key, current + delta)
end

-- Account-wide deaths tracking (overall + by class).
function stats:IncrementAccountClassDeath()
  local _, classFile = UnitClass('player')
  classFile = classFile or 'UNKNOWN'

  local store = self:_GetAccountStore()
  store.deathsByClass = store.deathsByClass or {}
  store.deathsByClass[classFile] = (store.deathsByClass[classFile] or 0) + 1
  RequestUIRefresh()
end

function stats:GetAccountClassDeaths(classFile)
  classFile = classFile or 'UNKNOWN'
  local store = self:_GetAccountStore()
  local map = store.deathsByClass
  if type(map) ~= 'table' then return 0 end
  return map[classFile] or 0
end

function stats:UpdateAccountClassDeaths(classFile, value)
  classFile = classFile or 'UNKNOWN'
  value = tonumber(value) or 0
  if value < 0 then value = 0 end

  local store = self:_GetAccountStore()
  store.deathsByClass = store.deathsByClass or {}
  store.deathsByClass[classFile] = value
  RequestUIRefresh()
end

function stats:IncrementAccountCurrentClassDeaths(delta)
  delta = tonumber(delta) or 1
  local _, classFile = UnitClass('player')
  classFile = classFile or 'UNKNOWN'
  local current = self:GetAccountClassDeaths(classFile) or 0
  self:UpdateAccountClassDeaths(classFile, current + delta)
end

function stats:GetAccountDeathsByClass()
  local store = self:_GetAccountStore()
  local map = store.deathsByClass
  if type(map) ~= 'table' then return {} end
  local out = {}
  for k, v in pairs(map) do
    out[k] = v
  end
  return out
end

-- Track best levels across the account and per class.
function stats:UpdateAccountMaxLevels(level)
  level = tonumber(level) or 0
  if level <= 0 then return end

  local store = self:_GetAccountStore()
  if (store.maxLevelOverall or 0) < level then
    store.maxLevelOverall = level
  end

  local _, classFile = UnitClass('player')
  classFile = classFile or 'UNKNOWN'
  store.maxLevelByClass = store.maxLevelByClass or {}
  if (store.maxLevelByClass[classFile] or 0) < level then
    store.maxLevelByClass[classFile] = level
  end

  RequestUIRefresh()
end

function stats:GetAccountMaxLevelOverall()
  return self:GetAccountStat('maxLevelOverall', 0) or 0
end

function stats:GetAccountMaxLevelForCurrentClass()
  local store = self:_GetAccountStore()
  local map = store.maxLevelByClass
  if type(map) ~= 'table' then return 0 end
  local _, classFile = UnitClass('player')
  classFile = classFile or 'UNKNOWN'
  return map[classFile] or 0
end

local function IsInDungeonInstance()
  local inInstance, instanceType = IsInInstance()
  return inInstance and instanceType == 'party'
end

-- Lowest health percentage (overall, this level, this session).
local function UpdateLowestHealth()
  local maxHealth = UnitHealthMax('player') or 0
  if maxHealth <= 0 then return end

  local currentHealth = UnitHealth('player') or 0
  local pct = (currentHealth / maxHealth) * 100
  pct = SafePct(pct)

  if pct < (stats:GetStat('lowestHealth') or 100) then
    stats:UpdateStat('lowestHealth', pct)
  end
  if pct < (stats:GetStat('lowestHealthThisLevel') or 100) then
    stats:UpdateStat('lowestHealthThisLevel', pct)
  end
  if pct < (stats:GetStat('lowestHealthThisSession') or 100) then
    stats:UpdateStat('lowestHealthThisSession', pct)
  end
end

local eventFrame = CreateFrame('Frame')

local state = {
  -- Cached GUIDs for non-combat events (pet/party death detection).
  petGUIDs = {},
  partyGUIDs = {},
  -- GUID -> cached NPC info (classification/level/instance context) to improve kill classification without requiring target at death.
  guidInfo = {},
  -- One-shot flags/counters for heuristics.
  escapeArmed = false,
  dungeonActive = false,
  dungeonBossesKilledThisRun = 0,
  -- Debounce / correlation windows for consumables.
  lastManaPotionAt = 0,
  pendingManaPotionAt = 0,
  lastBandageAt = 0,
  lastHealingPotionAt = 0,
  lastJumpAt = 0,
}

-- Cache classification/level for an NPC unit so PARTY_KILL can be classified even if not targeted at death.
local function CacheNPCInfo(unit)
  if not unit then return end
  if not UnitExists(unit) then return end

  local guid = UnitGUID(unit)
  if not guid then return end

  local isPlayer = UnitIsPlayer(unit)
  if isPlayer then return end

  state.guidInfo[guid] = state.guidInfo[guid] or {}
  local info = state.guidInfo[guid]
  info.classification = UnitClassification(unit)
  info.level = UnitLevel(unit)
  info.inInstance = IsInDungeonInstance() and true or false
end

-- Cache commonly inspected units.
local function CacheTargetAndMouseover()
  CacheNPCInfo('target')
  CacheNPCInfo('mouseover')
end

-- Cache current party GUIDs for party-member death counting.
local function UpdatePartyCache()
  state.partyGUIDs = {}
  state.partyGUIDs[UnitGUID('player') or ''] = true
  for i = 1, 4 do
    local guid = UnitGUID('party' .. i)
    if guid then
      state.partyGUIDs[guid] = true
    end
  end
end

-- Cache the current pet GUID (if any) so pet deaths can be detected from UNIT_DIED.
local function UpdatePetCache()
  local guid = UnitGUID('pet')
  if guid then
    state.petGUIDs[guid] = true
  end
end

-- Derived duel statistic.
local function UpdateDuelsWinPercent()
  local total = stats:GetStat('duelsTotal') or 0
  local won = stats:GetStat('duelsWon') or 0
  if total <= 0 then
    stats:UpdateStat('duelsWinPercent', 0)
    return
  end
  stats:UpdateStat('duelsWinPercent', (won / total) * 100)
end

-- World map open counter.
local function HookWorldMapOpen()
  if state.worldMapHooked then return end
  if not WorldMapFrame or not WorldMapFrame.HookScript then return end

  state.worldMapHooked = true
  WorldMapFrame:HookScript('OnShow', function()
    stats:IncrementStat('mapTimesOpened', 1)
  end)
end

-- "Close escape" heuristic: arm at <=10% HP, count once after recovery to >=70% HP.
local function MaybeCountCloseEscape()
  local maxHealth = UnitHealthMax('player') or 0
  if maxHealth <= 0 then return end
  local pct = SafePct(((UnitHealth('player') or 0) / maxHealth) * 100)

  if not state.escapeArmed and pct > 0 and pct <= 10 then
    state.escapeArmed = true
  elseif state.escapeArmed and pct >= 70 then
    state.escapeArmed = false
    stats:IncrementStat('closeEscapes', 1)
  end
end

-- Spell/item-use interpretation based on localized spell names.
-- Called from both UNIT_SPELLCAST_SUCCEEDED and relevant combat log events.
local BANDAGE_USE_SPELL_IDS = {
  [746] = true,   -- Linen Bandage
  [1159] = true,  -- Heavy Linen Bandage
  [3267] = true,  -- Wool Bandage
  [3268] = true,  -- Heavy Wool Bandage
  [7928] = true,  -- Silk Bandage
  [7929] = true,  -- Heavy Silk Bandage
  [10838] = true, -- Mageweave Bandage
  [10839] = true, -- Heavy Mageweave Bandage
  [18608] = true, -- Runecloth Bandage
  [18610] = true, -- Heavy Runecloth Bandage
}

local function HandleSpellcastSucceeded(unit, spellId, spellName)
  if unit ~= 'player' then return end
  if not spellId and not spellName then return end

  local now = GetTime and GetTime() or 0

  local id = tonumber(spellId)
  if id and BANDAGE_USE_SPELL_IDS[id] then
    if now - (state.lastBandageAt or 0) > 1.5 then
      state.lastBandageAt = now
      stats:IncrementStat('bandagesApplied', 1)
    end
    return
  end

  if not spellName then return end
  local name = tostring(spellName):lower()
  local normalized = name:gsub("[%s%p]", "")

  local function ContainsAny(haystack, needles)
    for _, needle in ipairs(needles) do
      if haystack:find(needle, 1, true) then
        return true
      end
    end
    return false
  end

  local isPotion = ContainsAny(name, { 'potion', 'trank' }) or ContainsAny(normalized, { 'potion', 'trank' })
  local isMana = ContainsAny(name, { 'mana', 'manatrank' }) or ContainsAny(normalized, { 'mana', 'manatrank' })
  local isHealth = ContainsAny(name, { 'healing', 'health', 'heil', 'heiltrank' }) or ContainsAny(normalized, { 'healing', 'health', 'heil', 'heiltrank' })

  if isPotion and isHealth then
    if now - (state.lastHealingPotionAt or 0) > 0.75 then
      state.lastHealingPotionAt = now
      stats:IncrementStat('healthPotionsUsed', 1)
    end
    return
  end
	  if isPotion and isMana then
	    stats:IncrementStat('manaPotionsUsed', 1)
	    return
	  end
	  if ContainsAny(name, { 'target dummy', 'zielattrappe', 'attrappe' }) then
	    stats:IncrementStat('targetDummiesUsed', 1)
	    return
	  end
  if ContainsAny(name, { 'grenade', 'granate' }) then
    stats:IncrementStat('grenadesUsed', 1)
    return
  end
end

-- Combat log handler: tagged kill credit, deaths, crit tracking, and consumable fallbacks.
local function HandleCombatLog()
  local _, subEvent,
    _, sourceGUID, _, sourceFlags,
    _, destGUID,
    _, _, _,
    spellId, spellName = CombatLogGetCurrentEventInfo()

  if subEvent == 'PARTY_KILL' then
    stats:IncrementStat('enemiesSlain', 1)

    if destGUID then
      local info = state.guidInfo[destGUID]
      local classification = info and info.classification
      local level = info and info.level
      local inInstance = info and info.inInstance

      if not classification and destGUID == UnitGUID('target') then
        classification = UnitClassification('target')
        level = UnitLevel('target')
        inInstance = IsInDungeonInstance()
      end

      if classification == 'elite' then
        stats:IncrementStat('elitesSlain', 1)
      elseif classification == 'rareelite' then
        stats:IncrementStat('rareElitesSlain', 1)
        stats:IncrementStat('elitesSlain', 1)
      elseif classification == 'worldboss' then
        stats:IncrementStat('worldBossesSlain', 1)
      elseif classification == 'rare' then
        stats:IncrementStat('rareElitesSlain', 1)
      end

      if (inInstance or IsInDungeonInstance()) and level == -1 then
        stats:IncrementStat('dungeonBossesKilled', 1)
        state.dungeonBossesKilledThisRun = (state.dungeonBossesKilledThisRun or 0) + 1
      end
    end
    return
  end

  if subEvent == 'UNIT_DIED' and destGUID then
    if state.petGUIDs[destGUID] then
      stats:IncrementStat('petDeaths', 1)
    elseif state.partyGUIDs[destGUID] and destGUID ~= UnitGUID('player') then
      stats:IncrementStat('partyMemberDeaths', 1)
    end
    return
  end

  local isPlayerSource = sourceGUID and sourceGUID == UnitGUID('player')
  local isPetSource = sourceGUID and sourceGUID == UnitGUID('pet')
  if not (isPlayerSource or isPetSource) then return end

  if (subEvent == 'SPELL_CAST_SUCCESS' or subEvent == 'SPELL_AURA_APPLIED' or subEvent == 'SPELL_AURA_REFRESH') and isPlayerSource then
    if spellName then
      HandleSpellcastSucceeded('player', spellId, spellName)

      local name = tostring(spellName):lower()
      local normalized = name:gsub("[%s%p]", "")
      if name:find('potion', 1, true) or name:find('trank', 1, true) or normalized:find('potion', 1, true) or normalized:find('trank', 1, true) then
        state.pendingManaPotionAt = GetTime and GetTime() or 0
      end
    end
    return
  end

  if (subEvent == 'SPELL_ENERGIZE' or subEvent == 'SPELL_PERIODIC_ENERGIZE') and isPlayerSource then
    local playerGUID = UnitGUID('player')
    if destGUID ~= playerGUID then
      return
    end

    local spellName, powerType = select(13, CombatLogGetCurrentEventInfo())
    -- select(13) returns spellName for energize events; powerType is 17th arg.
    powerType = select(17, CombatLogGetCurrentEventInfo())
    if not spellName then return end

    local name = tostring(spellName):lower()
    local normalized = name:gsub("[%s%p]", "")
    local isPotion = (name:find('potion', 1, true) or name:find('trank', 1, true) or normalized:find('potion', 1, true) or normalized:find('trank', 1, true))
    local isRestoreMana = (name:find('restore mana', 1, true) or name:find('mana wiederherstellen', 1, true) or normalized:find('restoremana', 1, true) or normalized:find('manawiederherstellen', 1, true))

    local isManaPower = (powerType == 0 or powerType == 'MANA')
    local now = GetTime and GetTime() or 0
    local likelyFromRecentPotion = (now - (state.pendingManaPotionAt or 0)) >= 0 and (now - (state.pendingManaPotionAt or 0)) <= 3.0
    if isManaPower and (isPotion or isRestoreMana or likelyFromRecentPotion) then
      if now - (state.lastManaPotionAt or 0) > 0.5 then
        state.lastManaPotionAt = now
        state.pendingManaPotionAt = 0
        stats:IncrementStat('manaPotionsUsed', 1)
      end
      return
    end
  end

  if subEvent == 'SWING_DAMAGE' then
    local amount = select(12, CombatLogGetCurrentEventInfo())
    local critical = select(18, CombatLogGetCurrentEventInfo())
    if critical then
      local current = stats:GetStat('highestCritValue') or 0
      if (amount or 0) > current then
        stats:UpdateStat('highestCritValue', amount or 0)
      end
    end
    return
  end

  if subEvent == 'RANGE_DAMAGE' or subEvent == 'SPELL_DAMAGE' then
    local _, _, _, amount, _, _, _, _, _, critical = select(12, CombatLogGetCurrentEventInfo())
    if critical then
      local current = stats:GetStat('highestCritValue') or 0
      if (amount or 0) > current then
        stats:UpdateStat('highestCritValue', amount or 0)
      end
    end
    return
  end

  if subEvent == 'SPELL_HEAL' then
    local _, _, _, amount, _, _, _, _, _, critical = select(12, CombatLogGetCurrentEventInfo())
    if critical then
      local current = stats:GetStat('highestHealCritValue') or 0
      if (amount or 0) > current then
        stats:UpdateStat('highestHealCritValue', amount or 0)
      end
    end
  end
end

local function OnEvent(_, event, ...)
  -- Central event dispatcher for tracking logic.
  if event == 'PLAYER_ENTERING_WORLD' then
    -- Migrate name-based character key -> GUID-based key once GUID is available.
    stats:_MigrateLegacyCharacterKey()

    UpdateLowestHealth()
    stats:UpdateAccountMaxLevels(UnitLevel('player'))
    UpdatePartyCache()
    UpdatePetCache()

    if IsInDungeonInstance() then
      state.dungeonActive = true
      state.dungeonBossesKilledThisRun = 0
    elseif state.dungeonActive then
      if (state.dungeonBossesKilledThisRun or 0) > 0 then
        stats:IncrementStat('dungeonsCompleted', 1)
      end
      state.dungeonActive = false
      state.dungeonBossesKilledThisRun = 0
    end
    HookWorldMapOpen()
    CacheTargetAndMouseover()
  elseif event == 'UNIT_HEALTH' or event == 'UNIT_MAXHEALTH' then
    UpdateLowestHealth()
    MaybeCountCloseEscape()
  elseif event == 'PLAYER_LEVEL_UP' then
    stats:UpdateStat('lowestHealthThisLevel', 100)
    local newLevel = ...
    stats:UpdateAccountMaxLevels(newLevel)
  elseif event == 'PLAYER_LOGOUT' then
    stats:UpdateStat('lowestHealthThisSession', 100)
  elseif event == 'PLAYER_DEAD' then
    stats:IncrementAccountStat('totalDeaths', 1)
    stats:IncrementAccountClassDeath()
  elseif event == 'COMBAT_LOG_EVENT_UNFILTERED' then
    HandleCombatLog()
  elseif event == 'UNIT_SPELLCAST_SUCCEEDED' then
    local unit, _, spellId = ...
    local name = GetSpellInfo(spellId)
    HandleSpellcastSucceeded(unit, spellId, name)
  elseif event == 'GROUP_ROSTER_UPDATE' then
    UpdatePartyCache()
  elseif event == 'UNIT_PET' then
    UpdatePetCache()
  elseif event == 'PLAYER_TARGET_CHANGED' or event == 'UPDATE_MOUSEOVER_UNIT' then
    CacheTargetAndMouseover()
  elseif event == 'NAME_PLATE_UNIT_ADDED' then
    local unit = ...
    CacheNPCInfo(unit)
  elseif event == 'DUEL_FINISHED' then
    stats:IncrementStat('duelsTotal', 1)
    UpdateDuelsWinPercent()
  elseif event == 'ADDON_LOADED' then
    local addonName = ...
    if addonName == 'Blizzard_WorldMap' then
      HookWorldMapOpen()
    end
  end
end

eventFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
eventFrame:RegisterEvent('UNIT_HEALTH')
eventFrame:RegisterEvent('UNIT_MAXHEALTH')
eventFrame:RegisterEvent('PLAYER_LEVEL_UP')
eventFrame:RegisterEvent('PLAYER_LOGOUT')
eventFrame:RegisterEvent('PLAYER_DEAD')
eventFrame:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
eventFrame:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
eventFrame:RegisterEvent('GROUP_ROSTER_UPDATE')
eventFrame:RegisterEvent('UNIT_PET')
eventFrame:RegisterEvent('PLAYER_TARGET_CHANGED')
eventFrame:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
eventFrame:RegisterEvent('NAME_PLATE_UNIT_ADDED')
eventFrame:RegisterEvent('DUEL_FINISHED')
eventFrame:RegisterEvent('ADDON_LOADED')
eventFrame:SetScript('OnEvent', function(self, event, ...)
  if event == 'UNIT_HEALTH' or event == 'UNIT_MAXHEALTH' then
    local unit = ...
    if unit ~= 'player' then return end
  end
  OnEvent(self, event, ...)
end)

function HSC_CharacterStats_Initialize()
  -- Export accessor object for other modules (UI, options, etc.).
  HSC_CharacterStats = stats
  HookWorldMapOpen()

  -- Jump tracking: best-effort heuristic. Some key presses can trigger JumpOrAscendStart even if the game disallows a jump.
  if hooksecurefunc and JumpOrAscendStart then
    hooksecurefunc('JumpOrAscendStart', function()
      local now = GetTime and GetTime() or 0
      if now - (state.lastJumpAt or 0) < 0.15 then
        return
      end
      state.lastJumpAt = now

      if not C_Timer or not C_Timer.After then
        stats:IncrementStat('playerJumps', 1)
        return
      end

      C_Timer.After(0, function()
        if IsFalling and IsFalling() and not (IsSwimming and IsSwimming()) and not (IsFlying and IsFlying()) then
          stats:IncrementStat('playerJumps', 1)
        end
      end)
    end)
  end

  -- Duel win/loss tracking: hook EndDuel and use GetDuelWinner (Classic-safe).
  if hooksecurefunc and EndDuel then
    hooksecurefunc('EndDuel', function()
      local winner = GetDuelWinner and GetDuelWinner() or nil
      if not winner or winner == '' then return end

      local playerName = UnitName('player')
      if not playerName or playerName == '' then return end

      if winner == playerName then
        stats:IncrementStat('duelsWon', 1)
      else
        stats:IncrementStat('duelsLost', 1)
      end
      UpdateDuelsWinPercent()
    end)
  end
end
