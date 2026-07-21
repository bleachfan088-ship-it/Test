if not (ImGui) then
    return warn("ImGui Library - your executor doesn't support ImGui");
end;

local library = {
    name = "AIMBOT";
};
local internal = {
    section = "";
    tab_list = {};
    tab = 1;
    sized = false;
    keybind_listening = nil;
};

local vector2_new, vector2_zero = Vector2.new, Vector2.zero;
local color3_new = Color3.new;
local insert, concat, clear, clone = table.insert, table.concat, table.clear, table.clone;
local random, floor = math.random, math.floor;
local char, find, split, format = string.char, string.find, string.split, string.format;

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
-- THEME - Dark Modern UI
-- ==========================================================
local presets = {
    Blue   = { 
        accent = color3_new(0.20, 0.60, 1.00), 
        hover = color3_new(0.30, 0.70, 1.00), 
        active = color3_new(0.15, 0.50, 0.90),
    };
    Purple = { 
        accent = color3_new(0.70, 0.35, 1.00), 
        hover = color3_new(0.78, 0.46, 1.00), 
        active = color3_new(0.60, 0.28, 0.92),
    };
    Green  = { 
        accent = color3_new(0.20, 0.85, 0.45), 
        hover = color3_new(0.30, 0.92, 0.55), 
        active = color3_new(0.15, 0.72, 0.36),
    };
    Red    = { 
        accent = color3_new(1.00, 0.25, 0.25), 
        hover = color3_new(1.00, 0.35, 0.35), 
        active = color3_new(0.90, 0.15, 0.15),
    };
    Orange = { 
        accent = color3_new(1.00, 0.60, 0.15), 
        hover = color3_new(1.00, 0.70, 0.25), 
        active = color3_new(0.90, 0.50, 0.10),
    };
};

local current_theme = "Blue";

function library.set_theme(name)
    if presets[name] then
        current_theme = name;
    end;
end;

-- Dark modern theme colors
local bg            = color3_new(0.06, 0.06, 0.08);
local bg_secondary  = color3_new(0.10, 0.10, 0.13);
local bg_child      = color3_new(0.08, 0.08, 0.10);
local border_color  = color3_new(0.15, 0.15, 0.20);
local text_color    = color3_new(0.92, 0.92, 0.95);
local text_muted    = color3_new(0.60, 0.60, 0.65);

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

local function push_muted_text()
    ImGui.PushStyleColor(ImGuiCol_Text, text_muted);
end;

local function pop_muted_text()
    ImGui.PopStyleColor(1);
end

-- Keybind system
local UserInputService = game:GetService("UserInputService");

UserInputService.InputBegan:Connect(function(input, game_processed)
    local target = internal.keybind_listening;
    if not target then
        return;
    end;

    if input.UserInputType == Enum.UserInputType.Keyboard then
        target.key = input.KeyCode;
    elseif input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.MouseButton2
        or input.UserInputType == Enum.UserInputType.MouseButton3 then
        target.key = input.UserInputType;
    else
        return;
    end;

    target.listening = false;
    internal.keybind_listening = nil;
end);

