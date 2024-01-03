local UserInputService = game:GetService("UserInputService")

type Device = "PC" | "Mobile" | "Console"

local currentDevice: Device = "PC"

local function HandleLastInputTypeChanged(inputType: Enum.UserInputType)
	if
		inputType == Enum.UserInputType.MouseButton1
		or inputType == Enum.UserInputType.MouseButton2
		or inputType == Enum.UserInputType.MouseButton3
		or inputType == Enum.UserInputType.MouseMovement
		or inputType == Enum.UserInputType.MouseWheel
	then
		currentDevice = "PC"
	elseif inputType == Enum.UserInputType.Touch then
		currentDevice = "Mobile"
	elseif inputType == Enum.UserInputType.Gamepad1 then
		currentDevice = "Console"
	end
end

UserInputService.LastInputTypeChanged:Connect(HandleLastInputTypeChanged)

local function GetLastDeviceInput(): Device
	return currentDevice
end

return GetLastDeviceInput
