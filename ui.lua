if not (ImGui) then
    return warn("ImGui Library - your programm doesnt support imguii");
end;

local library = {
    name = "Imgui lib";
};

local internal = {
    tab_list = {};
    tab = 1;
    sized = false;
    always_on_top = false;
    visible = true;
    ui_keybind = { Key = "F1", Listening = false, Down = false };
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
-- VK KEY CODES
-- ==========================================================
local VK = {
    A = 0x41, B = 0x42, C = 0x43, D = 0x44, E = 0x45,
    F = 0x46, G = 0x47, H = 0x48, I = 0x49, J = 0x4A,
    K = 0x4B, L = 0x4C, M = 0x4D, N = 0x4E, O = 0x4F,
    P = 0x50, Q = 0x51, R = 0x52, S = 0x53, T = 0x54,
    U = 0x55, V = 0x56, W = 0x57, X = 0x58, Y = 0x59,
    Z = 0x5A,
    One = 0x31, Two = 0x32, Three = 0x33, Four = 0x34,
    Five = 0x35, Six = 0x36, Seven = 0x37, Eight = 0x38,
    Nine = 0x39, Zero = 0x30,
    Space = 0x20, LeftControl = 0xA2, LeftShift = 0xA0,
    LeftAlt = 0x12, Tab = 0x09, Enter = 0x0D,
    Escape = 0x1B, Backspace = 0x08,
    F1 = 0x70, F2 = 0x71, F3 = 0x72, F4 = 0x73,
    F5 = 0x74, F6 = 0x75, F7 = 0x76, F8 = 0x77,
    F9 = 0x78, F10 = 0x79, F11 = 0x7A, F12 = 0x7B,
    Mouse1 = 0x01, Mouse2 = 0x02, Mouse3 = 0x04,
};

local function IsDown(code)
    local success, result = pcall(function()
        return is_key_down(code)
    end)
    return success and result
end

local function GetPressedKey()
    for name, code in pairs(VK) do
        if IsDown(code) then
            return name
        end
    end
end

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

-- UI Functions
do
    function library.on_render()
        if not isoverlayactive() then return end;
        
        -- Check UI keybind
        local code = VK[internal.ui_keybind.Key];
        if code and IsDown(code) then
            internal.ui_keybind.Down = true;
            -- Toggle UI visibility when key is pressed (just once)
            if not internal.ui_keybind._pressed then
                internal.ui_keybind._pressed = true;
                internal.visible = not internal.visible;
            end
        else
            internal.ui_keybind.Down = false;
            internal.ui_keybind._pressed = false;
        end
        
        if not internal.visible then return end;
        
        push_theme();
        
        if not internal.sized then
            ImGui.SetNextWindowSize(vector2_new(720, 480));
            internal.sized = true;
        end;
        
        -- Always on top flag
        local flags = ImGuiWindowFlags_NoTitleBar;
        if internal.always_on_top then
            flags = flags + ImGuiWindowFlags_NoMove;
        end;
        
        ImGui.Begin(library.name .. "###" .. noise, nil, flags);
        
        local window_size = ImGui.GetWindowSize();
        
        -- Top Bar
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
        
        -- Close button
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
            ImGui.BeginChild("Left##" .. noise, vector2_new(col_width, y_size), ImGuiChildFlags_Border);
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
            ImGui.EndChild();
            ImGui.SameLine();
            
            -- Right Column
            ImGui.BeginChild("Right##" .. noise, vector2_new(col_width, y_size), ImGuiChildFlags_Border);
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
        return ImGui.SliderAngle("##" .. library.format_name(name), ref, min, max, format or "%.1f°");
    end;
    
    function library.keybind(name, ref)
        local label = library.split_name(name);
        if #label > 0 then
            ImGui.Text(label);
            ImGui.SameLine();
        end;
        
        -- Check if key is held down
        local code = VK[ref.Key];
        if code and IsDown(code) then
            ref.Down = true;
        else
            ref.Down = false;
        end;
        
        -- Display current key or listening state
        if ref.Listening then
            ImGui.TextColored(ImGui.GetColorU32(1, 1, 0, 1), "...");
            ImGui.SameLine();
            
            -- Check for key press
            local pressed = GetPressedKey();
            if pressed then
                ref.Key = pressed;
                ref.Listening = false;
            end;
        else
            if ImGui.Button(ref.Key .. "##" .. library.format_name(name)) then
                ref.Listening = true;
            end;
        end;
        
        return ref.Key, ref.Down;
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
