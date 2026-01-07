-- Main addon entrypoint. Initializes SavedVariables, settings, stats tracking, and UI modules.
HardcoreStatCompanionDB = HardcoreStatCompanionDB or {}

local ADDON_NAME = ...

local eventFrame = CreateFrame('Frame')

local function Initialize()
  -- Settings must initialize before any UI reads HSC_SETTINGS.
  HSC_Settings_Initialize()
  -- Stats initializes globals + hooks/event listeners for tracking.
  HSC_CharacterStats_Initialize()

  -- UI modules are optional; guard for nil to support partial loads during development.
  if HSC_UI_MainScreenStatistics_Initialize then
    HSC_UI_MainScreenStatistics_Initialize()
  end

  if HSC_UI_StatisticsWindow_Initialize then
    HSC_UI_StatisticsWindow_Initialize()
  end

  if HSC_UI_OptionsPanel_Initialize then
    HSC_UI_OptionsPanel_Initialize()
  end

  if HSC_UI_MinimapButton_Initialize then
    HSC_UI_MinimapButton_Initialize()
  end
end

eventFrame:RegisterEvent('ADDON_LOADED')
eventFrame:SetScript('OnEvent', function(_, event, name)
  if event == 'ADDON_LOADED' and name == ADDON_NAME then
    Initialize()
  end
end)

SLASH_HARDCORESTATCOMPANION1 = '/hsc'
SlashCmdList.HARDCORESTATCOMPANION = function()
  if HSC_UI_StatisticsWindow_Toggle then
    HSC_UI_StatisticsWindow_Toggle()
  end
end
