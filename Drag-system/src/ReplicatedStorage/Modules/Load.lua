local ReplicatedStorage = game:GetService('ReplicatedStorage')
local load = function(name: string)
    local module = ReplicatedStorage:FindFirstChild(name, true)
    
    if not module then warn(`Following module {module} doesn\'t exist!\n\n` .. debug.traceback()) end
    
    if module:IsA("ModuleScript") then
       return require(module)
    end
end
return load