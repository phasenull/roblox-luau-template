local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
local utils = {}

export type Suffix = {
	value: number,
	symbol: string,
}

local SUFFIXES: { Suffix } = {
	{ value = 1e30, symbol = "No" }, -- nonillion
	{ value = 1e27, symbol = "Oc" }, -- octillion
	{ value = 1e24, symbol = "Sp" }, -- septillion
	{ value = 1e21, symbol = "Sx" }, -- sextillion
	{ value = 1e18, symbol = "Qi" }, -- quintillion
	{ value = 1e15, symbol = "Qa" }, -- quadrillion
	{ value = 1e12, symbol = "T" }, -- trillion
	{ value = 1e9, symbol = "B" }, -- billion
	{ value = 1e6, symbol = "M" }, -- million
	{ value = 1e3, symbol = "K" }, -- thousand
}
function utils.getPlayerByPKey(key: string)
	return Players:GetPlayerByUserId(tonumber(key))
end
function utils.getPKey(player: Player)
	return tostring(player.UserId)
end
function utils.buildError(text: string)
	return `<font color="rgb(255,0,0)">{text}</font>`
end
function utils.getFrameInstanceFromKey(key: string)
	if RunService:IsRunning() then
		return Players.LocalPlayer.PlayerGui.root:FindFirstChild(key)
	else
		return StarterGui.root:FindFirstChild(key)
	end
end
function utils.isFrameReal(instance: GuiObject)
	if instance:IsDescendantOf(ReplicatedStorage) then
		return false
	end
	if instance:IsDescendantOf(Players.LocalPlayer) and RunService:IsRunning() then
		return true
	end
	if instance:IsDescendantOf(CoreGui) and not RunService:IsRunning() then
		return true
	end
	return false
end
function utils.formatNumber(n: number, override_delimeter: number | nil): string
	local absN = math.abs(n)

	for _, suffix in SUFFIXES do
		if absN >= suffix.value then
			local scaled = n / suffix.value

			-- keep 1 decimal if needed, otherwise integer
			local formatted: string
			if math.abs(scaled) >= 100 then
				formatted = string.format(`%.{override_delimeter or 0}f`, scaled)
			elseif math.abs(scaled) >= 10 then
				formatted = string.format(`%.{override_delimeter or 1}f`, scaled)
			else
				formatted = string.format(`%.{override_delimeter or 2}f`, scaled)
			end
			return formatted .. suffix.symbol
		end
	end

	-- fallback for small numbers
	return tostring(n)
end
function utils.isPointWithinInstance(point: Vector3, instance: BasePart, area_multiplier: number?)
	area_multiplier = area_multiplier or 1
	local corner1 = instance.Position + (instance.Size / 2) * area_multiplier :: number
	local corner2 = instance.Position - (instance.Size / 2) * area_multiplier :: number
	local X = point.X <= corner1.X and point.X >= corner2.X
	local Y = point.Y <= corner1.Y and point.Y >= corner2.Y
	local Z = point.Z <= corner1.Z and point.Z >= corner2.Z
	return X and Y and Z
end
function utils.instantiateTweenNumber(initial_value: number, tween_info: TweenInfo)
	local number_value = Instance.new("NumberValue")
	number_value.Value = initial_value
	local event = Signal.new()
	local function playTween(target: number)
		local tween = TweenService:Create(number_value, tween_info, { Value = target })
		tween:Play()

		local conn = number_value.Changed:Connect(function(a0: number)
			event:Fire(number_value.Value)
		end)
		tween.Completed:Once(function(a0: Enum.PlaybackState)
			number_value:Destroy()
			conn:Disconnect()
		end)
	end
	return {
		instance = number_value,
		setTargetValue = function(new_value: number)
			playTween(new_value)
		end,
		Animated = event,
	}
end
return utils
