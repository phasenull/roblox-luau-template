local Charm = require("@game/ReplicatedStorage/Packages/Charm")
local type_helper = require("@game/ReplicatedStorage/Shared/type.helper")

local ContextAtom = Charm.atom({}) :: Charm.Atom<{ [type_helper.ActionType]: number|nil }>
return ContextAtom
