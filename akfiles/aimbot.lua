PLAYER  = game.Players.LocalPlayer
MOUSE   = PLAYER:GetMouse()
CC      = game.Workspace.CurrentCamera

ENABLED      = false       -- PC right-click aimbot activation
ESP_ENABLED  = false

_G.FREE_FOR_ALL = true

_G.ESP_BIND    = 52        -- Key code for ESP toggle (PC)
_G.CHANGE_AIM  = 'q'       -- Key for aim target toggle (PC)

_G.AIM_AT = 'Head'

-- Enhanced targeting system variables
local DAMAGE_DEALERS = {}           -- Track players who are damaging us
local LAST_HEALTH = 100            -- Track our health changes
local PRIORITY_TARGET = nil        -- Current priority target
local TARGET_LOCK_TIME = {}        -- Track how long we've been targeting someone
local BLACKLISTED_TARGETS = {}     -- Temporarily blacklist unresponsive targets

-- Camera movement detection for target switching
local LAST_CAMERA_CF = nil         -- Last camera position/rotation
local CAMERA_MOVE_THRESHOLD = 0.1  -- Sensitivity for camera movement detection
local LOCKED_TARGET = nil          -- Currently locked target
local ALLOW_TARGET_SWITCH = true   -- Flag to control target switching

wait(1)

-- Initialize health tracking
if PLAYER.Character and PLAYER.Character:FindFirstChild("Humanoid") then
    LAST_HEALTH = PLAYER.Character.Humanoid.Health
end

-- Function to check if a player is alive and valid
function IsPlayerAlive(player)
    if not player or not player.Character then
        return false
    end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then
        return false
    end
    
    -- Check if player is dead or dying
    if humanoid.Health <= 0 then
        return false
    end
    
    -- Check if player is in a "dead" state
    if humanoid:GetState() == Enum.HumanoidStateType.Dead then
        return false
    end
    
    -- Check if the character model is properly loaded
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return false
    end
    
    return true
end

-- Function to check if a player can be seen (not behind walls)
function CanSeePlayer(player)
    if not IsPlayerAlive(player) then
        return false
    end
    
    local targetPart = player.Character:FindFirstChild(_G.AIM_AT)
    if not targetPart then
        return false
    end
    
    local ray = Ray.new(CC.CoordinateFrame.Position, (targetPart.Position - CC.CoordinateFrame.Position).Unit * 1000)
    local hit, pos = game.Workspace:FindPartOnRayWithIgnoreList(ray, {PLAYER.Character})
    
    -- If we hit the target part or nothing, we can see them
    if hit and hit.Parent == player.Character then
        return true
    end
    
    return false
end

-- Function to track damage dealers
function TrackDamage()
    if PLAYER.Character and PLAYER.Character:FindFirstChild("Humanoid") then
        local currentHealth = PLAYER.Character.Humanoid.Health
        
        if currentHealth < LAST_HEALTH and LAST_HEALTH > 0 then
            -- We took damage, find who might have caused it
            local damageAmount = LAST_HEALTH - currentHealth
            local currentTime = tick()
            
            -- Look for nearby players who might be attacking us
            for _, player in pairs(game.Players:GetPlayers()) do
                if player ~= PLAYER and IsPlayerAlive(player) then
                    local distance = (player.Character.HumanoidRootPart.Position - PLAYER.Character.HumanoidRootPart.Position).Magnitude
                    
                    -- If player is close enough to have damaged us
                    if distance <= 100 then
                        if not DAMAGE_DEALERS[player.Name] then
                            DAMAGE_DEALERS[player.Name] = {
                                player = player,
                                lastDamageTime = currentTime,
                                damageCount = 1,
                                totalDamage = damageAmount
                            }
                        else
                            DAMAGE_DEALERS[player.Name].lastDamageTime = currentTime
                            DAMAGE_DEALERS[player.Name].damageCount = DAMAGE_DEALERS[player.Name].damageCount + 1
                            DAMAGE_DEALERS[player.Name].totalDamage = DAMAGE_DEALERS[player.Name].totalDamage + damageAmount
                        end
                    end
                end
            end
        end
        
        LAST_HEALTH = currentHealth
    end
