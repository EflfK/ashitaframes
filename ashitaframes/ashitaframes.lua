addon.name      = 'ashitaframes';
addon.author    = 'EflfK';
addon.version   = '0.2.1';
addon.desc      = 'Read-only unit frames and overhead bars for Ashita.';
addon.link      = 'https://github.com/EflfK/ashitaframes';

require('common');

local chat  = require('chat');
local imgui = require('imgui');
local bit   = require('bit');
local ffi_ok, ffi = pcall(require, 'ffi');
if (not ffi_ok) then
    ffi = nil;
end

local d3d_ok, d3d = pcall(require, 'd3d8');
if (not d3d_ok) then
    d3d = nil;
end

local C = ffi ~= nil and ffi.C or nil;
local d3d8dev = nil;

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
    show_nameplates = true,
    nameplate_show_self = false,
    nameplate_show_names = false,
    nameplate_max_distance = 35,
    nameplate_max_count = 28,
    nameplate_width = 72,
    nameplate_height = 8,
    nameplate_y_offset = 2.35,
    nameplate_scale_by_distance = true,
    same_zone_dim = true,
    show_jobs = true,
    show_percent = true,
    show_tp = true,
    party_window_x = 36,
    party_window_y = 362,
    target_window_x = 36,
    target_window_y = 296,
    frame_width = 232,
    row_height = 42,
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
    nameplate_neutral = { 0.42, 0.82, 0.94, 0.92 },
    nameplate_party = { 0.25, 0.86, 0.52, 0.94 },
    nameplate_target = { 1.00, 0.78, 0.24, 0.98 },
    nameplate_claimed = { 0.94, 0.36, 0.30, 0.94 },
};

local LIMITS = {
    width_min = 170,
    width_max = 360,
    row_height_min = 32,
    row_height_max = 64,
    row_gap_min = 0,
    row_gap_max = 14,
    opacity_min = 35,
    opacity_max = 100,
    nameplate_distance_min = 5,
    nameplate_distance_max = 100,
    nameplate_count_min = 1,
    nameplate_count_max = 80,
    nameplate_width_min = 28,
    nameplate_width_max = 140,
    nameplate_height_min = 3,
    nameplate_height_max = 18,
    nameplate_y_offset_min = 0.5,
    nameplate_y_offset_max = 5.0,
};

