print("[ESP] Loading ImGui ESP with integrated controls...")

-- ============================================
-- IMGUI LIBRARY LOAD
-- ============================================

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bouibot/ImGui-Library/refs/heads/main/Library.luau"))();
local rage = library.add_tab("Rage");
local visuals = library.add_tab("Visuals");
local options = library.add_tab("Options");

-- ============================================
-- SETTINGS
-- ============================================

local CONFIG = {
    -- BOX ESP
    BOX_ESP = true,
    BOX_COLOR = Color3.fromRGB(255, 255, 255),
    BOX_OUTLINE = true,
    BOX_OUTLINE_COLOR = Color3.fromRGB(0, 0, 0),
    BOX_OUTLINE_THICKNESS = 1,
    BOX_PADDING = 0,

    -- NAME ESP
    NAME_ESP = true,
    NAME_COLOR = Color3.fromRGB(255, 255, 255),
    NAME_OUTLINE_TYPE = 1, -- 1 = dropshadow, 2 = normal outline, 3 = no outline
    NAME_OUTLINE_COLOR = Color3.fromRGB(0, 0, 0),
    NAME_OFFSET = 0,
    TEXT_SIZE = 13,

    -- DISTANCE ESP
    DISTANCE_ESP = true,
    DISTANCE_COLOR = Color3.fromRGB(255, 255, 255),
    DISTANCE_OUTLINE_TYPE = 1, -- 1 = dropshadow, 2 = normal outline, 3 = no outline
    DISTANCE_OUTLINE_COLOR = Color3.fromRGB(0, 0, 0),
    DISTANCE_OFFSET = 0,

    -- HEALTHBAR
    HEALTHBAR = true,
    HEALTH_COLOR = Color3.fromRGB(0, 255, 0),
    HEALTHBAR_OUTLINE = true,
    HEALTHBAR_OUTLINE_COLOR = Color3.fromRGB(0, 0, 0),
    HEALTHBAR_POSITION = 0,

    -- OPTIONS
    TEAM_CHECK = false,
    VISIBILITY_CHECK = false,
    MAX_DISTANCE = 1000,
    SHOW_TEAMMATES = false
}

-- UI STATE
-- ============================================

local ui_state = {
    box_color = {color = CONFIG.BOX_COLOR},
    box_outline_color = {color = CONFIG.BOX_OUTLINE_COLOR},
    name_color = {color = CONFIG.NAME_COLOR},
    name_outline_color = {color = CONFIG.NAME_OUTLINE_COLOR},
    distance_color = {color = CONFIG.DISTANCE_COLOR},
    distance_outline_color = {color = CONFIG.DISTANCE_OUTLINE_COLOR},
    health_color = {color = CONFIG.HEALTH_COLOR},
    health_outline_color = {color = CONFIG.HEALTHBAR_OUTLINE_COLOR},
}

-- Dropdown options in the correct format for this library: {{"label", boolean}, ...}
local name_outline_options = {
    {"Dropshadow", true},
    {"Normal Outline", false},
    {"No Outline", false}
}
local distance_outline_options = {
    {"Dropshadow", true},
    {"Normal Outline", false},
    {"No Outline", false}
}

-- ============================================
-- SERVICES
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera


-- ============================================
-- SCREEN GUI
-- ============================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OptimizedESP"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")


-- ============================================
-- PLAYER OBJECT CACHE
-- ============================================

local ESPCache = {}


-- ============================================
-- CREATE OBJECTS
-- ============================================

local function createFrame(parent)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Color3.new(1, 1, 1)
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ZIndex = 10
    frame.Parent = parent

    return frame
end


local function createText(parent)
    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.BorderSizePixel = 0
    text.Visible = false

    text.Font = Enum.Font.GothamBold
    text.TextSize = CONFIG.TEXT_SIZE

    text.TextColor3 = CONFIG.NAME_COLOR
    text.TextStrokeColor3 = CONFIG.NAME_OUTLINE_COLOR
    text.TextStrokeTransparency = 0

    text.Size = UDim2.new(0, 200, 0, 20)
    text.AnchorPoint = Vector2.new(0.5, 0)

    text.ZIndex = 20
    text.Parent = parent

    return text
end


-- ============================================
-- PLAYER ESP CREATION
-- ============================================

