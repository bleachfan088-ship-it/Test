if not (ImGui) then
    return warn("ImGui Library - your program doesn't support ImGui");
end;

local library = {
    name = "Imgui Lib",
    version = "v1.0",
    build = "Release"
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

-- Unique ID generator
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
-- VK KEY CODES & INPUT HANDLING
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
};

local function IsDown(key_identifier)
    if not key_identifier then return false end
    
    local success, result = pcall(is_key_down, key_identifier)
    if success and result then return true end
    
    local code = VK[key_identifier] or (typeof(key_identifier) == "number" and key_identifier)
    if code then
        success, result = pcall(is_key_down, code)
        if success and result then return true end
    end
    
    return false
end

local function GetPressedKey()
    for name, _ in pairs(VK) do
        if IsDown(name) then
            return name
        end
    end
    return nil
end

-- ==========================================================
-- CLASSIC GREY THEME SYSTEM
-- ==========================================================
local presets = {
    Classic = { accent = color3_new(0.48, 0.48, 0.54), hover = color3_new(0.58, 0.58, 0.65), active = color3_new(0.38, 0.38, 0.44) },
    Grey    = { accent = color3_new(0.55, 0.55, 0.60), hover = color3_new(0.65, 0.65, 0.70), active = color3_new(0.45, 0.45, 0.50) },
    Blue    = { accent = color3_new(0.20, 0.60, 1.00), hover = color3_new(0.30, 0.70, 1.00), active = color3_new(0.15, 0.50, 0.90) },
    Purple  = { accent = color3_new(0.70, 0.35, 1.00), hover = color3_new(0.78, 0.46, 1.00), active = color3_new(0.60, 0.28, 0.92) },
    Green   = { accent = color3_new(0.20, 0.85, 0.45), hover = color3_new(0.30, 0.92, 0.55), active = color3_new(0.15, 0.72, 0.36) },
    Red     = { accent = color3_new(1.00, 0.25, 0.25), hover = color3_new(1.00, 0.35, 0.35), active = color3_new(0.90, 0.15, 0.15) },
};

local current_theme = "Classic";

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

function library.get_ui_keybind()
    return internal.ui_keybind;
end;

-- Classic Dark Grey Palette
local bg = color3_new(0.12, 0.12, 0.14);
local bg_secondary = color3_new(0.18, 0.18, 0.22);
local bg_child = color3_new(0.15, 0.15, 0.18);
local border_color = color3_new(0.26, 0.26, 0.30);
local text_color = color3_new(0.90, 0.90, 0.92);
local text_muted = color3_new(0.55, 0.55, 0.60);

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

local function get_ref_val(ref)
    if typeof(ref) == "table" then
        return ref.Value ~= nil and ref.Value or ref[1]
    end
    return ref
end

local function set_ref_val(ref, new_val)
    if typeof(ref) == "table" then
        if ref.Value ~= nil then
            ref.Value = new_val
        else
            ref[1] = new_val
        end
    end
    return new_val
end

local CHILD_BORDER = ImGuiChildFlags_Border or 1
local CHILD_NO_BORDER = 0

