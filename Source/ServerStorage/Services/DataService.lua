--- Collect the services needed to run this function.
local MarketplaceService = game:GetService("MarketplaceService") -- The marketplace service for handling purchases
local Players = game:GetService("Players") -- The service for managing players
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- The service for accessing replicated storage
local ServerStorage = game:GetService("ServerStorage") -- The service for accessing server storage
local Knit = require(ReplicatedStorage.Packages.Knit) -- External module for organizing code in a service-oriented architecture
local ProfileService = require(ReplicatedStorage.Packages.ProfileService) -- External module for managing player profiles
local Promise = require(ReplicatedStorage.Packages.Promise)
local Comm = require(ReplicatedStorage.Packages.Comm)
local DataComm = Comm.ServerComm.new(ReplicatedStorage, "DataComm")
local DataProfile = DataComm:CreateProperty("Profile", {})


-- Util files
local Template = require(ServerStorage.Source.Misc.DataTemplate) -- Template for player profiles
local Products = require(ServerStorage.Source.Misc.Products) -- Table of product functions
local PurchaseIdLog = 50 -- Maximum number of purchase IDs to store

local GameProfileStore = ProfileService.GetProfileStore("PlayerData", Template) -- Create a profile store for player data

local Profiles = {} -- Table to store player profiles

local function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = deepCopy(v)
		end
		copy[k] = v
	end
	return copy
end

--- Function called when a player joins the game.
-- @param Player The player who joined the game.
local function PlayerAdded(Player: Player)
    local profile = GameProfileStore:LoadProfileAsync("Player_"..Player.UserId)

    if profile then
        profile:AddUserId(Player.UserId)
        profile:Reconcile()
        profile:ListenToRelease(function()
            Profiles[Player] = nil
            Player:Kick("Profile was loaded elsewhere")
        end)

        if Player:IsDescendantOf(Players) then
            Profiles[Player] = profile
            DataProfile:SetFor(Player, deepCopy(profile.Data))
        else
            profile:Release()
        end
    else
        Player:Kick("Profile failed to load")
    end
end

--- Function to check the purchase ID and grant the product.
-- @param profile The player's profile.
-- @param purchase_id The purchase ID to check.
-- @param grantCallback The callback function to grant the product.
-- @return Enum.ProductPurchaseDecision The decision on whether to grant the product or not.
local function PurchaseIdCheckAsync(profile, purchase_id: number, grantCallback: () -> ()): Enum.ProductPurchaseDecision
    if not profile:IsActive() then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    else
        local MetaData = profile.MetaData

        local loggedPurchaseIds = MetaData.MetaTags.ProfilePurchaseIds
        if not loggedPurchaseIds then
            loggedPurchaseIds = {}
            MetaData.MetaTags.ProfilePurchaseIds = loggedPurchaseIds
        end

        if not table.find(loggedPurchaseIds, purchase_id) then
            while #loggedPurchaseIds >= PurchaseIdLog do
                table.remove(loggedPurchaseIds, 1)
            end
            table.insert(loggedPurchaseIds, purchase_id)
            task.spawn(grantCallback)
        end

        local result = nil

        local function checkMetaTags()
            local savedPurchaseIds = MetaData.MetaTagsLatest.ProfilePurchaseIds
            if savedPurchaseIds and table.find(savedPurchaseIds, purchase_id) then
                result = Enum.ProductPurchaseDecision.PurchaseGranted
            end
        end

        checkMetaTags()

        local metaTagsConnection = profile.MetaTagsUpdated:Connect(function()
            checkMetaTags()
            if not profile:IsActive() and not result then
                result = Enum.ProductPurchaseDecision.NotProcessedYet
            end
        end)

        while not result do
            task.wait()
        end

        metaTagsConnection:Disconnect()

        return result
    end
end

--- Function to get the player's profile asynchronously.
-- @param Player The player for which to retrieve the profile.
-- @return any The player's profile.
local function GetPlayerProfileAsync(Player: Player): any
    local profile = Profiles[Player]
    while not profile and Player:IsDescendantOf(Players) do
        task.wait()
        profile = Profiles[Player]
    end
    return profile
end

--- Function to grant a product to the player.
-- @param Player The player to grant the product to.
-- @param ProductId The ID of the product to grant.
local function GrantProduct(Player: Player, ProductId: number)
    local profile = Profiles[Player]
    local product_function = Products[ProductId]
    if product_function then
        product_function(profile)
    else
        warn("Product number "..ProductId.." does not have an attached function.")
    end
end

--- Function called when processing a receipt from a player's purchase.
-- @param receiptInfo The information about the receipt.
-- @return Enum.ProductPurchaseDecision The decision on whether to process the receipt or not.
local function processReceipt(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local profile = GetPlayerProfileAsync(player)

    if profile then
        return PurchaseIdCheckAsync(
            profile,
            receiptInfo.PurchaseId,
            function()
                GrantProduct(player, receiptInfo.ProductId)
            end
        )
    else
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

-- Spawn the PlayerAdded function for existing players
for _, Player in ipairs(Players:GetPlayers()) do
    task.spawn(PlayerAdded, Player)
end

-- Set the processReceipt function as the handler for processing receipts
MarketplaceService.ProcessReceipt = processReceipt

-- Connect the PlayerAdded function to the PlayerAdded event
Players.PlayerAdded:Connect(PlayerAdded)

-- Connect the profile release function to the PlayerRemoving event
Players.PlayerRemoving:Connect(function(Player: Player)
    local profile = Profiles[Player]
    if profile then
        profile:Release()
    end
end)

-- Create the DataService using Knit
local DataService = Knit.CreateService{
    Name = "DataService",
    Client = {

    }
}

-- Function called when Knit starts the service

function DataService:GetKey(Player: Player, Key: string): any
    return Promise.new(function(resolve, reject)
        local Profile = GetPlayerProfileAsync(Player)
        local askedValue = Profile.Data[Key]

        if askedValue then
            resolve(askedValue)
        else
            reject()
        end
    end)
end

function DataService:SetKey(Player: Player, Key: string, Value: any)
    return Promise.new(function(resolve, reject)
        local Profile = GetPlayerProfileAsync(Player)
        local askedValue = Profile.Data[Key]

        if askedValue then
            askedValue = Value
            DataProfile:SetFor(Player, deepCopy(Profile.Data))
        else
            reject()
        end
    end)
end

return DataService
