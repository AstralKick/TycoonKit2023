local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

Knit.AddControllers(ReplicatedStorage.Source.Controllers)

Knit.Start():andThen(function()
    -- Components to load here
    for i,Components in ipairs (ReplicatedStorage.Source.Components:GetChildren()) do
        require(Components)
    end
end):catch(warn)