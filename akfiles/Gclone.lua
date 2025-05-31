local function initializeTeleportClone()
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer
    local Mouse = Player:GetMouse()
    local Workspace = game:GetService("Workspace")
    
    -- Clone settings
    local CloneSettings = {
        Enabled = false,
        Bind = "G",
        Value = 15,
        Delay = 0.05
    }
    
    -- Error handling function
    local function safeGetCharacter()
        local character = Player.Character or Player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
        return character, humanoidRootPart
    end
    
    -- Teleport function with error handling
    local function teleportToMouse()
        local character, humanoidRootPart = safeGetCharacter()
        if humanoidRootPart then
            local mousePosition = Mouse.Hit.Position
            humanoidRootPart.CFrame = CFrame.new(mousePosition + Vector3.new(0, 3, 0))
        end
    end
    
    -- Input handling
    local function setupInputHandler()
        local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.KeyCode == Enum.KeyCode.F then
                teleportToMouse()
            end
            
            if input.KeyCode == Enum.KeyCode[CloneSettings.Bind] then
                CloneSettings.Enabled = not CloneSettings.Enabled
            end
        end)
        
        return connection
    end
    
    -- Clone movement handler
    local function handleCloneMovement()
        local cOld
        
        while true do
            if CloneSettings.Enabled then
                local character, humanoidRootPart = safeGetCharacter()
                
                if humanoidRootPart then
                    cOld = humanoidRootPart.CFrame
                    
                    -- Left movement
                    humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.new(-CloneSettings.Value, 0, 0)
                    task.wait(CloneSettings.Delay)
                    humanoidRootPart.CFrame = cOld
                    task.wait(CloneSettings.Delay)
                    
                    -- Right movement
                    humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.new(CloneSettings.Value, 0, 0)
                    task.wait(CloneSettings.Delay)
                    humanoidRootPart.CFrame = cOld
                end
            end
            task.wait(0.1)
        end
    end
    
    -- Setup and error handling
    local success, errorMsg = pcall(function()
        local inputConnection = setupInputHandler()
        
        -- Cleanup on script stop
        local cleanupConnection
        cleanupConnection = game:GetService("CoreGui").DescendantRemoving:Connect(function(instance)
            if instance == script then
                inputConnection:Disconnect()
                cleanupConnection:Disconnect()
            end
        end)
        
        -- Start clone movement
        coroutine.wrap(handleCloneMovement)()
    end)
    
    if not success then
        warn("Teleport Clone Script Error:", errorMsg)
    end
end

-- Initialize the script
initializeTeleportClone()
