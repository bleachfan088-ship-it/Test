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
    group = 1;
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
-- These are just plain colour values fed into the existing
-- ImGui.PushStyleColor / PushStyleVar calls (standard Dear
-- ImGui API, no custom/made-up functions).
-- ==========================================================
local theme = {
    bg            = color3_new(0.07, 0.07, 0.09),
    bg_secondary  = color3_new(0.10, 0.10, 0.13),
    bg_child      = color3_new(0.09, 0.09, 0.115),
    border        = color3_new(0.18, 0.18, 0.22),
    accent        = color3_new(0.35, 0.55, 1.00),
    accent_hover  = color3_new(0.45, 0.63, 1.00),
    accent_active = color3_new(0.28, 0.46, 0.92),
    text          = color3_new(0.90, 0.90, 0.94),
    text_dim      = color3_new(0.55, 0.55, 0.62),
    selectable    = color3_new(0.16, 0.16, 0.20),
};

local function push_theme()
    ImGui.PushStyleColor(ImGuiCol_WindowBg, theme.bg);
    ImGui.PushStyleColor(ImGuiCol_ChildBg, theme.bg_child);
    ImGui.PushStyleColor(ImGuiCol_Border, theme.border);
    ImGui.PushStyleColor(ImGuiCol_Text, theme.text);

    ImGui.PushStyleColor(ImGuiCol_Button, theme.bg_secondary);
    ImGui.PushStyleColor(ImGuiCol_ButtonHovered, theme.accent_hover);
    ImGui.PushStyleColor(ImGuiCol_ButtonActive, theme.accent_active);

    ImGui.PushStyleColor(ImGuiCol_FrameBg, theme.bg_secondary);
    ImGui.PushStyleColor(ImGuiCol_FrameBgHovered, theme.bg_secondary);
    ImGui.PushStyleColor(ImGuiCol_FrameBgActive, theme.bg_secondary);

    ImGui.PushStyleColor(ImGuiCol_Header, theme.accent_active);
    ImGui.PushStyleColor(ImGuiCol_HeaderHovered, theme.accent_hover);
    ImGui.PushStyleColor(ImGuiCol_HeaderActive, theme.accent);

    ImGui.PushStyleColor(ImGuiCol_SliderGrab, theme.accent);
    ImGui.PushStyleColor(ImGuiCol_SliderGrabActive, theme.accent_hover);
    ImGui.PushStyleColor(ImGuiCol_CheckMark, theme.accent);
    ImGui.PushStyleColor(ImGuiCol_Separator, theme.border);

    ImGui.PushStyleVar(ImGuiStyleVar_WindowRounding, 8);
    ImGui.PushStyleVar(ImGuiStyleVar_ChildRounding, 6);
    ImGui.PushStyleVar(ImGuiStyleVar_FrameRounding, 4);
    ImGui.PushStyleVar(ImGuiStyleVar_GrabRounding, 4);
    ImGui.PushStyleVar(ImGuiStyleVar_ItemSpacing, vector2_new(8, 6));
    ImGui.PushStyleVar(ImGuiStyleVar_WindowPadding, vector2_new(12, 12));
end;

local function pop_theme()
    ImGui.PopStyleVar(6);
    ImGui.PopStyleColor(17);
end;

do

    function library.on_render()
        if (not isoverlayactive()) then
            return;
        end;

        push_theme();

        ImGui.SetNextWindowSize(vector2_new(680, 420));
        ImGui.Begin(library.name .. "###" .. noise, nil, ImGuiWindowFlags_NoTitleBar + ImGuiWindowFlags_NoResize + ImGuiWindowFlags_NoScrollbar --[[+ 0x2000000]]); -- ImGuiWindowFlags_NoDocking

        local tab_list = internal.tab_list;
        local window_size = ImGui.GetWindowSize();

        -- top bar: brand on the left, tab buttons centered/left after it
        do
            ImGui.PushStyleColor(ImGuiCol_Text, theme.accent);
            ImGui.Text(library.name);
            ImGui.PopStyleColor(1);

            ImGui.SameLine();
            ImGui.PushStyleColor(ImGuiCol_Text, theme.text_dim);
            ImGui.Text("|");
            ImGui.PopStyleColor(1);
            ImGui.SameLine();

            local amount = #tab_list;
            for i = 1, amount do
                local tab = tab_list[i];
                local is_active = (internal.tab == i);

                if is_active then
                    ImGui.PushStyleColor(ImGuiCol_Button, theme.accent);
                    ImGui.PushStyleColor(ImGuiCol_ButtonHovered, theme.accent_hover);
                end;

                if ImGui.Button(tab.name) then
                    internal.tab = i;
                    internal.group = 1;
                end;

                if is_active then
                    ImGui.PopStyleColor(2);
                end;

                if i ~= amount then
                    ImGui.SameLine();
                end;
            end;
        end;

        ImGui.Separator();

        local y_size = window_size.Y - 70;
        local tab = tab_list[internal.tab];

        if (ImGui.BeginChild("Groups##" .. noise, vector2_new(180, y_size), ImGuiChildFlags_Border)) then
            ImGui.PushStyleColor(ImGuiCol_Text, theme.text_dim);
            ImGui.Text("CATEGORIES");
            ImGui.PopStyleColor(1);
            ImGui.Separator();

            local group = internal.group;

            for i = 1, #tab.data do
                local drawn, clicked = ImGui.Selectable(tab.data[i].name, group == i);
                if clicked then
                    internal.group = i;
                end;
            end;
        end; ImGui.EndChild(); ImGui.SameLine();

        if (ImGui.BeginChild("Data##" .. noise, vector2_new(window_size.X - 202, y_size), ImGuiChildFlags_Border)) then
            local group = tab.data[internal.group];
            if group then
                ImGui.PushStyleColor(ImGuiCol_Text, theme.accent);
                ImGui.Text(group.name);
                ImGui.PopStyleColor(1);
                ImGui.Separator();
                ImGui.Text(" ");

                group.callback();
            end;
        end; ImGui.EndChild();

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
