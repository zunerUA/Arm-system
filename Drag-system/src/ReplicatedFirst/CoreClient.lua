if not game:IsLoaded()
then
    game.Loaded:Wait()
end

local InteractService = require(game:GetService('ReplicatedStorage').Services.InteractService)