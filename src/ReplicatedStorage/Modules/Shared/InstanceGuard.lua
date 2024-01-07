local InstanceGuard = {}

function InstanceGuard.BasePart(part: unknown)
	assert(typeof(part) == "Instance" and part:IsA("BasePart"))
	return part
end

function InstanceGuard.Model(model: unknown)
	assert(typeof(model) == "Instance" and model:IsA("Model"))
	return model
end

return InstanceGuard
