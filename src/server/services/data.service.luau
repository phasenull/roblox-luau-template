local Players = game:GetService("Players")
local Charm = require("@game/ReplicatedStorage/Packages/Charm")
local CharmSync = require("@game/ReplicatedStorage/Packages/CharmSync")
local data_atom = require("@game/ReplicatedStorage/Shared/atoms/data.atom")
local env = require("@game/ReplicatedStorage/Shared/env")
local network = require("@game/ReplicatedStorage/Shared/network")
local profile_template = require("@game/ReplicatedStorage/Shared/profile.template")
local util_helper = require("@game/ReplicatedStorage/Shared/util.helper")
local ProfileStore = require("@game/ServerScriptService/ServerPackages/ProfileStore")

local DataService = {
	atom_reference = data_atom,
}
local PlayerStore = ProfileStore.New("player_data_" .. env, profile_template)
local PROFILES: { [number]: typeof((PlayerStore:StartSessionAsync(`____`, {
	Cancel = function()
		return
	end,
}))) } =
	{}
local syncer = CharmSync.server({
	-- A dictionary of the atoms to sync, matching the client's
	atoms = { data_atom },
	-- The minimum interval between state updates
	interval = 0.5,
	-- Whether to send a full history of changes made to the atoms (slower)
	preserveHistory = false,
	-- Whether to apply fixes for remote event limitations. Disable this option
	-- when using a network library with custom ser/des, like ByteNet or Zap.
	autoSerialize = false,
})
syncer:connect(
	function(
		player: Player,
		...: { data: { [number | string]: any }, type: "init" } | { data: { [number | string]: any }, type: "patch" }
	)
		network.DataAtomSyncer:FireClient(player, ...)
	end
)
local PREFIX = "[data.service.luau]:"
local JOINS: { [Player]: number } = {}

function DataService.PlayerRemoving(player: Player) end
function DataService.UpdatePlayer(player: Player, callback: (data: typeof(profile_template)) -> ())
	local user_id = tostring(player.UserId)
	local response
	data_atom(function(state)
		local player_data = state[user_id]
		if not player_data then
			return state
		end

		-- Shallow clone the top-level state
		local new_state = table.clone(state)
		-- Shallow clone the specific player's data
		local new_player_data = table.clone(player_data)

		-- Apply mutation locally to the clone
		response = callback(new_player_data)

		new_state[user_id] = new_player_data
		return new_state
	end)
	return response
end

function DataService.PlayerAdded(player: Player)
	local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if not profile then
		player:Kick("Failed to load data!")
		return
	end
	-- profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		local p = PROFILES[player.UserId]
		if p then
			local diff = os.clock() - (JOINS[player] or os.clock())
			print(PREFIX, "adding", diff, "seconds of playtime to player", player)
			DataService.UpdatePlayer(player, function(data)
				data.playtime += diff
			end)
		end
		print(PREFIX, "Ended session for player", player)
		PROFILES[player.UserId] = nil
		player:Kick(`Profile session ended, try rejoining.`)

		-- Clear player from atom
		data_atom(function(state)
			local new_state = table.clone(state)
			new_state[tostring(player.UserId)] = nil
			return new_state
		end)
	end)
	if player.Parent == Players then
		JOINS[player] = os.clock()
		PROFILES[player.UserId] = profile
		print(PREFIX, `Profile loaded for {player.DisplayName}!`, PROFILES[player.UserId])

		-- Initialize player data in atom
		data_atom(function(state)
			local new_state = table.clone(state)
			new_state[tostring(player.UserId)] = profile.Data
			return new_state
		end)

		syncer:hydrate(player)
	else
		profile:EndSession()
	end
end
function DataService.GetPlayerProfile(player: Player)
	return PROFILES[player.UserId]
end
function DataService.GetPlayerSubatom(player: Player)
	return data_atom()[util_helper.getPKey(player)]
end
-- function DataService.GetPlayerProfile(player:Player)
-- return PROFILES[player]
-- end

function DataService.OnStart()
	print(PREFIX, "Starting data service on environment:", env)

	-- Keep ProfileStore Data updated automatically based on the Charm atom
	Charm.effect(function()
		local state = data_atom()
		for user_id_str, data in state do
			local user_id = tonumber(user_id_str)
			local profile = PROFILES[user_id :: number]
			if profile then
				profile.Data = data
			end
		end
	end)

	network.RequestState.OnServerEvent:Connect(function(player: Player)
		syncer:hydrate(player)
	end)
	game:BindToClose(function()
		for player, profile in pairs(PROFILES) do
			if not profile then
				continue
			end
			print(PREFIX, "Handling bind to close for player", player)
			profile:EndSession()
		end
	end)
	Players.PlayerAdded:Connect(DataService.PlayerAdded)
	Players.PlayerRemoving:Connect(DataService.PlayerRemoving)
end

function DataService.MakePlayerPurchase(player: Player, price: number, descriptor: string,callback: (data: typeof(profile_template)) -> ()): string | nil
	local sub_atom = DataService.GetPlayerSubatom(player)
	if sub_atom.cash < price then
		return `Missing: {util_helper.formatNumber(price - sub_atom.cash, 2)}`
	end
	DataService.UpdatePlayer(player, function(data)
		data.cash -= math.max(price, 0)
		callback(data)
		-- notify client
		return
	end)
	return nil
end
return DataService