local function createESP(player)

    local folder = Instance.new("Folder")
    folder.Name = player.Name
    folder.Parent = ScreenGui


    local data = {
        Folder = folder,

        Box = {
            Top = createFrame(folder),
            Bottom = createFrame(folder),
            Left = createFrame(folder),
            Right = createFrame(folder)
        },

        Outline = {
            Top = createFrame(folder),
            Bottom = createFrame(folder),
            Left = createFrame(folder),
            Right = createFrame(folder)
        },

        HealthOutline = {
            Top = createFrame(folder),
            Bottom = createFrame(folder),
            Left = createFrame(folder),
            Right = createFrame(folder)
        },

        Health = createFrame(folder),

        Name = createText(folder),
        Distance = createText(folder)
    }


    ESPCache[player] = data

    return data
end


local function removeESP(player)

    local data = ESPCache[player]

    if not data then
        return
    end


    data.Folder:Destroy()
    ESPCache[player] = nil
end


local function getESP(player)

    return ESPCache[player] or createESP(player)

end


print("[ESP] UI cache initialized")

-- ============================================
-- ROOTPART BOUNDING BOX
-- ============================================

local function getBoundingBox(character)

    local root = character:FindFirstChild("HumanoidRootPart")

    if not root then
        return nil
    end


    local size

    -- R15
    if character:FindFirstChild("UpperTorso") then
        size = Vector3.new(4, 7, 3)

    -- R6
    elseif character:FindFirstChild("Torso") then
        size = Vector3.new(4, 6, 3)

    else
        return nil
    end


    local corners = {
        Vector3.new(-size.X / 2, size.Y / 2, -size.Z / 2),
        Vector3.new(size.X / 2, size.Y / 2, -size.Z / 2),
        Vector3.new(-size.X / 2, -size.Y / 2, -size.Z / 2),
        Vector3.new(size.X / 2, -size.Y / 2, -size.Z / 2),

        Vector3.new(-size.X / 2, size.Y / 2, size.Z / 2),
        Vector3.new(size.X / 2, size.Y / 2, size.Z / 2),
        Vector3.new(-size.X / 2, -size.Y / 2, size.Z / 2),
        Vector3.new(size.X / 2, -size.Y / 2, size.Z / 2)
    }


    local minX = math.huge
    local minY = math.huge

    local maxX = -math.huge
    local maxY = -math.huge


    local visible = false


    for i = 1, 8 do

        local world = root.CFrame:PointToWorldSpace(corners[i])

        local screen = Camera:WorldToViewportPoint(world)


        if screen.Z > 0 then

            visible = true

            minX = math.min(minX, screen.X)
            maxX = math.max(maxX, screen.X)

            minY = math.min(minY, screen.Y)
            maxY = math.max(maxY, screen.Y)

        end
    end


    if not visible then
        return nil
    end


    return {
        X = minX,
        Y = minY,
        W = maxX - minX,
        H = maxY - minY,
        Root = root
    }

end



-- ============================================
-- FRAME POSITION HELPER
-- ============================================

local function setLine(frame, x, y, width, height, color)

    frame.Position = UDim2.new(
        0,
        math.floor(x),
        0,
        math.floor(y)
    )

    frame.Size = UDim2.new(
        0,
        math.floor(width),
        0,
        math.floor(height)
    )

    frame.BackgroundColor3 = color
    frame.Visible = true

end



-- ============================================
-- DRAW BOX
-- ============================================