end

-- Clean up old damage dealer records
function CleanupDamageDealers()
    local currentTime = tick()
    for name, data in pairs(DAMAGE_DEALERS) do
        -- Remove records older than 10 seconds
        if currentTime - data.lastDamageTime > 10 then
            DAMAGE_DEALERS[name] = nil
        end
    end
end

-- Function to detect camera movement
function HasCameraMoved()
    if not LAST_CAMERA_CF then
        LAST_CAMERA_CF = CC.CoordinateFrame
        return false
    end
    
    local currentCF = CC.CoordinateFrame
    local positionDiff = (currentCF.Position - LAST_CAMERA_CF.Position).Magnitude
    local rotationDiff = math.abs(currentCF.LookVector:Dot(LAST_CAMERA_CF.LookVector) - 1)
    
    -- Check if camera moved significantly
    if positionDiff > CAMERA_MOVE_THRESHOLD or rotationDiff > 0.01 then
        LAST_CAMERA_CF = currentCF
        return true
    end
    
    return false
end

-- Function to check if current locked target is still valid
function IsLockedTargetValid()
    if not LOCKED_TARGET then
        return false
    end
    
    -- Check if target is still alive and valid
    if not IsPlayerAlive(LOCKED_TARGET) then
        return false
    end
    
    -- Check if we can still see the target
    if not CanSeePlayer(LOCKED_TARGET) then
        return false
    end
    
    -- Check if target is within reasonable range
    local targetPart = LOCKED_TARGET.Character:FindFirstChild(_G.AIM_AT)
    if targetPart then
        local distance = (targetPart.Position - CC.CoordinateFrame.Position).Magnitude
        if distance > 600 then -- Increased range tolerance for locked targets
            return false
        end
    end
    
    return true
