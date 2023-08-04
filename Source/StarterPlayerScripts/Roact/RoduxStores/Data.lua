local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Rodux = require(Packages.Rodux)
local Comm = require(Packages.Comm)

local DataComm = Comm.ClientComm.new(ReplicatedStorage, true, "DataComm")
local DataProfile = DataComm:GetProperty("Profile")

local function Reducer(State: {}, Action: {}): {}
    local Success,Info = DataProfile:OnReady():await()
    State = State or Info

    -->> Type changes based on action here.

    if Action.type == "UpdateProfile" then
        return Action.Profile
    end
    
    return State
end

local Store = Rodux.Store.new(Reducer)

DataProfile:Observe(function(Profile)
    Store:dispatch{
        type = "UpdateProfile",
        profile = Profile
    }
end)

return Store