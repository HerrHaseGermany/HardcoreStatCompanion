-- Blizzard Options/Interface panel for Hardcore Stat Companion.
-- Includes row toggles, ordering controls, overlay styling, and adjustment/reset utilities.

local function Clamp01(v)
  if v < 0 then return 0 end
  if v > 1 then return 1 end
  return v
end

local function CreateCheckbox(parent, label)
  local cb = CreateFrame('CheckButton', nil, parent, 'InterfaceOptionsCheckButtonTemplate')
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
  -- Re-apply all overlay UI state immediately.
  if HardcoreStatCompanionStatsFrame and HardcoreStatCompanionStatsFrame.UpdateRowVisibility then
    HardcoreStatCompanionStatsFrame.UpdateRowVisibility()
  end
  if HardcoreStatCompanionStatsFrame and HardcoreStatCompanionStatsFrame.ApplyStatsBackgroundOpacity then
    HardcoreStatCompanionStatsFrame.ApplyStatsBackgroundOpacity()
  end
  if HardcoreStatCompanionStatsFrame and HardcoreStatCompanionStatsFrame.CheckAddonEnabled then
    HardcoreStatCompanionStatsFrame.CheckAddonEnabled()
  end
  if HardcoreStatCompanionStatsFrame and HardcoreStatCompanionStatsFrame.ApplyLockState then
    HardcoreStatCompanionStatsFrame.ApplyLockState()
  end
  if HardcoreStatCompanionStatsFrame and HardcoreStatCompanionStatsFrame.ApplyScale then
    HardcoreStatCompanionStatsFrame.ApplyScale()
  end
  if HardcoreStatCompanionStatsFrame and HardcoreStatCompanionStatsFrame.ApplyTextColor then
    HardcoreStatCompanionStatsFrame.ApplyTextColor()
  end
end

local function Clamp(v, minV, maxV)
  if v < minV then return minV end
  if v > maxV then return maxV end
  return v
end

local function EnsureTextColor()
  if not HSC_SETTINGS then return { r = 1, g = 1, b = 1, a = 1 } end
  if type(HSC_SETTINGS.statisticsTextColor) ~= 'table' then
    HSC_SETTINGS.statisticsTextColor = { r = 1, g = 1, b = 1, a = 1 }
  end
  local c = HSC_SETTINGS.statisticsTextColor
  c.r = tonumber(c.r) or 1
  c.g = tonumber(c.g) or 1
  c.b = tonumber(c.b) or 1
  c.a = tonumber(c.a)
  if c.a == nil then c.a = 1 end
  return c
end

local function ResetPanelDefaults()
  -- Resets only appearance/position settings (not tracked stats).
  if not HSC_SETTINGS then return end
  HSC_SETTINGS.statisticsBackgroundOpacity = 0.3
  HSC_SETTINGS.statisticsScale = 1.0
  HSC_SETTINGS.statisticsTextColor = { r = 1, g = 1, b = 1, a = 1 }
  if HSC_PANEL_SETTINGS then
    HSC_PANEL_SETTINGS.onScreenPanelPosition = nil
  end
end

local function ConfirmResetPanel(onConfirm)
  local key = 'HSC_RESET_PANEL_DEFAULTS_CONFIRM'
  StaticPopupDialogs[key] = StaticPopupDialogs[key] or {
    text = 'Reset on-screen panel position, scale, and text color?',
    button1 = 'Reset',
    button2 = 'Cancel',
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnAccept = function()
      if onConfirm then onConfirm() end
    end,
  }
  StaticPopup_Show(key)
end

