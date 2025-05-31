-------------------------------
-- Flashback Controller (Holds C to rewind)
-- Simple version with no GUI
-------------------------------

-- Load services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

-------------------------------
-- Variables & Parameters
-------------------------------
local flashbackRecords = {}        -- Buffer for all individual frames
local maxFlashbackTime = 60        -- Record the last 60 seconds (max)
local isRewinding = false          -- Flag for rewind mode
local rewindKey = Enum.KeyCode.C   -- Default keybind (C)

-------------------------------
-- Helper function: Get character/wait
-------------------------------
local function getCharacter()
    while not Player.Character or not Player.Character.Parent do
        Player.CharacterAdded:Wait()
    end
    return Player.Character
end

-------------------------------
-- Record character state (each frame)
-------------------------------
local function recordCurrentState(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local currentRecord = {
        timestamp = tick(),
        cf = (character.PrimaryPart or hrp).CFrame,
        velocity = hrp.Velocity,
        state = humanoid:GetState()
    }
    table.insert(flashbackRecords, currentRecord)

    -- Remove entries older than maxFlashbackTime seconds
    local currentTime = tick()
    while #flashbackRecords > 0 and (currentTime - flashbackRecords[1].timestamp) > maxFlashbackTime do
        table.remove(flashbackRecords, 1)
    end
end

-------------------------------
-- Apply a recorded frame
-------------------------------
local function applyRecord(character, record)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local primary = character.PrimaryPart or hrp
    primary.CFrame = record.cf
    hrp.Velocity = record.velocity

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and record.state then
        pcall(function()
            humanoid:ChangeState(record.state)
        end)
    end
end

-------------------------------
-- RenderStep: Each frame either record or rewind
-------------------------------
RunService:BindToRenderStep("FlashbackStep", 80, function(dt)
    local character = Player.Character or getCharacter()
    if not character then return end

    if isRewinding then
        -- Rewind: Apply the last recorded frame and remove it
        if #flashbackRecords > 0 then
            local record = table.remove(flashbackRecords)
            if record then
                applyRecord(character, record)
            end
        end
    else
        -- Normal: Record each frame
        recordCurrentState(character)
    end
end)

-------------------------------
-- Input: Toggle rewind mode when C is pressed/released
-------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == rewindKey then
            isRewinding = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == rewindKey then
            isRewinding = false
        end
    end
end)

print("Flashback Controller loaded. Hold C to rewind time.")
