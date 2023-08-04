local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)

local RoactApp = Roact.createElement("ScreenGui", {ResetOnSpawn = false}, {

})

Roact.mount(RoactApp)