local state = {
    settings = { },
    visible = { true },
    config_visible = { false },
    config_error = nil,
    projection_error = nil,
    projection_context = nil,
    nameplate_overlay_open = { true },
    last_nameplate_count = 0,
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

local NAMEPLATE_WINDOW_FLAGS = flag(ImGuiWindowFlags_NoTitleBar)
    + flag(ImGuiWindowFlags_NoResize)
    + flag(ImGuiWindowFlags_NoMove)
    + flag(ImGuiWindowFlags_NoInputs)
    + flag(ImGuiWindowFlags_NoBackground)
    + flag(ImGuiWindowFlags_NoSavedSettings)
    + flag(ImGuiWindowFlags_NoScrollbar)
    + flag(ImGuiWindowFlags_NoScrollWithMouse)
    + flag(ImGuiWindowFlags_NoFocusOnAppearing)
    + flag(ImGuiWindowFlags_NoBringToFrontOnFocus);

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
    settings.show_nameplates = settings.show_nameplates ~= false;
    settings.nameplate_show_self = settings.nameplate_show_self == true;
    settings.nameplate_show_names = settings.nameplate_show_names == true;
    settings.nameplate_scale_by_distance = settings.nameplate_scale_by_distance ~= false;
    settings.same_zone_dim = settings.same_zone_dim ~= false;
    settings.show_jobs = settings.show_jobs ~= false;
    settings.show_percent = settings.show_percent ~= false;
    settings.show_tp = settings.show_tp ~= false;

    settings.party_window_x = clamp_int(settings.party_window_x, -2000, 4000);
    settings.party_window_y = clamp_int(settings.party_window_y, -2000, 4000);
    settings.target_window_x = clamp_int(settings.target_window_x, -2000, 4000);
    settings.target_window_y = clamp_int(settings.target_window_y, -2000, 4000);
    settings.frame_width = clamp_int(settings.frame_width, LIMITS.width_min, LIMITS.width_max);
    settings.row_height = clamp_int(settings.row_height, LIMITS.row_height_min, LIMITS.row_height_max);
    settings.row_gap = clamp_int(settings.row_gap, LIMITS.row_gap_min, LIMITS.row_gap_max);
    settings.opacity = clamp_int(settings.opacity, LIMITS.opacity_min, LIMITS.opacity_max);
    settings.nameplate_max_distance = clamp_int(settings.nameplate_max_distance, LIMITS.nameplate_distance_min, LIMITS.nameplate_distance_max);
    settings.nameplate_max_count = clamp_int(settings.nameplate_max_count, LIMITS.nameplate_count_min, LIMITS.nameplate_count_max);
    settings.nameplate_width = clamp_int(settings.nameplate_width, LIMITS.nameplate_width_min, LIMITS.nameplate_width_max);
    settings.nameplate_height = clamp_int(settings.nameplate_height, LIMITS.nameplate_height_min, LIMITS.nameplate_height_max);
    settings.nameplate_y_offset = clamp(settings.nameplate_y_offset, LIMITS.nameplate_y_offset_min, LIMITS.nameplate_y_offset_max);

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

local function get_d3d_device()
    if (d3d8dev ~= nil) then
        return d3d8dev;
    end

    if (d3d == nil) then
        return nil;
    end

    d3d8dev = safe_read(function () return d3d.get_device(); end, nil);
    return d3d8dev;
end

local function matrix_cell(matrix, field)
    local value = safe_read(function () return matrix[field]; end, nil);
    if (type(value) == 'number') then
        return value;
    end
    if (type(value) == 'boolean') then
        return value and 1 or 0;
    end

    return tonumber(value) or 0;
end

local function matrix_multiply(m1, m2)
    local a11, a12, a13, a14 = matrix_cell(m1, '_11'), matrix_cell(m1, '_12'), matrix_cell(m1, '_13'), matrix_cell(m1, '_14');
    local a21, a22, a23, a24 = matrix_cell(m1, '_21'), matrix_cell(m1, '_22'), matrix_cell(m1, '_23'), matrix_cell(m1, '_24');
    local a31, a32, a33, a34 = matrix_cell(m1, '_31'), matrix_cell(m1, '_32'), matrix_cell(m1, '_33'), matrix_cell(m1, '_34');
    local a41, a42, a43, a44 = matrix_cell(m1, '_41'), matrix_cell(m1, '_42'), matrix_cell(m1, '_43'), matrix_cell(m1, '_44');
    local b11, b12, b13, b14 = matrix_cell(m2, '_11'), matrix_cell(m2, '_12'), matrix_cell(m2, '_13'), matrix_cell(m2, '_14');
    local b21, b22, b23, b24 = matrix_cell(m2, '_21'), matrix_cell(m2, '_22'), matrix_cell(m2, '_23'), matrix_cell(m2, '_24');
    local b31, b32, b33, b34 = matrix_cell(m2, '_31'), matrix_cell(m2, '_32'), matrix_cell(m2, '_33'), matrix_cell(m2, '_34');
    local b41, b42, b43, b44 = matrix_cell(m2, '_41'), matrix_cell(m2, '_42'), matrix_cell(m2, '_43'), matrix_cell(m2, '_44');

    return {
        _11 = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41,
        _12 = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42,
        _13 = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43,
        _14 = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44,
        _21 = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41,
        _22 = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42,
        _23 = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43,
        _24 = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44,
        _31 = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41,
        _32 = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42,
        _33 = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43,
        _34 = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44,
        _41 = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41,
        _42 = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42,
        _43 = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43,
        _44 = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44,
    };
end

local function vec4_transform(v, m)
    return {
        x = m._11 * v.x + m._21 * v.y + m._31 * v.z + m._41 * v.w,
        y = m._12 * v.x + m._22 * v.y + m._32 * v.z + m._42 * v.w,
        z = m._13 * v.x + m._23 * v.y + m._33 * v.z + m._43 * v.w,
        w = m._14 * v.x + m._24 * v.y + m._34 * v.z + m._44 * v.w,
    };
end

local function read_projection_context()
    if (ffi == nil or C == nil) then
        return nil;
    end

    local device = get_d3d_device();
    if (device == nil) then
        return nil;
    end

    local transform_view = safe_read(function () return C.D3DTS_VIEW; end, nil);
    local transform_projection = safe_read(function () return C.D3DTS_PROJECTION; end, nil);
    if (transform_view == nil or transform_projection == nil) then
        return nil;
    end

    local viewport = safe_read(function ()
        local _, vp = device:GetViewport();
        return vp;
    end, nil);
    local view = safe_read(function ()
        local _, value = device:GetTransform(transform_view);
        return value;
    end, nil);
    local projection = safe_read(function ()
        local _, value = device:GetTransform(transform_projection);
        return value;
    end, nil);

    if (viewport == nil or view == nil or projection == nil) then
        return nil;
    end

    return {
        width = tonumber(viewport.Width) or 0,
        height = tonumber(viewport.Height) or 0,
        view = view,
        projection = projection,
    };
end

local function capture_projection_context()
    local context = read_projection_context();
    if (context ~= nil and context.width > 0 and context.height > 0) then
        state.projection_context = context;
    end
end

local function projection_context()
    return state.projection_context or read_projection_context();
end

local function world_to_screen(x, y, z, context)
    local view_projection = matrix_multiply(context.view, context.projection);
    local point = ffi.new('D3DXVECTOR4', { x, y, z, 1 });
    local camera = vec4_transform(point, view_projection);

    if (camera.w == nil or math.abs(camera.w) < 0.0001) then
        return nil;
    end

    local rhw = 1 / camera.w;
    local ndc_x = camera.x * rhw;
    local ndc_y = camera.y * rhw;
    local ndc_z = camera.z * rhw;

    if (ndc_z < 0 or ndc_z > 1) then
        return nil;
    end

    local screen_x = math.floor((ndc_x + 1) * 0.5 * context.width);
    local screen_y = math.floor((1 - ndc_y) * 0.5 * context.height);

    if (screen_x < -160 or screen_x > context.width + 160 or screen_y < -80 or screen_y > context.height + 80) then
        return nil;
    end

    return screen_x, screen_y, ndc_z;
end

local function entity_screen_position(entity, index, context)
    local local_x = safe_read(function () return entity:GetLocalPositionX(index); end, nil);
    local local_y = safe_read(function () return entity:GetLocalPositionY(index); end, nil);
    local local_z = safe_read(function () return entity:GetLocalPositionZ(index); end, nil);

    if (local_x == nil or local_y == nil or local_z == nil) then
        return nil;
    end

    return world_to_screen(local_x, local_z - state.settings.nameplate_y_offset, local_y, context);
end

local function has_visible_render_flag(entity, index)
    local flags = safe_read(function () return entity:GetRenderFlags0(index); end, 0);
    return bit.band(flags, 0x200) == 0x200 and bit.band(flags, 0x4000) == 0;
end

local function is_nameplate_entity(entity, index)
    local entity_type = safe_read(function () return entity:GetType(index); end, nil);
    if (entity_type ~= 0 and entity_type ~= 1 and entity_type ~= 2) then
        return false;
    end

    local spawn_flags = safe_read(function () return entity:GetSpawnFlags(index); end, 0);
    return bit.band(spawn_flags, 0x01) ~= 0
        or bit.band(spawn_flags, 0x02) ~= 0
        or bit.band(spawn_flags, 0x10) ~= 0;
end

local function active_target_index(memory)
    local target = safe_read(function () return memory:GetTarget(); end, nil);
    if (target == nil) then
        return 0;
    end

    local primary_index = safe_read(function () return target:GetTargetIndex(0); end, 0);
    local sub_index = safe_read(function () return target:GetTargetIndex(1); end, 0);
    local is_sub_target_active = truthy(safe_read(function () return target:GetIsSubTargetActive(); end, false));
    return is_sub_target_active and sub_index or primary_index;
end

local function party_target_lookup(party)
    local result = { };
    for index = 0, 17, 1 do
        local active = truthy(safe_read(function () return party:GetMemberIsActive(index); end, false));
        if (active) then
            local target_index = safe_read(function () return party:GetMemberTargetIndex(index); end, 0);
            if (target_index ~= nil and target_index > 0) then
                result[target_index] = true;
            end
        end
    end

    return result;
end

local function nameplate_color(plate)
    if (plate.is_target) then
        return COLORS.nameplate_target;
    end
    if (plate.is_party) then
        return COLORS.nameplate_party;
    end
    if (plate.claim_status ~= nil and plate.claim_status ~= 0) then
        return COLORS.nameplate_claimed;
    end

    return COLORS.nameplate_neutral;
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

    local locked = settings.locked and not state.config_visible[1];
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

local function collect_nameplates(context)
    local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
    if (memory == nil or context == nil) then
        return { };
    end

    local entity = safe_read(function () return memory:GetEntity(); end, nil);
    local party = safe_read(function () return memory:GetParty(); end, nil);
    if (entity == nil or party == nil) then
        return { };
    end

    local self_index = safe_read(function () return party:GetMemberTargetIndex(0); end, 0);
    local target_index = active_target_index(memory);
    local party_lookup = party_target_lookup(party);
    local max_distance = state.settings.nameplate_max_distance;
    local map_size = safe_read(function () return entity:GetEntityMapSize(); end, 0);
    local scan_max = math.min(map_size, 0x900);
    local plates = { };

    for index = 0, scan_max, 1 do
        if (index ~= self_index or state.settings.nameplate_show_self) then
            local name = clean_string(safe_read(function () return entity:GetName(index); end, ''));
            local server_id = safe_read(function () return entity:GetServerId(index); end, 0);

            if (#name > 0 and server_id ~= 0 and has_visible_render_flag(entity, index) and is_nameplate_entity(entity, index)) then
                local distance = entity_distance(entity, index);
                if (distance ~= nil and distance <= max_distance) then
                    local screen_x, screen_y, depth = entity_screen_position(entity, index, context);
                    if (screen_x ~= nil and screen_y ~= nil) then
                        table.insert(plates, {
                            index = index,
                            name = name,
                            screen_x = screen_x,
                            screen_y = screen_y,
                            depth = depth,
                            distance = distance,
                            hp_pct = safe_read(function () return entity:GetHPPercent(index); end, nil),
                            claim_status = safe_read(function () return entity:GetClaimStatus(index); end, 0),
                            is_target = index == target_index,
                            is_party = party_lookup[index] == true,
                        });
                    end
                end
            end
        end
    end

    table.sort(plates, function (a, b)
        return (a.distance or 0) > (b.distance or 0);
    end);

    while (#plates > state.settings.nameplate_max_count) do
        table.remove(plates, 1);
    end

    return plates;
end

local function draw_nameplate(draw_list, plate)
    local settings = state.settings;
    local distance_scale = 1.0;
    if (settings.nameplate_scale_by_distance) then
        distance_scale = clamp(1.12 - ((plate.distance or 0) / math.max(settings.nameplate_max_distance, 1)) * 0.42, 0.64, 1.12);
    end

    local width = math.floor(settings.nameplate_width * distance_scale);
    local height = math.floor(settings.nameplate_height * distance_scale);
    local alpha = (settings.opacity / 100) * clamp(1.10 - ((plate.distance or 0) / math.max(settings.nameplate_max_distance, 1)) * 0.35, 0.48, 1.0);
    local hp = percent_value(plate.hp_pct);
    local fill_color = nameplate_color(plate);
    if (hp ~= nil and hp <= 35) then
        fill_color = COLORS.hp_low;
    end

    local x = math.floor(plate.screen_x - (width / 2));
    local y = math.floor(plate.screen_y);
    local fill_width = hp ~= nil and math.floor(width * (hp / 100)) or width;
    local border = plate.is_target and COLORS.nameplate_target or COLORS.shadow;

    if (settings.nameplate_show_names) then
        local label = fit_text(plate.name, math.max(width + 42, 72));
        local text_width = calc_text_width(label);
        draw_text(draw_list, math.floor(plate.screen_x - (text_width / 2)), y - 14, apply_alpha(COLORS.text, alpha), label);
    end

    draw_list:AddRectFilled({ x - 1, y - 1 }, { x + width + 1, y + height + 1 }, color_u32(apply_alpha(COLORS.shadow, alpha * 0.72)), 2.0);
    draw_list:AddRectFilled({ x, y }, { x + width, y + height }, color_u32(apply_alpha(COLORS.bar_empty, alpha)), 2.0);
    draw_list:AddRectFilled({ x, y }, { x + fill_width, y + height }, color_u32(apply_alpha(fill_color, alpha)), 2.0);
    draw_list:AddRect({ x, y }, { x + width, y + height }, color_u32(apply_alpha(border, plate.is_target and alpha or alpha * 0.34)), 2.0, ImDrawCornerFlags_All, plate.is_target and 2.0 or 1.0);

    if (plate.is_party) then
        draw_list:AddRectFilled({ x - 3, y + 1 }, { x - 1, y + height - 1 }, color_u32(apply_alpha(COLORS.nameplate_party, alpha)), 1.0);
    end
end

local function render_nameplates()
    if (not state.settings.show_nameplates) then
        state.last_nameplate_count = 0;
        return;
    end

    local context = projection_context();
    if (context == nil or context.width <= 0 or context.height <= 0) then
        state.projection_error = 'Direct3D projection context is unavailable.';
        state.last_nameplate_count = 0;
        return;
    end

    state.projection_error = nil;
    local plates = collect_nameplates(context);
    state.last_nameplate_count = #plates;
    if (#plates == 0) then
        return;
    end

    state.nameplate_overlay_open[1] = true;
    imgui.SetNextWindowPos({ 0, 0 }, ImGuiCond_Always);
    imgui.SetNextWindowSize({ context.width, context.height }, ImGuiCond_Always);
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { 0, 0 });
    imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0);
    imgui.PushStyleColor(ImGuiCol_WindowBg, { 0, 0, 0, 0 });

    if (imgui.Begin('AshitaFrames Nameplates###AshitaFramesNameplates', state.nameplate_overlay_open, NAMEPLATE_WINDOW_FLAGS)) then
        local draw_list = imgui.GetWindowDrawList();
        for _, plate in ipairs(plates) do
            draw_nameplate(draw_list, plate);
        end
    end

    imgui.End();
    imgui.PopStyleColor(1);
    imgui.PopStyleVar(2);
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

        local show_nameplates = state.settings.show_nameplates == true;
        if (imgui.Checkbox('Overhead Bars##ashitaframes_show_nameplates', { show_nameplates })) then
            state.settings.show_nameplates = not show_nameplates;
        end

        local show_alliance = state.settings.show_alliance == true;
        if (imgui.Checkbox('Alliance Slots##ashitaframes_show_alliance', { show_alliance })) then
            state.settings.show_alliance = not show_alliance;
        end

        local same_zone_dim = state.settings.same_zone_dim == true;
        if (imgui.Checkbox('Dim Different Zone##ashitaframes_same_zone_dim', { same_zone_dim })) then
            state.settings.same_zone_dim = not same_zone_dim;
        end

        local nameplate_names = state.settings.nameplate_show_names == true;
        if (imgui.Checkbox('Overhead Names##ashitaframes_nameplate_names', { nameplate_names })) then
            state.settings.nameplate_show_names = not nameplate_names;
        end

        local nameplate_self = state.settings.nameplate_show_self == true;
        if (imgui.Checkbox('Self Overhead Bar##ashitaframes_nameplate_self', { nameplate_self })) then
            state.settings.nameplate_show_self = not nameplate_self;
        end

        local nameplate_scale = state.settings.nameplate_scale_by_distance == true;
        if (imgui.Checkbox('Scale Overhead Bars##ashitaframes_nameplate_scale', { nameplate_scale })) then
            state.settings.nameplate_scale_by_distance = not nameplate_scale;
        end

        imgui.Separator();
        imgui.TextColored(COLORS.accent, 'Layout');
        render_int_control('Frame Width', 'frame_width', state.settings.frame_width, LIMITS.width_min, LIMITS.width_max, function (value)
            state.settings.frame_width = clamp_int(value, LIMITS.width_min, LIMITS.width_max);
        end);
        render_int_control('Row Height', 'row_height', state.settings.row_height, LIMITS.row_height_min, LIMITS.row_height_max, function (value)
            state.settings.row_height = clamp_int(value, LIMITS.row_height_min, LIMITS.row_height_max);
        end);
        render_int_control('Row Gap', 'row_gap', state.settings.row_gap, LIMITS.row_gap_min, LIMITS.row_gap_max, function (value)
            state.settings.row_gap = clamp_int(value, LIMITS.row_gap_min, LIMITS.row_gap_max);
        end);
        render_int_control('Opacity', 'opacity', state.settings.opacity, LIMITS.opacity_min, LIMITS.opacity_max, function (value)
            state.settings.opacity = clamp_int(value, LIMITS.opacity_min, LIMITS.opacity_max);
        end, '%');

        imgui.Separator();
        imgui.TextColored(COLORS.accent, 'Overhead Bars');
        render_int_control('Max Distance', 'nameplate_distance', state.settings.nameplate_max_distance, LIMITS.nameplate_distance_min, LIMITS.nameplate_distance_max, function (value)
            state.settings.nameplate_max_distance = clamp_int(value, LIMITS.nameplate_distance_min, LIMITS.nameplate_distance_max);
        end, 'yalm');
        render_int_control('Max Bars', 'nameplate_count', state.settings.nameplate_max_count, LIMITS.nameplate_count_min, LIMITS.nameplate_count_max, function (value)
            state.settings.nameplate_max_count = clamp_int(value, LIMITS.nameplate_count_min, LIMITS.nameplate_count_max);
        end, 'bars');
        render_int_control('Bar Width', 'nameplate_width', state.settings.nameplate_width, LIMITS.nameplate_width_min, LIMITS.nameplate_width_max, function (value)
            state.settings.nameplate_width = clamp_int(value, LIMITS.nameplate_width_min, LIMITS.nameplate_width_max);
        end);
        render_int_control('Bar Height', 'nameplate_height', state.settings.nameplate_height, LIMITS.nameplate_height_min, LIMITS.nameplate_height_max, function (value)
            state.settings.nameplate_height = clamp_int(value, LIMITS.nameplate_height_min, LIMITS.nameplate_height_max);
        end);

        imgui.Separator();
        imgui.Text(('Party pos: %d, %d'):fmt(state.party_window_x, state.party_window_y));
        imgui.Text(('Target pos: %d, %d'):fmt(state.target_window_x, state.target_window_y));
        imgui.Text(('Overhead bars: %d'):fmt(state.last_nameplate_count));
        imgui.Text('Runtime changes are not persisted yet.');

        if (state.config_error ~= nil) then
            imgui.Separator();
            imgui.TextColored(COLORS.warning, 'Config load warning:');
            imgui.TextWrapped(state.config_error);
        end

        if (state.projection_error ~= nil) then
            imgui.Separator();
            imgui.TextColored(COLORS.warning, 'Overhead bar warning:');
            imgui.TextWrapped(state.projection_error);
        end
    end

    imgui.End();
end

local function print_help()
    log_info('Commands:');
    print(chat.header(addon.name):append(chat.message('/ashitaframes show | hide | toggle')));
    print(chat.header(addon.name):append(chat.message('/ashitaframes plates on | off | toggle | names')));
    print(chat.header(addon.name):append(chat.message('/ashitaframes lock | unlock | config')));
    print(chat.header(addon.name):append(chat.message('/ashitaframes reload | status')));
end

local function print_status()
    log_info(('visible=%s locked=%s target=%s party=%s nameplates=%s alliance=%s width=%d rowHeight=%d opacity=%d plates=%d/%d maxDistance=%d party=(%d,%d) target=(%d,%d)'):fmt(
        tostring(state.visible[1] == true),
        tostring(state.settings.locked == true),
        tostring(state.settings.show_target == true),
        tostring(state.settings.show_party == true),
        tostring(state.settings.show_nameplates == true),
        tostring(state.settings.show_alliance == true),
        state.settings.frame_width,
        state.settings.row_height,
        state.settings.opacity,
        state.last_nameplate_count,
        state.settings.nameplate_max_count,
        state.settings.nameplate_max_distance,
        state.party_window_x,
        state.party_window_y,
        state.target_window_x,
        state.target_window_y));

    if (state.config_error ~= nil) then
        log_error('Config load warning: ' .. state.config_error);
    end
    if (state.projection_error ~= nil) then
        log_error('Overhead bar warning: ' .. state.projection_error);
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

    if (action == 'plates' or action == 'nameplates') then
        local mode = clean_string(args[3]):lower();
        if (mode == 'on' or mode == 'show') then
            state.settings.show_nameplates = true;
        elseif (mode == 'off' or mode == 'hide') then
            state.settings.show_nameplates = false;
        elseif (mode == 'toggle' or mode == '') then
            state.settings.show_nameplates = not state.settings.show_nameplates;
        elseif (mode == 'names') then
            state.settings.nameplate_show_names = not state.settings.nameplate_show_names;
        else
            print_help();
        end
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

ashita.events.register('d3d_beginscene', 'beginscene_cb', function (is_rendering_back_buffer)
    if (is_rendering_back_buffer) then
        capture_projection_context();
    end
end);

ashita.events.register('d3d_present', 'present_cb', function ()
    if (not state.visible[1]) then
        render_config_window();
        return;
    end

    render_nameplates();
    render_target();
    render_party();
    render_config_window();
end);

