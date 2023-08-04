local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

Knit.AddServices(ServerStorage.Source.Services)

Knit.Start():andThen(function()
    -- Components to load here
    for _,Component in ipairs (ServerStorage.Source.Components:GetChildren()) do
        require(Component)
    end
end):catch(warn)