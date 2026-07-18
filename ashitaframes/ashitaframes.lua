addon.name      = 'ashitaframes';
addon.author    = 'EflfK';
addon.version   = '0.2.1';
addon.desc      = 'Read-only party and target unit frames for Ashita.';
addon.link      = 'https://github.com/EflfK/ashitaframes';

require('common');

local bit   = require('bit');
local chat  = require('chat');
local d3d8  = require('d3d8');
local ffi   = require('ffi');
local imgui = require('imgui');

local d3d8_device = nil;

local JOBS = {
    [0]  = '',
    [1]  = 'WAR',
    [2]  = 'MNK',
    [3]  = 'WHM',
    [4]  = 'BLM',
    [5]  = 'RDM',
    [6]  = 'THF',
    [7]  = 'PLD',
    [8]  = 'DRK',
    [9]  = 'BST',
    [10] = 'BRD',
    [11] = 'RNG',
    [12] = 'SAM',
    [13] = 'NIN',
    [14] = 'DRG',
    [15] = 'SMN',
    [16] = 'BLU',
    [17] = 'COR',
    [18] = 'PUP',
    [19] = 'DNC',
    [20] = 'SCH',
    [21] = 'GEO',
    [22] = 'RUN',
};

local DEFAULT_SETTINGS = {
    visible = true,
    locked = false,
    show_target = true,
    show_party = true,
    show_alliance = false,
    show_empty_target = true,
    same_zone_dim = true,
    show_jobs = true,
    show_percent = true,
    show_tp = true,
    show_buffs = true,
    max_buffs = 8,
    party_window_x = 36,
    party_window_y = 362,
    target_window_x = 36,
    target_window_y = 296,
    frame_width = 232,
    row_height = 56,
    row_gap = 5,
    opacity = 88,
};

local COLORS = {
    panel_bg = { 0.025, 0.024, 0.022, 0.88 },
    panel_border = { 0.64, 0.48, 0.22, 0.72 },
    row_bg = { 0.035, 0.039, 0.043, 0.88 },
    row_dim = { 0.035, 0.039, 0.043, 0.46 },
    row_border = { 0.76, 0.61, 0.32, 0.36 },
    row_border_active = { 1.00, 0.82, 0.42, 0.72 },
    hp = { 0.25, 0.76, 0.35, 0.90 },
    hp_low = { 0.92, 0.30, 0.22, 0.92 },
    mp = { 0.28, 0.52, 0.98, 0.82 },
    tp = { 0.96, 0.78, 0.26, 0.86 },
    bar_empty = { 0.08, 0.08, 0.08, 0.78 },
    text = { 0.94, 0.91, 0.82, 1.00 },
    text_muted = { 0.66, 0.66, 0.68, 0.92 },
    text_dim = { 0.45, 0.45, 0.48, 0.84 },
    accent = { 0.42, 0.82, 0.94, 1.00 },
    shadow = { 0.00, 0.00, 0.00, 0.90 },
    warning = { 1.00, 0.56, 0.26, 1.00 },
};

local BUFF_ICON_SIZE = 18;
local BUFF_ICON_GAP = 4;
local BUFF_ICON_FILES = {
    protect = 'protect_1.png',
    shell = 'shell_1.png',
};

local LIMITS = {
    width_min = 170,
    width_max = 360,
    row_height_min = 32,
    row_height_with_buffs_min = 54,
    row_height_max = 84,
    row_gap_min = 0,
    row_gap_max = 14,
    max_buffs_min = 1,
    max_buffs_max = 16,
    opacity_min = 35,
    opacity_max = 100,
};

local state = {
    settings = { },
    visible = { true },
    config_visible = { false },
    config_error = nil,
    buff_name_cache = { },
    buff_icon_cache = { },
    party_window_x = 36,
    party_window_y = 362,
    target_window_x = 36,
    target_window_y = 296,
};

local function flag(value)
    return value or 0;
end

local WINDOW_FLAGS_BASE = flag(ImGuiWindowFlags_NoResize)
    + flag(ImGuiWindowFlags_NoScrollbar)
    + flag(ImGuiWindowFlags_NoScrollWithMouse)
    + flag(ImGuiWindowFlags_NoSavedSettings)
    + flag(ImGuiWindowFlags_AlwaysAutoResize);