local function updateBox(data, b)

    local x = math.floor(b.X) + CONFIG.BOX_PADDING
    local y = math.floor(b.Y) + CONFIG.BOX_PADDING

    local w = math.floor(b.W) - (CONFIG.BOX_PADDING * 2)
    local h = math.floor(b.H) - (CONFIG.BOX_PADDING * 2)

    local box = data.Box
    local outline = data.Outline

    if not CONFIG.BOX_ESP then
        for _, obj in pairs(box) do obj.Visible = false end
        for _, obj in pairs(outline) do obj.Visible = false end
        return
    end

    local outlineThickness = CONFIG.BOX_OUTLINE_THICKNESS

    if CONFIG.BOX_OUTLINE and outlineThickness > 0 then
        -- black outline (variable thickness)
        setLine(
            outline.Top,
            x - outlineThickness,
            y - outlineThickness,
            w + (outlineThickness * 2),
            outlineThickness,
            CONFIG.BOX_OUTLINE_COLOR
        )

        setLine(
            outline.Bottom,
            x - outlineThickness,
            y + h,
            w + (outlineThickness * 2),
            outlineThickness,
            CONFIG.BOX_OUTLINE_COLOR
        )

        setLine(
            outline.Left,
            x - outlineThickness,
            y,
            outlineThickness,
            h,
            CONFIG.BOX_OUTLINE_COLOR
        )

        setLine(
            outline.Right,
            x + w,
            y,
            outlineThickness,
            h,
            CONFIG.BOX_OUTLINE_COLOR
        )
    else
        for _, obj in pairs(outline) do obj.Visible = false end
    end


    -- white box
    setLine(
        box.Top,
        x,
        y,
        w,
        1,
        CONFIG.BOX_COLOR
    )

    setLine(
        box.Bottom,
        x,
        y + h - 1,
        w,
        1,
        CONFIG.BOX_COLOR
    )

    setLine(
        box.Left,
        x,
        y,
        1,
        h,
        CONFIG.BOX_COLOR
    )

    setLine(
        box.Right,
        x + w - 1,
        y,
        1,
        h,
        CONFIG.BOX_COLOR
    )

end



-- ============================================
-- HEALTHBAR
-- ============================================

local function updateHealth(data, b, humanoid)

    if not CONFIG.HEALTHBAR then
        data.Health.Visible = false
        for _, obj in pairs(data.HealthOutline) do obj.Visible = false end
        return
    end

    local percent = math.clamp(
        humanoid.Health / humanoid.MaxHealth,
        0,
        1
    )

    -- Apply box padding to healthbar position
    local padding = CONFIG.BOX_PADDING
    
    -- Position healthbar relative to the box position (accounting for padding)
    local x = math.floor(b.X - 6 + CONFIG.HEALTHBAR_POSITION + padding)
    local y = math.floor(b.Y + padding)  -- Sync with box padding

    -- Height should account for box padding
    local height = math.floor(b.H - (padding * 2))  -- Sync with box padding

    -- Don't render if height is too small
    if height <= 0 then
        data.Health.Visible = false
        for _, obj in pairs(data.HealthOutline) do obj.Visible = false end
        return
    end

    local filled = math.floor(height * percent)


    local outline = data.HealthOutline


    if CONFIG.HEALTHBAR_OUTLINE then
        -- 1px black outline
        setLine(
            outline.Top,
            x,
            y - 1,
            3,
            1,
            CONFIG.HEALTHBAR_OUTLINE_COLOR
        )

        setLine(
            outline.Bottom,
            x,
            y + height,
            3,
            1,
            CONFIG.HEALTHBAR_OUTLINE_COLOR
        )

        setLine(
            outline.Left,
            x,
            y,
            1,
            height,
            CONFIG.HEALTHBAR_OUTLINE_COLOR
        )

        setLine(
            outline.Right,
            x + 2,
            y,
            1,
            height,
            CONFIG.HEALTHBAR_OUTLINE_COLOR
        )
    else
        for _, obj in pairs(outline) do obj.Visible = false end
    end


    -- 1px green health
    data.Health.Position = UDim2.new(
        0,
        x + 1,
        0,
        y + (height - filled)
    )

    data.Health.Size = UDim2.new(
        0,
        1,
        0,
        filled
    )

    data.Health.BackgroundColor3 = CONFIG.HEALTH_COLOR
    data.Health.Visible = true

end



-- ============================================
-- VISIBILITY CHECK
-- ============================================

local function isPlayerVisible(character)
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local localCharacter = LocalPlayer.Character
    if not localCharacter then return false end
    
    local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRoot then return false end
    
    -- Cast a ray from the local player's eyes to the target player
    local origin = localRoot.Position + Vector3.new(0, 1.5, 0)
    local target = rootPart.Position + Vector3.new(0, 1.5, 0)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {localCharacter, character}
    raycastParams.IgnoreWater = true
    
    local result = Workspace:Raycast(origin, (target - origin), raycastParams)
    
    -- If no result, the player is visible
    return result == nil
end

-- ============================================
-- TEAM CHECK
-- ============================================

