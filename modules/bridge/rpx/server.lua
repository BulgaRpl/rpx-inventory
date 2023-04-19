local playerDropped = ...
local Inventory = require 'modules.inventory.server'

RegisterNetEvent('SERVER:RPX:Logout', function()
	local src = source
	playerDropped(source)
end)

AddStateBagChangeHandler("job", nil, function(bagName, key, value) 
    local source = GetPlayerFromStateBagName(bagName)
    if source == 0 then return end

	local inventory = Inventory(source)
	if not inventory then return end
	inventory.player.groups[value.name] = value.rank
end)

AddStateBagChangeHandler("gang", nil, function(bagName, key, value) 
    local source = GetPlayerFromStateBagName(bagName)
    if source == 0 then return end

	local inventory = Inventory(source)
	if not inventory then return end
	inventory.player.groups[value.name] = value.rank
end)

---@diagnostic disable-next-line: duplicate-set-field
function server.hasLicense(inv, name)
	return false
end

---@diagnostic disable-next-line: duplicate-set-field
function server.buyLicense(inv, license)
	return false, '_'
end

---@diagnostic disable-next-line: duplicate-set-field
function server.isPlayerBoss(playerId, group, grade)
	local groupData = GlobalState.Shared_Jobs[group]

	return groupData and exports['rpx-core']:HasJobPermission(group, grade, "generic:bossmenu")
end

-- Accounts that need to be synced with physical items
server.accounts = {
    money = 0
}

function server.syncInventory(inv)
	local money = table.clone(server.accounts)

	for _, v in pairs(inv.items) do
		if money[v.name] then
			money[v.name] += v.count
		end
	end

	local player = server.GetPlayerFromId(inv.id)
	if money.money then
		player.SetMoney('cash', money.money)
	end
end

SetTimeout(2000, function()
    RPX = exports["rpx-core"]:GetObject()
    server.GetPlayerFromId = RPX.GetPlayer
    for _, id in pairs(GetPlayers()) do
		local character = RPX.GetPlayer(id)
		if character then
			character.identifier = character.citizenid
			character.name = character.name
			character.dateofbirth = character.charinfo.age
			server.setPlayerInventory(character)
			Inventory.SetItem(character.source, "money", character?.money.cash)
		end
	end
end)

local function setupPlayer(src, Player)
	Player.identifier = Player.citizenid
	Player.name = Player.fullname
	Player.dateofbirth = Player.age
	Player.source = src

	server.setPlayerInventory(Player)
	Inventory.SetItem(Player.source, 'money', Player.money.cash)
end
AddEventHandler('SERVER:RPX:PlayerLoaded', setupPlayer)

AddEventHandler("SERVER:RPX:OnCashChanged", function(source, cash) 
    Inventory.SetItem(source, "money", cash)
end)