local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Rodux = require(Packages.Rodux)

local function Reducer(State: {}, Action: {}): {}
    State = State or {

    }

    -->> Type changes based on action here.
    
    return State
end

local Store = Rodux.Store.new(Reducer)