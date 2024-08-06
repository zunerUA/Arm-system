--[[ 
        
        This script is used to handle user input and interact.
        
]]
-- services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')
local GuiService = game:GetService('GuiService')

local Services = ReplicatedStorage:WaitForChild('Services')

local Load = require(ReplicatedStorage.Modules.Load)
-- Getting modules
local HoverService = Load("HoverService")
local ArmService = Load("ArmService")

local Highlight = Load("Highlight")
local CONSTANTS = require(script.CONSTANTS)

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = Player:GetMouse()

local Remotes = ReplicatedStorage:WaitForChild('RemoteEvents')

local InteractService = {}
InteractService.__index = InteractService

UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
-- class
function InteractService.new()
    local self = setmetatable({}, InteractService)
    
    self.HoverItem = HoverService.new("Item", CONSTANTS.MAX_ACTIVATION)
    self.HoverDoor = HoverService.new("Door", CONSTANTS.MAX_ACTIVATION)
    
    self.CurrentItem = nil
    self.CurrentDoor = nil
    
    self.HoverItem.ItemHover:Connect(function(part: BasePart)
        self.Highlight = Highlight.new(part)
        self.CurrentItem = part
    end)
    self.HoverItem.ItemReleased:Connect(function(oldPart: BasePart)
        if self.Highlight then
            self.Highlight:destroy()
            self.Highlight = nil
            self.CurrentItem = nil
        end
    end)
    self.HoverItem.ItemChanged:Connect(function(oldPart: BasePart, part: BasePart) 
        self.Highlight:destroy()
        self.Highlight = Highlight.new(part)
        self.CurrentItem = part
    end)
    
    self.HoverDoor.ItemHover:Connect(function(part: BasePart) 
        self.DoorHighlight = Highlight.new(part)
        self.CurrentDoor = part
    end)
    self.HoverDoor.ItemReleased:Connect(function(...: any) 
        if self.DoorHighlight then
            self.DoorHighlight:destroy()
            self.DoorHighlight = nil
            self.CurrentDoor = nil
            self.HoverDoor:reset()
        end
    end)
    self.HoverItem.ItemChanged:Connect(function(oldPart: BasePart, part: BasePart) 
        if self.DoorHighlight then
            self.DoorHighlight:destroy()
            self.DoorHighlight = Highlight.new(part)
            self.CurrentDoor = part
        end
    end)
    UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean) 
        if gameProcessedEvent then return end
        
        if input.KeyCode == Enum.KeyCode.F then
            if self.CurrentItem then
                self:pick_up_item(self.CurrentItem)
            elseif self.Item then
                self:drop_item()
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not self.Item and self.CurrentDoor then
                self:attach_door(self.CurrentDoor)
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessedEvent: boolean) 
        if gameProcessedEvent then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self.Door then
                self:leave_door()
            end
        end
    end)
    
    self:main_loop()
    
    return self
end
function InteractService:leave_door()
    self.HoverDoor:unfreeze()
    self.Arm:destroy()
    
    self.Door = nil
    
    Camera.CameraType = Enum.CameraType.Custom
end
function InteractService:attach_door(door: BasePart)
    self.Door = door
    self.HoverDoor:freeze()
     
    self.Arm = ArmService.new(door)
    self.lastCameraCFrame = Camera.CFrame
    
    Camera.CameraType = Enum.CameraType.Scriptable
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
end
function InteractService:pick_up_item(item: BasePart)
    self.Item = item
    self.HoverItem:freeze()
    
    self.Arm = ArmService.new(item)
end
function InteractService:drop_item()
    Remotes.Drop:FireServer(self.Item)
    task.delay(.2, function()
        self.HoverItem:unfreeze()
        self.HoverItem:reset()
    end)
    self.Arm:destroy()
    self.Item = nil
end
function InteractService:main_loop(dt: number)
    task.defer(function()
        RunService:BindToRenderStep("update", Enum.RenderPriority.Input.Value, function(deltaTime: number) 
            local Character = Player.Character or Player.CharacterAdded:Wait()
            local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
            
            if self.Item then
                if GuiService.MenuIsOpen then return end
                local origin = Mouse.Origin
                Remotes.Pick:FireServer(self.Item, origin)
                
                if (self.Item.Position-HumanoidRootPart.Position).Magnitude >= CONSTANTS.MAX_ACTIVATION then
                    self:drop_item()
                end
            end
            if self.Door then
                if not self.doorMousePosition then
                    self.doorMousePosition = UserInputService:GetMouseLocation()
                else
                    Remotes.MoveDoor:FireServer((UserInputService:GetMouseDelta()*CONSTANTS.DOOR_OPENING_ACCELERATION), self.Door)
                end

                if (self.Door.Position-HumanoidRootPart.Position).Magnitude >= CONSTANTS.MAX_ACTIVATION then
                    self:leave_door()
                end
                
                if not self.CameraOffset then
                    self.CameraOffset = HumanoidRootPart.CFrame:ToObjectSpace(Camera.CFrame)
                end
                
                Camera.CFrame = CFrame.fromMatrix(
                    HumanoidRootPart.CFrame:ToWorldSpace(self.CameraOffset).Position, 
                    self.lastCameraCFrame.XVector,
                    self.lastCameraCFrame.YVector,
                    self.lastCameraCFrame.ZVector
                )
            elseif self.doorMousePosition then
                self.doorMousePosition = nil
            end
        end)
    end)
end
local singleton = InteractService.new()
return singleton