local function EnsureDeathCountAdjustFrame()
  if HardcoreStatCompanion_DeathCountAdjustFrame then
    return HardcoreStatCompanion_DeathCountAdjustFrame
  end

  local frame = CreateFrame('Frame', 'HardcoreStatCompanion_DeathCountAdjustFrame', UIParent, 'BasicFrameTemplateWithInset')
  frame:SetSize(360, 180)
  frame:SetPoint('CENTER')
  frame:SetFrameStrata('DIALOG')
  frame:Hide()

  frame.TitleText:SetText('Death Count Adjust')

  local function MakeRow(y, labelText)
    local label = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    label:SetPoint('TOPLEFT', frame, 'TOPLEFT', 16, y)
    label:SetText(labelText)

    local value = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    value:SetPoint('LEFT', label, 'RIGHT', 8, 0)
    value:SetText('0')

    local minus = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
    minus:SetText('-')
    minus:SetSize(22, 20)
    minus:SetPoint('LEFT', value, 'RIGHT', 10, 0)

    local plus = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
    plus:SetText('+')
    plus:SetSize(22, 20)
    plus:SetPoint('LEFT', minus, 'RIGHT', 6, 0)

    return value, minus, plus
  end

  local totalValue, totalMinus, totalPlus = MakeRow(-44, 'Account deaths:')
  local classValue, classMinus, classPlus = MakeRow(-72, 'Class deaths (current):')

  local classInfo = CreateFrame('Button', nil, frame)
  classInfo:SetSize(18, 18)
  classInfo:SetPoint('LEFT', classPlus, 'RIGHT', 10, 0)
  local infoText = classInfo:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  infoText:SetPoint('CENTER')
  infoText:SetText('?')

  local function FormatTimestamp(ts)
    if not ts then return 'Never' end
    ts = tonumber(ts)
    if not ts or ts <= 0 then return 'Never' end
    if date then
      return date('%Y-%m-%d %H:%M:%S', ts)
    end
    return tostring(ts)
  end

  local lastTotal = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
  lastTotal:SetPoint('TOPLEFT', frame, 'TOPLEFT', 16, -104)
  lastTotal:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -16, -104)
  lastTotal:SetJustifyH('LEFT')
  lastTotal:SetText('Last manual adjust (account): Never')

  local lastClass = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
  lastClass:SetPoint('TOPLEFT', lastTotal, 'BOTTOMLEFT', 0, -4)
  lastClass:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -16, 0)
  lastClass:SetJustifyH('LEFT')
  lastClass:SetText('Last manual adjust (class): Never')

  local cancel = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
  cancel:SetText('Cancel')
  cancel:SetSize(90, 22)
  cancel:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -16, 14)

  local apply = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
  apply:SetText('Apply')
  apply:SetSize(90, 22)
  apply:SetPoint('RIGHT', cancel, 'LEFT', -10, 0)

  local function ClampNonNegative(v)
    v = tonumber(v) or 0
    if v < 0 then return 0 end
    return math.floor(v)
  end

  function frame:RefreshValues()
    local total = 0
    local classDeaths = 0
    local _, classFile = UnitClass('player')
    classFile = classFile or 'UNKNOWN'

    if HSC_CharacterStats then
      total = HSC_CharacterStats:GetAccountStat('totalDeaths', 0) or 0
      classDeaths = HSC_CharacterStats:GetAccountClassDeaths(classFile) or 0
    end

    frame.pendingTotal = ClampNonNegative(total)
    frame.pendingClassDeaths = ClampNonNegative(classDeaths)
    frame.classFile = classFile
    totalValue:SetText(tostring(frame.pendingTotal))
    classValue:SetText(tostring(frame.pendingClassDeaths))

    if HSC_SETTINGS then
      lastTotal:SetText('Last manual adjust (account): ' .. FormatTimestamp(HSC_SETTINGS.deathCountAdjustLastAtTotal))
      lastClass:SetText('Last manual adjust (class): ' .. FormatTimestamp(HSC_SETTINGS.deathCountAdjustLastAtClass))
    else
      lastTotal:SetText('Last manual adjust (account): Never')
      lastClass:SetText('Last manual adjust (class): Never')
    end
  end

  totalMinus:SetScript('OnClick', function()
    frame.pendingTotal = ClampNonNegative((frame.pendingTotal or 0) - 1)
    totalValue:SetText(tostring(frame.pendingTotal))
  end)
  totalPlus:SetScript('OnClick', function()
    frame.pendingTotal = ClampNonNegative((frame.pendingTotal or 0) + 1)
    totalValue:SetText(tostring(frame.pendingTotal))
  end)
  classMinus:SetScript('OnClick', function()
    frame.pendingClassDeaths = ClampNonNegative((frame.pendingClassDeaths or 0) - 1)
    classValue:SetText(tostring(frame.pendingClassDeaths))
  end)
  classPlus:SetScript('OnClick', function()
    frame.pendingClassDeaths = ClampNonNegative((frame.pendingClassDeaths or 0) + 1)
    classValue:SetText(tostring(frame.pendingClassDeaths))
  end)

  cancel:SetScript('OnClick', function()
    frame:Hide()
  end)

  apply:SetScript('OnClick', function()
    local confirmKey = 'HSC_DEATH_COUNT_ADJUST_APPLY_CONFIRM'
    StaticPopupDialogs[confirmKey] = StaticPopupDialogs[confirmKey] or {
      text = 'Apply death count changes?',
      button1 = 'Apply',
      button2 = 'Cancel',
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
      OnAccept = function()
        if not HSC_CharacterStats then return end
        local now = time and time() or (GetServerTime and GetServerTime()) or nil

        local classFile = frame.classFile or 'UNKNOWN'
        local newClass = ClampNonNegative(frame.pendingClassDeaths)
        local currentClass = HSC_CharacterStats:GetAccountClassDeaths(classFile) or 0
        local currentTotal = HSC_CharacterStats:GetAccountStat('totalDeaths', 0) or 0
        local pendingTotal = ClampNonNegative(frame.pendingTotal)

        -- If the user didn't touch total deaths directly, keep total in sync with class delta.
        local newTotal = pendingTotal
        if pendingTotal == (tonumber(currentTotal) or 0) then
          local deltaClass = newClass - (tonumber(currentClass) or 0)
          newTotal = ClampNonNegative((tonumber(currentTotal) or 0) + deltaClass)
        end

        if newTotal < newClass then
          newTotal = newClass
        end

        if newClass ~= (tonumber(currentClass) or 0) then
          if HSC_CharacterStats.UpdateAccountClassDeaths then
            HSC_CharacterStats:UpdateAccountClassDeaths(classFile, newClass)
          end
          if HSC_SETTINGS then HSC_SETTINGS.deathCountAdjustLastAtClass = now end
        end

        if newTotal ~= (tonumber(currentTotal) or 0) then
          HSC_CharacterStats:UpdateAccountStat('totalDeaths', newTotal)
          if HSC_SETTINGS then HSC_SETTINGS.deathCountAdjustLastAtTotal = now end
        end

        frame:Hide()
        RefreshOverlay()
      end,
    }
    StaticPopup_Show(confirmKey)
  end)

  classInfo:SetScript('OnEnter', function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    GameTooltip:SetText('Deaths by class')

    if not HSC_CharacterStats or not HSC_CharacterStats.GetAccountDeathsByClass then
      GameTooltip:AddLine('No data yet.', 1, 1, 1)
      GameTooltip:Show()
      return
    end

    local map = HSC_CharacterStats:GetAccountDeathsByClass()
    local entries = {}
    for classFile, count in pairs(map) do
      entries[#entries + 1] = { classFile = classFile, count = tonumber(count) or 0 }
    end
    table.sort(entries, function(a, b)
      if a.count == b.count then
        return tostring(a.classFile) < tostring(b.classFile)
      end
      return a.count > b.count
    end)

    if #entries == 0 then
      GameTooltip:AddLine('Never', 1, 1, 1)
    else
      for _, e in ipairs(entries) do
        local className = e.classFile
        if LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[e.classFile] then
          className = LOCALIZED_CLASS_NAMES_MALE[e.classFile]
        elseif LOCALIZED_CLASS_NAMES_FEMALE and LOCALIZED_CLASS_NAMES_FEMALE[e.classFile] then
          className = LOCALIZED_CLASS_NAMES_FEMALE[e.classFile]
        end
        GameTooltip:AddDoubleLine(className, tostring(e.count), 1, 1, 1, 1, 1, 1)
      end
    end

    GameTooltip:Show()
  end)

  classInfo:SetScript('OnLeave', function()
    if GameTooltip then GameTooltip:Hide() end
  end)

  HardcoreStatCompanion_DeathCountAdjustFrame = frame
  return frame
end

local function ShowDeathCountAdjustPopup()
  local frame = EnsureDeathCountAdjustFrame()
  frame:RefreshValues()
  frame:Show()
end

local function OpenColorPicker(initial, onChanged)
  if not ColorPickerFrame then return end

  local function ApplyColor()
    local r, g, b = ColorPickerFrame:GetColorRGB()
    local a = 1
    if OpacitySliderFrame and OpacitySliderFrame.GetValue then
      a = 1 - (OpacitySliderFrame:GetValue() or 0)
    end
    onChanged(r, g, b, a)
  end

  local prevR, prevG, prevB, prevA = initial.r, initial.g, initial.b, initial.a
  ColorPickerFrame.hasOpacity = true
  ColorPickerFrame.opacity = 1 - (prevA or 1)
  ColorPickerFrame.previousValues = { prevR, prevG, prevB, prevA }
  ColorPickerFrame.func = ApplyColor
  ColorPickerFrame.swatchFunc = ApplyColor
  ColorPickerFrame.opacityFunc = ApplyColor
  ColorPickerFrame.cancelFunc = function()
    onChanged(prevR, prevG, prevB, prevA)
  end

  ColorPickerFrame:SetColorRGB(prevR, prevG, prevB)
  ColorPickerFrame:Hide()
  ColorPickerFrame:Show()
end

local function SwapArrayEntries(array, i, j)
  if not array or not i or not j then return end
  if i < 1 or j < 1 then return end
  if i > #array or j > #array then return end
  array[i], array[j] = array[j], array[i]
end

local function ApplyArrowTextures(button, direction)
  local normal, pushed, highlight, disabled
  if direction == 'up' then
    normal = 'Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up'
    pushed = 'Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down'
    highlight = 'Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight'
    disabled = 'Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Disabled'
  else
    normal = 'Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up'
    pushed = 'Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down'
    highlight = 'Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight'
    disabled = 'Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled'
  end

  button:SetNormalTexture(normal)
  button:SetPushedTexture(pushed)
  button:SetHighlightTexture(highlight)
  button:SetDisabledTexture(disabled)

  local n = button:GetNormalTexture()
  local p = button:GetPushedTexture()
  local h = button:GetHighlightTexture()
  local d = button:GetDisabledTexture()

  if n then n:SetVertexColor(1, 1, 1, 1) end
  if p then p:SetVertexColor(1, 1, 1, 1) end
  if h then h:SetVertexColor(1, 1, 1, 1) end
  if d then d:SetVertexColor(1, 1, 1, 1) end
end

local function CreateArrowButton(parent, direction)
  local button = CreateFrame('Button', nil, parent)
  button:SetSize(32, 32)
  ApplyArrowTextures(button, direction)
  return button
end

local function HideAllCheckboxText(cb)
  if not cb then return end

  if cb.Text then
    cb.Text:SetText('')
    cb.Text:Hide()
  end
  if cb.text then
    cb.text:SetText('')
    cb.text:Hide()
  end

  local i = 1
  while true do
    local region = select(i, cb:GetRegions())
    if not region then break end
    if region.GetObjectType and region:GetObjectType() == 'FontString' then
      if region.SetText then region:SetText('') end
      region:Hide()
    end
    i = i + 1
  end
end

local function CreateOptionsPanel()
  local panel = CreateFrame('Frame', 'HardcoreStatCompanionOptionsPanel', UIParent)
  panel.name = 'Hardcore Stat Companion'

  local title = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
  title:SetPoint('TOPLEFT', 16, -16)
  title:SetText('Hardcore Stat Companion')

  local subtitle = panel:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
  subtitle:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -8)
  subtitle:SetText('Configure the on-screen stats panel. Use /hsc for the standalone window.')

  local showPanel = CreateCheckbox(panel, 'Show on-screen statistics panel')
  if showPanel.Text then
    showPanel.Text:SetText('Show on-screen statistics panel')
  end
  showPanel:SetPoint('TOPLEFT', subtitle, 'BOTTOMLEFT', 0, -12)

  local opacity = CreateSlider(panel, 'Background opacity')
  opacity:SetPoint('TOPLEFT', showPanel, 'BOTTOMLEFT', 0, -28)
  opacity:SetWidth(260)

  local scale = CreateSlider(panel, 'Scale')
  scale:SetPoint('TOPLEFT', opacity, 'BOTTOMLEFT', 0, -28)
  scale:SetWidth(260)
  scale:SetMinMaxValues(50, 200)
  scale:SetValueStep(1)
  scale.Low:SetText('0.5x')
  scale.High:SetText('2.0x')

  local textColorLabel = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  textColorLabel:SetPoint('TOPLEFT', scale, 'BOTTOMLEFT', 0, -18)
  textColorLabel:SetText('Text color')

  local textColorSwatch = CreateFrame('Button', nil, panel)
  textColorSwatch:SetSize(24, 24)
  textColorSwatch:SetPoint('LEFT', textColorLabel, 'RIGHT', 8, 0)
  local swatchTex = textColorSwatch:CreateTexture(nil, 'ARTWORK')
  swatchTex:SetAllPoints()
  swatchTex:SetTexture('Interface\\ChatFrame\\ChatFrameColorSwatch')
  swatchTex:SetVertexColor(1, 1, 1, 1)

  local resetPanel = CreateFrame('Button', nil, panel, 'UIPanelButtonTemplate')
  resetPanel:SetText('Reset panel')
  resetPanel:SetSize(120, 22)
  resetPanel:SetPoint('TOPLEFT', textColorLabel, 'BOTTOMLEFT', 0, -12)

  local lockPanel = CreateCheckbox(panel, 'Lock on-screen panel position')
  if lockPanel.Text then
    lockPanel.Text:SetText('Lock on-screen panel position')
  end
  lockPanel:SetPoint('TOPLEFT', resetPanel, 'BOTTOMLEFT', 0, -10)

  local deathAdjust = CreateFrame('Button', nil, panel, 'UIPanelButtonTemplate')
  deathAdjust:SetText('Death Count Adjust...')
  deathAdjust:SetSize(170, 22)
  deathAdjust:SetPoint('LEFT', resetPanel, 'RIGHT', 12, 0)

  local rowsHeader = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  rowsHeader:SetPoint('TOPLEFT', lockPanel, 'BOTTOMLEFT', 0, -16)
  rowsHeader:SetText('Rows')

  local rowsScroll = CreateFrame('ScrollFrame', nil, panel, 'UIPanelScrollFrameTemplate')
  rowsScroll:SetPoint('TOPLEFT', rowsHeader, 'BOTTOMLEFT', 0, -8)
  rowsScroll:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', -30, 16)

  local rowsContent = CreateFrame('Frame', nil, rowsScroll)
  rowsContent:SetSize(1, 1)
  rowsScroll:SetScrollChild(rowsContent)

  local rowsByKey = {
    showMainStatisticsPanelAccountMaxLevel = { key = 'showMainStatisticsPanelAccountMaxLevel', label = 'Max Level Account' },
    showMainStatisticsPanelClassMaxLevel = { key = 'showMainStatisticsPanelClassMaxLevel', label = 'Max Level Class' },
    showMainStatisticsPanelLowestHealth = { key = 'showMainStatisticsPanelLowestHealth', label = 'Lowest Health' },
    showMainStatisticsPanelThisLevel = { key = 'showMainStatisticsPanelThisLevel', label = 'Lowest Level Health' },
    showMainStatisticsPanelSessionHealth = { key = 'showMainStatisticsPanelSessionHealth', label = 'Lowest Session Health' },
    showMainStatisticsPanelPetDeaths = { key = 'showMainStatisticsPanelPetDeaths', label = 'Pet deaths' },
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
    showMainStatisticsPanelPartyMemberDeaths = { key = 'showMainStatisticsPanelPartyMemberDeaths', label = 'Party member deaths' },
    showMainStatisticsPanelCloseEscapes = { key = 'showMainStatisticsPanelCloseEscapes', label = 'Close calls' },
    showMainStatisticsPanelDuelsTotal = { key = 'showMainStatisticsPanelDuelsTotal', label = 'Duels (total)' },
    showMainStatisticsPanelDuelsWon = { key = 'showMainStatisticsPanelDuelsWon', label = 'Duels (won)' },
    showMainStatisticsPanelDuelsLost = { key = 'showMainStatisticsPanelDuelsLost', label = 'Duels (lost)' },
    showMainStatisticsPanelDuelsWinPercent = { key = 'showMainStatisticsPanelDuelsWinPercent', label = 'Duels (win %)' },
    showMainStatisticsPanelPlayerJumps = { key = 'showMainStatisticsPanelPlayerJumps', label = 'Player jumps' },
    showMainStatisticsPanelMapTimesOpened = { key = 'showMainStatisticsPanelMapTimesOpened', label = 'Map opened' },
    showMainStatisticsPanelClassDeaths = { key = 'showMainStatisticsPanelClassDeaths', label = 'Class deaths (current class)' },
    showMainStatisticsPanelAccountTotalDeaths = { key = 'showMainStatisticsPanelAccountTotalDeaths', label = 'Account deaths (all characters)' },
  }

  local rowFrames = {}
  local rowCheckboxes = {}
  local rowButtons = {}
  local rowLabels = {}

  local function ReleaseRows()
    for _, frame in ipairs(rowFrames) do
      frame:Hide()
      frame:SetParent(nil)
    end
    for _, cb in ipairs(rowCheckboxes) do
      cb:Hide()
      cb:SetParent(nil)
    end
    for _, buttons in ipairs(rowButtons) do
      buttons.up:Hide()
      buttons.up:SetParent(nil)
      buttons.down:Hide()
      buttons.down:SetParent(nil)
    end
    rowCheckboxes = {}
    rowButtons = {}
    rowFrames = {}
    rowLabels = {}
  end

  local function BuildRows()
    ReleaseRows()
    local panelSettings = HSC_PANEL_SETTINGS or HSC_SETTINGS
    if not panelSettings or type(panelSettings.mainPanelRowOrder) ~= 'table' then return end

    local scrollWidth = rowsScroll:GetWidth() or 0
    local contentWidth = scrollWidth > 0 and (scrollWidth - 32) or 360
    rowsContent:SetWidth(contentWidth)

    local lastRow = nil
    local contentHeight = 0
    for index, key in ipairs(panelSettings.mainPanelRowOrder) do
      local row = rowsByKey[key]
      if row then
        local rowFrame = CreateFrame('Frame', nil, rowsContent)
        rowFrame:SetHeight(18)
        rowFrame:SetWidth(contentWidth)
        if lastRow then
          rowFrame:SetPoint('TOPLEFT', lastRow, 'BOTTOMLEFT', 0, -6)
        else
          rowFrame:SetPoint('TOPLEFT', rowsContent, 'TOPLEFT', 0, 0)
        end

        rowFrames[#rowFrames + 1] = rowFrame

        local up = CreateArrowButton(rowFrame, 'up')
        up:SetPoint('LEFT', rowFrame, 'LEFT', 0, 0)
        up:SetEnabled(index > 1)
        up:SetShown(index > 1)
        up:SetScript('OnClick', function()
          SwapArrayEntries(panelSettings.mainPanelRowOrder, index, index - 1)
          BuildRows()
          RefreshOverlay()
        end)

        local down = CreateArrowButton(rowFrame, 'down')
        down:SetPoint('LEFT', up, 'RIGHT', 6, 0)
        down:SetEnabled(index < #panelSettings.mainPanelRowOrder)
        down:SetShown(index < #panelSettings.mainPanelRowOrder)
        down:SetScript('OnClick', function()
          SwapArrayEntries(panelSettings.mainPanelRowOrder, index, index + 1)
          BuildRows()
          RefreshOverlay()
        end)

        local cb = CreateCheckbox(rowFrame, '')
        cb:SetPoint('LEFT', down, 'RIGHT', 8, 0)
        HideAllCheckboxText(cb)
        cb.settingKey = row.key
        cb:SetChecked(panelSettings[row.key] and true or false)
        cb:SetScript('OnClick', function(self)
          local panel = HSC_PANEL_SETTINGS or HSC_SETTINGS
          if not panel then return end
          panel[self.settingKey] = self:GetChecked() and true or false
          RefreshOverlay()
        end)

        local label = rowFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
        label:SetPoint('LEFT', cb, 'RIGHT', 4, 0)
        label:SetPoint('RIGHT', rowFrame, 'RIGHT', 0, 0)
        label:SetJustifyH('LEFT')
        label:SetText(row.label)

        rowLabels[#rowLabels + 1] = label
        rowCheckboxes[#rowCheckboxes + 1] = cb
        rowButtons[#rowButtons + 1] = { up = up, down = down }
        lastRow = rowFrame
        contentHeight = contentHeight + rowFrame:GetHeight() + 6
      end
    end

    rowsContent:SetHeight(math.max(1, contentHeight))
  end

  local function SyncFromSettings()
    if not HSC_SETTINGS then return end
    showPanel:SetChecked(HSC_SETTINGS.showOnScreenStatistics and true or false)
    opacity:SetValue((HSC_SETTINGS.statisticsBackgroundOpacity or 0.3) * 100)
    scale:SetValue(((HSC_SETTINGS.statisticsScale or 1) * 100))
    local c = EnsureTextColor()
    swatchTex:SetVertexColor(c.r, c.g, c.b, c.a)
    lockPanel:SetChecked(HSC_SETTINGS.lockOnScreenPanelPosition and true or false)

    BuildRows()
  end

  showPanel:SetScript('OnClick', function(self)
    if not HSC_SETTINGS then return end
    HSC_SETTINGS.showOnScreenStatistics = self:GetChecked() and true or false
    RefreshOverlay()
  end)

  opacity:SetScript('OnValueChanged', function(_, value)
    if not HSC_SETTINGS then return end
    HSC_SETTINGS.statisticsBackgroundOpacity = Clamp01((value or 30) / 100)
    RefreshOverlay()
  end)

  scale:SetScript('OnValueChanged', function(_, value)
    if not HSC_SETTINGS then return end
    local s = Clamp((value or 100) / 100, 0.5, 2.0)
    HSC_SETTINGS.statisticsScale = s
    RefreshOverlay()
  end)

  textColorSwatch:SetScript('OnClick', function()
    if not HSC_SETTINGS then return end
    local c = EnsureTextColor()
    OpenColorPicker(c, function(r, g, b, a)
      local color = EnsureTextColor()
      color.r, color.g, color.b, color.a = r, g, b, a
      swatchTex:SetVertexColor(r, g, b, a)
      RefreshOverlay()
    end)
  end)

  resetPanel:SetScript('OnClick', function()
    ConfirmResetPanel(function()
      ResetPanelDefaults()
      SyncFromSettings()
      if HardcoreStatCompanionStatsFrame and HardcoreStatCompanionStatsFrame.ApplySavedPosition then
        HardcoreStatCompanionStatsFrame.ApplySavedPosition()
      end
      RefreshOverlay()
    end)
  end)

  deathAdjust:SetScript('OnClick', function()
    ShowDeathCountAdjustPopup()
  end)

  lockPanel:SetScript('OnClick', function(self)
    if not HSC_SETTINGS then return end
    HSC_SETTINGS.lockOnScreenPanelPosition = self:GetChecked() and true or false
    RefreshOverlay()
  end)

  panel.refresh = SyncFromSettings
  panel:SetScript('OnShow', SyncFromSettings)
  rowsScroll:SetScript('OnSizeChanged', function()
    if panel:IsShown() then
      BuildRows()
    end
  end)

  SyncFromSettings()

  return panel
end

local function RegisterPanel(panel)
  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    category.ID = panel.name
    Settings.RegisterAddOnCategory(category)
    return
  end

  if InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  end
end

function HSC_UI_OptionsPanel_Initialize()
  local panel = CreateOptionsPanel()
  RegisterPanel(panel)
end
