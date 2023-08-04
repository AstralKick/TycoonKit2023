local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local TycoonComponent = require(ServerStorage.Source.Components.Tycoon)

Knit.OnStart():await()

Players.PlayerAdded:Connect(function(Player: Player)
    local TycoonComponents = TycoonComponent:GetAll()

    for _,Tycoon in ipairs (TycoonComponents) do
        if Tycoon.Owner ~= nil then continue end
        Tycoon:Claim(Player)
        break
    end
end)

Players.PlayerRemoving:Connect(function(Player: Player)
    local TycoonComponents = TycoonComponent:GetAll()

    for _,Tycoon in ipairs (TycoonComponents) do
        if Tycoon.Owner ~= Player then continue end
        Tycoon:Reset()
        break
    end
end)
