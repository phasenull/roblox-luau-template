local Players = game:GetService("Players")
local Charm = require("@game/ReplicatedStorage/Packages/Charm")
local data_atom = require("@game/ReplicatedStorage/Shared/atoms/data.atom")
local profile_template = require("@game/ReplicatedStorage/Shared/profile.template")

local MY_DATA_ATOM = Charm.computed(function()
	local player = Players.LocalPlayer
	local data = data_atom()[player.UserId]
	if not data then return profile_template end
	local result = table.clone(data)
	return result
end)
return MY_DATA_ATOM