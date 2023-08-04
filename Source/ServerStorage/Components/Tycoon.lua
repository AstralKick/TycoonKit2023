local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)
local Trove = require(Packages.Trove)
local Knit = require(Packages.Knit)
local TycoonTemplate = ReplicatedStorage.Tycoon

local Tycoon = Component.new{ Tag = "Tycoon" }

function Tycoon:Construct()
    self._defaultItems = {}

    for i,Items in ipairs (self.Instance:GetChildren()) do
        table.insert(self._defaultItems, Items)
    end
end

function Tycoon:Start()

end

function Tycoon:Claim(Player: Player)
    print("TYCOON OWNER UPDATED: ", Player.Name)

    self._trove = Trove.new()
    self.Owner = Player

    self._trove:Add(function()
        self.Owner = nil
        print("TYCOON OWNER UPDATED: nil")
    end) -->> Cleanup.
end

function Tycoon:UpdateState()
    
end

function Tycoon:Reset()
    for index,Item in ipairs (self.Instance:GetChildren()) do
        if table.find(self._defaultItems, Item) then continue end
        Item:Destroy()
    end
    self._trove:Destroy()
end

function Tycoon:Stop()

end

return Tycoon