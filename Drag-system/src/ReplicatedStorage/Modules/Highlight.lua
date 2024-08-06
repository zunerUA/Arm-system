local TweenService = game:GetService('TweenService')

local Highlight = {}
Highlight.__index = Highlight
function Highlight.new(part: BasePart)
    local self = setmetatable({}, Highlight)
    self.Highlight = Instance.new('Highlight', part)
    
    self.Highlight.Adornee = part
    self.Highlight.OutlineColor = Color3.new(1, 1, 1)
    self.Highlight.FillTransparency = 1
    self.Highlight.OutlineTransparency = 1
    self.Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    
    TweenService:Create(self.Highlight, TweenInfo.new(0.2), {
        OutlineTransparency = 0
    }):Play()
    
    return self
end
function Highlight:destroy()
    self.Highlight:Destroy()
end

return Highlight