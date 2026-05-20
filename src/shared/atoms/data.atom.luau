local Charm = require("@game/ReplicatedStorage/Packages/Charm")
local profile_template = require("@game/ReplicatedStorage/Shared/profile.template")

local PLAYER_DATA_ATOM = Charm.atom({}) :: Charm.Atom<{
	[string]:typeof(profile_template)
}>
return PLAYER_DATA_ATOM