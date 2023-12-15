local InstanceGuard = {}

function InstanceGuard.BasePart(part: unknown)
	assert(typeof(part) == "Instance" and part:IsA("BasePart"))
	return part
end

return InstanceGuard