local WINDOW_FLAGS_LOCKED = WINDOW_FLAGS_BASE
    + flag(ImGuiWindowFlags_NoTitleBar)
    + flag(ImGuiWindowFlags_NoMove);

local function clamp(value, min_value, max_value)
    value = tonumber(value) or min_value;

    if (value < min_value) then
        return min_value;
    end

    if (value > max_value) then
        return max_value;
    end

    return value;
end

local function clamp_int(value, min_value, max_value)
    return math.floor(clamp(value, min_value, max_value) + 0.5);
end

local function apply_alpha(color, alpha)
    return {
        color[1] or 0,
        color[2] or 0,
        color[3] or 0,
        (color[4] or 1) * alpha,
    };
end

local function color_u32(color)
    return imgui.GetColorU32(color);
end

local function clean_string(value)
    if (value == nil) then
        return '';
    end

    return tostring(value):gsub('%z', ''):gsub('^%s+', ''):gsub('%s+$', '');
end

local function safe_read(reader, default)
    local ok, value = pcall(reader);
    if (ok and value ~= nil) then
        return value;
    end

    return default;
end

local function truthy(value)
    return value == true or value == 1;
end

local function overlay_settings(target, source)
    if (type(source) ~= 'table') then
        return target;
    end

    for key, value in pairs(source) do
        if (target[key] ~= nil) then
            target[key] = value;
        end
    end

    return target;
end

local function normalize_settings(settings)
    settings.visible = settings.visible ~= false;
    settings.locked = settings.locked == true;
    settings.show_target = settings.show_target ~= false;
    settings.show_party = settings.show_party ~= false;
    settings.show_alliance = settings.show_alliance == true;
    settings.show_empty_target = settings.show_empty_target ~= false;
    settings.same_zone_dim = settings.same_zone_dim ~= false;
    settings.show_jobs = settings.show_jobs ~= false;
    settings.show_percent = settings.show_percent ~= false;
    settings.show_tp = settings.show_tp ~= false;
    settings.show_buffs = settings.show_buffs ~= false;

    settings.party_window_x = clamp_int(settings.party_window_x, -2000, 4000);
    settings.party_window_y = clamp_int(settings.party_window_y, -2000, 4000);
    settings.target_window_x = clamp_int(settings.target_window_x, -2000, 4000);
    settings.target_window_y = clamp_int(settings.target_window_y, -2000, 4000);
    settings.frame_width = clamp_int(settings.frame_width, LIMITS.width_min, LIMITS.width_max);
    local row_height_min = settings.show_buffs and LIMITS.row_height_with_buffs_min or LIMITS.row_height_min;
    settings.row_height = clamp_int(settings.row_height, row_height_min, LIMITS.row_height_max);
    settings.row_gap = clamp_int(settings.row_gap, LIMITS.row_gap_min, LIMITS.row_gap_max);
    settings.max_buffs = clamp_int(settings.max_buffs, LIMITS.max_buffs_min, LIMITS.max_buffs_max);
    settings.opacity = clamp_int(settings.opacity, LIMITS.opacity_min, LIMITS.opacity_max);

    return settings;
end

local function load_config()
    local settings = { };
    for key, value in pairs(DEFAULT_SETTINGS) do
        settings[key] = value;
    end

    state.config_error = nil;
    package.loaded.ashitaframes_config = nil;

    local ok, config = pcall(require, 'ashitaframes_config');
    if (not ok) then
        state.config_error = tostring(config);
    elseif (type(config) == 'table') then
        overlay_settings(settings, config.settings);
    end

    state.settings = normalize_settings(settings);
    state.visible[1] = state.settings.visible;
    state.party_window_x = state.settings.party_window_x;
    state.party_window_y = state.settings.party_window_y;
    state.target_window_x = state.settings.target_window_x;
    state.target_window_y = state.settings.target_window_y;
end

local function log_info(message)
    print(chat.header(addon.name):append(chat.message(message)));
end

local function log_error(message)
    print(chat.header(addon.name):append(chat.error(message)));
end

local function percent_value(value)
    local numeric = tonumber(value);
    if (numeric == nil) then
        return nil;
    end

    return clamp(numeric, 0, 100);
end

local function display_percent(value)
    local numeric = percent_value(value);
    if (numeric == nil) then
        return '--%';
    end

    return ('%d%%'):fmt(math.floor(numeric + 0.5));
end