end
function GetSmartestTarget()
    local PLAYERS = {}
    local CANDIDATES = {}
    
    -- Get all valid players
    for i, v in pairs(game.Players:GetPlayers()) do
        if v ~= PLAYER and IsPlayerAlive(v) then
            -- Check team conditions
            if _G.FREE_FOR_ALL == false then
                if v.TeamColor ~= PLAYER.TeamColor then
                    table.insert(PLAYERS, v)
                end
            else
                table.insert(PLAYERS, v)
            end
        end
    end
    
    -- Score each player based on multiple factors
    for _, player in pairs(PLAYERS) do
        if not BLACKLISTED_TARGETS[player.Name] or tick() - BLACKLISTED_TARGETS[player.Name] > 5 then
            local targetPart = player.Character:FindFirstChild(_G.AIM_AT)
            if targetPart then
                local distance = (targetPart.Position - CC.CoordinateFrame.Position).Magnitude
                local canSee = CanSeePlayer(player)
                
                if canSee and distance <= 500 then -- Reasonable range limit
                    local score = 0
                    
                    -- Distance scoring (closer = better, but not the only factor)
                    score = score + math.max(0, 100 - distance / 5)
                    
                    -- Damage dealer priority (much higher score)
                    if DAMAGE_DEALERS[player.Name] then
                        local damageData = DAMAGE_DEALERS[player.Name]
                        score = score + 200 -- High priority for damage dealers
                        score = score + damageData.damageCount * 50 -- More damage = higher priority
                        score = score + math.max(0, 50 - (tick() - damageData.lastDamageTime) * 5) -- Recent damage = higher priority
                    end
                    
                    -- Health scoring (lower health enemies are easier targets)
                    local enemyHealth = player.Character.Humanoid.Health
                    score = score + math.max(0, 50 - enemyHealth / 2)
                    
                    -- Mouse proximity scoring
                    local screenPos, onScreen = CC:WorldToScreenPoint(targetPart.Position)
                    if onScreen then
                        local mouseDistance = math.sqrt((screenPos.X - MOUSE.X)^2 + (screenPos.Y - MOUSE.Y)^2)
                        score = score + math.max(0, 100 - mouseDistance / 5)
                    end
                    
                    -- Consistency bonus (if we've been tracking this target)
                    if PRIORITY_TARGET == player then
                        score = score + 30 -- Slight bonus for target consistency
                    end
                    
                    table.insert(CANDIDATES, {
                        player = player,
                        score = score,
                        distance = distance
                    })
                end
            end
        end
    end
    
    -- Sort by score (highest first)
    table.sort(CANDIDATES, function(a, b) return a.score > b.score end)
    
    -- Return the best candidate
    if #CANDIDATES > 0 then
        local bestTarget = CANDIDATES[1].player
        
        -- Update priority target tracking
        if PRIORITY_TARGET ~= bestTarget then
            PRIORITY_TARGET = bestTarget
            TARGET_LOCK_TIME[bestTarget.Name] = tick()
        end
        
        return bestTarget
    end
    
    return false
end

-- Enhanced target validation
function ValidateTarget(target)
    if not target or not IsPlayerAlive(target) then
        return false
    end
    
    if not CanSeePlayer(target) then
        return false
    end
    
    -- Check if target has been unresponsive for too long
    if TARGET_LOCK_TIME[target.Name] and tick() - TARGET_LOCK_TIME[target.Name] > 8 then
        BLACKLISTED_TARGETS[target.Name] = tick()
        TARGET_LOCK_TIME[target.Name] = nil
        return false
    end
    
    return true
end

-- Main GUI setup (keeping original design)
GUI_MAIN                           = Instance.new('ScreenGui', game.CoreGui)
GUI_MAIN.Name                      = 'SMART_AIMBOT'

GUI_TARGET                         = Instance.new('TextLabel', GUI_MAIN)
GUI_TARGET.Size                    = UDim2.new(0,250,0,30)
GUI_TARGET.BackgroundTransparency  = 0.3
GUI_TARGET.BackgroundColor         = BrickColor.new('Really black')
GUI_TARGET.BorderSizePixel         = 0
GUI_TARGET.Position                = UDim2.new(0.5,-125,0,0)
GUI_TARGET.Text                    = 'SMART AIMBOT : OFF'
GUI_TARGET.TextColor3              = Color3.new(0,1,0)
GUI_TARGET.TextStrokeTransparency  = 0.5
GUI_TARGET.TextWrapped             = true
GUI_TARGET.FontSize                = 'Size24'
GUI_TARGET.Font                    = 'SourceSansBold'

GUI_AIM_AT                         = Instance.new('TextLabel', GUI_MAIN)
GUI_AIM_AT.Size                    = UDim2.new(0,250,0,20)
GUI_AIM_AT.BackgroundTransparency  = 0.3
GUI_AIM_AT.BackgroundColor         = BrickColor.new('Really black')
GUI_AIM_AT.BorderSizePixel         = 0
GUI_AIM_AT.Position                = UDim2.new(0.5,-125,0,30)
GUI_AIM_AT.Text                    = 'TARGETING : HEAD'
GUI_AIM_AT.TextColor3              = Color3.new(1,1,0)
GUI_AIM_AT.TextStrokeTransparency  = 0.5
GUI_AIM_AT.TextWrapped             = true
GUI_AIM_AT.FontSize                = 'Size18'
GUI_AIM_AT.Font                    = 'SourceSansBold'

-- Status display
GUI_STATUS                         = Instance.new('TextLabel', GUI_MAIN)
GUI_STATUS.Size                    = UDim2.new(0,250,0,20)
GUI_STATUS.BackgroundTransparency  = 0.3
GUI_STATUS.BackgroundColor         = BrickColor.new('Really black')
GUI_STATUS.BorderSizePixel         = 0
GUI_STATUS.Position                = UDim2.new(0.5,-125,0,50)
GUI_STATUS.Text                    = 'STATUS: READY'
GUI_STATUS.TextColor3              = Color3.new(0,0.7,1)
GUI_STATUS.TextStrokeTransparency  = 0.5
GUI_STATUS.TextWrapped             = true
GUI_STATUS.FontSize                = 'Size14'
GUI_STATUS.Font                    = 'SourceSansBold'

-- Controls GUI Panel
local guiControlsToggle = Instance.new("TextButton", GUI_MAIN)
guiControlsToggle.Name = "ControlsToggle"
guiControlsToggle.Size = UDim2.new(0, 150, 0, 30)
guiControlsToggle.Position = UDim2.new(0, 10, 0, 100)
guiControlsToggle.BackgroundTransparency = 0.3
guiControlsToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
guiControlsToggle.BorderSizePixel = 0
guiControlsToggle.Text = "Show Controls"
guiControlsToggle.TextColor3 = Color3.new(1, 1, 1)
guiControlsToggle.Font = Enum.Font.SourceSansBold
guiControlsToggle.TextSize = 16

local guiControlsDetails = Instance.new("Frame", GUI_MAIN)
guiControlsDetails.Name = "ControlsDetails"
guiControlsDetails.Size = UDim2.new(0, 250, 0, 120)
guiControlsDetails.Position = UDim2.new(0, 10, 0, 140)
guiControlsDetails.BackgroundTransparency = 0.2
guiControlsDetails.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
guiControlsDetails.Visible = false

local controlsText = Instance.new("TextLabel", guiControlsDetails)
controlsText.Size = UDim2.new(1, 0, 1, 0)
controlsText.BackgroundTransparency = 1
controlsText.TextColor3 = Color3.new(1, 1, 1)
controlsText.Font = Enum.Font.SourceSans
controlsText.TextSize = 14
controlsText.TextWrapped = true
controlsText.Text = "SMART CONTROLS:\n- PC: Right Mouse = Hold to aim\n- Q = Toggle aim target (Head/Torso)\n- 4 = Toggle ESP\n- Mobile: Use buttons below\n\nSMART FEATURES:\n- Locks onto targets until YOU move camera\n- Auto-targets damage dealers\n- Ignores dead players\n- Move your mouse/camera to switch targets"

guiControlsToggle.MouseButton1Click:Connect(function()
    guiControlsDetails.Visible = not guiControlsDetails.Visible
    guiControlsToggle.Text = guiControlsDetails.Visible and "Hide Controls" or "Show Controls"
end)

-- Mobile Controls
local MOBILE_AIMBOT = false

local aimbotToggleButton = Instance.new("TextButton", GUI_MAIN)
aimbotToggleButton.Name = "AimbotToggleButton"
aimbotToggleButton.Size = UDim2.new(0, 120, 0, 35)
aimbotToggleButton.Position = UDim2.new(0, 10, 0, 270)
aimbotToggleButton.BackgroundTransparency = 0.2
aimbotToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
aimbotToggleButton.BorderSizePixel = 0
aimbotToggleButton.Text = "AIMBOT: OFF"
aimbotToggleButton.TextColor3 = Color3.new(1,1,1)
aimbotToggleButton.Font = Enum.Font.SourceSansBold
aimbotToggleButton.TextSize = 16

aimbotToggleButton.MouseButton1Click:Connect(function()
    MOBILE_AIMBOT = not MOBILE_AIMBOT
    aimbotToggleButton.Text = MOBILE_AIMBOT and "AIMBOT: ON" or "AIMBOT: OFF"
    aimbotToggleButton.BackgroundColor3 = MOBILE_AIMBOT and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

local espToggleButton = Instance.new("TextButton", GUI_MAIN)
espToggleButton.Name = "ESPToggleButton"
espToggleButton.Size = UDim2.new(0, 120, 0, 35)
espToggleButton.Position = UDim2.new(0, 140, 0, 270)
espToggleButton.BackgroundTransparency = 0.2
espToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
espToggleButton.BorderSizePixel = 0
espToggleButton.Text = "ESP: OFF"
espToggleButton.TextColor3 = Color3.new(1,1,1)
espToggleButton.Font = Enum.Font.SourceSansBold
espToggleButton.TextSize = 16

espToggleButton.MouseButton1Click:Connect(function()
    ESP_ENABLED = not ESP_ENABLED
    if ESP_ENABLED then
        FIND()
        espToggleButton.Text = "ESP: ON"
        espToggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    else
        CLEAR()
        TRACK = false
        espToggleButton.Text = "ESP: OFF"
        espToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
    end
end)

-- ESP System (Enhanced)
local TRACK = false

function CREATE(BASE, TEAM, isDamageDealer)
    local ESP_MAIN = Instance.new('BillboardGui', PLAYER.PlayerGui)
    local ESP_DOT = Instance.new('Frame', ESP_MAIN)
    local ESP_NAME = Instance.new('TextLabel', ESP_MAIN)
    local ESP_HEALTH = Instance.new('TextLabel', ESP_MAIN)
    
    ESP_MAIN.Name = 'ESP'
    ESP_MAIN.Adornee = BASE
    ESP_MAIN.AlwaysOnTop = true
    ESP_MAIN.ExtentsOffset = Vector3.new(0, 1, 0)
    ESP_MAIN.Size = UDim2.new(0, 5, 0, 5)
    
    -- Color coding for different threat levels
    local dotColor = isDamageDealer and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 165, 0)
    
    ESP_DOT.Name = 'DOT'
    ESP_DOT.BackgroundColor3 = dotColor
    ESP_DOT.BackgroundTransparency = 0.2
    ESP_DOT.BorderSizePixel = 0
    ESP_DOT.Position = UDim2.new(-0.5, 0, -0.5, 0)
    ESP_DOT.Size = UDim2.new(2, 0, 2, 0)
    ESP_DOT.Visible = true
    ESP_DOT.ZIndex = 10
    
    ESP_NAME.Name = 'NAME'
    ESP_NAME.BackgroundTransparency = 1
    ESP_NAME.Position = UDim2.new(0, 0, 0, -50)
    ESP_NAME.Size = UDim2.new(1, 0, 10, 0)
    ESP_NAME.ZIndex = 10
    ESP_NAME.Font = 'ArialBold'
    ESP_NAME.TextSize = 14
    ESP_NAME.Text = (isDamageDealer and "[THREAT] " or "") .. BASE.Parent.Name:upper()
    ESP_NAME.TextColor3 = dotColor
    ESP_NAME.TextStrokeTransparency = 0.5
    
    -- Health display
    if BASE.Parent:FindFirstChild("Humanoid") then
        ESP_HEALTH.Name = 'HEALTH'
        ESP_HEALTH.BackgroundTransparency = 1
        ESP_HEALTH.Position = UDim2.new(0, 0, 0, -30)
        ESP_HEALTH.Size = UDim2.new(1, 0, 10, 0)
        ESP_HEALTH.ZIndex = 10
        ESP_HEALTH.Font = 'Arial'
        ESP_HEALTH.TextSize = 12
        ESP_HEALTH.Text = "HP: " .. math.floor(BASE.Parent.Humanoid.Health)
        ESP_HEALTH.TextColor3 = Color3.fromRGB(0, 255, 0)
        ESP_HEALTH.TextStrokeTransparency = 0.5
    end
end

function CLEAR()
    for _,v in pairs(PLAYER.PlayerGui:GetChildren()) do
        if v.Name == 'ESP' and v:IsA('BillboardGui') then
            v:Destroy()
        end
    end
end

function FIND()
    CLEAR()
    TRACK = true
    spawn(function()
        while TRACK do
            wait(0.5) -- Reduced update frequency for performance
            if TRACK then
                CLEAR()
                for i,v in pairs(game.Players:GetChildren()) do
                    if v ~= PLAYER and IsPlayerAlive(v) then
                        local shouldShow = false
                        
                        if _G.FREE_FOR_ALL == false then
                            shouldShow = v.TeamColor ~= PLAYER.TeamColor
                        else
                            shouldShow = true
                        end
                        
                        if shouldShow and v.Character:FindFirstChild('Head') then
                            local isDamageDealer = DAMAGE_DEALERS[v.Name] ~= nil
                            CREATE(v.Character.Head, true, isDamageDealer)
                        end
                    end
                end
            end
        end
    end)
end

-- Input handling
MOUSE.Button2Down:connect(function()
    ENABLED = true
end)

MOUSE.Button2Up:connect(function()
    ENABLED = false
end)

MOUSE.KeyDown:connect(function(KEY)
    KEY = KEY:lower():byte()
    if KEY == _G.ESP_BIND then
        ESP_ENABLED = not ESP_ENABLED
        if ESP_ENABLED then
            FIND()
        else
            CLEAR()
            TRACK = false
        end
    end
end)

MOUSE.KeyDown:connect(function(KEY)
    if KEY == _G.CHANGE_AIM then
        _G.AIM_AT = (_G.AIM_AT == 'Head') and 'Torso' or 'Head'
        GUI_AIM_AT.Text = 'TARGETING : ' .. _G.AIM_AT:upper()
    end
end)

-- Enhanced main loop with damage tracking
spawn(function()
    while wait(0.1) do
        TrackDamage()
        CleanupDamageDealers()
        
        -- Update status display
        local activeDealers = 0
        for _ in pairs(DAMAGE_DEALERS) do
            activeDealers = activeDealers + 1
        end
        
        if activeDealers > 0 then
            GUI_STATUS.Text = 'THREATS DETECTED: ' .. activeDealers
            GUI_STATUS.TextColor3 = Color3.new(1, 0, 0)
        else
            GUI_STATUS.Text = 'STATUS: SCANNING'
            GUI_STATUS.TextColor3 = Color3.new(0, 0.7, 1)
        end
    end
end)

-- Main aimbot loop with camera movement detection
game:GetService('RunService').RenderStepped:connect(function()
    if ENABLED or MOBILE_AIMBOT then
        -- Check for camera movement to allow target switching
        if HasCameraMoved() then
            ALLOW_TARGET_SWITCH = true
        end
        
        local TARGET = GetSmartestTarget()
        
        if TARGET and ValidateTarget(TARGET) then
            local AIM = TARGET.Character:FindFirstChild(_G.AIM_AT)
            if AIM then
                -- Smooth aiming with prediction
                local targetPos = AIM.Position
                
                -- Lead target if they're moving
                if TARGET.Character:FindFirstChild("HumanoidRootPart") then
                    local velocity = TARGET.Character.HumanoidRootPart.Velocity
                    local distance = (targetPos - CC.CoordinateFrame.Position).Magnitude
                    local timeToTarget = distance / 1000 -- Approximate bullet speed
                    targetPos = targetPos + (velocity * timeToTarget * 0.5) -- Lead the target
                end
                
                CC.CoordinateFrame = CFrame.new(CC.CoordinateFrame.Position, targetPos)
                
                -- Update camera reference after aiming (don't count aimbot movement as user movement)
                LAST_CAMERA_CF = CC.CoordinateFrame
                
                -- Update GUI
                local threatIndicator = DAMAGE_DEALERS[TARGET.Name] and " [THREAT]" or ""
                local lockIndicator = (LOCKED_TARGET == TARGET and not ALLOW_TARGET_SWITCH) and " 🔒" or ""
                GUI_TARGET.Text = 'LOCKED: ' .. TARGET.Name:sub(1, 8) .. threatIndicator .. lockIndicator
                GUI_TARGET.TextColor3 = DAMAGE_DEALERS[TARGET.Name] and Color3.new(1, 0.2, 0.2) or Color3.new(0.2, 1, 0.2)
            end
        else
            -- No valid target, allow switching
            LOCKED_TARGET = nil
            ALLOW_TARGET_SWITCH = true
            GUI_TARGET.Text = 'SMART AIMBOT : SCANNING'
            GUI_TARGET.TextColor3 = Color3.new(1, 1, 0)
        end
    else
        -- Aimbot is off, reset target lock
        LOCKED_TARGET = nil
        ALLOW_TARGET_SWITCH = true
        GUI_TARGET.Text = 'SMART AIMBOT : OFF'
        GUI_TARGET.TextColor3 = Color3.new(0.5, 0.5, 0.5)
    end
end)

-- ESP maintenance loop
spawn(function()
    while wait(1) do
        if ESP_ENABLED then
            FIND()
        end
    end
end)
