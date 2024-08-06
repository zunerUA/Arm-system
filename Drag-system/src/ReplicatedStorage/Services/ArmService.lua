local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Constants = require(ReplicatedStorage.Services.InteractService.CONSTANTS)
local Maid = require(ReplicatedStorage.Modules.Maid)

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera
local ArmService = {}
ArmService.__index = ArmService

function ArmService.new(object: BasePart)
    local self = setmetatable({}, ArmService)
    
    self.Maid = Maid.new()
    
    self.Object = object
    self.Character = Player.Character
    self._arm = self.Character:FindFirstChild("Right Arm")
    self.Root = self.Character:FindFirstChild("HumanoidRootPart")
    
    self.RootAttachment = self.Root:FindFirstChildOfClass("Attachment")
    
    self.ArmAttachment = self.RootAttachment:Clone()
    self.ArmAttachment.Parent = self.Root
    self.ArmAttachment.Name = "ArmAttachment"
    self.ArmAttachment.Position += Constants.ARM_OFFSET
    
    self.Offset = Mouse.Hit:ToObjectSpace(object.CFrame):Inverse()
    
    self.Maid:GiveTask(self.ArmAttachment)
    self:create()
    
    task.spawn(self.update, self)
    
    return self
end
function ArmService:create()
    self.ArmHolder = Instance.new("Model", Camera)
    
    self.ArmHolder.Name = "ArmHolder"
    
    self.Humanoid = Instance.new("Humanoid", self.ArmHolder)
    
    for _, Clothing: Clothing in self.Character:GetChildren() do
        if Clothing:IsA("Clothing") then
            Clothing:Clone().Parent = self.ArmHolder
        end
    end
    
    self.Arm = self._arm:Clone()
    self.Arm.Anchored = true
    self.Arm.Parent = self.ArmHolder
    
    self.Maid:GiveTask(self.ArmHolder)
end
function ArmService:destroy()
    self.Maid:Destroy()
    RunService:UnbindFromRenderStep("updateArm")
end
function ArmService.update(self)
    RunService:BindToRenderStep("updateArm", Enum.RenderPriority.Character.Value, function(dt)
        local pos1 = self.ArmAttachment.WorldPosition
        local pos2 = self.Object.CFrame:ToWorldSpace(self.Offset).Position
        self.Arm.Size = Vector3.new(Constants.ARM_SIZE, Constants.ARM_SIZE, (pos2 - pos1).Magnitude + 1)
        self.Arm.CFrame = CFrame.lookAt((pos1 + pos2) / 2, pos2) 
    end)
end


return ArmService