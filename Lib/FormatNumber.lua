-- Utility: format integer numbers with thousands separators.
local function formatNumberWithCommas(number)
  number = tonumber(number) or 0
  local formatted = tostring(math.floor(number))
  local k
  while true do
    formatted, k = formatted:gsub('^(%d+)(%d%d%d)', '%1,%2')
    if k == 0 then
      break
    end
  end
  return formatted
end

HSC_FormatNumberWithCommas = formatNumberWithCommas
