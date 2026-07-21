if not (ImGui) then
    return warn("ImGui Library - your executor doesn't support ImGui");
end;

local library = {
    name = "Modern UI";
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
-- generating noise
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
-- Confirmed working: ImGui.PushStyleColor / ImGui.PopStyleColor
-- (your executor errored specifically on PushStyleVar, one line
-- after the last PushStyleColor call - so only PushStyleColor is
-- used here, never PushStyleVar/PopStyleVar).
-- ==========================================================
local presets = {
    Blue   = { accent = color3_new(0.30, 0.55, 1.00), hover = color3_new(0.42, 0.63, 1.00), active = color3_new(0.24, 0.46, 0.92) };
    Purple = { accent = color3_new(0.60, 0.35, 1.00), hover = color3_new(0.68, 0.46, 1.00), active = color3_new(0.50, 0.28, 0.92) };
    Green  = { accent = color3_new(0.30, 0.85, 0.45), hover = color3_new(0.42, 0.92, 0.55), active = color3_new(0.22, 0.72, 0.36) };
};

local current_theme = "Blue";

function library.set_theme(name)
    if presets[name] then
        current_theme = name;
    end;
end;

local bg            = color3_new(0.07, 0.07, 0.09);
local bg_secondary  = color3_new(0.11, 0.11, 0.14);
local bg_child      = color3_new(0.09, 0.09, 0.115);
local border_color  = color3_new(0.18, 0.18, 0.22);
local text_color    = color3_new(0.90, 0.90, 0.94);
local pushed_colors = 0;

local function push_theme()
    local t = presets[current_theme];
    local n = 0;

    local function push(col, value)
        ImGui.PushStyleColor(col, value);
        n += 1;
    end;

    push(ImGuiCol_WindowBg, bg);
    push(ImGuiCol_ChildBg, bg_child);
    push(ImGuiCol_Border, border_color);
    push(ImGuiCol_Text, text_color);

    push(ImGuiCol_Button, bg_secondary);
    push(ImGuiCol_ButtonHovered, t.hover);
    push(ImGuiCol_ButtonActive, t.active);

    push(ImGuiCol_FrameBg, bg_secondary);
    push(ImGuiCol_FrameBgHovered, bg_secondary);
    push(ImGuiCol_FrameBgActive, bg_secondary);

    push(ImGuiCol_Header, t.active);
    push(ImGuiCol_HeaderHovered, t.hover);
    push(ImGuiCol_HeaderActive, t.accent);

    push(ImGuiCol_SliderGrab, t.accent);
    push(ImGuiCol_SliderGrabActive, t.hover);
    push(ImGuiCol_CheckMark, t.accent);
    push(ImGuiCol_Separator, border_color);

    pushed_colors = n;
end;

local function pop_theme()
    ImGui.PopStyleColor(pushed_colors);
end;

-- push/pop just the text color, used to highlight the active tab
-- and group headers without any extra decorative icons
local function push_accent_text()
    ImGui.PushStyleColor(ImGuiCol_Text, presets[current_theme].accent);
end;
local function pop_accent_text()
    ImGui.PopStyleColor(1);
end;

do

    function library.on_render()
        if (not isoverlayactive()) then
            return;
        end;

        push_theme();

        if not internal.sized then
            ImGui.SetNextWindowSize(vector2_new(680, 420));
            internal.sized = true;
        end;
        ImGui.Begin(library.name .. "###" .. noise, nil, ImGuiWindowFlags_NoTitleBar --[[+ 0x2000000]]); -- ImGuiWindowFlags_NoDocking

        local tab_list = internal.tab_list;
        local window_size = ImGui.GetWindowSize();

        -- top bar: brand name, then tab buttons (active tab is
        -- highlighted by its own text color, no icons)
        do
            push_accent_text();
            ImGui.Text(library.name);
            pop_accent_text();
            ImGui.SameLine();
            ImGui.Text("|");
            ImGui.SameLine();

            local amount = #tab_list;
            for i = 1, amount do
                local tab = tab_list[i];
                local is_active = (internal.tab == i);

                if is_active then
                    push_accent_text();
                end;

                if ImGui.Button(tab.name) then
                    internal.tab = i;
                end;

                if is_active then
                    pop_accent_text();
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

        -- render every group in the current tab at once, side by side
        -- in two columns, instead of a categories list that shows one
        -- group at a time
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
            assert(tab_data, "doesn't exist");
            insert(tab_data.data, group);
        else
            error("string | table");
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
        return ImGui.Checkbox(library.format_name(name), check);
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
        return ImGui.SliderFloat("##" .. new_name, value, min, max, format or "%.3f");
    end;

    -- ======================================================
    -- KEYBIND PICKER (new - built only from ImGui functions
    -- already used elsewhere in this file, plus Roblox's
    -- standard UserInputService; no invented ImGui API)
    -- ======================================================
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

    -- data = { key = Enum.KeyCode.E (or nil), listening = false }
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

        if ImGui.ColorButton(split_name, color, ImGuiColorEditFlags_NoTooltip) then
            data.visible = not data.visible;
        end;

        if ImGui.BeginItemTooltip("##TOOLTIP"..new_name) then
            ImGui.Text(split_name);
            ImGui.Separator();
            ImGui.ColorButton("##color", color, ImGuiColorEditFlags_NoTooltip, vector2_new(50, 50)); ImGui.SameLine();

            local r, g, b = color.R, color.G, color.B;
            local r255, g255, b255 = floor(r * 255), floor(g * 255), floor(b * 255);
            ImGui.Text(to_hex(r255, g255, b255) .. `\nR: {r255}, G: {g255}, B: {b255}\n({format("%.3f", r)}, {format("%.3f", g)}, {format("%.3f", b)})`);
            ImGui.EndTooltip();
        end;

        if data.visible then
            local position = ImGui.GetWindowPos() + ImGui.GetCursorPos();

            ImGui.SetNextWindowPos(position, ImGuiCond_Appearing);
            local drawn = ImGui.Begin(split_name .. "###COLORPICKER" .. new_name, nil, ImGuiWindowFlags_NoResize + ImGuiWindowFlags_AlwaysAutoResize + ImGuiWindowFlags_NoCollapse);
            data.color = ImGui.ColorPicker3("Color Picker##COLORPICKER" .. noise, color, ImGuiColorEditFlags_NoLabel);
            ImGui.End();

            if not drawn then
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
        
        if ImGui.ColorButton(split_name, color, ImGuiColorEditFlags_NoTooltip) then
            data.visible = not data.visible;
        end;

        if ImGui.BeginItemTooltip("##TOOLTIP"..new_name) then
            ImGui.Text(split_name);
            ImGui.Separator();
            ImGui.ColorButton("##color", color, ImGuiColorEditFlags_NoTooltip, vector2_new(50, 50)); ImGui.SameLine();

            local r, g, b = color.R, color.G, color.B;
            local r255, g255, b255, a255 = floor(r * 255), floor(g * 255), floor(b * 255), floor(alpha * 255);
            ImGui.Text(to_hex(r255, g255, b255, a255) .. `\nR: {r255}, G: {g255}, B: {b255}, A: {a255}\n({format("%.3f", r)}, {format("%.3f", g)}, {format("%.3f", b)}, {format("%.3f", alpha)})`);
            ImGui.EndTooltip();
        end;

        if data.visible then
            local position = ImGui.GetWindowPos() + ImGui.GetCursorPos();

            ImGui.SetNextWindowPos(position, ImGuiCond_Appearing);
            local drawn = ImGui.Begin(split_name .. "###COLORPICKER" .. new_name, nil, ImGuiWindowFlags_NoResize + ImGuiWindowFlags_AlwaysAutoResize + ImGuiWindowFlags_NoCollapse);
            data.color = ImGui.ColorPicker3("Color Picker##COLORPICKER" .. noise, color, ImGuiColorEditFlags_NoLabel);
            data.alpha = ImGui.SliderFloat("Opacity##COLORPICKER" .. noise, alpha, 0, 1);
            ImGui.End();

            if not drawn then
                data.visible = false;
            end;
        end;
    end;
end;
ImGui.OnRender(library.on_render);

return library;
