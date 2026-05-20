local RunService = game:GetService("RunService")
local ENV = RunService:IsStudio() and "dev" or "production"
return ENV