local function isSameTeam(player)
    if not player then return false end
    
    -- Check if player has a TeamColor on their Humanoid
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid:FindFirstChild("TeamColor") then
            local localCharacter = LocalPlayer.Character
            if localCharacter then
                local localHumanoid = localCharacter:FindFirstChildOfClass("Humanoid")
                if localHumanoid and localHumanoid:FindFirstChild("TeamColor") then
                    return humanoid.TeamColor == localHumanoid.TeamColor
                end
            end
        end
    end
    
    -- Fallback: Check if they're on the same team using team property
    if player.Team and LocalPlayer.Team then
        return player.Team == LocalPlayer.Team
    end
    
    return false
end



-- ============================================
-- TEXT RENDERING WITH OUTLINE TYPES
-- ============================================

local function applyNameOutline(textLabel)
    local outlineType = CONFIG.NAME_OUTLINE_TYPE
    local outlineColor = CONFIG.NAME_OUTLINE_COLOR
    
    if outlineType == 1 then
        -- Dropshadow
        textLabel.TextStrokeColor3 = outlineColor
        textLabel.TextStrokeTransparency = 0.3
    elseif outlineType == 2 then
        -- Normal outline
        textLabel.TextStrokeColor3 = outlineColor
        textLabel.TextStrokeTransparency = 0
    else
        -- No outline
        textLabel.TextStrokeTransparency = 1
    end
end

local function applyDistanceOutline(textLabel)
    local outlineType = CONFIG.DISTANCE_OUTLINE_TYPE
    local outlineColor = CONFIG.DISTANCE_OUTLINE_COLOR
    
    if outlineType == 1 then
        -- Dropshadow
        textLabel.TextStrokeColor3 = outlineColor
        textLabel.TextStrokeTransparency = 0.3
    elseif outlineType == 2 then
        -- Normal outline
        textLabel.TextStrokeColor3 = outlineColor
        textLabel.TextStrokeTransparency = 0
    else
        -- No outline
        textLabel.TextStrokeTransparency = 1
    end
end



-- ============================================
-- UPDATE PLAYER
-- ============================================

local function updatePlayer(player)

    local data = getESP(player)

    local character = player.Character


    if not character then
        cleanupESP(data)
        return
    end


    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not humanoid or humanoid.Health <= 0 then
        cleanupESP(data)
        return
    end


    local bounds = getBoundingBox(character)

    if not bounds then
        cleanupESP(data)
        return
    end


    local localCharacter = LocalPlayer.Character

    local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")


    if not localRoot then
        cleanupESP(data)
        return
    end


    local distance = (bounds.Root.Position - localRoot.Position).Magnitude


    if distance > CONFIG.MAX_DISTANCE then
        cleanupESP(data)
        return
    end

    -- Team check
    if CONFIG.TEAM_CHECK then
        if isSameTeam(player) then
            if not CONFIG.SHOW_TEAMMATES then
                cleanupESP(data)
                return
            end
        end
    end

    -- Visibility check
    if CONFIG.VISIBILITY_CHECK then
        if not isPlayerVisible(character) then
            cleanupESP(data)
            return
        end
    end

    -- Get padding value for syncing positions
    local padding = CONFIG.BOX_PADDING
    
    -- Calculate padded box dimensions
    local paddedX = bounds.X + padding
    local paddedY = bounds.Y + padding
    local paddedW = bounds.W - (padding * 2)
    local paddedH = bounds.H - (padding * 2)
    
    -- Calculate center of padded box
    local centerX = paddedX + (paddedW / 2)

    if CONFIG.BOX_ESP then
        updateBox(data, bounds)
    else
        for _, obj in pairs(data.Box) do obj.Visible = false end
        for _, obj in pairs(data.Outline) do obj.Visible = false end
    end


    if CONFIG.HEALTHBAR then
        updateHealth(data, bounds, humanoid)
    else
        data.Health.Visible = false
        for _, obj in pairs(data.HealthOutline) do obj.Visible = false end
    end


    if CONFIG.NAME_ESP then
        data.Name.Text = player.Name
        -- Center name above the padded box
        data.Name.Position = UDim2.new(
            0,
            centerX,  -- Center of padded box
            0,
            paddedY - 18 + CONFIG.NAME_OFFSET  -- Above padded box
        )
        data.Name.TextColor3 = CONFIG.NAME_COLOR
        applyNameOutline(data.Name)
        data.Name.Visible = true
    else
        data.Name.Visible = false
    end

    if CONFIG.DISTANCE_ESP then
        data.Distance.Text = "[" .. math.floor(distance) .. "m]"
        -- Center distance below the padded box
        data.Distance.Position = UDim2.new(
            0,
            centerX,  -- Center of padded box
            0,
            paddedY + paddedH + 3 + CONFIG.DISTANCE_OFFSET  -- Below padded box
        )
        data.Distance.TextColor3 = CONFIG.DISTANCE_COLOR
        applyDistanceOutline(data.Distance)
        data.Distance.Visible = true
    else
        data.Distance.Visible = false
    end

