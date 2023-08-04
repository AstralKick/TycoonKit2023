local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local PurchaseService = Knit.CreateService{
    Name = "PurchaseService",
    Client = {}
}

function PurchaseService.Client:PurchaseItem(Player: Player, Item: string)

    return true
end

return PurchaseService