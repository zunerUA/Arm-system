--[[
        
        A script to detect is player hovering object with special tag
        
]]
-- services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local Modules = ReplicatedStorage:WaitForChild('Modules')

local Load = require(ReplicatedStorage.Modules.Load)
local Signal = Load("Signal")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local HoverService = {}
HoverService.__index = HoverService

function HoverService.update(self)
    self.LastTarget = nil
    RunService:BindToRenderStep("hover" .. self.tag, Enum.RenderPriority.Input.Value, function(dt)
        local Character = Player.Character or Player.CharacterAdded:Wait()
        local HumanoidRootPart: Part = Character:FindFirstChild("HumanoidRootPart")
        
        self.Target = not self.Isfreeze and Mouse.Target or nil
        
        if self.Target 
            and self.Target:HasTag(self.tag) 
            and not self.Target:HasTag("Occupied")
            and not self.Isfreeze
            and (self.Target.Position - HumanoidRootPart.Position).Magnitude <= self.maxDist
        then
            if not self.LastTarget then
                self.ItemHover:Fire(self.Target)
            elseif self.LastTarget ~= self.Target then
                self.ItemChanged:Fire(self.LastTarget, self.Target)
            end
        elseif self.LastTarget then
            self.ItemReleased:Fire(self.LastTarget)
        end
        
        if self.Target then
            self.LastTarget = self.Target:HasTag(self.tag) and self.Target or nil
        else
            self.LastTarget = nil
        end
    end)
end
function HoverService:reset()
    self.Target = nil
    self.LastTarget = nil
end
function HoverService:freeze()
    self.Isfreeze = true
end
function HoverService:unfreeze()
    self.Isfreeze = false
end
function HoverService.new(tag: string, maxDist: number)
    local self = setmetatable({}, HoverService)
    
    self.ItemHover = Signal.new()
    self.ItemReleased = Signal.new()
    self.ItemChanged = Signal.new()
    self.tag = tag
    self.maxDist = maxDist
    
    self.Isfreeze = false
    
    task.spawn(self.update, self)

    return self
end
return HoverService