do
    function library.on_render()
        if (not isoverlayactive()) then
            return;
        end;

        push_theme();

        if not internal.sized then
            ImGui.SetNextWindowSize(vector2_new(720, 480));
            internal.sized = true;
        end;
        
        ImGui.Begin(library.name .. "###" .. noise, nil, ImGuiWindowFlags_NoTitleBar);

        local tab_list = internal.tab_list;
        local window_size = ImGui.GetWindowSize();

        -- Top bar
        do
            push_accent_text();
            ImGui.Text(library.name);
            pop_accent_text();
            ImGui.SameLine();
            
            push_muted_text();
            ImGui.Text("|");
            pop_muted_text();
            ImGui.SameLine();

            local amount = #tab_list;
            for i = 1, amount do
                local tab = tab_list[i];
                local is_active = (internal.tab == i);

                if is_active then
                    push_accent_text();
                else
                    push_muted_text();
                end;

                if ImGui.Button(tab.name .. "##" .. noise .. i) then
                    internal.tab = i;
                end;

                if is_active then
                    pop_accent_text();
                else
                    pop_muted_text();
                end;

                if i ~= amount then
                    ImGui.SameLine();
                end;
            end;
        end;

        ImGui.Separator();

        local tab = tab_list[internal.tab];
        local y_size = window_size.Y - 70;
        local col_width = (window_size.X - 30) / 2;

        if tab then
            local groups = tab.data;

            if (ImGui.BeginChild("ColLeft##" .. noise, vector2_new(col_width, y_size), ImGuiChildFlags_Border)) then
                for i = 1, #groups, 2 do
                    local group = groups[i];
                    
                    push_accent_text();
                    ImGui.Text(group.name);
                    pop_accent_text();
                    
                    ImGui.Separator();
                    group.callback();
                    
                    if groups[i + 2] then
                        ImGui.Separator();
                    end;
                end;
            end; ImGui.EndChild(); ImGui.SameLine();

            if (ImGui.BeginChild("ColRight##" .. noise, vector2_new(col_width, y_size), ImGuiChildFlags_Border)) then
                for i = 2, #groups, 2 do
                    local group = groups[i];
                    
                    push_accent_text();
                    ImGui.Text(group.name);
                    pop_accent_text();
                    
                    ImGui.Separator();
                    group.callback();
                    
                    if groups[i + 2] then
                        ImGui.Separator();
                    end;
                end;
            end; ImGui.EndChild();
        end;

        ImGui.End();
        pop_theme();
    end;

    function library.add_tab(name)
        local tab = {name = name, data = {}};
        insert(internal.tab_list, tab);
        return tab;
    end;

    function library.add_group(tab, name, callback)
        local group = {name = name, callback = callback};
        if typeof(tab) == "table" then
            insert(tab.data, group);
        elseif typeof(tab) == "string" then
            local tab_data;
            for i, data in internal.tab_list do
                if data.name == tab then
                    tab_data = data;
                    break;
                end;
            end;
            assert(tab_data, "Tab doesn't exist");
            insert(tab_data.data, group);
        else
            error("Expected table or string for tab parameter");
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

    function library.toggle(name, check)
        local new_name = library.format_name(name);
        return ImGui.Checkbox(new_name, check);
    end;

    local function extract_options(options)
        local selected = {};
        for i = 1, #options do
            local option = options[i];
            if not option[2] then continue end;
            insert(selected, option[1]);
        end;
        return selected;
    end;

    function library.multi_dropdown(name, options, min_selected)
        min_selected = min_selected or 1;
        local new_name = library.format_name(name);
        local selected_options = extract_options(options);
        
        ImGui.Text(library.split_name(name));

        if (ImGui.BeginCombo("##" .. new_name, concat(selected_options, ", "))) then
            for i = 1, #options do
                local option = options[i];
                local toggle = option[2];
                local drawn, clicked = ImGui.Selectable(option[1], toggle);
                if clicked then
                    if toggle and #selected_options == min_selected then
                        continue;
                    end;
                    option[2] = not toggle;
                end;
            end;
            ImGui.EndCombo();
        end;
        clear(selected_options);
    end;

    function library.dropdown(name, options)
        local new_name = library.format_name(name);
        local selected_options = extract_options(options);
        
        ImGui.Text(library.split_name(name));

        if (ImGui.BeginCombo("##" .. new_name, concat(selected_options, ", "))) then
            local opts_amount = #options;
            for i = 1, opts_amount do
                local option = options[i];
                local drawn, clicked = ImGui.Selectable(option[1], option[2]);
                if clicked then
                    for n = 1, opts_amount do
                        local opt = options[n];
                        opt[2] = opt == option;
                    end;
                end;
            end;
            ImGui.EndCombo();
        end;
        clear(selected_options);
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

    function library.slider_int(name, min, max, value, format)
        local new_name = library.format_name(name);
        local split_name = library.split_name(name)
        if (#split_name ~= 0) then
            ImGui.Text(split_name);
        end;
        return ImGui.SliderInt("##" .. new_name, value, min, max, format or "%i");
    end;
    
    function library.slider_float(name, min, max, value, format)
        local new_name = library.format_name(name);
        local split_name = library.split_name(name)
        if (#split_name ~= 0) then
            ImGui.Text(split_name);
        end;
        return ImGui.SliderFloat("##" .. new_name, value, min, max, format or "%.2f");
    end;

    function library.slider_angle(name, min, max, value, format)
        local new_name = library.format_name(name);
        local split_name = library.split_name(name)
        if (#split_name ~= 0) then
            ImGui.Text(split_name);
        end;
        return ImGui.SliderFloat("##" .. new_name, value, min, max, format or "%.1f°");
    end;

    function library.keybind(name, data)
        if data.listening == nil then
            data.listening = false;
        end;

        local new_name = library.format_name(name);
        local split_name = library.split_name(name);

        if (#split_name ~= 0) then
            ImGui.Text(split_name);
            ImGui.SameLine();
        end;

        local label;
        if data.listening then
            label = "...";
        elseif data.key then
            label = data.key.Name;
        else
            label = "None";
        end;

        if ImGui.Button(label .. "##" .. new_name) then
            data.listening = true;
            internal.keybind_listening = data;
        end;

        return data.key;
    end;

    -- Color utilities
    local function hex(n)
        local s = format("%x", n);
        if #s == 1 then
            return "0" .. s;
        end;
        return s;
    end;
    
    local function to_hex(r, g, b, a)
        if a then
            return "#" .. (hex(r) .. hex(g) .. hex(b) .. hex(a)):upper();
        end;
        return "#" .. (hex(r) .. hex(g) .. hex(b)):upper();
    end;
    
    function library.color_picker3(name, data)
        if not data.visible then
            data.visible = false;
        end;

        local new_name = library.format_name(name);
        local split_name = library.split_name(name);
        
        local color = data.color;

        ImGui.Text(split_name);
        ImGui.SameLine();
        
        if ImGui.ColorButton("##" .. new_name, color, ImGuiColorEditFlags_NoTooltip, vector2_new(30, 20)) then
            data.visible = not data.visible;
        end;

        if data.visible then
            ImGui.SetNextWindowPos(ImGui.GetWindowPos() + ImGui.GetCursorPos(), ImGuiCond_Appearing);
            local open = ImGui.Begin(split_name .. "###COLORPICKER" .. new_name, nil, ImGuiWindowFlags_NoResize + ImGuiWindowFlags_AlwaysAutoResize + ImGuiWindowFlags_NoCollapse);
            if open then
                data.color = ImGui.ColorPicker3("##COLORPICKER" .. noise, color, ImGuiColorEditFlags_NoLabel);
                ImGui.End();
            else
                data.visible = false;
            end;
        end;
    end;
    
    function library.color_picker4(name, data)
        if not data.visible then
            data.visible = false;
        end;

        local new_name = library.format_name(name);
        local split_name = library.split_name(name);

        local color = data.color;
        local alpha = data.alpha;
        
        ImGui.Text(split_name);
        ImGui.SameLine();
        
        if ImGui.ColorButton("##" .. new_name, color, ImGuiColorEditFlags_NoTooltip, vector2_new(30, 20)) then
            data.visible = not data.visible;
        end;

        if data.visible then
            ImGui.SetNextWindowPos(ImGui.GetWindowPos() + ImGui.GetCursorPos(), ImGuiCond_Appearing);
            local open = ImGui.Begin(split_name .. "###COLORPICKER" .. new_name, nil, ImGuiWindowFlags_NoResize + ImGuiWindowFlags_AlwaysAutoResize + ImGuiWindowFlags_NoCollapse);
            if open then
                data.color = ImGui.ColorPicker3("##COLORPICKER" .. noise, color, ImGuiColorEditFlags_NoLabel);
                data.alpha = ImGui.SliderFloat("Opacity##COLORPICKER" .. noise, alpha, 0, 1, "%.2f");
                ImGui.End();
            else
                data.visible = false;
            end;
        end;
    end;
end;

ImGui.OnRender(library.on_render);
return library;
