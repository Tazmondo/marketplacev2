local StarterGui = game:GetService("StarterGui")
-- Need to disable these three to stop the top right menu from appearing
-- StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
-- StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- Need to wait for client scripts to register this, so it may error at first.
local successful = false
local start = os.clock()
repeat
	successful = pcall(StarterGui.SetCore, StarterGui, "ResetButtonCallback", false)
	if os.clock() - start > 5 then
		warn("Took too long to disable reset!")
		return
	end
	task.wait()
until successful == true