end

-- ============================================
-- HIDE PLAYER ESP
-- ============================================

local function hideESP(player)

    local data = ESPCache[player]

    if not data then
        return
    end

    for _, object in pairs(data.Box) do
        object.Visible = false
    end

    for _, object in pairs(data.Outline) do
        object.Visible = false
    end

    data.Health.Visible = false
    for _, object in pairs(data.HealthOutline) do
        object.Visible = false
    end

    data.Name.Visible = false
    data.Distance.Visible = false

end

-- ============================================
-- CLEANUP ESP (When distance exceeded or settings disabled)
-- ============================================

local function cleanupESP(data)

    for _, object in pairs(data.Box) do
        object.Visible = false
    end

    for _, object in pairs(data.Outline) do
        object.Visible = false
    end

    data.Health.Visible = false
    for _, object in pairs(data.HealthOutline) do
        object.Visible = false
    end

    data.Name.Visible = false
    data.Distance.Visible = false

end



-- ============================================
-- PLAYER SETUP
-- ============================================

local function addPlayer(player)

    if player == LocalPlayer then
        return
    end


    createESP(player)


    player.CharacterAdded:Connect(function()

        task.defer(function()

            hideESP(player)

        end)

    end)

end



local function removePlayer(player)

    removeESP(player)

end



for _, player in ipairs(Players:GetPlayers()) do

    addPlayer(player)

end


Players.PlayerAdded:Connect(addPlayer)

Players.PlayerRemoving:Connect(removePlayer)



-- ============================================
-- CAMERA UPDATE
-- ============================================

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()

    Camera = workspace.CurrentCamera

end)


-- ============================================
-- IMGUI CONTROLS - VISUALS TAB
-- ============================================

library.add_group(visuals, "Box ESP", function()
    CONFIG.BOX_ESP = library.toggle("Toggle##box_esp", CONFIG.BOX_ESP)
    
    library.text("Box Color")
    library.same_line()
    library.color_picker3("Box Color##picker", ui_state.box_color)
    CONFIG.BOX_COLOR = ui_state.box_color.color

    CONFIG.BOX_OUTLINE = library.toggle("Box Outline##toggle", CONFIG.BOX_OUTLINE)
    
    library.text("Outline Color")
    library.same_line()
    library.color_picker3("Outline Color##picker", ui_state.box_outline_color)
    CONFIG.BOX_OUTLINE_COLOR = ui_state.box_outline_color.color

    CONFIG.BOX_OUTLINE_THICKNESS = library.slider_int("Outline Thickness##slider", 0, 5, CONFIG.BOX_OUTLINE_THICKNESS, "%ipx")
    CONFIG.BOX_PADDING = library.slider_int("Box Padding##slider", -10, 10, CONFIG.BOX_PADDING, "%ipx")
end)


library.add_group(visuals, "Name ESP", function()
    CONFIG.NAME_ESP = library.toggle("Toggle##name_esp", CONFIG.NAME_ESP)

    -- Use dropdown with proper format
    library.text("Outline Type")
    library.dropdown("Name Outline##dropdown", name_outline_options)
    
    -- Update CONFIG based on selected option
    for i, option in ipairs(name_outline_options) do
        if option[2] then
            CONFIG.NAME_OUTLINE_TYPE = i
            break
        end
    end

    library.text("Name Color")
    library.same_line()
    library.color_picker3("Name Color##picker", ui_state.name_color)
    CONFIG.NAME_COLOR = ui_state.name_color.color

    library.text("Outline Color")
    library.same_line()
    library.color_picker3("Name Outline##picker", ui_state.name_outline_color)
    CONFIG.NAME_OUTLINE_COLOR = ui_state.name_outline_color.color

    CONFIG.NAME_OFFSET = library.slider_int("Name Offset##slider", -50, 50, CONFIG.NAME_OFFSET, "%ipx")
end)


