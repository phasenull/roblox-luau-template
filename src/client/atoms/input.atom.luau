local UserInputService = game:GetService("UserInputService")
local Charm = require("@game/ReplicatedStorage/Packages/Charm")

local InputAtom = Charm.atom({
	input = UserInputService.PreferredInput,
})
UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
	if UserInputService.PreferredInput == InputAtom().input then
		return
	end

	InputAtom(function(state)
		local new_state = table.clone(state)
		new_state.input = UserInputService.PreferredInput
		return new_state
	end)
end)
return InputAtom
