local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TypedRemote = require(ReplicatedStorage.Packages.TypedRemote)

local RF, RE, URE = TypedRemote.parent(script)

type RF<T..., R...> = TypedRemote.Function<T..., R...>
type RE<T...> = TypedRemote.Event<T...>
type URE<T...> = TypedRemote.UnreliableEvent<T...>

return {
	DataAtomSyncer = RE("DataAtomSyncer") :: RE<
		{ data: { [number | string]: any }, type: "init" } | { data: { [number | string]: any }, type: "patch" }
	>,
	RequestState = RE("RequestState") :: RE<()>,
}
