local Loader = require("@game/ReplicatedStorage/Packages/Loader")
local UILabs = require("@game/ReplicatedStorage/Packages/UILabs")
local trove = require("@game/ReplicatedStorage/Packages/trove")
local story = {
	controls = {},
	render = function(props: UILabs.GenericProps)
		local manager = trove.new()
		Loader.SpawnAll(Loader.LoadDescendants(script.Parent.Parent.ui["example-frame"]), "OnStart")
		return function()
			Loader.SpawnAll(Loader.LoadDescendants(script.Parent.Parent.ui["example-frame"]), "OnDestroy")
			manager:Destroy()
		end
	end,
}

return story
