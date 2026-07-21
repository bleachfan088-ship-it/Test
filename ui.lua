if not (ImGui) then
    return warn("ImGui Library - your executor doesn't support ImGui");
end;

local library = {
    name = "AIMBOT";
};

local internal = {
    tab_list = {};
    tab = 1;
    sized = false;
    keybind_listening = nil;
    always_on_top = false;
    visible = true;
};

local vector2_new = Vector2.new;
local color3_new = Color3.new;
local insert, concat, clear = table.insert, table.concat, table.clear;
local random, floor = math.random, math.floor;
local char, find, split = string.char, string.find, string.split;

local noise;
do
    local noise_data = {};
    for i = 1, 32 do
        insert(noise_data, char(random(32, 126)));
    end;
    noise = "ImGuiLibrary" .. concat(noise_data);
    clear(noise_data);
end;

-- ==========================================================
-- THEME
-- ==========================================================
local presets = {
    Blue   = { accent = color3_new(0.20, 0.60, 1.00), hover = color3_new(0.30, 0.70, 1.00), active = color3_new(0.15, 0.50, 0.90) };
    Purple = { accent = color3_new(0.70, 0.35, 1.00), hover = color3_new(0.78, 0.46, 1.00), active = color3_new(0.60, 0.28, 0.92) };
    Green  = { accent = color3_new(0.20, 0.85, 0.45), hover = color3_new(0.30, 0.92, 0.55), active = color3_new(0.15, 0.72, 0.36) };
    Red    = { accent = color3_new(1.00, 0.25, 0.25), hover = color3_new(1.00, 0.35, 0.35), active = color3_new(0.90, 0.15, 0.15) };
    Orange = { accent = color3_new(1.00, 0.60, 0.15), hover = color3_new(1.00, 0.70, 0.25), active = color3_new(0.90, 0.50, 0.10) };
};

local current_theme = "Blue";

function library.set_theme(name)
    if presets[name] then
        current_theme = name;
    end;
end;

function library.toggle_visibility()
    internal.visible = not internal.visible;
end;

function library.set_always_on_top(state)
    internal.always_on_top = state;
end;

function library.toggle_always_on_top()
    internal.always_on_top = not internal.always_on_top;
end;

-- Colors
local bg = color3_new(0.06, 0.06, 0.08);
local bg_secondary = color3_new(0.10, 0.10, 0.13);
local bg_child = color3_new(0.08, 0.08, 0.10);
local border_color = color3_new(0.15, 0.15, 0.20);
local text_color = color3_new(0.92, 0.92, 0.95);
local text_muted = color3_new(0.60, 0.60, 0.65);

local function push_theme()
    local t = presets[current_theme];
    
    ImGui.PushStyleColor(ImGuiCol_WindowBg, bg);
    ImGui.PushStyleColor(ImGuiCol_ChildBg, bg_child);
    ImGui.PushStyleColor(ImGuiCol_Border, border_color);
    ImGui.PushStyleColor(ImGuiCol_Text, text_color);
    ImGui.PushStyleColor(ImGuiCol_TextDisabled, text_muted);
    ImGui.PushStyleColor(ImGuiCol_Button, bg_secondary);
    ImGui.PushStyleColor(ImGuiCol_ButtonHovered, t.hover);
    ImGui.PushStyleColor(ImGuiCol_ButtonActive, t.active);
    ImGui.PushStyleColor(ImGuiCol_FrameBg, bg_secondary);
    ImGui.PushStyleColor(ImGuiCol_FrameBgHovered, bg_secondary);
    ImGui.PushStyleColor(ImGuiCol_FrameBgActive, bg_secondary);
    ImGui.PushStyleColor(ImGuiCol_Header, t.active);
    ImGui.PushStyleColor(ImGuiCol_HeaderHovered, t.hover);
    ImGui.PushStyleColor(ImGuiCol_HeaderActive, t.accent);
    ImGui.PushStyleColor(ImGuiCol_SliderGrab, t.accent);
    ImGui.PushStyleColor(ImGuiCol_SliderGrabActive, t.hover);
    ImGui.PushStyleColor(ImGuiCol_CheckMark, t.accent);
    ImGui.PushStyleColor(ImGuiCol_Separator, border_color);
end;

local function pop_theme()
    ImGui.PopStyleColor(18);
end;

local function push_accent_text()
    ImGui.PushStyleColor(ImGuiCol_Text, presets[current_theme].accent);
end;

local function pop_accent_text()
    ImGui.PopStyleColor(1);
end;

-- Keybind System
local UserInputService = game:GetService("UserInputService");
local VirtualInputManager = game:GetService("VirtualInputManager");

local function keypress(key)
    VirtualInputManager:SendKeyEvent(true, key, false, game);