library.add_group(visuals, "Distance ESP", function()
    CONFIG.DISTANCE_ESP = library.toggle("Toggle##distance_esp", CONFIG.DISTANCE_ESP)

    -- Use dropdown with proper format
    library.text("Outline Type")
    library.dropdown("Distance Outline##dropdown", distance_outline_options)
    
    -- Update CONFIG based on selected option
    for i, option in ipairs(distance_outline_options) do
        if option[2] then
            CONFIG.DISTANCE_OUTLINE_TYPE = i
            break
        end
    end

    library.text("Distance Color")
    library.same_line()
    library.color_picker3("Distance Color##picker", ui_state.distance_color)
    CONFIG.DISTANCE_COLOR = ui_state.distance_color.color

    library.text("Outline Color")
    library.same_line()
    library.color_picker3("Distance Outline##picker", ui_state.distance_outline_color)
    CONFIG.DISTANCE_OUTLINE_COLOR = ui_state.distance_outline_color.color

    CONFIG.DISTANCE_OFFSET = library.slider_int("Distance Offset##slider", -50, 50, CONFIG.DISTANCE_OFFSET, "%ipx")
end)


library.add_group(visuals, "Healthbar ESP", function()
    CONFIG.HEALTHBAR = library.toggle("Toggle##health_esp", CONFIG.HEALTHBAR)
    CONFIG.HEALTHBAR_OUTLINE = library.toggle("Outlines Enabled##health_outline", CONFIG.HEALTHBAR_OUTLINE)

    library.text("Health Color")
    library.same_line()
    library.color_picker3("Health Color##picker", ui_state.health_color)
    CONFIG.HEALTH_COLOR = ui_state.health_color.color

    library.text("Outline Color")
    library.same_line()
    library.color_picker3("Health Outline##picker", ui_state.health_outline_color)
    CONFIG.HEALTHBAR_OUTLINE_COLOR = ui_state.health_outline_color.color

    CONFIG.HEALTHBAR_POSITION = library.slider_int("Bar Position##slider", -10, 10, CONFIG.HEALTHBAR_POSITION, "%ipx")
end)


-- ============================================
-- IMGUI CONTROLS - OPTIONS TAB
-- ============================================

library.add_group(options, "ESP Options", function()
    CONFIG.TEAM_CHECK = library.toggle("Team Check##team_check", CONFIG.TEAM_CHECK)
    CONFIG.SHOW_TEAMMATES = library.toggle("Show Teammates##show_teammates", CONFIG.SHOW_TEAMMATES)
    CONFIG.VISIBILITY_CHECK = library.toggle("Visibility Check##vis_check", CONFIG.VISIBILITY_CHECK)
    CONFIG.MAX_DISTANCE = library.slider_int("Max Distance##max_dist", 100, 2000, CONFIG.MAX_DISTANCE, "%im")
    library.text("Note: Visibility check may impact performance")
end)


print("[ESP] ImGui controls loaded")

-- ============================================
-- SINGLE RENDER LOOP
-- ============================================

local updateAccumulator = 0

local UPDATE_RATE = 1 / 144


RunService.RenderStepped:Connect(function(delta)

    updateAccumulator += delta


    if updateAccumulator < UPDATE_RATE then
        return
    end


    updateAccumulator = 0

    for player, data in pairs(ESPCache) do

        if player.Parent then

            local character = player.Character

            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")

                if not humanoid or humanoid.Health <= 0 then
                    cleanupESP(data)
                else
                    local bounds = getBoundingBox(character)

                    if bounds then
                        local localCharacter = LocalPlayer.Character
                        local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")

                        if localRoot then
                            local distance = (bounds.Root.Position - localRoot.Position).Magnitude

                            if distance > CONFIG.MAX_DISTANCE then
                                cleanupESP(data)
                            else
                                updatePlayer(player)
                            end
                        else
                            cleanupESP(data)
                        end
                    else
                        cleanupESP(data)
                    end
                end
            else
                cleanupESP(data)
            end

        else

            removeESP(player)

        end

    end

end)


print("[ESP] Optimized ScreenGui ESP with ImGui loaded")