-- ==========================================================
-- UI RENDER ENGINE
-- ==========================================================
do
    function library.on_render()
        if isoverlayactive and not isoverlayactive() then return end;
        
        -- Default F1 Toggle Key Handler
        if IsDown(internal.ui_keybind.Key) then
            if not internal.ui_keybind._pressed then
                internal.ui_keybind._pressed = true;
                internal.visible = not internal.visible;
            end
        else
            internal.ui_keybind._pressed = false;
        end
        
        if not internal.visible then return end;
        
        push_theme();
        
        if not internal.sized then
            ImGui.SetNextWindowSize(vector2_new(740, 480));
            internal.sized = true;
        end;
        
        local flags = ImGuiWindowFlags_NoTitleBar or 1;
        if internal.always_on_top then
            flags = flags + (ImGuiWindowFlags_NoMove or 4);
        end;
        
        ImGui.Begin(library.name .. "###" .. noise, nil, flags);
        
        local window_size = ImGui.GetWindowSize();
        local sidebar_width = 140;
        local header_height = 28;
        local footer_height = 24;
        local content_height = window_size.Y - header_height - footer_height - 20;
        
        -- ------------------------------------------------------
        -- 1. TOP HEADER BAR
        -- ------------------------------------------------------
        push_accent_text();
        ImGui.Text(library.name);
        pop_accent_text();
        
        ImGui.SameLine();
        ImGui.TextColored(ImGui.GetColorU32(0.55, 0.55, 0.60, 1), library.version or "v1.0");
        
        local close_btn_size = 26;
        ImGui.SetCursorPos(vector2_new(window_size.X - close_btn_size - 10, 4));
        if ImGui.Button("[X]##close" .. noise) then
            internal.visible = false;
        end;
        
        ImGui.SetCursorPos(vector2_new(0, header_height));
        ImGui.Separator();
        
        -- ------------------------------------------------------
        -- 2. LEFT SIDEBAR
        -- ------------------------------------------------------
        ImGui.BeginChild("Sidebar##" .. noise, vector2_new(sidebar_width, content_height), CHILD_BORDER);
        
        ImGui.Indent(5);
        ImGui.TextDisabled("NAVIGATION");
        ImGui.Unindent(5);
        ImGui.Separator();
        
        for i, tab in ipairs(internal.tab_list) do
            local is_active = internal.tab == i;
            local tab_label = (is_active and "> " or "  ") .. tab.name;
            
            if is_active then
                ImGui.PushStyleColor(ImGuiCol_Button, bg_secondary);
                ImGui.PushStyleColor(ImGuiCol_Text, presets[current_theme].accent);
            end;
            
            if ImGui.Button(tab_label .. "##sidebar_" .. noise .. i, vector2_new(sidebar_width - 16, 26)) then
                internal.tab = i;
            end;
            
            if is_active then
                ImGui.PopStyleColor(2);
            end;
        end;
        
        ImGui.EndChild();
        ImGui.SameLine();
        
        -- ------------------------------------------------------
        -- 3. MAIN CONTENT AREA
        -- ------------------------------------------------------
        local main_width = window_size.X - sidebar_width - 25;
        ImGui.BeginChild("MainArea##" .. noise, vector2_new(main_width, content_height), CHILD_NO_BORDER);
        
        local current_tab = internal.tab_list[internal.tab];
        if current_tab then
            push_accent_text();
            ImGui.Text(current_tab.name);
            pop_accent_text();
            ImGui.Separator();
            
            local groups = current_tab.data;
            for i, group in ipairs(groups) do
                ImGui.BeginChild("GroupCard_" .. i .. "##" .. noise, vector2_new(main_width - 5, 0), CHILD_BORDER);
                
                push_accent_text();
                ImGui.Text(group.name);
                pop_accent_text();
                ImGui.Separator();
                
                group.callback();
                
                ImGui.EndChild();
                ImGui.Separator();
            end;
        end;
        
        ImGui.EndChild();
        
        -- ------------------------------------------------------
        -- 4. BOTTOM FOOTER / STATUS BAR
        -- ------------------------------------------------------
        ImGui.SetCursorPos(vector2_new(0, window_size.Y - footer_height));
        ImGui.Separator();
        
        ImGui.Indent(10);
        ImGui.TextDisabled("Theme: " .. current_theme);
        ImGui.SameLine();
        ImGui.TextDisabled("|  Toggle Key: [" .. internal.ui_keybind.Key .. "]");
        ImGui.Unindent(10);
        
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
    
    -- ------------------------------------------------------
    -- CONTROLS IMPLEMENTATION (FIXED RETURN SIGNATURES)
    -- ------------------------------------------------------
    function library.toggle(name, ref)
        local current_state = get_ref_val(ref)
        if typeof(current_state) ~= "boolean" then current_state = false end
        local new_val, changed = ImGui.Checkbox(library.format_name(name), current_state)
        set_ref_val(ref, new_val)
        return new_val
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
        local current_val = get_ref_val(ref)
        if typeof(current_val) ~= "number" then current_val = min end
        local new_val, changed = ImGui.SliderInt("##" .. library.format_name(name), current_val, min, max, format or "%i");
        set_ref_val(ref, new_val)
        return new_val
    end;
    
    function library.slider_float(name, min, max, ref, format)
        local label = library.split_name(name);
        if #label > 0 then
            ImGui.Text(label);
        end;
        local current_val = get_ref_val(ref)
        if typeof(current_val) ~= "number" then current_val = min end
        local new_val, changed = ImGui.SliderFloat("##" .. library.format_name(name), current_val, min, max, format or "%.2f");
        set_ref_val(ref, new_val)
        return new_val
    end;
    
    function library.slider_angle(name, min, max, ref, format)
        local label = library.split_name(name);
        if #label > 0 then
            ImGui.Text(label);
        end;
        local current_val = get_ref_val(ref)
        if typeof(current_val) ~= "number" then current_val = min end
        local new_val, changed = ImGui.SliderAngle("##" .. library.format_name(name), current_val, min, max, format or "%.1f°");
        set_ref_val(ref, new_val)
        return new_val
    end;
    
    function library.keybind(name, ref)
        local label = library.split_name(name);
        if #label > 0 then
            ImGui.Text(label);
            ImGui.SameLine();
        end;
        
        ref.Down = IsDown(ref.Key);
        
        if ref.Listening then
            if ImGui.Button("[ Press Key... ]##" .. library.format_name(name)) then
                ref.Listening = false;
                ref._skip = nil
            end
            
            if ref._skip then
                ref._skip = ref._skip - 1
                if ref._skip <= 0 then ref._skip = nil end
            else
                local key_pressed = GetPressedKey();
                if key_pressed then
                    ref.Key = key_pressed;
                    ref.Listening = false;
                end;
            end
        else
            if ImGui.Button("[" .. (ref.Key or "None") .. "]##" .. library.format_name(name)) then
                ref.Listening = true;
                ref._skip = 5;
            end;
        end;
        
        return ref.Key, ref.Down;
    end;
    
    function library.ui_keybind_picker(label_name)
        return library.keybind(label_name or "Menu Toggle Key", internal.ui_keybind);
    end;
    
    function library.dropdown(name, options)
        local label = library.split_name(name);
        if #label > 0 then ImGui.Text(label); end
        
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
        if #label > 0 then ImGui.Text(label); end
        
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
                        -- Keep min selection
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
        if #label > 0 then
            ImGui.Text(label);
            ImGui.SameLine();
        end;
        
        ref.color = ref.color or color3_new(1, 1, 1);
        
        if ImGui.ColorButton("##btn_" .. library.format_name(name), ref.color, ImGuiColorEditFlags_NoTooltip, vector2_new(30, 20)) then
            ref.visible = not ref.visible;
        end;
        
        if ref.visible then
            ImGui.SetNextWindowPos(ImGui.GetWindowPos() + ImGui.GetCursorPos(), ImGuiCond_Appearing);
            local open = ImGui.Begin(label .. "###win_" .. library.format_name(name), nil, 
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