end;

local function keyrelease(key)
    VirtualInputManager:SendKeyEvent(false, key, false, game);
end;

-- F1 Toggle
UserInputService.InputBegan:Connect(function(input, game_processed)
    if game_processed then return end;
    
    -- F1 key to toggle UI visibility
    if input.KeyCode == Enum.KeyCode.F1 then
        internal.visible = not internal.visible;
        return;
    end;
    
    -- Keybind listening
    local target = internal.keybind_listening;
    if not target then return end;
    
    if input.UserInputType == Enum.UserInputType.Keyboard then
        target.key = input.KeyCode;
        target.listening = false;
        internal.keybind_listening = nil;
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.MouseButton2 or
           input.UserInputType == Enum.UserInputType.MouseButton3 then
        target.key = input.UserInputType;
        target.listening = false;
        internal.keybind_listening = nil;
    end;
end);

-- UI Functions
do
    function library.on_render()
        if not isoverlayactive() then return end;
        if not internal.visible then return end;
        
        push_theme();
        
        if not internal.sized then
            ImGui.SetNextWindowSize(vector2_new(720, 480));
            internal.sized = true;
        end;
        
        -- Set always on top flag
        local flags = ImGuiWindowFlags_NoTitleBar;
        if internal.always_on_top then
            flags = flags + 0x00000020; -- ImGuiWindowFlags_NoMove
        end;
        
        ImGui.Begin(library.name .. "###" .. noise, nil, flags);
        
        local window_size = ImGui.GetWindowSize();
        
        -- Top Bar with Always On Top toggle
        push_accent_text();
        ImGui.Text(library.name);
        pop_accent_text();
        ImGui.SameLine();
        ImGui.Text("|");
        ImGui.SameLine();
        
        -- Always On Top toggle button
        if internal.always_on_top then
            ImGui.PushStyleColor(ImGuiCol_Button, presets[current_theme].accent);
            ImGui.PushStyleColor(ImGuiCol_ButtonHovered, presets[current_theme].hover);
            ImGui.PushStyleColor(ImGuiCol_ButtonActive, presets[current_theme].active);
            ImGui.PushStyleColor(ImGuiCol_Text, color3_new(1, 1, 1));
        end;
        
        if ImGui.Button("📌##pin" .. noise) then
            internal.always_on_top = not internal.always_on_top;
        end;
        
        if internal.always_on_top then
            ImGui.PopStyleColor(4);
        end;
        
        ImGui.SameLine();
        
        -- Close button (F1)
        if ImGui.Button("✕##close" .. noise) then
            internal.visible = false;
        end;
        
        ImGui.SameLine();
        
        -- Tabs
        for i, tab in ipairs(internal.tab_list) do
            local is_active = internal.tab == i;
            
            if is_active then
                push_accent_text();
            end;
            
            if ImGui.Button(tab.name .. "##" .. noise .. i) then
                internal.tab = i;
            end;
            
            if is_active then
                pop_accent_text();
            end;
            
            if i ~= #internal.tab_list then
                ImGui.SameLine();
            end;
        end;
        
        ImGui.Separator();
        
        -- Content
        local current_tab = internal.tab_list[internal.tab];
        if current_tab then
            local groups = current_tab.data;
            local y_size = window_size.Y - 70;
            local col_width = (window_size.X - 30) / 2;
            
            -- Left Column
            if ImGui.BeginChild("Left##" .. noise, vector2_new(col_width, y_size), ImGuiChildFlags_Border) then
                for i = 1, #groups, 2 do
                    local group = groups[i];
                    if group then
                        push_accent_text();
                        ImGui.Text(group.name);
                        pop_accent_text();
                        ImGui.Separator();
                        group.callback();
                        if groups[i + 2] then
                            ImGui.Separator();
                        end;
                    end;
                end;
            end;
            ImGui.EndChild();
            ImGui.SameLine();
            
            -- Right Column
            if ImGui.BeginChild("Right##" .. noise, vector2_new(col_width, y_size), ImGuiChildFlags_Border) then
                for i = 2, #groups, 2 do
                    local group = groups[i];
                    if group then
                        push_accent_text();
                        ImGui.Text(group.name);
                        pop_accent_text();
                        ImGui.Separator();
                        group.callback();
                        if groups[i + 2] then
                            ImGui.Separator();
                        end;
                    end;
                end;
            end;
            ImGui.EndChild();
        end;
        
        ImGui.End();
        pop_theme();
    end;
    
    function library.add_tab(name)
        local tab = { name = name, data = {} };
        insert(internal.tab_list, tab);
        return tab;
    end;
    
    function library.add_group(tab, name, callback)
        local group = { name = name, callback = callback };
        if typeof(tab) == "table" then
            insert(tab.data, group);
        elseif typeof(tab) == "string" then
            for _, data in ipairs(internal.tab_list) do
                if data.name == tab then
                    insert(data.data, group);
                    break;
                end;
            end;
        end;
        return group;
    end;
    
    function library.format_name(name)
        if find(name, "##") then
            return name .. noise;
        end;
        return name .. "##" .. noise;
    end;
    
    function library.split_name(name)
        return split(name, "##")[1];
    end;
    
    -- Controls
    function library.toggle(name, ref)
        return ImGui.Checkbox(library.format_name(name), ref);
    end;
    
    function library.separator()
        ImGui.Separator();
    end;
    
    function library.same_line()
        ImGui.SameLine();
    end;
    
    function library.text(text)
        ImGui.Text(text);
    end;
    
    function library.slider_int(name, min, max, ref, format)
        local label = library.split_name(name);
        if #label > 0 then
            ImGui.Text(label);
        end;
        return ImGui.SliderInt("##" .. library.format_name(name), ref, min, max, format or "%i");
    end;
    
    function library.slider_float(name, min, max, ref, format)
        local label = library.split_name(name);
        if #label > 0 then
            ImGui.Text(label);
        end;
        return ImGui.SliderFloat("##" .. library.format_name(name), ref, min, max, format or "%.2f");
    end;
    
    function library.slider_angle(name, min, max, ref, format)
        local label = library.split_name(name);
        if #label > 0 then
            ImGui.Text(label);
        end;
        return ImGui.SliderFloat("##" .. library.format_name(name), ref, min, max, format or "%.1f°");
    end;
    
    function library.keybind(name, ref)
        local label = library.split_name(name);
        if #label > 0 then
            ImGui.Text(label);
            ImGui.SameLine();
        end;
        
        local display = "None";
        if ref.listening then
            display = "...";
        elseif ref.key then
            display = ref.key.Name;
        end;
        
        if ImGui.Button(display .. "##" .. library.format_name(name)) then
            ref.listening = not ref.listening;
            if ref.listening then
                internal.keybind_listening = ref;
            else
                internal.keybind_listening = nil;
            end;
        end;
        
        return ref.key;
    end;
    
    function library.dropdown(name, options)
        local label = library.split_name(name);
        ImGui.Text(label);
        
        local selected = {};
        for i, opt in ipairs(options) do
            if opt[2] then
                insert(selected, opt[1]);
            end;
        end;
        
        if ImGui.BeginCombo("##" .. library.format_name(name), concat(selected, ", ")) then
            for i, opt in ipairs(options) do
                local clicked = ImGui.Selectable(opt[1], opt[2]);
                if clicked then
                    for j, o in ipairs(options) do
                        o[2] = (j == i);
                    end;
                end;
            end;
            ImGui.EndCombo();
        end;
        clear(selected);
    end;
    
    function library.multi_dropdown(name, options, min)
        min = min or 0;
        local label = library.split_name(name);
        ImGui.Text(label);
        
        local selected = {};
        for i, opt in ipairs(options) do
            if opt[2] then
                insert(selected, opt[1]);
            end;
        end;
        
        if ImGui.BeginCombo("##" .. library.format_name(name), concat(selected, ", ")) then
            for i, opt in ipairs(options) do
                local clicked = ImGui.Selectable(opt[1], opt[2]);
                if clicked then
                    if opt[2] and #selected <= min then
                        -- Keep at least min selected
                    else
                        opt[2] = not opt[2];
                    end;
                end;
            end;
            ImGui.EndCombo();
        end;
        clear(selected);
    end;
    
    function library.color_picker3(name, ref)
        local label = library.split_name(name);
        ImGui.Text(label);
        ImGui.SameLine();
        
        if ImGui.ColorButton("##" .. library.format_name(name), ref.color, ImGuiColorEditFlags_NoTooltip, vector2_new(30, 20)) then
            ref.visible = not ref.visible;
        end;
        
        if ref.visible then
            ImGui.SetNextWindowPos(ImGui.GetWindowPos() + ImGui.GetCursorPos(), ImGuiCond_Appearing);
            local open = ImGui.Begin(label .. "###" .. library.format_name(name), nil, 
                ImGuiWindowFlags_NoResize + ImGuiWindowFlags_AlwaysAutoResize + ImGuiWindowFlags_NoCollapse);
            if open then
                ref.color = ImGui.ColorPicker3("##picker" .. noise, ref.color, ImGuiColorEditFlags_NoLabel);
                ImGui.End();
            else
                ref.visible = false;
            end;
        end;
    end;
end;

ImGui.OnRender(library.on_render);
return library;
