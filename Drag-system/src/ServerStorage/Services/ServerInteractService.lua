--[[   
        
        This script is used to replicate item/door movement
        
]]

-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local PhysicsService = game:GetService('PhysicsService')
local Players = game:GetService('Players')
-- Modules
local Load = require(ReplicatedStorage.Modules.Load)
local Maid = Load("Maid")
-- Registering Item collision group
PhysicsService:RegisterCollisionGroup("Item")

local Remotes = ReplicatedStorage:WaitForChild('RemoteEvents')
-- CONSTANTS
local CONSTANTS = {}
CONSTANTS.MAX_DOOR_OPEN_ANGLE = 90

table.freeze(CONSTANTS)

local Interact = {}
Interact.__index = Interact
function Interact.new()
    local self = setmetatable({}, Interact)

    self.Maids = {}
    self.Offsets = {}

    Players.PlayerAdded:Connect(function(player: Player) 
        PhysicsService:RegisterCollisionGroup(player.Name)
        player.CharacterAdded:Connect(function(character: Model) 
            for _, component: BasePart in character:GetDescendants() do
                if not component:IsA("BasePart") then continue end
                component.CollisionGroup = player.Name
            end
        end)
    end)
    Remotes.Pick.OnServerEvent:Connect(function(player: Player, item: BasePart, origin: CFrame) 
        if PhysicsService:CollisionGroupsAreCollidable(player.Name, "Item") then
            self:setup_collisions(player, item)
            
            local Attachment = Instance.new('Attachment', item)
            local AlignOrientation = script.AlignOrientation:Clone()
            local AlignPosition = script.AlignPosition:Clone()
            
            AlignOrientation.Attachment0 = Attachment
            AlignPosition.Attachment0 = Attachment
            
            AlignPosition.Parent = item
            AlignOrientation.Parent = item

            self.Maids[player.Name] = Maid.new()
            
            local _maid = self.Maids[player.Name]
            
            _maid:GiveTask(Attachment)
            _maid:GiveTask(AlignPosition)
            _maid:GiveTask(AlignOrientation)
            
            item:SetNetworkOwner(player)
            item:AddTag("Occupied")
            
            self.Offsets[player.Name] = (origin:ToObjectSpace(item.CFrame):Inverse()):Inverse()
        else
            local AlignPosition = item:FindFirstChildOfClass('AlignPosition')
            local AlignOrientation = item:FindFirstChildOfClass('AlignOrientation')
            
            local X, Y, Z = origin.LookVector.X, origin.LookVector.Y, origin.LookVector.Z
            
            AlignOrientation.CFrame = origin:ToWorldSpace(self.Offsets[player.Name])
            AlignPosition.Position = (origin.Position + Vector3.new(X, Y, Z) * (GetRatio(item.Size) + 2))-Vector3.yAxis
        end
    end)
    Remotes.Drop.OnServerEvent:Connect(function(player: Player, item: BasePart)
        self.Maids[player.Name]:Destroy()
        self:return_collisions(player, item)
        item:RemoveTag("Occupied")
    end)
    Remotes.MoveDoor.OnServerEvent:Connect(function(player: Player, delta: Vector2, door: BasePart) 
        local model = door:FindFirstAncestor("Door")
        local hingeConstraint = model:FindFirstChildWhichIsA("HingeConstraint", true)
        hingeConstraint.TargetAngle = 
            if hingeConstraint.CurrentAngle >= 0 then
            math.min(hingeConstraint.TargetAngle+(delta.X+delta.Y), CONSTANTS.MAX_DOOR_OPEN_ANGLE)
            else math.max(0, (hingeConstraint.TargetAngle+(delta.X+delta.Y))-1)
    end)

    return self
end
function Interact:return_collisions(player: Player, item: BasePart)
    item.CollisionGroup = "Default"
    PhysicsService:CollisionGroupSetCollidable(player.Name, "Item", true)
end
function Interact:setup_collisions(player: Player, item: BasePart)
    item.CollisionGroup = "Item"
    PhysicsService:CollisionGroupSetCollidable(player.Name, "Item", false)
end
function GetRatio(Vector: Vector3): number
    return math.max(Vector.X, Vector.Y, Vector.Z)
end

local singleton = Interact.new()
return singleton