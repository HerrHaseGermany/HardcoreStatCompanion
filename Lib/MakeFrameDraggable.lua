-- Utility: adds basic drag behavior (left button) to a frame.
local function MakeFrameDraggable(frame)
  if not frame then return end

  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag('LeftButton')

  frame:SetScript('OnDragStart', function(self)
    if self:IsMovable() then
      self:StartMoving()
    end
  end)

  frame:SetScript('OnDragStop', function(self)
    self:StopMovingOrSizing()
  end)
end

HSC_MakeFrameDraggable = MakeFrameDraggable