local function entity_distance(entity, index)
    if (entity == nil or index == nil or index <= 0) then
        return nil;
    end

    local raw_distance = safe_read(function () return entity:GetDistance(index); end, nil);
    if (raw_distance == nil or raw_distance < 0) then
        return nil;
    end

    return math.sqrt(raw_distance);
end

local function job_label(main_job, main_level, sub_job, sub_level)
    local main = JOBS[tonumber(main_job) or 0] or '';
    local sub = JOBS[tonumber(sub_job) or 0] or '';
    local main_text = main;

    if (#main_text > 0 and tonumber(main_level) ~= nil and tonumber(main_level) > 0) then
        main_text = ('%s%d'):fmt(main_text, main_level);
    end

    if (#sub > 0) then
        if (tonumber(sub_level) ~= nil and tonumber(sub_level) > 0) then
            return ('%s/%s%d'):fmt(main_text, sub, sub_level);
        end

        return ('%s/%s'):fmt(main_text, sub);
    end

    return main_text;
end

local function append_buff_id(result, seen, value)
    local buff_id = tonumber(value);
    if (buff_id == nil or buff_id <= 0 or buff_id == 255 or buff_id > 0x3FF or seen[buff_id]) then
        return;
    end

    seen[buff_id] = true;
    table.insert(result, buff_id);
end

local function player_buffs()
    local player = safe_read(function () return AshitaCore:GetMemoryManager():GetPlayer(); end, nil);
    local icons = player ~= nil and safe_read(function () return player:GetStatusIcons(); end, nil) or nil;
    local result = { };
    local seen = { };

    if (icons == nil) then
        return result;
    end

    for index = 1, 32, 1 do
        local buff_id = safe_read(function () return icons[index]; end, nil);
        if (buff_id == 255) then
            break;
        end

        append_buff_id(result, seen, buff_id);
    end

    return result;
end

local function party_status_buffs(server_id)
    server_id = tonumber(server_id) or 0;
    if (server_id == 0) then
        return { };
    end

    local pointer_manager = safe_read(function () return AshitaCore:GetPointerManager(); end, nil);
    local pointer = pointer_manager ~= nil and safe_read(function () return pointer_manager:Get('party.statusicons'); end, 0) or 0;
    local base = pointer ~= 0 and safe_read(function () return ashita.memory.read_uint32(pointer); end, 0) or 0;
    if (base == 0) then
        return { };
    end

    for member_index = 0, 4, 1 do
        local member_ptr = base + (0x30 * member_index);
        local player_id = safe_read(function () return ashita.memory.read_uint32(member_ptr); end, 0);
        if (player_id == server_id) then
            local result = { };
            local seen = { };

            for buff_index = 0, 31, 1 do
                local high_bits = safe_read(function () return ashita.memory.read_uint8(member_ptr + 8 + math.floor(buff_index / 4)); end, 0);
                local shift = math.fmod(buff_index, 4) * 2;
                high_bits = bit.lshift(bit.band(bit.rshift(high_bits, shift), 0x03), 8);

                local low_bits = safe_read(function () return ashita.memory.read_uint8(member_ptr + 16 + buff_index); end, 255);
                local buff_id = high_bits + low_bits;
                if (buff_id == 255) then
                    break;
                end

                append_buff_id(result, seen, buff_id);
            end

            return result;
        end
    end

    return { };
end

local function party_member_buffs(party, index, server_id, same_zone)
    if (not state.settings.show_buffs or index > 5 or same_zone == false) then
        return { };
    end

    if (index == 0) then
        return player_buffs();
    end

    return party_status_buffs(server_id);
end

local function buff_name(buff_id)
    buff_id = tonumber(buff_id) or 0;
    if (state.buff_name_cache[buff_id] ~= nil) then
        return state.buff_name_cache[buff_id];
    end

    local resources = safe_read(function () return AshitaCore:GetResourceManager(); end, nil);
    local name = resources ~= nil and clean_string(safe_read(function () return resources:GetString('buffs.names', buff_id); end, '')) or '';
    if (#name == 0) then
        name = ('#%d'):fmt(buff_id);
    end

    state.buff_name_cache[buff_id] = name;
    return name;
end

local function ensure_d3d_device()
    if (d3d8_device == nil) then
        d3d8_device = safe_read(function () return d3d8.get_device(); end, nil);
    end

    return d3d8_device;
end

local function load_buff_icon(filename)
    if (state.buff_icon_cache[filename] == false) then
        return nil;
    end
    if (state.buff_icon_cache[filename] ~= nil) then
        return state.buff_icon_cache[filename];
    end

    local device = ensure_d3d_device();
    if (device == nil) then
        return nil;
    end

    local path = ('%s/icons/%s'):fmt(addon.path, filename);
    local texture_ptr = ffi.new('IDirect3DTexture8*[1]');
    local result = safe_read(function () return ffi.C.D3DXCreateTextureFromFileA(device, path, texture_ptr); end, nil);
    if (result ~= 0 or texture_ptr[0] == nil) then
        state.buff_icon_cache[filename] = false;
        return nil;
    end

    local texture = d3d8.gc_safe_release(ffi.cast('IDirect3DTexture8*', texture_ptr[0]));
    local icon = {
        texture = texture,
        handle = tonumber(ffi.cast('uint32_t', texture)),
    };

    state.buff_icon_cache[filename] = icon;
    return icon;
end

local function buff_icon_file(buff_id)
    local name = buff_name(buff_id):lower();
    if (name:find('protect', 1, true) ~= nil) then
        return BUFF_ICON_FILES.protect;
    end
    if (name:find('shell', 1, true) ~= nil) then
        return BUFF_ICON_FILES.shell;
    end

    return nil;
end

local function buff_icon_items(buffs)
    local items = { };
    if (type(buffs) ~= 'table' or #buffs == 0) then
        return items;
    end

    local max_buffs = state.settings.max_buffs or DEFAULT_SETTINGS.max_buffs;
    for index = 1, #buffs, 1 do
        if (#items >= max_buffs) then
            break;
        end

        local buff_id = buffs[index];
        local filename = buff_icon_file(buff_id);
        local icon = filename ~= nil and load_buff_icon(filename) or nil;
        if (icon ~= nil) then
            table.insert(items, {
                id = buff_id,
                name = buff_name(buff_id),
                handle = icon.handle,
            });
        end
    end

    return items;
end

local function party_member_unit(party, index, self_zone)
    local active = truthy(safe_read(function () return party:GetMemberIsActive(index); end, false));
    local name = clean_string(safe_read(function () return party:GetMemberName(index); end, ''));
    local server_id = safe_read(function () return party:GetMemberServerId(index); end, 0);
    local target_index = safe_read(function () return party:GetMemberTargetIndex(index); end, 0);

    if (not active and server_id == 0 and #name == 0 and target_index == 0) then
        return nil;
    end

    local zone_id = safe_read(function () return party:GetMemberZone(index); end, nil);
    local same_zone = self_zone == nil or zone_id == nil or zone_id == self_zone;
    local tag = index == 0 and 'YOU' or tostring(index + 1);

    return {
        kind = 'party',
        tag = tag,
        index = index,
        name = #name > 0 and name or ('Slot %d'):fmt(index + 1),
        hp_pct = safe_read(function () return party:GetMemberHPPercent(index); end, nil),
        mp_pct = safe_read(function () return party:GetMemberMPPercent(index); end, nil),
        tp = safe_read(function () return party:GetMemberTP(index); end, nil),
        job = job_label(
            safe_read(function () return party:GetMemberMainJob(index); end, nil),
            safe_read(function () return party:GetMemberMainJobLevel(index); end, nil),
            safe_read(function () return party:GetMemberSubJob(index); end, nil),
            safe_read(function () return party:GetMemberSubJobLevel(index); end, nil)),
        buffs = party_member_buffs(party, index, server_id, same_zone),
        same_zone = same_zone,
        dim = state.settings.same_zone_dim and not same_zone,
    };
end

local function collect_party_units()
    local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
    if (memory == nil) then
        return { };
    end

    local party = safe_read(function () return memory:GetParty(); end, nil);
    if (party == nil) then
        return { };
    end

    local self_zone = safe_read(function () return party:GetMemberZone(0); end, nil);
    local max_index = state.settings.show_alliance and 17 or 5;
    local units = { };

    for index = 0, max_index, 1 do
        local unit = party_member_unit(party, index, self_zone);
        if (unit ~= nil) then
            table.insert(units, unit);
        end
    end

    return units;
end

local function collect_target_unit()
    local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
    if (memory == nil) then
        return nil;
    end

    local target = safe_read(function () return memory:GetTarget(); end, nil);
    local entity = safe_read(function () return memory:GetEntity(); end, nil);
    if (target == nil) then
        return nil;
    end

    local primary_index = safe_read(function () return target:GetTargetIndex(0); end, 0);
    local sub_index = safe_read(function () return target:GetTargetIndex(1); end, 0);
    local is_sub_target_active = truthy(safe_read(function () return target:GetIsSubTargetActive(); end, false));
    local active_index = is_sub_target_active and sub_index or primary_index;

    if (active_index == nil or active_index <= 0) then
        if (state.settings.show_empty_target) then
            return {
                kind = 'target',
                tag = 'T',
                name = 'No target',
                hp_pct = nil,
                distance = nil,
                dim = true,
            };
        end

        return nil;
    end

    local name = clean_string(safe_read(function () return entity:GetName(active_index); end, ''));
    if (#name == 0) then
        name = clean_string(safe_read(function () return target:GetWindowName(); end, ''));
    end
    if (#name == 0) then
        name = clean_string(safe_read(function () return target:GetLastTargetName(); end, ''));
    end

    local hp_pct = safe_read(function () return entity:GetHPPercent(active_index); end, nil);
    if (hp_pct == nil) then
        hp_pct = safe_read(function () return target:GetWindowHPPercent(); end, nil);
    end

    return {
        kind = 'target',
        tag = is_sub_target_active and 'ST' or 'T',
        index = active_index,
        name = #name > 0 and name or ('Target %d'):fmt(active_index),
        hp_pct = hp_pct,
        mp_pct = nil,
        tp = nil,
        distance = entity_distance(entity, active_index),
        job = '',
        same_zone = true,
        dim = false,
    };
end

local function calc_text_width(text)
    local width = safe_read(function () return imgui.CalcTextSize(text); end, nil);
    if (type(width) == 'number') then
        return width;
    end

    return #tostring(text) * 7;
end

local function fit_text(text, max_width)
    text = clean_string(text);
    if (calc_text_width(text) <= max_width) then
        return text;
    end

    while (#text > 4) do
        text = text:sub(1, #text - 1);
        local candidate = text .. '...';
        if (calc_text_width(candidate) <= max_width) then
            return candidate;
        end
    end

    return text;
end

local function draw_text(draw_list, x, y, color, text)
    text = tostring(text or '');
    draw_list:AddText({ x + 1, y + 1 }, color_u32(COLORS.shadow), text);
    draw_list:AddText({ x, y }, color_u32(color), text);
end

local function draw_bar(draw_list, x, y, width, height, percent, fill_color, alpha)
    percent = percent_value(percent);
    local fill_width = 0;

    if (percent ~= nil) then
        fill_width = math.floor(width * (percent / 100));
    end

    draw_list:AddRectFilled({ x, y }, { x + width, y + height }, color_u32(apply_alpha(COLORS.bar_empty, alpha)), 2.0);
    if (fill_width > 0) then
        draw_list:AddRectFilled({ x, y }, { x + fill_width, y + height }, color_u32(apply_alpha(fill_color, alpha)), 2.0);
    end
end

local function draw_tp_line(draw_list, x, y, width, tp, alpha)
    local numeric = tonumber(tp) or 0;
    local percent = clamp(numeric / 30, 0, 100);
    draw_bar(draw_list, x, y, width, 3, percent, COLORS.tp, alpha);
end

local function unit_right_label(unit)
    if (unit.kind == 'target') then
        if (unit.distance ~= nil) then
            return ('%.1f'):fmt(unit.distance);
        end

        return '';
    end

    local pieces = { };
    if (state.settings.show_tp and tonumber(unit.tp) ~= nil) then
        table.insert(pieces, ('%dTP'):fmt(unit.tp));
    end
    if (state.settings.show_jobs and unit.job ~= nil and #unit.job > 0) then
        table.insert(pieces, unit.job);
    end

    return table.concat(pieces, ' ');
end

local function draw_buff_icon_row(unit, x, y, width)
    if (not state.settings.show_buffs or unit.kind ~= 'party') then
        return;
    end

    local items = buff_icon_items(unit.buffs);
    if (#items == 0) then
        return;
    end

    local tint = unit.dim and { 0.62, 0.62, 0.62, 0.62 } or { 1.00, 1.00, 1.00, 1.00 };
    local icon_x = x + 8;
    local icon_y = y + 21;
    local max_x = x + width - 8;

    for _, item in ipairs(items) do
        if ((icon_x + BUFF_ICON_SIZE) > max_x) then
            break;
        end

        imgui.SetCursorScreenPos({ icon_x, icon_y });
        imgui.Image(item.handle, { BUFF_ICON_SIZE, BUFF_ICON_SIZE }, { 0, 0 }, { 1, 1 }, tint, { 0, 0, 0, 0 });
        if (imgui.IsItemHovered()) then
            imgui.BeginTooltip();
            imgui.Text(item.name);
            imgui.EndTooltip();
        end

        icon_x = icon_x + BUFF_ICON_SIZE + BUFF_ICON_GAP;
    end

    imgui.SetCursorScreenPos({ x, y });
end

local function draw_unit_row(unit, width, row_height)
    local x, y = imgui.GetCursorScreenPos();
    local draw_list = imgui.GetWindowDrawList();
    local settings = state.settings;
    local alpha = (settings.opacity / 100) * (unit.dim and 0.62 or 1.0);
    local row_bg = unit.dim and COLORS.row_dim or COLORS.row_bg;
    local border = unit.kind == 'target' and COLORS.row_border_active or COLORS.row_border;
    local hp = percent_value(unit.hp_pct);
    local hp_color = hp ~= nil and hp <= 35 and COLORS.hp_low or COLORS.hp;
    local bar_x = x + 8;
    local bar_w = width - 16;
    local hp_y = y + row_height - 16;
    local mp_y = y + row_height - 8;
    local name_max_width = width - 84;
    local name = fit_text(unit.name, name_max_width);
    local right = unit_right_label(unit);
    local right_width = calc_text_width(right);
    local text_color = unit.dim and COLORS.text_dim or COLORS.text;

    draw_list:AddRectFilled({ x, y }, { x + width, y + row_height }, color_u32(apply_alpha(row_bg, alpha)), 4.0);
    draw_list:AddRect({ x, y }, { x + width, y + row_height }, color_u32(apply_alpha(border, alpha)), 4.0, ImDrawCornerFlags_All, 1.0);

    draw_text(draw_list, x + 8, y + 5, COLORS.accent, unit.tag or '');
    draw_text(draw_list, x + 38, y + 5, text_color, name);

    if (#right > 0) then
        draw_text(draw_list, x + width - right_width - 8, y + 5, COLORS.text_muted, right);
    end

    draw_buff_icon_row(unit, x, y, width);

    draw_bar(draw_list, bar_x, hp_y, bar_w, 6, unit.hp_pct, hp_color, alpha);

    if (unit.kind == 'party') then
        draw_bar(draw_list, bar_x, mp_y, bar_w, 4, unit.mp_pct, COLORS.mp, alpha);
        if (settings.show_tp) then
            draw_tp_line(draw_list, bar_x, y + row_height - 3, bar_w, unit.tp, alpha);
        end
    end

    if (settings.show_percent) then
        local hp_text = display_percent(unit.hp_pct);
        local hp_text_width = calc_text_width(hp_text);
        draw_text(draw_list, x + width - hp_text_width - 8, hp_y - 13, COLORS.text, hp_text);
    end

    imgui.Dummy({ width, row_height + settings.row_gap });
end

local function render_window(title, open_state, x, y, width, units, position_callback)
    local settings = state.settings;
    if (#units == 0) then
        return;
    end

    local locked = settings.locked == true;
    local window_flags = locked and WINDOW_FLAGS_LOCKED or WINDOW_FLAGS_BASE;
    local pad = locked and 4 or 8;
    local alpha = settings.opacity / 100;

    imgui.SetNextWindowPos({ x, y }, locked and ImGuiCond_Always or ImGuiCond_FirstUseEver);
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { pad, pad });
    imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, locked and 0.0 or 1.0);
    imgui.PushStyleColor(ImGuiCol_WindowBg, apply_alpha(COLORS.panel_bg, alpha));
    imgui.PushStyleColor(ImGuiCol_Border, apply_alpha(COLORS.panel_border, alpha));

    if (imgui.Begin(title, open_state, window_flags)) then
        local current_x, current_y = imgui.GetWindowPos();
        position_callback(current_x, current_y);

        for _, unit in ipairs(units) do
            draw_unit_row(unit, width, settings.row_height);
        end
    end

    imgui.End();
    imgui.PopStyleColor(2);
    imgui.PopStyleVar(2);
end

local function render_target()
    if (not state.settings.show_target) then
        return;
    end

    local unit = collect_target_unit();
    if (unit == nil) then
        return;
    end

    render_window(
        'AshitaFrames Target###AshitaFramesTarget',
        state.visible,
        state.target_window_x,
        state.target_window_y,
        state.settings.frame_width,
        { unit },
        function (x, y)
            state.target_window_x = math.floor(x + 0.5);
            state.target_window_y = math.floor(y + 0.5);
        end);
end

local function render_party()
    if (not state.settings.show_party) then
        return;
    end

    local units = collect_party_units();
    render_window(
        'AshitaFrames Party###AshitaFramesParty',
        state.visible,
        state.party_window_x,
        state.party_window_y,
        state.settings.frame_width,
        units,
        function (x, y)
            state.party_window_x = math.floor(x + 0.5);
            state.party_window_y = math.floor(y + 0.5);
        end);
end

local function render_int_control(label, id, value, min_value, max_value, apply_value, unit)
    unit = unit or 'px';
    local buffer = { value };
    local slider_format = unit == '%' and '%d%%' or ('%d ' .. unit);

    imgui.TextColored(COLORS.accent, label);
    imgui.SameLine(150);
    imgui.Text(unit == '%' and ('%d%%'):fmt(value) or ('%d %s'):fmt(value, unit));

    imgui.PushItemWidth(260);
    local changed = imgui.SliderInt(('##ashitaframes_%s_slider'):fmt(id), buffer, min_value, max_value, slider_format, ImGuiSliderFlags_AlwaysClamp);
    imgui.PopItemWidth();
    if (changed) then
        apply_value(buffer[1]);
    end
end

local function render_config_window()
    if (not state.config_visible[1]) then
        return;
    end

    imgui.SetNextWindowSize({ 430, 0 }, ImGuiCond_FirstUseEver);
    if (imgui.Begin(('AshitaFrames v%s Configuration###AshitaFramesConfig'):fmt(addon.version), state.config_visible, ImGuiWindowFlags_AlwaysAutoResize)) then
        imgui.TextColored(COLORS.accent, 'Visibility');

        local visible = state.visible[1] == true;
        if (imgui.Checkbox('Show Frames##ashitaframes_show_frames', { visible })) then
            state.visible[1] = not visible;
            state.settings.visible = state.visible[1];
        end

        local locked = state.settings.locked == true;
        if (imgui.Checkbox('Lock Frames##ashitaframes_lock_frames', { locked })) then
            state.settings.locked = not locked;
        end

        local show_target = state.settings.show_target == true;
        if (imgui.Checkbox('Target Frame##ashitaframes_show_target', { show_target })) then
            state.settings.show_target = not show_target;
        end

        local show_party = state.settings.show_party == true;
        if (imgui.Checkbox('Party Frame##ashitaframes_show_party', { show_party })) then
            state.settings.show_party = not show_party;
        end

        local show_alliance = state.settings.show_alliance == true;
        if (imgui.Checkbox('Alliance Slots##ashitaframes_show_alliance', { show_alliance })) then
            state.settings.show_alliance = not show_alliance;
        end

        local same_zone_dim = state.settings.same_zone_dim == true;
        if (imgui.Checkbox('Dim Different Zone##ashitaframes_same_zone_dim', { same_zone_dim })) then
            state.settings.same_zone_dim = not same_zone_dim;
        end

        local show_buffs = state.settings.show_buffs == true;
        if (imgui.Checkbox('Party Buffs##ashitaframes_show_buffs', { show_buffs })) then
            state.settings.show_buffs = not show_buffs;
            state.settings = normalize_settings(state.settings);
        end

        imgui.Separator();
        imgui.TextColored(COLORS.accent, 'Layout');
        render_int_control('Frame Width', 'frame_width', state.settings.frame_width, LIMITS.width_min, LIMITS.width_max, function (value)
            state.settings.frame_width = clamp_int(value, LIMITS.width_min, LIMITS.width_max);
        end);
        local row_height_min = state.settings.show_buffs and LIMITS.row_height_with_buffs_min or LIMITS.row_height_min;
        render_int_control('Row Height', 'row_height', state.settings.row_height, row_height_min, LIMITS.row_height_max, function (value)
            state.settings.row_height = clamp_int(value, row_height_min, LIMITS.row_height_max);
        end);
        render_int_control('Row Gap', 'row_gap', state.settings.row_gap, LIMITS.row_gap_min, LIMITS.row_gap_max, function (value)
            state.settings.row_gap = clamp_int(value, LIMITS.row_gap_min, LIMITS.row_gap_max);
        end);
        render_int_control('Max Buffs', 'max_buffs', state.settings.max_buffs, LIMITS.max_buffs_min, LIMITS.max_buffs_max, function (value)
            state.settings.max_buffs = clamp_int(value, LIMITS.max_buffs_min, LIMITS.max_buffs_max);
        end, 'buffs');
        render_int_control('Opacity', 'opacity', state.settings.opacity, LIMITS.opacity_min, LIMITS.opacity_max, function (value)
            state.settings.opacity = clamp_int(value, LIMITS.opacity_min, LIMITS.opacity_max);
        end, '%');

        imgui.Separator();
        imgui.Text(('Party pos: %d, %d'):fmt(state.party_window_x, state.party_window_y));
        imgui.Text(('Target pos: %d, %d'):fmt(state.target_window_x, state.target_window_y));
        imgui.Text('Runtime changes are not persisted yet.');

        if (state.config_error ~= nil) then
            imgui.Separator();
            imgui.TextColored(COLORS.warning, 'Config load warning:');
            imgui.TextWrapped(state.config_error);
        end
    end

    imgui.End();
end

local function print_help()
    log_info('Commands:');
    print(chat.header(addon.name):append(chat.message('/ashitaframes show | hide | toggle')));
    print(chat.header(addon.name):append(chat.message('/ashitaframes lock | unlock | config')));
    print(chat.header(addon.name):append(chat.message('/ashitaframes reload | status')));
end

local function print_status()
    log_info(('visible=%s locked=%s target=%s party=%s alliance=%s buffs=%s maxBuffs=%d width=%d rowHeight=%d opacity=%d party=(%d,%d) target=(%d,%d)'):fmt(
        tostring(state.visible[1] == true),
        tostring(state.settings.locked == true),
        tostring(state.settings.show_target == true),
        tostring(state.settings.show_party == true),
        tostring(state.settings.show_alliance == true),
        tostring(state.settings.show_buffs == true),
        state.settings.max_buffs,
        state.settings.frame_width,
        state.settings.row_height,
        state.settings.opacity,
        state.party_window_x,
        state.party_window_y,
        state.target_window_x,
        state.target_window_y));

    if (state.config_error ~= nil) then
        log_error('Config load warning: ' .. state.config_error);
    end
end

local function handle_command(e)
    local args = e.command:args();
    local name = clean_string(args[1]):lower();

    if (name ~= '/ashitaframes' and name ~= '/aframes') then
        return;
    end

    e.blocked = true;

    local action = clean_string(args[2]):lower();
    if (action == '' or action == 'help') then
        print_help();
        return;
    end

    if (action == 'show') then
        state.visible[1] = true;
        state.settings.visible = true;
        return;
    end

    if (action == 'hide') then
        state.visible[1] = false;
        state.settings.visible = false;
        return;
    end

    if (action == 'toggle') then
        state.visible[1] = not state.visible[1];
        state.settings.visible = state.visible[1];
        return;
    end

    if (action == 'lock') then
        state.settings.locked = true;
        return;
    end

    if (action == 'unlock') then
        state.settings.locked = false;
        return;
    end

    if (action == 'config') then
        state.config_visible[1] = not state.config_visible[1];
        return;
    end

    if (action == 'reload') then
        load_config();
        log_info('Reloaded ashitaframes_config.lua.');
        return;
    end

    if (action == 'status') then
        print_status();
        return;
    end

    print_help();
end

ashita.events.register('load', 'load_cb', function ()
    load_config();
    log_info('Loaded. Use /ashitaframes config to position frames.');
end);

ashita.events.register('command', 'command_cb', function (e)
    handle_command(e);
end);

ashita.events.register('d3d_present', 'present_cb', function ()
    if (not state.visible[1]) then
        render_config_window();
        return;
    end

    render_target();
    render_party();
    render_config_window();
end);

