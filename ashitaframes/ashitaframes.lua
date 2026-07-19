addon.name      = 'ashitaframes';
addon.author    = 'EflfK';
addon.version   = '0.3.25';
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

local JOB_ORDER = {
    'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG',
    'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN',
};

local DEFAULT_SETTINGS = {
    visible = true,
    locked = false,
    show_self = true,
    show_target = true,
    show_party = true,
    show_pet = true,
    show_alliance = false,
    show_empty_target = true,
    same_zone_dim = true,
    show_jobs = true,
    show_percent = true,
    show_mp = true,
    show_tp = true,
    show_buffs = true,
    show_buff_reminders = true,
    show_target_debuffs = true,
    show_target_debuff_reminders = true,
    hide_buff_reminders_in_towns = true,
    buff_reminder_suppressed_zone_ids = { },
    max_buffs = 8,
    party_preview_size = 6,
    self_window_x = 36,
    self_window_y = 164,
    party_window_x = 36,
    party_window_y = 362,
    pet_window_x = 36,
    pet_window_y = 230,
    target_window_x = 36,
    target_window_y = 296,
    frame_width = 232,
    height = -1,
    row_height = 56,
    row_gap = 5,
    opacity = 88,
    self_frame_width = -1,
    self_height = -1,
    self_row_height = -1,
    self_row_gap = -1,
    self_opacity = -1,
    self_show_mp = 'default',
    self_show_tp = 'default',
    self_mp_text_threshold = -1,
    self_tp_text_threshold = -1,
    party_frame_width = -1,
    party_height = -1,
    party_row_height = -1,
    party_row_gap = -1,
    party_opacity = -1,
    party_show_mp = 'default',
    party_show_tp = 'default',
    party_mp_text_threshold = -1,
    party_tp_text_threshold = -1,
    party_size_layouts = { },
    pet_frame_width = -1,
    pet_height = -1,
    pet_row_height = -1,
    pet_row_gap = -1,
    pet_opacity = -1,
    pet_show_mp = 'default',
    pet_show_tp = 'default',
    pet_mp_text_threshold = -1,
    pet_tp_text_threshold = -1,
    target_frame_width = -1,
    target_height = -1,
    target_row_height = -1,
    target_row_gap = -1,
    target_opacity = -1,
    target_show_mp = false,
    target_show_tp = false,
    target_mp_text_threshold = -1,
    target_tp_text_threshold = -1,
    buff_reminders = {
        default = {
            enabled = true,
            self = true,
            players = true,
            trusts = true,
            buffs = { 'protect', 'shell' },
        },
        BST = {
            enabled = true,
            self = true,
            players = true,
            trusts = true,
            buffs = { 'protect' },
        },
    },
    target_debuff_reminders = {
        default = {
            enabled = true,
            debuffs = { 'dia', 'paralyze', 'slow' },
        },
    },
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
    buff_active_border = { 0.08, 0.10, 0.10, 0.90 },
    buff_missing_bg = { 0.70, 0.05, 0.03, 0.76 },
    buff_missing_border = { 1.00, 0.10, 0.05, 1.00 },
    buff_missing_flash = { 1.00, 0.94, 0.18, 1.00 },
};

local BUFF_ICON_SIZE = 54;
local BUFF_ICON_GAP = 6;
local OBSERVED_LOG_SEED_MAX_LINES = 12000;
local BUFF_ICON_FILES = {
    protect = 'protect_1.png',
    shell = 'shell_1.png',
};
local BUFF_DEFINITIONS = {
    protect = { id = 40, label = 'Protect', spell = 'Protect', file = BUFF_ICON_FILES.protect },
    shell = { id = 41, label = 'Shell', spell = 'Shell', file = BUFF_ICON_FILES.shell },
};
local TARGET_DEBUFF_DEFINITIONS = {
    dia = {
        id = 134,
        label = 'Dia',
        spell = 'Dia',
        spell_ids = { 23, 24, 25, 26, 27, 33 },
        duration_seconds = 60,
    },
    paralyze = {
        id = 4,
        label = 'Paralyze',
        spell = 'Paralyze',
        spell_ids = { 58, 80 },
        duration_seconds = 120,
    },
    slow = {
        id = 13,
        label = 'Slow',
        spell = 'Slow',
        spell_ids = { 56, 79 },
        duration_seconds = 180,
    },
};
local TARGET_DEBUFF_SPELL_IDS = {
    [23] = 'dia',
    [24] = 'dia',
    [25] = 'dia',
    [26] = 'dia',
    [27] = 'dia',
    [33] = 'dia',
    [58] = 'paralyze',
    [80] = 'paralyze',
    [56] = 'slow',
    [79] = 'slow',
};
local TARGET_DEBUFF_SPELL_DURATIONS = {
    [23] = 60,
    [24] = 120,
    [25] = 180,
    [26] = 180,
    [27] = 180,
    [33] = 60,
    [56] = 180,
    [58] = 120,
    [79] = 180,
    [80] = 120,
};
local TARGET_DEBUFF_STATUS_IDS = {
    [4] = 'paralyze',
    [13] = 'slow',
    [134] = 'dia',
};
local TARGET_DEBUFF_REMINDER_PROFILE_DEFAULT = {
    enabled = true,
    debuffs = { 'dia', 'paralyze', 'slow' },
};
local TARGET_DEBUFF_MONSTER_SPAWN_FLAG = 0x10;
local BUFF_REMINDER_PROFILE_DEFAULT = {
    enabled = true,
    self = true,
    players = true,
    trusts = true,
    buffs = { 'protect', 'shell' },
};
local TOWN_ZONE_IDS = {
    [26]  = true, -- Tavnazian Safehold
    [48]  = true, -- Al Zahbi
    [50]  = true, -- Aht Urhgan Whitegate
    [53]  = true, -- Nashmau
    [230] = true, -- Southern San d'Oria
    [231] = true, -- Northern San d'Oria
    [232] = true, -- Port San d'Oria
    [233] = true, -- Chateau d'Oraguille
    [234] = true, -- Bastok Mines
    [235] = true, -- Bastok Markets
    [236] = true, -- Port Bastok
    [237] = true, -- Metalworks
    [238] = true, -- Windurst Waters
    [239] = true, -- Windurst Walls
    [240] = true, -- Port Windurst
    [241] = true, -- Windurst Woods
    [242] = true, -- Heavens Tower
    [243] = true, -- Ru'Lude Gardens
    [244] = true, -- Upper Jeuno
    [245] = true, -- Lower Jeuno
    [246] = true, -- Port Jeuno
    [247] = true, -- Rabao
    [248] = true, -- Selbina
    [249] = true, -- Mhaura
    [250] = true, -- Kazham
    [252] = true, -- Norg
    [256] = true, -- Western Adoulin
    [257] = true, -- Eastern Adoulin
    [280] = true, -- Mog Garden
    [284] = true, -- Celennia Memorial Library
};

local LIMITS = {
    width_min = 170,
    width_max = 360,
    row_height_min = 32,
    target_row_height_with_debuffs_min = 92,
    party_row_height_with_buffs_min = 92,
    row_height_max = 132,
    row_gap_min = 0,
    row_gap_max = 14,
    max_buffs_min = 1,
    max_buffs_max = 16,
    mp_text_threshold_min = 0,
    mp_text_threshold_max = 100,
    tp_text_threshold_min = 0,
    tp_text_threshold_max = 3000,
    opacity_min = 35,
    opacity_max = 100,
};

local state = {
    settings = { },
    visible = { true },
    config_visible = { false },
    config_error = nil,
    config_save_message = nil,
    config_save_message_color = nil,
    config_job_key = nil,
    config_debuff_job_key = nil,
    buff_name_cache = { },
    buff_icon_cache = { },
    status_icon_cache = { },
    observed_buffs = { },
    observed_target_debuffs = { },
    observed_target_debuff_names = { },
    pending_target_debuff_cast = nil,
    observed_buff_zone_id = nil,
    observed_text_events = 0,
    observed_log_path = nil,
    observed_log_position = 0,
    observed_log_last_check = 0,
    observed_log_events = 0,
    self_window_x = 36,
    self_window_y = 164,
    party_window_x = 36,
    party_window_y = 362,
    pet_window_x = 36,
    pet_window_y = 230,
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

function normalize_frame_width(value, fallback)
    value = tonumber(value);
    if (value == nil or value <= 0) then
        value = fallback;
    end

    return clamp_int(value, LIMITS.width_min, LIMITS.width_max);
end

function normalize_frame_row_height(value, fallback)
    value = tonumber(value);
    if (value == nil or value <= 0) then
        value = fallback;
    end

    return clamp_int(value, LIMITS.row_height_min, LIMITS.row_height_max);
end

function normalize_frame_row_gap(value, fallback)
    value = tonumber(value);
    if (value == nil or value < 0) then
        value = fallback;
    end

    return clamp_int(value, LIMITS.row_gap_min, LIMITS.row_gap_max);
end

function normalize_frame_opacity(value, fallback)
    value = tonumber(value);
    if (value == nil or value <= 0) then
        value = fallback;
    end

    return clamp_int(value, LIMITS.opacity_min, LIMITS.opacity_max);
end

function normalize_frame_bar_enabled(value, fallback)
    if (value == nil or value == 'default') then
        return fallback == true;
    end

    return value ~= false;
end

function normalize_mp_text_threshold(value, fallback)
    value = tonumber(value);
    if (value == nil or value < 0) then
        value = fallback;
    end

    return clamp_int(value, LIMITS.mp_text_threshold_min, LIMITS.mp_text_threshold_max);
end

function normalize_tp_text_threshold(value, fallback)
    value = tonumber(value);
    if (value == nil or value < 0) then
        value = fallback;
    end

    return clamp_int(value, LIMITS.tp_text_threshold_min, LIMITS.tp_text_threshold_max);
end

function apply_frame_bar_options(layout, kind)
    layout.kind = kind;
    layout.show_mp = state.settings[('%s_show_mp'):fmt(kind)] == true;
    layout.show_tp = state.settings[('%s_show_tp'):fmt(kind)] == true;
    layout.mp_text_threshold = state.settings[('%s_mp_text_threshold'):fmt(kind)] or state.settings.mp_text_threshold;
    layout.tp_text_threshold = state.settings[('%s_tp_text_threshold'):fmt(kind)] or state.settings.tp_text_threshold;

    return layout;
end

function frame_layout(kind)
    local settings = state.settings;
    return apply_frame_bar_options({
        width = settings[('%s_frame_width'):fmt(kind)] or settings.frame_width,
        row_height = settings[('%s_height'):fmt(kind)] or settings[('%s_row_height'):fmt(kind)] or settings.height or settings.row_height,
        row_gap = settings[('%s_row_gap'):fmt(kind)] or settings.row_gap,
        opacity = settings[('%s_opacity'):fmt(kind)] or settings.opacity,
    }, kind);
end

function party_size(value)
    return clamp_int(value, 1, 6);
end

function party_display_count_for_size(size)
    return math.max(party_size(size) - 1, 0);
end

function normalize_party_grid_columns(value, size)
    local max_columns = math.max(party_display_count_for_size(size), 1);
    return clamp_int(value, 1, max_columns);
end

function normalize_party_grid_rows(value, size)
    local max_rows = math.max(party_display_count_for_size(size), 1);
    return clamp_int(value, 1, max_rows);
end

function fit_party_grid(layout, size, preserve)
    layout.columns = normalize_party_grid_columns(layout.columns, size);
    layout.rows = normalize_party_grid_rows(layout.rows, size);

    local display_count = party_display_count_for_size(size);
    if (display_count <= 0 or (layout.columns * layout.rows) >= display_count) then
        return layout;
    end

    if (preserve == 'rows') then
        layout.columns = normalize_party_grid_columns(math.ceil(display_count / layout.rows), size);
    else
        layout.rows = normalize_party_grid_rows(math.ceil(display_count / layout.columns), size);
    end

    return layout;
end

function normalize_party_size_layout(layout, size, settings)
    layout = type(layout) == 'table' and layout or { };
    local preserve = (layout.rows ~= nil and layout.columns == nil) and 'rows' or 'columns';

    local result = {
        x = clamp_int(layout.x or layout.window_x or settings.party_window_x, -2000, 4000),
        y = clamp_int(layout.y or layout.window_y or settings.party_window_y, -2000, 4000),
        width = normalize_frame_width(layout.frame_width or layout.width, settings.party_frame_width),
        row_height = normalize_frame_row_height(layout.row_height, settings.party_row_height),
        row_gap = normalize_frame_row_gap(layout.row_gap, settings.party_row_gap),
        opacity = normalize_frame_opacity(layout.opacity, settings.party_opacity),
        columns = normalize_party_grid_columns(layout.columns, size),
        rows = normalize_party_grid_rows(layout.rows, size),
        size = party_size(size),
    };

    return fit_party_grid(result, size, preserve);
end

function normalize_party_size_layouts(layouts, settings)
    layouts = type(layouts) == 'table' and layouts or { };

    local result = { };
    for size = 1, 6, 1 do
        result[size] = normalize_party_size_layout(layouts[size], size, settings);
    end

    return result;
end

function party_layout_for_size(size)
    size = party_size(size);
    if (type(state.settings.party_size_layouts) ~= 'table') then
        state.settings.party_size_layouts = normalize_party_size_layouts(nil, state.settings);
    end
    if (type(state.settings.party_size_layouts[size]) ~= 'table') then
        state.settings.party_size_layouts[size] = normalize_party_size_layout(nil, size, state.settings);
    end

    return apply_frame_bar_options(state.settings.party_size_layouts[size], 'party');
end

function party_size_from_units(units)
    if (type(units) == 'table' and tonumber(units.party_size) ~= nil) then
        return party_size(units.party_size);
    end

    return party_size(type(units) == 'table' and (#units + 1) or 1);
end

function update_party_layout_position(size, x, y)
    local layout = party_layout_for_size(size);
    layout.x = clamp_int(x, -2000, 4000);
    layout.y = clamp_int(y, -2000, 4000);
    state.party_window_x = layout.x;
    state.party_window_y = layout.y;
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

local function compact_name(value)
    return clean_string(value):lower():gsub('%s+', ' ');
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

local function normalize_buff_key(value)
    local key = clean_string(value):lower():gsub('[%s%-]+', '_');
    if (key == 'protect' or key == 'protect_1') then
        return 'protect';
    end
    if (key == 'shell' or key == 'shell_1') then
        return 'shell';
    end

    return BUFF_DEFINITIONS[key] ~= nil and key or nil;
end

local function normalize_target_debuff_key(value)
    local key = clean_string(value):lower():gsub('[%s%-]+', '_');
    if (key == 'dia' or key == 'dia_1') then
        return 'dia';
    end
    if (key == 'paralyze' or key == 'paralysis' or key == 'paralyze_1') then
        return 'paralyze';
    end
    if (key == 'slow' or key == 'slow_1' or key == 'slow_i' or key == 'slow_2' or key == 'slow_ii' or key == 'slowii') then
        return 'slow';
    end

    return TARGET_DEBUFF_DEFINITIONS[key] ~= nil and key or nil;
end

local function append_buff_key(result, seen, value)
    local key = normalize_buff_key(value);
    if (key == nil or seen[key]) then
        return;
    end

    seen[key] = true;
    table.insert(result, key);
end

local function append_target_debuff_key(result, seen, value)
    local key = normalize_target_debuff_key(value);
    if (key == nil or seen[key]) then
        return;
    end

    seen[key] = true;
    table.insert(result, key);
end

local function normalize_buff_list(source)
    local result = { };
    local seen = { };

    if (type(source) ~= 'table') then
        return result;
    end

    for _, value in ipairs(source) do
        append_buff_key(result, seen, value);
    end

    for key, value in pairs(source) do
        if (type(key) == 'string' and value == true) then
            append_buff_key(result, seen, key);
        end
    end

    return result;
end

local function normalize_target_debuff_list(source)
    local result = { };
    local seen = { };

    if (type(source) ~= 'table') then
        return result;
    end

    for _, value in ipairs(source) do
        append_target_debuff_key(result, seen, value);
    end

    for key, value in pairs(source) do
        if (type(key) == 'string' and value == true) then
            append_target_debuff_key(result, seen, key);
        end
    end

    return result;
end

local function copy_buff_list(source)
    local result = { };
    if (type(source) ~= 'table') then
        return result;
    end

    for index = 1, #source, 1 do
        result[index] = source[index];
    end

    return result;
end

local function normalize_job_key(value)
    if (type(value) == 'number') then
        return JOBS[value] or '';
    end

    local numeric = tonumber(value);
    if (numeric ~= nil) then
        return JOBS[numeric] or '';
    end

    return clean_string(value):upper();
end

local function normalize_reminder_profile(source, fallback)
    fallback = fallback or BUFF_REMINDER_PROFILE_DEFAULT;

    local profile = {
        enabled = fallback.enabled == true,
        self = fallback.self ~= false,
        players = fallback.players ~= false,
        trusts = fallback.trusts ~= false,
        buffs = copy_buff_list(fallback.buffs),
    };

    if (type(source) ~= 'table') then
        return profile;
    end

    if (source.enabled ~= nil) then
        profile.enabled = source.enabled == true;
    end
    if (source.self ~= nil) then
        profile.self = source.self == true;
    end
    if (source.players ~= nil) then
        profile.players = source.players == true;
    end
    if (source.trusts ~= nil) then
        profile.trusts = source.trusts == true;
    end

    local buffs = source.buffs or source.required or source.required_buffs;
    if (buffs ~= nil) then
        profile.buffs = normalize_buff_list(buffs);
    end

    return profile;
end

local function normalize_target_debuff_reminder_profile(source, fallback)
    fallback = fallback or TARGET_DEBUFF_REMINDER_PROFILE_DEFAULT;

    local profile = {
        enabled = fallback.enabled == true,
        debuffs = copy_buff_list(fallback.debuffs),
    };

    if (type(source) ~= 'table') then
        return profile;
    end

    if (source.enabled ~= nil) then
        profile.enabled = source.enabled == true;
    end

    local debuffs = source.debuffs or source.required or source.required_debuffs;
    if (debuffs ~= nil) then
        profile.debuffs = normalize_target_debuff_list(debuffs);
    end

    return profile;
end

local function normalize_buff_reminders(source)
    local result = { };
    local default_source = nil;

    if (type(source) == 'table') then
        default_source = source.default;
        if (default_source == nil and (source.enabled ~= nil or source.buffs ~= nil or source.required ~= nil or source.required_buffs ~= nil)) then
            default_source = source;
        end
    end

    result.default = normalize_reminder_profile(default_source, BUFF_REMINDER_PROFILE_DEFAULT);

    if (type(source) ~= 'table') then
        return result;
    end

    for key, value in pairs(source) do
        local job = normalize_job_key(key);
        if (job ~= '' and job ~= 'DEFAULT' and type(value) == 'table') then
            result[job] = normalize_reminder_profile(value, result.default);
        end
    end

    return result;
end

local function normalize_target_debuff_reminders(source)
    local result = { };
    local default_source = nil;

    if (type(source) == 'table') then
        default_source = source.default;
        if (default_source == nil and (source.enabled ~= nil or source.debuffs ~= nil or source.required ~= nil or source.required_debuffs ~= nil)) then
            default_source = source;
        end
    end

    result.default = normalize_target_debuff_reminder_profile(default_source, TARGET_DEBUFF_REMINDER_PROFILE_DEFAULT);

    if (type(source) ~= 'table') then
        return result;
    end

    for key, value in pairs(source) do
        local job = normalize_job_key(key);
        if (job ~= '' and job ~= 'DEFAULT' and type(value) == 'table') then
            result[job] = normalize_target_debuff_reminder_profile(value, result.default);
        end
    end

    return result;
end

local function append_zone_id(result, seen, value)
    local zone_id = tonumber(value);
    if (zone_id == nil) then
        return;
    end

    zone_id = math.floor(zone_id + 0.5);
    if (zone_id <= 0 or seen[zone_id]) then
        return;
    end

    seen[zone_id] = true;
    table.insert(result, zone_id);
end

local function normalize_zone_id_list(source)
    local result = { };
    local seen = { };

    if (type(source) ~= 'table') then
        return result;
    end

    for _, value in ipairs(source) do
        append_zone_id(result, seen, value);
    end

    for key, value in pairs(source) do
        if (value == true) then
            append_zone_id(result, seen, key);
        end
    end

    table.sort(result);
    return result;
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
    settings.show_self = settings.show_self ~= false;
    settings.show_target = settings.show_target ~= false;
    settings.show_party = settings.show_party ~= false;
    settings.show_pet = settings.show_pet ~= false;
    settings.show_alliance = settings.show_alliance == true;
    settings.show_empty_target = settings.show_empty_target ~= false;
    settings.same_zone_dim = settings.same_zone_dim ~= false;
    settings.show_jobs = settings.show_jobs ~= false;
    settings.show_percent = settings.show_percent ~= false;
    settings.show_mp = settings.show_mp ~= false;
    settings.show_tp = settings.show_tp ~= false;
    settings.show_buffs = settings.show_buffs ~= false;
    settings.show_buff_reminders = settings.show_buff_reminders ~= false;
    settings.show_target_debuffs = settings.show_target_debuffs ~= false;
    settings.show_target_debuff_reminders = settings.show_target_debuff_reminders ~= false;
    settings.hide_buff_reminders_in_towns = settings.hide_buff_reminders_in_towns ~= false;

    settings.self_window_x = clamp_int(settings.self_window_x, -2000, 4000);
    settings.self_window_y = clamp_int(settings.self_window_y, -2000, 4000);
    settings.party_window_x = clamp_int(settings.party_window_x, -2000, 4000);
    settings.party_window_y = clamp_int(settings.party_window_y, -2000, 4000);
    settings.pet_window_x = clamp_int(settings.pet_window_x, -2000, 4000);
    settings.pet_window_y = clamp_int(settings.pet_window_y, -2000, 4000);
    settings.target_window_x = clamp_int(settings.target_window_x, -2000, 4000);
    settings.target_window_y = clamp_int(settings.target_window_y, -2000, 4000);
    settings.frame_width = clamp_int(settings.frame_width, LIMITS.width_min, LIMITS.width_max);
    settings.row_height = normalize_frame_row_height(settings.height or settings.row_height, settings.row_height);
    settings.height = settings.row_height;
    settings.row_gap = clamp_int(settings.row_gap, LIMITS.row_gap_min, LIMITS.row_gap_max);
    settings.max_buffs = clamp_int(settings.max_buffs, LIMITS.max_buffs_min, LIMITS.max_buffs_max);
    settings.party_preview_size = party_size(settings.party_preview_size);
    settings.mp_text_threshold = normalize_mp_text_threshold(settings.mp_text_threshold, 1);
    settings.tp_text_threshold = normalize_tp_text_threshold(settings.tp_text_threshold, 1000);
    settings.opacity = clamp_int(settings.opacity, LIMITS.opacity_min, LIMITS.opacity_max);
    settings.self_frame_width = normalize_frame_width(settings.self_frame_width, settings.frame_width);
    settings.self_row_height = normalize_frame_row_height(settings.self_height or settings.self_row_height, settings.row_height);
    settings.self_height = settings.self_row_height;
    settings.self_row_gap = normalize_frame_row_gap(settings.self_row_gap, settings.row_gap);
    settings.self_opacity = normalize_frame_opacity(settings.self_opacity, settings.opacity);
    settings.self_show_mp = normalize_frame_bar_enabled(settings.self_show_mp, settings.show_mp);
    settings.self_show_tp = normalize_frame_bar_enabled(settings.self_show_tp, settings.show_tp);
    settings.self_mp_text_threshold = normalize_mp_text_threshold(settings.self_mp_text_threshold, settings.mp_text_threshold);
    settings.self_tp_text_threshold = normalize_tp_text_threshold(settings.self_tp_text_threshold, settings.tp_text_threshold);
    settings.party_frame_width = normalize_frame_width(settings.party_frame_width, settings.frame_width);
    settings.party_row_height = normalize_frame_row_height(settings.party_height or settings.party_row_height, settings.row_height);
    settings.party_height = settings.party_row_height;
    settings.party_row_gap = normalize_frame_row_gap(settings.party_row_gap, settings.row_gap);
    settings.party_opacity = normalize_frame_opacity(settings.party_opacity, settings.opacity);
    settings.party_show_mp = normalize_frame_bar_enabled(settings.party_show_mp, settings.show_mp);
    settings.party_show_tp = normalize_frame_bar_enabled(settings.party_show_tp, settings.show_tp);
    settings.party_mp_text_threshold = normalize_mp_text_threshold(settings.party_mp_text_threshold, settings.mp_text_threshold);
    settings.party_tp_text_threshold = normalize_tp_text_threshold(settings.party_tp_text_threshold, settings.tp_text_threshold);
    settings.party_size_layouts = normalize_party_size_layouts(settings.party_size_layouts, settings);
    settings.pet_frame_width = normalize_frame_width(settings.pet_frame_width, settings.frame_width);
    settings.pet_row_height = normalize_frame_row_height(settings.pet_height or settings.pet_row_height, settings.row_height);
    settings.pet_height = settings.pet_row_height;
    settings.pet_row_gap = normalize_frame_row_gap(settings.pet_row_gap, settings.row_gap);
    settings.pet_opacity = normalize_frame_opacity(settings.pet_opacity, settings.opacity);
    settings.pet_show_mp = normalize_frame_bar_enabled(settings.pet_show_mp, settings.show_mp);
    settings.pet_show_tp = normalize_frame_bar_enabled(settings.pet_show_tp, settings.show_tp);
    settings.pet_mp_text_threshold = normalize_mp_text_threshold(settings.pet_mp_text_threshold, settings.mp_text_threshold);
    settings.pet_tp_text_threshold = normalize_tp_text_threshold(settings.pet_tp_text_threshold, settings.tp_text_threshold);
    settings.target_frame_width = normalize_frame_width(settings.target_frame_width, settings.frame_width);
    settings.target_row_height = normalize_frame_row_height(settings.target_height or settings.target_row_height, settings.row_height);
    settings.target_height = settings.target_row_height;
    settings.target_row_gap = normalize_frame_row_gap(settings.target_row_gap, settings.row_gap);
    settings.target_opacity = normalize_frame_opacity(settings.target_opacity, settings.opacity);
    settings.target_show_mp = normalize_frame_bar_enabled(settings.target_show_mp, false);
    settings.target_show_tp = normalize_frame_bar_enabled(settings.target_show_tp, false);
    settings.target_mp_text_threshold = normalize_mp_text_threshold(settings.target_mp_text_threshold, settings.mp_text_threshold);
    settings.target_tp_text_threshold = normalize_tp_text_threshold(settings.target_tp_text_threshold, settings.tp_text_threshold);
    settings.buff_reminders = normalize_buff_reminders(settings.buff_reminders);
    settings.target_debuff_reminders = normalize_target_debuff_reminders(settings.target_debuff_reminders);
    settings.buff_reminder_suppressed_zone_ids = normalize_zone_id_list(settings.buff_reminder_suppressed_zone_ids);

    return settings;
end

local function load_config()
    local settings = { };
    for key, value in pairs(DEFAULT_SETTINGS) do
        settings[key] = value;
    end

    state.config_error = nil;
    state.config_save_message = nil;
    state.config_save_message_color = nil;
    package.loaded.ashitaframes_config = nil;

    local ok, config = pcall(require, 'ashitaframes_config');
    if (not ok) then
        state.config_error = tostring(config);
    elseif (type(config) == 'table') then
        overlay_settings(settings, config.settings);
    end

    state.settings = normalize_settings(settings);
    state.visible[1] = state.settings.visible;
    state.self_window_x = state.settings.self_window_x;
    state.self_window_y = state.settings.self_window_y;
    state.party_window_x = state.settings.party_window_x;
    state.party_window_y = state.settings.party_window_y;
    state.pet_window_x = state.settings.pet_window_x;
    state.pet_window_y = state.settings.pet_window_y;
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

function resource_current_value(value)
    local numeric = tonumber(value);
    if (numeric == nil or numeric < 0) then
        return nil;
    end

    return math.floor(numeric + 0.5);
end

function estimate_resource_max(current, percent)
    current = resource_current_value(current);
    percent = percent_value(percent);

    if (current == nil or percent == nil or percent <= 0) then
        return nil;
    end

    local estimated = math.floor(((current * 100) / percent) + 0.5);
    if (estimated < current) then
        estimated = current;
    end

    return estimated;
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

local function party_status_base()
    local pointer_manager = safe_read(function () return AshitaCore:GetPointerManager(); end, nil);
    local pointer = pointer_manager ~= nil and safe_read(function () return pointer_manager:Get('party.statusicons'); end, 0) or 0;
    local base = pointer ~= 0 and safe_read(function () return ashita.memory.read_uint32(pointer); end, 0) or 0;
    if (base == 0) then
        return 0;
    end

    return base;
end

local function party_status_member_ptr(base, member_index)
    member_index = tonumber(member_index);
    if (base == nil or base == 0 or member_index == nil or member_index < 0 or member_index > 4) then
        return 0;
    end

    return base + (0x30 * member_index);
end

local function party_status_row_buffs(member_ptr)
    local result = { };
    local seen = { };

    if (member_ptr == nil or member_ptr == 0) then
        return result;
    end

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

local function party_status_buffs_by_server_id(base, server_id)
    server_id = tonumber(server_id) or 0;
    if (base == 0 or server_id == 0) then
        return nil;
    end

    for member_index = 0, 4, 1 do
        local member_ptr = party_status_member_ptr(base, member_index);
        local player_id = safe_read(function () return ashita.memory.read_uint32(member_ptr); end, 0);
        if (player_id == server_id) then
            return party_status_row_buffs(member_ptr);
        end
    end

    return nil;
end

local function party_status_buffs_by_party_slot(base, party_index)
    party_index = tonumber(party_index) or 0;
    if (base == 0 or party_index < 1 or party_index > 5) then
        return nil;
    end

    return party_status_row_buffs(party_status_member_ptr(base, party_index - 1));
end

local function party_status_buffs(party_index, server_id)
    local base = party_status_base();
    if (base == 0) then
        return { };
    end

    local by_id = party_status_buffs_by_server_id(base, server_id);
    if (by_id ~= nil) then
        return by_id;
    end

    local by_slot = party_status_buffs_by_party_slot(base, party_index);
    if (by_slot ~= nil) then
        return by_slot;
    end

    return { };
end

local function observed_name_key(name)
    name = clean_string(name):lower():gsub('%s+', ' ');
    if (#name == 0) then
        return nil;
    end

    return name;
end

function observed_target_name_key(name)
    name = clean_string(name):lower():gsub('%s+', ' ');
    name = name:gsub('^the%s+', ''):gsub('^an%s+', ''):gsub('^a%s+', '');
    if (#name == 0) then
        return nil;
    end

    return name;
end

local function buff_id_for_key(key)
    key = normalize_buff_key(key);
    local definition = key ~= nil and BUFF_DEFINITIONS[key] or nil;
    return definition ~= nil and tonumber(definition.id) or nil;
end

local function observed_buffs_for_name(name)
    local name_key = observed_name_key(name);
    local entry = name_key ~= nil and state.observed_buffs[name_key] or nil;
    local result = { };
    local seen = { };

    if (type(entry) ~= 'table') then
        return result;
    end

    for key, enabled in pairs(entry) do
        if (enabled == true) then
            append_buff_id(result, seen, buff_id_for_key(key));
        end
    end

    return result;
end

local function merge_buff_lists(primary, secondary)
    local result = { };
    local seen = { };

    for _, value in ipairs(primary or { }) do
        append_buff_id(result, seen, value);
    end

    for _, value in ipairs(secondary or { }) do
        append_buff_id(result, seen, value);
    end

    return result;
end

local function clear_observed_buffs()
    state.observed_buffs = { };
end

local function clear_observed_target_debuffs()
    state.observed_target_debuffs = { };
    state.observed_target_debuff_names = { };
    state.pending_target_debuff_cast = nil;
end

local function target_debuff_id_for_key(key)
    key = normalize_target_debuff_key(key);
    local definition = key ~= nil and TARGET_DEBUFF_DEFINITIONS[key] or nil;
    return definition ~= nil and tonumber(definition.id) or nil;
end

local function prune_observed_target_debuffs()
    local now = os.time();
    for target_id, entry in pairs(state.observed_target_debuffs) do
        if (type(entry) ~= 'table') then
            state.observed_target_debuffs[target_id] = nil;
        else
            local has_active = false;
            for key, value in pairs(entry) do
                if (type(value) ~= 'table' or tonumber(value.expires_at) == nil or value.expires_at <= now) then
                    entry[key] = nil;
                else
                    has_active = true;
                end
            end

            if (not has_active) then
                state.observed_target_debuffs[target_id] = nil;
            end
        end
    end

    for name, entry in pairs(state.observed_target_debuff_names) do
        if (type(entry) ~= 'table') then
            state.observed_target_debuff_names[name] = nil;
        else
            local has_active = false;
            for key, value in pairs(entry) do
                if (type(value) ~= 'table' or tonumber(value.expires_at) == nil or value.expires_at <= now) then
                    entry[key] = nil;
                else
                    has_active = true;
                end
            end

            if (not has_active) then
                state.observed_target_debuff_names[name] = nil;
            end
        end
    end
end

local function observed_target_debuff_key_lookup(server_id)
    prune_observed_target_debuffs();

    local target_id = tonumber(server_id);
    local entry = target_id ~= nil and state.observed_target_debuffs[target_id] or nil;
    local result = { };
    if (type(entry) ~= 'table') then
        return result;
    end

    for key, value in pairs(entry) do
        if (type(value) == 'table' and tonumber(value.expires_at) ~= nil and value.expires_at > os.time()) then
            result[key] = true;
        end
    end

    return result;
end

function observed_target_debuff_name_lookup(name)
    prune_observed_target_debuffs();

    local name_key = observed_target_name_key(name);
    local entry = name_key ~= nil and state.observed_target_debuff_names[name_key] or nil;
    local result = { };
    if (type(entry) ~= 'table') then
        return result;
    end

    for key, value in pairs(entry) do
        if (type(value) == 'table' and tonumber(value.expires_at) ~= nil and value.expires_at > os.time()) then
            result[key] = true;
        end
    end

    return result;
end

function observed_target_debuffs_for_unit(server_id, name)
    local active = observed_target_debuff_key_lookup(server_id);
    for key, enabled in pairs(observed_target_debuff_name_lookup(name)) do
        if (enabled == true) then
            active[key] = true;
        end
    end

    local result = { };
    local seen = { };

    for key, _ in pairs(active) do
        append_buff_id(result, seen, target_debuff_id_for_key(key));
    end

    return result;
end

local function sync_observed_buffs_for_party(party, self_zone)
    local zone_id = tonumber(self_zone);
    if (zone_id ~= nil) then
        zone_id = math.floor(zone_id + 0.5);
        if (state.observed_buff_zone_id ~= nil and state.observed_buff_zone_id ~= zone_id) then
            clear_observed_buffs();
            clear_observed_target_debuffs();
        end
        state.observed_buff_zone_id = zone_id;
    end

    if (party == nil) then
        return;
    end

    local active_names = { };
    for index = 0, 5, 1 do
        local active = truthy(safe_read(function () return party:GetMemberIsActive(index); end, false));
        local name = clean_string(safe_read(function () return party:GetMemberName(index); end, ''));
        local member_zone = safe_read(function () return party:GetMemberZone(index); end, nil);
        local same_zone = self_zone == nil or member_zone == nil or member_zone == self_zone;
        local key = observed_name_key(name);

        if (active and same_zone and key ~= nil) then
            active_names[key] = true;
        end
    end

    for key, _ in pairs(state.observed_buffs) do
        if (active_names[key] ~= true) then
            state.observed_buffs[key] = nil;
        end
    end
end

local function party_member_buffs(party, index, server_id, same_zone, name)
    if (not state.settings.show_buffs or index > 5 or same_zone == false) then
        return { };
    end

    local observed = observed_buffs_for_name(name);
    if (index == 0) then
        return merge_buff_lists(player_buffs(), observed);
    end

    return merge_buff_lists(party_status_buffs(index, server_id), observed);
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

local function load_status_icon(status_id)
    status_id = tonumber(status_id);
    if (status_id == nil or status_id <= 0 or status_id > 0x3FF) then
        return nil;
    end

    if (state.status_icon_cache[status_id] == false) then
        return nil;
    end
    if (state.status_icon_cache[status_id] ~= nil) then
        return state.status_icon_cache[status_id];
    end

    local device = ensure_d3d_device();
    if (device == nil) then
        return nil;
    end

    local resources = safe_read(function () return AshitaCore:GetResourceManager(); end, nil);
    local resource = resources ~= nil and safe_read(function () return resources:GetStatusIconByIndex(status_id); end, nil) or nil;
    if (resource == nil or resource.Bitmap == nil or tonumber(resource.ImageSize) == nil) then
        state.status_icon_cache[status_id] = false;
        return nil;
    end

    local texture_ptr = ffi.new('IDirect3DTexture8*[1]');
    local result = safe_read(function ()
        return ffi.C.D3DXCreateTextureFromFileInMemoryEx(
            device,
            resource.Bitmap,
            resource.ImageSize,
            0xFFFFFFFF,
            0xFFFFFFFF,
            1,
            0,
            ffi.C.D3DFMT_A8R8G8B8,
            ffi.C.D3DPOOL_MANAGED,
            ffi.C.D3DX_DEFAULT,
            ffi.C.D3DX_DEFAULT,
            0xFF000000,
            nil,
            nil,
            texture_ptr);
    end, nil);

    if (result ~= 0 or texture_ptr[0] == nil) then
        state.status_icon_cache[status_id] = false;
        return nil;
    end

    local texture = d3d8.gc_safe_release(ffi.cast('IDirect3DTexture8*', texture_ptr[0]));
    local icon = {
        texture = texture,
        handle = tonumber(ffi.cast('uint32_t', texture)),
    };

    state.status_icon_cache[status_id] = icon;
    return icon;
end

local function buff_key_from_name(name)
    name = clean_string(name):lower();
    if (name:find('protect', 1, true) ~= nil) then
        return 'protect';
    end
    if (name:find('shell', 1, true) ~= nil) then
        return 'shell';
    end

    return nil;
end

local function buff_key_from_id(buff_id)
    return buff_key_from_name(buff_name(buff_id));
end

local function target_debuff_key_from_id(debuff_id)
    return TARGET_DEBUFF_STATUS_IDS[tonumber(debuff_id)];
end

local function active_buff_key_lookup(buffs)
    local lookup = { };
    if (type(buffs) ~= 'table') then
        return lookup;
    end

    for index = 1, #buffs, 1 do
        local key = buff_key_from_id(buffs[index]);
        if (key ~= nil) then
            lookup[key] = true;
        end
    end

    return lookup;
end

local function active_target_debuff_key_lookup(debuffs)
    local lookup = { };
    if (type(debuffs) ~= 'table') then
        return lookup;
    end

    for index = 1, #debuffs, 1 do
        local key = target_debuff_key_from_id(debuffs[index]);
        if (key ~= nil) then
            lookup[key] = true;
        end
    end

    return lookup;
end

local function spell_id(spell)
    if (spell == nil) then
        return nil;
    end

    return tonumber(safe_read(function () return spell.Index; end, safe_read(function () return spell.Id; end, nil)));
end

local function current_player_spell_state()
    local player = safe_read(function () return AshitaCore:GetMemoryManager():GetPlayer(); end, nil);
    if (player == nil) then
        return nil;
    end

    return {
        player = player,
        main_job = safe_read(function () return player:GetMainJob(); end, nil),
        sub_job = safe_read(function () return player:GetSubJob(); end, nil),
        main_level = safe_read(function () return player:GetMainJobLevel(); end, nil),
        sub_level = safe_read(function () return player:GetSubJobLevel(); end, nil),
        has_spell_data = safe_read(function () return player:HasSpellData(); end, false),
    };
end

local function spell_level_required(spell, job_id)
    if (spell == nil or spell.LevelRequired == nil or job_id == nil or job_id <= 0) then
        return nil;
    end

    local level = tonumber(safe_read(function () return spell.LevelRequired[job_id + 1]; end, nil));
    if (level == nil or level < 0 or level > 99) then
        return nil;
    end

    return level;
end

local function spell_usable_for_current_job(spell, spell_state)
    if (spell == nil or spell_state == nil or spell.LevelRequired == nil) then
        return false;
    end

    local main_required = spell_level_required(spell, spell_state.main_job);
    if (main_required ~= nil and spell_state.main_level ~= nil and spell_state.main_level >= main_required) then
        return true;
    end

    local sub_required = spell_level_required(spell, spell_state.sub_job);
    if (sub_required ~= nil and spell_state.sub_level ~= nil and spell_state.sub_level >= sub_required) then
        return true;
    end

    return false;
end

local function spell_available_info(definition)
    if (definition == nil or definition.spell == nil) then
        return nil;
    end

    local spell_state = current_player_spell_state();
    if (spell_state == nil or not truthy(spell_state.has_spell_data)) then
        return nil;
    end

    local resources = safe_read(function () return AshitaCore:GetResourceManager(); end, nil);
    local spell = resources ~= nil and safe_read(function () return resources:GetSpellByName(definition.spell, 0); end, nil) or nil;
    local id = spell_id(spell);
    if (spell == nil or id == nil or not truthy(safe_read(function () return spell_state.player:HasSpell(id); end, false))) then
        return nil;
    end

    if (not spell_usable_for_current_job(spell, spell_state)) then
        return nil;
    end

    return {
        id = id,
        spell = spell,
    };
end

local function reminder_spell_available(key)
    key = normalize_buff_key(key);
    local definition = key ~= nil and BUFF_DEFINITIONS[key] or nil;
    return spell_available_info(definition) ~= nil;
end

local function target_debuff_spell_available(key)
    key = normalize_target_debuff_key(key);
    local definition = key ~= nil and TARGET_DEBUFF_DEFINITIONS[key] or nil;
    return spell_available_info(definition) ~= nil;
end

local function spell_recast_timer(spell_id)
    spell_id = tonumber(spell_id);
    if (spell_id == nil or spell_id <= 0) then
        return 0;
    end

    local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
    local recast = memory ~= nil and safe_read(function () return memory:GetRecast(); end, nil) or nil;
    return recast ~= nil and (tonumber(safe_read(function () return recast:GetSpellTimer(spell_id); end, 0)) or 0) or 0;
end

local function target_debuff_spell_recast_active(key)
    key = normalize_target_debuff_key(key);
    local definition = key ~= nil and TARGET_DEBUFF_DEFINITIONS[key] or nil;
    local info = spell_available_info(definition);
    if (info == nil or info.id == nil) then
        return false;
    end

    return spell_recast_timer(info.id) > 0;
end

local function reminder_profile_for_job(job)
    local reminders = state.settings.buff_reminders;
    if (type(reminders) ~= 'table') then
        return BUFF_REMINDER_PROFILE_DEFAULT;
    end

    return reminders[job] or reminders.default or BUFF_REMINDER_PROFILE_DEFAULT;
end

local function target_debuff_reminder_profile_for_job(job)
    local reminders = state.settings.target_debuff_reminders;
    if (type(reminders) ~= 'table') then
        return TARGET_DEBUFF_REMINDER_PROFILE_DEFAULT;
    end

    job = normalize_job_key(job);
    return reminders[job] or reminders.default or TARGET_DEBUFF_REMINDER_PROFILE_DEFAULT;
end

local function ensure_reminder_profile(job)
    if (type(state.settings.buff_reminders) ~= 'table') then
        state.settings.buff_reminders = normalize_buff_reminders(nil);
    end
    if (type(state.settings.buff_reminders.default) ~= 'table') then
        state.settings.buff_reminders.default = normalize_reminder_profile(nil, BUFF_REMINDER_PROFILE_DEFAULT);
    end

    job = normalize_job_key(job);
    if (#job == 0 or job == 'DEFAULT') then
        return state.settings.buff_reminders.default;
    end

    if (type(state.settings.buff_reminders[job]) ~= 'table') then
        state.settings.buff_reminders[job] = normalize_reminder_profile(nil, state.settings.buff_reminders.default);
    end

    return state.settings.buff_reminders[job];
end

local function ensure_target_debuff_reminder_profile(job)
    if (type(state.settings.target_debuff_reminders) ~= 'table') then
        state.settings.target_debuff_reminders = normalize_target_debuff_reminders(nil);
    end
    if (type(state.settings.target_debuff_reminders.default) ~= 'table') then
        state.settings.target_debuff_reminders.default = normalize_target_debuff_reminder_profile(nil, TARGET_DEBUFF_REMINDER_PROFILE_DEFAULT);
    end

    job = normalize_job_key(job);
    if (#job == 0 or job == 'DEFAULT') then
        return state.settings.target_debuff_reminders.default;
    end

    if (type(state.settings.target_debuff_reminders[job]) ~= 'table') then
        state.settings.target_debuff_reminders[job] = normalize_target_debuff_reminder_profile(nil, state.settings.target_debuff_reminders.default);
    end

    return state.settings.target_debuff_reminders[job];
end

local function buff_list_has(buffs, key)
    key = normalize_buff_key(key);
    if (key == nil or type(buffs) ~= 'table') then
        return false;
    end

    for _, value in ipairs(buffs) do
        if (normalize_buff_key(value) == key) then
            return true;
        end
    end

    return false;
end

local function target_debuff_list_has(debuffs, key)
    key = normalize_target_debuff_key(key);
    if (key == nil or type(debuffs) ~= 'table') then
        return false;
    end

    for _, value in ipairs(debuffs) do
        if (normalize_target_debuff_key(value) == key) then
            return true;
        end
    end

    return false;
end

local function set_profile_buff_enabled(profile, key, enabled)
    if (type(profile) ~= 'table') then
        return;
    end

    key = normalize_buff_key(key);
    if (key == nil) then
        return;
    end

    local result = { };
    local seen = { };
    for _, value in ipairs(profile.buffs or { }) do
        local existing = normalize_buff_key(value);
        if (existing ~= nil and existing ~= key and not seen[existing]) then
            seen[existing] = true;
            table.insert(result, existing);
        end
    end

    if (enabled == true and not seen[key]) then
        table.insert(result, key);
    end

    profile.buffs = result;
end

local function set_profile_target_debuff_enabled(profile, key, enabled)
    if (type(profile) ~= 'table') then
        return;
    end

    key = normalize_target_debuff_key(key);
    if (key == nil) then
        return;
    end

    local result = { };
    local seen = { };
    for _, value in ipairs(profile.debuffs or { }) do
        local existing = normalize_target_debuff_key(value);
        if (existing ~= nil and existing ~= key and not seen[existing]) then
            seen[existing] = true;
            table.insert(result, existing);
        end
    end

    if (enabled == true and not seen[key]) then
        table.insert(result, key);
    end

    profile.debuffs = result;
end

local function unit_reminder_enabled(unit, profile)
    if (unit.same_zone == false or profile.enabled ~= true) then
        return false;
    end
    if (unit.category == 'self') then
        return profile.self == true;
    end
    if (unit.category == 'trust') then
        return profile.trusts == true;
    end

    return profile.players == true;
end

local function reminder_buff_keys(unit)
    if (not state.settings.show_buff_reminders or unit.kind ~= 'party' or unit.reminders_suppressed == true) then
        return { };
    end

    local profile = reminder_profile_for_job(unit.reminder_job or 'default');
    if (not unit_reminder_enabled(unit, profile)) then
        return { };
    end

    local result = { };
    for _, key in ipairs(profile.buffs or { }) do
        if (reminder_spell_available(key)) then
            table.insert(result, normalize_buff_key(key));
        end
    end

    return result;
end

local function target_debuff_suppressed_name(name)
    local value = compact_name(name);
    if (#value == 0) then
        return false;
    end

    if (value == 'armoury crate' or value == 'armory crate' or value == 'sturdy pyxis') then
        return true;
    end

    return value:find('treasure', 1, true) ~= nil
        and (value:find('chest', 1, true) ~= nil or value:find('coffer', 1, true) ~= nil or value:find('casket', 1, true) ~= nil);
end

local function target_debuff_has_monster_spawn_flag(spawn_flags)
    spawn_flags = tonumber(spawn_flags);
    return spawn_flags ~= nil and bit.band(spawn_flags, TARGET_DEBUFF_MONSTER_SPAWN_FLAG) == TARGET_DEBUFF_MONSTER_SPAWN_FLAG;
end

local function target_debuff_target_eligible(unit)
    if (unit == nil or unit.kind ~= 'target' or unit.target_type ~= 2 or target_debuff_suppressed_name(unit.name)) then
        return false;
    end

    if (unit.spawn_flags ~= nil and not target_debuff_has_monster_spawn_flag(unit.spawn_flags)) then
        return false;
    end

    return true;
end

local function target_debuff_reminder_keys(unit)
    if (not state.settings.show_target_debuff_reminders or not target_debuff_target_eligible(unit) or tonumber(unit.server_id) == nil or tonumber(unit.server_id) == 0) then
        return { };
    end

    local profile = target_debuff_reminder_profile_for_job(unit.reminder_job or 'default');
    if (profile.enabled ~= true) then
        return { };
    end

    local result = { };
    for _, key in ipairs(profile.debuffs or { }) do
        key = normalize_target_debuff_key(key);
        if (key ~= nil and target_debuff_spell_available(key) and not target_debuff_spell_recast_active(key)) then
            table.insert(result, key);
        end
    end

    return result;
end

local function buff_icon_items(unit)
    local items = { };
    if (type(unit.buffs) ~= 'table') then
        return items;
    end

    local max_buffs = state.settings.max_buffs or DEFAULT_SETTINGS.max_buffs;
    local active_keys = active_buff_key_lookup(unit.buffs);

    for index = 1, #unit.buffs, 1 do
        if (#items >= max_buffs) then
            break;
        end

        local buff_id = unit.buffs[index];
        local key = buff_key_from_id(buff_id);
        local definition = key ~= nil and BUFF_DEFINITIONS[key] or nil;
        local icon = definition ~= nil and load_buff_icon(definition.file) or nil;
        if (icon ~= nil) then
            table.insert(items, {
                id = buff_id,
                key = key,
                name = buff_name(buff_id),
                handle = icon.handle,
                state = 'active',
            });
        end
    end

    for _, key in ipairs(reminder_buff_keys(unit)) do
        if (#items >= max_buffs) then
            break;
        end

        local definition = BUFF_DEFINITIONS[key];
        local icon = definition ~= nil and load_buff_icon(definition.file) or nil;
        if (icon ~= nil and active_keys[key] ~= true) then
            table.insert(items, {
                key = key,
                name = definition.label,
                handle = icon.handle,
                state = 'missing',
            });
        end
    end

    return items;
end

local function target_debuff_icon_items(unit)
    local items = { };
    if (type(unit.debuffs) ~= 'table') then
        return items;
    end

    local max_buffs = state.settings.max_buffs or DEFAULT_SETTINGS.max_buffs;
    local active_keys = active_target_debuff_key_lookup(unit.debuffs);

    for index = 1, #unit.debuffs, 1 do
        if (#items >= max_buffs) then
            break;
        end

        local debuff_id = unit.debuffs[index];
        local key = target_debuff_key_from_id(debuff_id);
        local definition = key ~= nil and TARGET_DEBUFF_DEFINITIONS[key] or nil;
        local icon = definition ~= nil and load_status_icon(definition.id) or nil;
        if (icon ~= nil) then
            table.insert(items, {
                id = debuff_id,
                key = key,
                name = buff_name(debuff_id),
                handle = icon.handle,
                state = 'active',
                kind = 'debuff',
            });
        end
    end

    for _, key in ipairs(target_debuff_reminder_keys(unit)) do
        if (#items >= max_buffs) then
            break;
        end

        local definition = TARGET_DEBUFF_DEFINITIONS[key];
        local icon = definition ~= nil and load_status_icon(definition.id) or nil;
        if (icon ~= nil and active_keys[key] ~= true) then
            table.insert(items, {
                key = key,
                name = definition.label,
                handle = icon.handle,
                state = 'missing',
                kind = 'debuff',
            });
        end
    end

    return items;
end

local function current_player_job_key(party)
    if (party == nil) then
        local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
        party = memory ~= nil and safe_read(function () return memory:GetParty(); end, nil) or nil;
    end

    if (party == nil) then
        return 'default';
    end

    local job_id = safe_read(function () return party:GetMemberMainJob(0); end, nil);
    local job = normalize_job_key(job_id);
    return #job > 0 and job or 'default';
end

local function current_player_zone_id(party)
    if (party == nil) then
        local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
        party = memory ~= nil and safe_read(function () return memory:GetParty(); end, nil) or nil;
    end

    if (party == nil) then
        return nil;
    end

    return tonumber(safe_read(function () return party:GetMemberZone(0); end, nil));
end

local function zone_name(zone_id)
    zone_id = tonumber(zone_id);
    if (zone_id == nil) then
        return 'Unknown';
    end

    local resources = safe_read(function () return AshitaCore:GetResourceManager(); end, nil);
    local name = resources ~= nil and clean_string(safe_read(function () return resources:GetString('zones.names', zone_id); end, '')) or '';
    if (#name == 0) then
        return ('Zone %d'):fmt(zone_id);
    end

    return name;
end

local function zone_list_has(zone_ids, zone_id)
    zone_id = tonumber(zone_id);
    if (zone_id == nil or type(zone_ids) ~= 'table') then
        return false;
    end

    zone_id = math.floor(zone_id + 0.5);
    for _, value in ipairs(zone_ids) do
        if (value == zone_id) then
            return true;
        end
    end

    return false;
end

local function set_zone_suppressed(zone_id, suppressed)
    zone_id = tonumber(zone_id);
    if (zone_id == nil or zone_id <= 0) then
        return;
    end

    zone_id = math.floor(zone_id + 0.5);
    local result = { };
    local seen = { };

    for _, value in ipairs(state.settings.buff_reminder_suppressed_zone_ids or { }) do
        if (value ~= zone_id) then
            append_zone_id(result, seen, value);
        end
    end

    if (suppressed == true) then
        append_zone_id(result, seen, zone_id);
    end

    state.settings.buff_reminder_suppressed_zone_ids = result;
end

local function buff_reminders_suppressed_for_zone(zone_id)
    zone_id = tonumber(zone_id);
    if (zone_id == nil) then
        return false;
    end

    zone_id = math.floor(zone_id + 0.5);
    if (state.settings.hide_buff_reminders_in_towns and TOWN_ZONE_IDS[zone_id] == true) then
        return true;
    end

    return zone_list_has(state.settings.buff_reminder_suppressed_zone_ids, zone_id);
end

local function party_member_category(index, target_index, server_id)
    if (index == 0) then
        return 'self';
    end

    if (target_index ~= nil and target_index ~= 0) then
        local entity = safe_read(function () return GetEntity(target_index); end, nil);
        local entity_type = entity ~= nil and entity.Type or nil;
        local trust_owner = entity ~= nil and entity.TrustOwnerTargetIndex or nil;
        if (entity_type == 8 or (trust_owner ~= nil and trust_owner ~= 0)) then
            return 'trust';
        end
    end

    -- Trust server ids are zone entity ids, unlike player ids. When zoning,
    -- Ashita can retain those stale trust ids even after the actors despawn.
    server_id = tonumber(server_id) or 0;
    if (server_id >= 0x01000000) then
        return 'trust';
    end

    return 'player';
end

local function mark_config_changed()
    state.config_save_message = nil;
    state.config_save_message_color = nil;
end

local function job_order_index(job)
    job = normalize_job_key(job);
    for index, value in ipairs(JOB_ORDER) do
        if (value == job) then
            return index;
        end
    end

    return 1;
end

local function current_config_job_key()
    local current_job = current_player_job_key();
    if (current_job == 'default') then
        current_job = 'BST';
    end

    local selected = normalize_job_key(state.config_job_key);
    if (#selected == 0) then
        selected = current_job;
    end

    state.config_job_key = selected;
    return selected;
end

local function step_config_job(delta)
    local index = job_order_index(current_config_job_key());
    index = ((index - 1 + delta) % #JOB_ORDER) + 1;
    state.config_job_key = JOB_ORDER[index];
    mark_config_changed();
end

local function current_config_debuff_job_key()
    local current_job = current_player_job_key();
    if (current_job == 'default') then
        current_job = 'BST';
    end

    local selected = normalize_job_key(state.config_debuff_job_key);
    if (#selected == 0) then
        selected = current_job;
    end

    state.config_debuff_job_key = selected;
    return selected;
end

local function step_config_debuff_job(delta)
    local index = job_order_index(current_config_debuff_job_key());
    index = ((index - 1 + delta) % #JOB_ORDER) + 1;
    state.config_debuff_job_key = JOB_ORDER[index];
    mark_config_changed();
end

local function path_join(left, right)
    left = tostring(left or '');
    right = tostring(right or '');
    if (#left == 0) then
        return right;
    end

    local last = left:sub(#left);
    if (last == '\\' or last == '/') then
        return left .. right;
    end

    return left .. '\\' .. right;
end

local function config_file_path()
    return path_join(addon.path, 'ashitaframes_config.lua');
end

local function bool_text(value)
    return value == true and 'true' or 'false';
end

local function buff_list_text(buffs)
    local normalized = normalize_buff_list(buffs);
    if (#normalized == 0) then
        return '{ }';
    end

    local pieces = { };
    for _, key in ipairs(normalized) do
        table.insert(pieces, ("'%s'"):fmt(key));
    end

    return ('{ %s }'):fmt(table.concat(pieces, ', '));
end

local function target_debuff_list_text(debuffs)
    local normalized = normalize_target_debuff_list(debuffs);
    if (#normalized == 0) then
        return '{ }';
    end

    local pieces = { };
    for _, key in ipairs(normalized) do
        table.insert(pieces, ("'%s'"):fmt(key));
    end

    return ('{ %s }'):fmt(table.concat(pieces, ', '));
end

local function zone_id_list_text(zone_ids)
    local normalized = normalize_zone_id_list(zone_ids);
    if (#normalized == 0) then
        return '{ }';
    end

    local pieces = { };
    for _, zone_id in ipairs(normalized) do
        table.insert(pieces, tostring(zone_id));
    end

    return ('{ %s }'):fmt(table.concat(pieces, ', '));
end

local function config_key_text(key)
    if (key == 'default' or key:match('^%a[%w_]*$') ~= nil) then
        return key;
    end

    return ('[%q]'):fmt(key);
end

local function reminder_profile_keys(reminders)
    local keys = { 'default' };
    local seen = { default = true };

    for _, job in ipairs(JOB_ORDER) do
        if (type(reminders[job]) == 'table') then
            table.insert(keys, job);
            seen[job] = true;
        end
    end

    local extra = { };
    for key, value in pairs(reminders) do
        if (type(key) == 'string' and not seen[key] and type(value) == 'table') then
            table.insert(extra, key);
        end
    end
    table.sort(extra);

    for _, key in ipairs(extra) do
        table.insert(keys, key);
    end

    return keys;
end

local function append_profile_config(lines, key, profile)
    profile = normalize_reminder_profile(profile, state.settings.buff_reminders.default);

    table.insert(lines, ('            %s = {'):fmt(config_key_text(key)));
    table.insert(lines, ('                enabled = %s,'):fmt(bool_text(profile.enabled)));
    table.insert(lines, ('                self = %s,'):fmt(bool_text(profile.self)));
    table.insert(lines, ('                players = %s,'):fmt(bool_text(profile.players)));
    table.insert(lines, ('                trusts = %s,'):fmt(bool_text(profile.trusts)));
    table.insert(lines, ('                buffs = %s,'):fmt(buff_list_text(profile.buffs)));
    table.insert(lines, '            },');
end

local function append_target_debuff_profile_config(lines, key, profile)
    profile = normalize_target_debuff_reminder_profile(profile, state.settings.target_debuff_reminders.default);

    table.insert(lines, ('            %s = {'):fmt(config_key_text(key)));
    table.insert(lines, ('                enabled = %s,'):fmt(bool_text(profile.enabled)));
    table.insert(lines, ('                debuffs = %s,'):fmt(target_debuff_list_text(profile.debuffs)));
    table.insert(lines, '            },');
end

function append_party_size_layout_config(lines, size, layout)
    layout = normalize_party_size_layout(layout, size, state.settings);

    table.insert(lines, ('            [%d] = { x = %d, y = %d, frame_width = %d, row_height = %d, row_gap = %d, opacity = %d, columns = %d, rows = %d },'):fmt(
        size,
        layout.x,
        layout.y,
        layout.width,
        layout.row_height,
        layout.row_gap,
        layout.opacity,
        layout.columns,
        layout.rows));
end

local function capture_runtime_settings_for_save()
    state.settings.visible = state.visible[1] == true;
    state.settings.self_window_x = state.self_window_x;
    state.settings.self_window_y = state.self_window_y;
    state.settings.party_window_x = state.party_window_x;
    state.settings.party_window_y = state.party_window_y;
    state.settings.pet_window_x = state.pet_window_x;
    state.settings.pet_window_y = state.pet_window_y;
    state.settings.target_window_x = state.target_window_x;
    state.settings.target_window_y = state.target_window_y;
    state.settings.party_size_layouts = normalize_party_size_layouts(state.settings.party_size_layouts, state.settings);
    state.settings.buff_reminders = normalize_buff_reminders(state.settings.buff_reminders);
    state.settings.target_debuff_reminders = normalize_target_debuff_reminders(state.settings.target_debuff_reminders);
    state.settings.buff_reminder_suppressed_zone_ids = normalize_zone_id_list(state.settings.buff_reminder_suppressed_zone_ids);

    return normalize_settings(state.settings);
end

local function config_text_from_settings(settings)
    local reminders = settings.buff_reminders or normalize_buff_reminders(nil);
    local target_debuff_reminders = settings.target_debuff_reminders or normalize_target_debuff_reminders(nil);
    local lines = {
        'return {',
        '    settings = {',
        ('        visible = %s,'):fmt(bool_text(settings.visible)),
        ('        locked = %s,'):fmt(bool_text(settings.locked)),
        '',
        ('        show_self = %s,'):fmt(bool_text(settings.show_self)),
        ('        show_target = %s,'):fmt(bool_text(settings.show_target)),
        ('        show_party = %s,'):fmt(bool_text(settings.show_party)),
        ('        show_pet = %s,'):fmt(bool_text(settings.show_pet)),
        ('        show_alliance = %s,'):fmt(bool_text(settings.show_alliance)),
        ('        show_empty_target = %s,'):fmt(bool_text(settings.show_empty_target)),
        '',
        ('        same_zone_dim = %s,'):fmt(bool_text(settings.same_zone_dim)),
        ('        show_jobs = %s,'):fmt(bool_text(settings.show_jobs)),
        ('        show_percent = %s,'):fmt(bool_text(settings.show_percent)),
        ('        show_mp = %s,'):fmt(bool_text(settings.show_mp)),
        ('        show_tp = %s,'):fmt(bool_text(settings.show_tp)),
        ('        show_buffs = %s,'):fmt(bool_text(settings.show_buffs)),
        ('        show_buff_reminders = %s,'):fmt(bool_text(settings.show_buff_reminders)),
        ('        show_target_debuffs = %s,'):fmt(bool_text(settings.show_target_debuffs)),
        ('        show_target_debuff_reminders = %s,'):fmt(bool_text(settings.show_target_debuff_reminders)),
        ('        hide_buff_reminders_in_towns = %s,'):fmt(bool_text(settings.hide_buff_reminders_in_towns)),
        ('        buff_reminder_suppressed_zone_ids = %s,'):fmt(zone_id_list_text(settings.buff_reminder_suppressed_zone_ids)),
        ('        max_buffs = %d,'):fmt(settings.max_buffs),
        ('        party_preview_size = %d,'):fmt(settings.party_preview_size),
        ('        mp_text_threshold = %d,'):fmt(settings.mp_text_threshold),
        ('        tp_text_threshold = %d,'):fmt(settings.tp_text_threshold),
        '',
        ('        self_window_x = %d,'):fmt(state.self_window_x),
        ('        self_window_y = %d,'):fmt(state.self_window_y),
        ('        party_window_x = %d,'):fmt(state.party_window_x),
        ('        party_window_y = %d,'):fmt(state.party_window_y),
        ('        pet_window_x = %d,'):fmt(state.pet_window_x),
        ('        pet_window_y = %d,'):fmt(state.pet_window_y),
        ('        target_window_x = %d,'):fmt(state.target_window_x),
        ('        target_window_y = %d,'):fmt(state.target_window_y),
        '',
        ('        frame_width = %d,'):fmt(settings.frame_width),
        ('        height = %d,'):fmt(settings.height),
        ('        row_height = %d,'):fmt(settings.row_height),
        ('        row_gap = %d,'):fmt(settings.row_gap),
        ('        opacity = %d,'):fmt(settings.opacity),
        '',
        ('        self_frame_width = %d,'):fmt(settings.self_frame_width),
        ('        self_height = %d,'):fmt(settings.self_height),
        ('        self_row_height = %d,'):fmt(settings.self_row_height),
        ('        self_row_gap = %d,'):fmt(settings.self_row_gap),
        ('        self_opacity = %d,'):fmt(settings.self_opacity),
        ('        self_show_mp = %s,'):fmt(bool_text(settings.self_show_mp)),
        ('        self_show_tp = %s,'):fmt(bool_text(settings.self_show_tp)),
        ('        self_mp_text_threshold = %d,'):fmt(settings.self_mp_text_threshold),
        ('        self_tp_text_threshold = %d,'):fmt(settings.self_tp_text_threshold),
        ('        party_frame_width = %d,'):fmt(settings.party_frame_width),
        ('        party_height = %d,'):fmt(settings.party_height),
        ('        party_row_height = %d,'):fmt(settings.party_row_height),
        ('        party_row_gap = %d,'):fmt(settings.party_row_gap),
        ('        party_opacity = %d,'):fmt(settings.party_opacity),
        ('        party_show_mp = %s,'):fmt(bool_text(settings.party_show_mp)),
        ('        party_show_tp = %s,'):fmt(bool_text(settings.party_show_tp)),
        ('        party_mp_text_threshold = %d,'):fmt(settings.party_mp_text_threshold),
        ('        party_tp_text_threshold = %d,'):fmt(settings.party_tp_text_threshold),
        '        party_size_layouts = {',
    };

    for size = 1, 6, 1 do
        append_party_size_layout_config(lines, size, settings.party_size_layouts[size]);
    end

    table.insert(lines, '        },');
    table.insert(lines, '');

    local tail_lines = {
        ('        pet_frame_width = %d,'):fmt(settings.pet_frame_width),
        ('        pet_height = %d,'):fmt(settings.pet_height),
        ('        pet_row_height = %d,'):fmt(settings.pet_row_height),
        ('        pet_row_gap = %d,'):fmt(settings.pet_row_gap),
        ('        pet_opacity = %d,'):fmt(settings.pet_opacity),
        ('        pet_show_mp = %s,'):fmt(bool_text(settings.pet_show_mp)),
        ('        pet_show_tp = %s,'):fmt(bool_text(settings.pet_show_tp)),
        ('        pet_mp_text_threshold = %d,'):fmt(settings.pet_mp_text_threshold),
        ('        pet_tp_text_threshold = %d,'):fmt(settings.pet_tp_text_threshold),
        ('        target_frame_width = %d,'):fmt(settings.target_frame_width),
        ('        target_height = %d,'):fmt(settings.target_height),
        ('        target_row_height = %d,'):fmt(settings.target_row_height),
        ('        target_row_gap = %d,'):fmt(settings.target_row_gap),
        ('        target_opacity = %d,'):fmt(settings.target_opacity),
        ('        target_show_mp = %s,'):fmt(bool_text(settings.target_show_mp)),
        ('        target_show_tp = %s,'):fmt(bool_text(settings.target_show_tp)),
        ('        target_mp_text_threshold = %d,'):fmt(settings.target_mp_text_threshold),
        ('        target_tp_text_threshold = %d,'):fmt(settings.target_tp_text_threshold),
        '',
        '        buff_reminders = {',
    };

    for _, line in ipairs(tail_lines) do
        table.insert(lines, line);
    end

    for _, key in ipairs(reminder_profile_keys(reminders)) do
        append_profile_config(lines, key, reminders[key]);
        table.insert(lines, '');
    end

    table.insert(lines, '        },');
    table.insert(lines, '');
    table.insert(lines, '        target_debuff_reminders = {');

    for _, key in ipairs(reminder_profile_keys(target_debuff_reminders)) do
        append_target_debuff_profile_config(lines, key, target_debuff_reminders[key]);
        table.insert(lines, '');
    end

    table.insert(lines, '        },');
    table.insert(lines, '    },');
    table.insert(lines, '}');
    table.insert(lines, '');

    return table.concat(lines, '\n');
end

local function save_config()
    local settings = capture_runtime_settings_for_save();
    local path = config_file_path();
    local file, error_message = io.open(path, 'w');
    if (file == nil) then
        return false, tostring(error_message or 'open failed');
    end

    file:write(config_text_from_settings(settings));
    file:close();

    state.settings = settings;
    return true, ('Saved %s.'):fmt(path);
end

local function party_member_unit(party, index, self_zone, reminder_job, reminders_suppressed)
    local active = truthy(safe_read(function () return party:GetMemberIsActive(index); end, false));
    local name = clean_string(safe_read(function () return party:GetMemberName(index); end, ''));
    local server_id = safe_read(function () return party:GetMemberServerId(index); end, 0);
    local target_index = safe_read(function () return party:GetMemberTargetIndex(index); end, 0);

    if (not active and server_id == 0 and #name == 0 and target_index == 0) then
        return nil;
    end

    local zone_id = safe_read(function () return party:GetMemberZone(index); end, nil);
    local same_zone = self_zone == nil or zone_id == nil or zone_id == self_zone;
    local tag = index == 0 and 'YOU' or tostring(index);
    local category = party_member_category(index, target_index, server_id);

    if (category == 'trust' and same_zone == false) then
        return nil;
    end

    local hp_pct = safe_read(function () return party:GetMemberHPPercent(index); end, nil);
    local mp_pct = safe_read(function () return party:GetMemberMPPercent(index); end, nil);
    local hp = resource_current_value(safe_read(function () return party:GetMemberHP(index); end, nil));
    local mp = resource_current_value(safe_read(function () return party:GetMemberMP(index); end, nil));
    local player = index == 0 and safe_read(function () return AshitaCore:GetMemoryManager():GetPlayer(); end, nil) or nil;
    local hp_max = player ~= nil and resource_current_value(safe_read(function () return player:GetHPMax(); end, nil)) or estimate_resource_max(hp, hp_pct);
    local mp_max = player ~= nil and resource_current_value(safe_read(function () return player:GetMPMax(); end, nil)) or estimate_resource_max(mp, mp_pct);

    return {
        kind = 'party',
        tag = tag,
        index = index,
        name = #name > 0 and name or ('Slot %d'):fmt(index + 1),
        category = category,
        reminder_job = reminder_job,
        reminders_suppressed = reminders_suppressed == true,
        hp = hp,
        hp_max = hp_max,
        hp_pct = hp_pct,
        mp = mp,
        mp_max = mp_max,
        mp_pct = mp_pct,
        tp = safe_read(function () return party:GetMemberTP(index); end, nil),
        job = job_label(
            safe_read(function () return party:GetMemberMainJob(index); end, nil),
            safe_read(function () return party:GetMemberMainJobLevel(index); end, nil),
            safe_read(function () return party:GetMemberSubJob(index); end, nil),
            safe_read(function () return party:GetMemberSubJobLevel(index); end, nil)),
        buffs = party_member_buffs(party, index, server_id, same_zone, name),
        same_zone = same_zone,
        dim = state.settings.same_zone_dim and not same_zone,
    };
end

function collect_self_unit()
    local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
    if (memory == nil) then
        return nil;
    end

    local party = safe_read(function () return memory:GetParty(); end, nil);
    if (party == nil) then
        return nil;
    end

    local self_zone = safe_read(function () return party:GetMemberZone(0); end, nil);
    sync_observed_buffs_for_party(party, self_zone);

    return party_member_unit(party, 0, self_zone, current_player_job_key(party), buff_reminders_suppressed_for_zone(self_zone));
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
    local reminder_job = current_player_job_key(party);
    local reminders_suppressed = buff_reminders_suppressed_for_zone(self_zone);
    local max_index = state.settings.show_alliance and 17 or 5;
    local units = { };
    local total_size = party_member_unit(party, 0, self_zone, reminder_job, reminders_suppressed) ~= nil and 1 or 0;

    sync_observed_buffs_for_party(party, self_zone);

    for index = 1, max_index, 1 do
        local unit = party_member_unit(party, index, self_zone, reminder_job, reminders_suppressed);
        if (unit ~= nil) then
            table.insert(units, unit);
            total_size = total_size + 1;
        end
    end

    units.party_size = party_size(total_size);
    return units;
end

function party_preview_unit(index)
    return {
        kind = 'party',
        tag = tostring(index),
        index = index,
        name = ('Party %d'):fmt(index),
        category = 'player',
        reminder_job = current_player_job_key(),
        reminders_suppressed = true,
        hp = math.max(320, 920 - (index * 82)),
        hp_max = 920,
        hp_pct = math.max(48, 100 - (index * 7)),
        mp = math.max(48, 280 - (index * 24)),
        mp_max = 280,
        mp_pct = math.max(34, 92 - (index * 8)),
        tp = index * 230,
        job = ({ 'WAR30/MNK15', 'WHM30/BLM15', 'SAM30/WAR15', 'BRD30/WHM15', 'RDM30/WHM15' })[index] or '',
        buffs = index == 1 and { 40, 41 } or { 40 },
        same_zone = true,
        dim = false,
    };
end

function party_preview_units(units, size)
    size = party_size(size);

    local result = { };
    local display_count = math.max(size - 1, 0);
    for index = 1, display_count, 1 do
        if (type(units) == 'table' and units[index] ~= nil) then
            table.insert(result, units[index]);
        else
            table.insert(result, party_preview_unit(index));
        end
    end

    return result;
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

    local server_id = safe_read(function () return entity:GetServerId(active_index); end, nil);
    if (server_id == nil or server_id == 0) then
        server_id = safe_read(function () return target:GetServerId(0); end, nil);
    end
    local target_type = safe_read(function () return entity:GetType(active_index); end, nil);
    local spawn_flags = safe_read(function () return entity:GetSpawnFlags(active_index); end, nil);

    return {
        kind = 'target',
        tag = is_sub_target_active and 'ST' or 'T',
        index = active_index,
        server_id = server_id,
        target_type = target_type,
        spawn_flags = spawn_flags,
        name = #name > 0 and name or ('Target %d'):fmt(active_index),
        hp_pct = hp_pct,
        mp_pct = nil,
        tp = nil,
        distance = entity_distance(entity, active_index),
        job = '',
        reminder_job = current_player_job_key(),
        debuffs = observed_target_debuffs_for_unit(server_id, name),
        same_zone = true,
        dim = false,
    };
end

function collect_pet_unit()
    local player_entity = safe_read(function () return GetPlayerEntity(); end, nil);
    if (player_entity == nil) then
        return nil;
    end

    local pet_index = tonumber(safe_read(function () return player_entity.PetTargetIndex; end, 0)) or 0;
    if (pet_index <= 0) then
        return nil;
    end

    local pet = safe_read(function () return GetEntity(pet_index); end, nil);
    if (pet == nil) then
        return nil;
    end

    local name = clean_string(safe_read(function () return pet.Name; end, ''));
    if (#name == 0) then
        return nil;
    end

    local distance = nil;
    local raw_distance = tonumber(safe_read(function () return pet.Distance; end, nil));
    if (raw_distance ~= nil and raw_distance >= 0) then
        distance = math.sqrt(raw_distance);
    end

    local player = safe_read(function () return AshitaCore:GetMemoryManager():GetPlayer(); end, nil);

    return {
        kind = 'pet',
        tag = 'PET',
        index = pet_index,
        server_id = safe_read(function () return pet.ServerId; end, nil),
        name = name,
        hp_pct = safe_read(function () return pet.HPPercent; end, nil),
        mp_pct = player ~= nil and safe_read(function () return player:GetPetMPPercent(); end, nil) or nil,
        tp = player ~= nil and safe_read(function () return player:GetPetTP(); end, nil) or nil,
        distance = distance,
        job = '',
        buffs = { },
        debuffs = { },
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

function draw_bar_fill(draw_list, x, y, width, height, percent, fill_color, alpha, rounding)
    percent = percent_value(percent);
    local fill_width = 0;

    if (percent ~= nil) then
        fill_width = math.floor(width * (percent / 100));
    end

    if (fill_width > 0) then
        draw_list:AddRectFilled({ x, y }, { x + fill_width, y + height }, color_u32(apply_alpha(fill_color, alpha)), rounding or 2.0);
    end
end

local function draw_bar(draw_list, x, y, width, height, percent, fill_color, alpha)
    draw_list:AddRectFilled({ x, y }, { x + width, y + height }, color_u32(apply_alpha(COLORS.bar_empty, alpha)), 2.0);
    draw_bar_fill(draw_list, x, y, width, height, percent, fill_color, alpha, 2.0);
end

function tp_percent_value(tp)
    local numeric = tonumber(tp);
    if (numeric == nil) then
        return nil;
    end

    return clamp(numeric / 30, 0, 100);
end

local function draw_tp_line(draw_list, x, y, width, tp, alpha)
    local percent = tp_percent_value(tp) or 0;
    draw_bar(draw_list, x, y, width, 3, percent, COLORS.tp, alpha);
end

function resource_pair_text(current, max)
    current = resource_current_value(current);
    max = resource_current_value(max);

    if (current == nil or max == nil or max <= 0) then
        return nil;
    end

    return ('%d/%d'):fmt(current, max);
end

function hp_status_text(unit)
    local percent_text = display_percent(unit.hp_pct);
    local pair = resource_pair_text(unit.hp, unit.hp_max);

    if (pair ~= nil) then
        return ('%s %s'):fmt(percent_text, pair);
    end

    return percent_text;
end

function unit_has_mp(unit)
    local percent = percent_value(unit.mp_pct);
    if (percent == nil) then
        return false;
    end

    local max = resource_current_value(unit.mp_max);
    return percent > 0 or (max ~= nil and max > 0);
end

function unit_has_tp(unit)
    return tonumber(unit.tp) ~= nil;
end

function mp_status_text(unit, layout)
    if (layout.show_mp ~= true or not unit_has_mp(unit)) then
        return nil;
    end

    local percent = percent_value(unit.mp_pct);
    if (percent == nil or percent < layout.mp_text_threshold) then
        return nil;
    end

    local pair = resource_pair_text(unit.mp, unit.mp_max);
    if (pair ~= nil) then
        return ('MP %s'):fmt(pair);
    end

    return ('MP %s'):fmt(display_percent(unit.mp_pct));
end

function tp_status_text(unit, layout)
    if (layout.show_tp ~= true or not unit_has_tp(unit)) then
        return nil;
    end

    local numeric = tonumber(unit.tp) or 0;
    if (numeric < layout.tp_text_threshold) then
        return nil;
    end

    return ('%dTP'):fmt(numeric);
end

local function unit_right_label(unit)
    if (unit.kind == 'target') then
        if (unit.distance ~= nil) then
            return ('%.1f'):fmt(unit.distance);
        end

        return '';
    end

    if (unit.kind == 'pet') then
        local pieces = { };
        if (unit.distance ~= nil) then
            table.insert(pieces, ('%.1f'):fmt(unit.distance));
        end

        return table.concat(pieces, ' ');
    end

    local pieces = { };
    if (state.settings.show_jobs and unit.job ~= nil and #unit.job > 0) then
        table.insert(pieces, unit.job);
    end

    return table.concat(pieces, ' ');
end

local function draw_buff_icon_frame(draw_list, item, icon_x, icon_y, alpha, tint)
    local pad = 3;
    local min = { icon_x - pad, icon_y - pad };
    local max = { icon_x + BUFF_ICON_SIZE + pad, icon_y + BUFF_ICON_SIZE + pad };

    if (item.state == 'missing') then
        local pulse = (math.sin(os.clock() * 7.0) + 1.0) * 0.5;
        local pulse_alpha = alpha * (0.62 + (pulse * 0.38));
        local border_color = pulse > 0.5 and COLORS.buff_missing_flash or COLORS.buff_missing_border;

        draw_list:AddRectFilled(min, max, color_u32(apply_alpha(COLORS.buff_missing_bg, pulse_alpha)), 4.0);
        draw_list:AddRect(min, max, color_u32(apply_alpha(border_color, alpha)), 4.0, ImDrawCornerFlags_All, 3.0);
    else
        draw_list:AddRectFilled(min, max, color_u32(apply_alpha(COLORS.shadow, alpha * 0.56)), 4.0);
        draw_list:AddRect(min, max, color_u32(apply_alpha(COLORS.buff_active_border, alpha)), 4.0, ImDrawCornerFlags_All, 1.0);
    end

    imgui.SetCursorScreenPos({ icon_x, icon_y });
    imgui.Image(item.handle, { BUFF_ICON_SIZE, BUFF_ICON_SIZE }, { 0, 0 }, { 1, 1 }, tint, { 0, 0, 0, 0 });

    if (item.state == 'missing') then
        local mark_color = color_u32(apply_alpha(COLORS.buff_missing_border, alpha));
        draw_list:AddLine({ icon_x + 7, icon_y + 7 }, { icon_x + BUFF_ICON_SIZE - 7, icon_y + BUFF_ICON_SIZE - 7 }, mark_color, 3.0);
        draw_list:AddLine({ icon_x + BUFF_ICON_SIZE - 7, icon_y + 7 }, { icon_x + 7, icon_y + BUFF_ICON_SIZE - 7 }, mark_color, 3.0);
    end
end

local function draw_buff_icon_row(unit, x, y, width, alpha)
    if (not state.settings.show_buffs or unit.kind ~= 'party') then
        return;
    end

    local items = buff_icon_items(unit);
    if (#items == 0) then
        return;
    end

    local draw_list = imgui.GetWindowDrawList();
    local tint = unit.dim and { 0.62, 0.62, 0.62, 0.62 } or { 1.00, 1.00, 1.00, 1.00 };
    local icon_x = x + 8;
    local icon_y = y + 24;
    local max_x = x + width - 8;

    for _, item in ipairs(items) do
        if ((icon_x + BUFF_ICON_SIZE + 3) > max_x) then
            break;
        end

        draw_buff_icon_frame(draw_list, item, icon_x, icon_y, alpha, tint);
        if (imgui.IsItemHovered()) then
            imgui.BeginTooltip();
            if (item.state == 'missing') then
                imgui.TextColored(COLORS.warning, ('Missing: %s'):fmt(item.name));
            else
                imgui.Text(item.name);
            end
            imgui.EndTooltip();
        end

        icon_x = icon_x + BUFF_ICON_SIZE + BUFF_ICON_GAP;
    end

    imgui.SetCursorScreenPos({ x, y });
end

local function draw_target_debuff_icon_row(unit, x, y, width, alpha)
    if (not state.settings.show_target_debuffs or not target_debuff_target_eligible(unit)) then
        return;
    end

    local items = target_debuff_icon_items(unit);
    if (#items == 0) then
        return;
    end

    local draw_list = imgui.GetWindowDrawList();
    local tint = unit.dim and { 0.62, 0.62, 0.62, 0.62 } or { 1.00, 1.00, 1.00, 1.00 };
    local icon_x = x + 8;
    local icon_y = y + 24;
    local max_x = x + width - 8;

    for _, item in ipairs(items) do
        if ((icon_x + BUFF_ICON_SIZE + 3) > max_x) then
            break;
        end

        draw_buff_icon_frame(draw_list, item, icon_x, icon_y, alpha, tint);
        if (imgui.IsItemHovered()) then
            imgui.BeginTooltip();
            if (item.state == 'missing') then
                imgui.TextColored(COLORS.warning, ('Missing: %s'):fmt(item.name));
            else
                imgui.Text(item.name);
            end
            imgui.EndTooltip();
        end

        icon_x = icon_x + BUFF_ICON_SIZE + BUFF_ICON_GAP;
    end

    imgui.SetCursorScreenPos({ x, y });
end

function draw_resource_labels(draw_list, unit, layout, x, y, width, alpha)
    local hp_x = x + width;
    if (state.settings.show_percent == true) then
        local hp_text = hp_status_text(unit);
        local hp_width = calc_text_width(hp_text);
        hp_x = x + width - hp_width;
        draw_text(draw_list, hp_x, y, COLORS.text, hp_text);
    end

    local label_x = x;
    local max_label_x = hp_x - 8;
    local mp_text = mp_status_text(unit, layout);
    if (mp_text ~= nil) then
        local mp_width = calc_text_width(mp_text);
        if ((label_x + mp_width) < max_label_x) then
            draw_text(draw_list, label_x, y, COLORS.mp, mp_text);
            label_x = label_x + mp_width + 8;
        end
    end

    local tp_text = tp_status_text(unit, layout);
    if (tp_text ~= nil) then
        local tp_width = calc_text_width(tp_text);
        if ((label_x + tp_width) < max_label_x) then
            draw_text(draw_list, label_x, y, COLORS.tp, tp_text);
        end
    end
end

function draw_resource_bars(draw_list, unit, layout, x, y, width, height, hp_color, alpha)
    draw_bar(draw_list, x, y, width, height, unit.hp_pct, hp_color, alpha);

    local bottom_y = y + height;
    if (layout.show_tp == true and unit_has_tp(unit)) then
        local tp_h = 3;
        bottom_y = bottom_y - tp_h;
        draw_bar_fill(draw_list, x, bottom_y, width, tp_h, tp_percent_value(unit.tp), COLORS.tp, alpha, 1.0);
    end

    if (layout.show_mp == true and unit_has_mp(unit)) then
        local mp_h = 4;
        bottom_y = bottom_y - mp_h;
        draw_bar_fill(draw_list, x, bottom_y, width, mp_h, unit.mp_pct, COLORS.mp, alpha, 1.0);
    end
end

local function draw_unit_row(unit, layout, row_height, skip_spacing)
    local x, y = imgui.GetCursorScreenPos();
    local draw_list = imgui.GetWindowDrawList();
    local width = layout.width;
    local alpha = (layout.opacity / 100) * (unit.dim and 0.62 or 1.0);
    local row_bg = unit.dim and COLORS.row_dim or COLORS.row_bg;
    local border = unit.kind == 'target' and COLORS.row_border_active or COLORS.row_border;
    local hp = percent_value(unit.hp_pct);
    local hp_color = hp ~= nil and hp <= 35 and COLORS.hp_low or COLORS.hp;
    local bar_x = x + 8;
    local bar_w = width - 16;
    local bar_h = 14;
    local bar_y = y + row_height - bar_h - 6;
    local label_y = math.max(y + 22, bar_y - 14);
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

    draw_buff_icon_row(unit, x, y, width, alpha);
    draw_target_debuff_icon_row(unit, x, y, width, alpha);

    draw_resource_bars(draw_list, unit, layout, bar_x, bar_y, bar_w, bar_h, hp_color, alpha);
    draw_resource_labels(draw_list, unit, layout, bar_x, label_y, bar_w, alpha);

    if (skip_spacing ~= true) then
        imgui.Dummy({ width, row_height + layout.row_gap });
    end
end

local function effective_row_height(unit, layout)
    if (unit.kind == 'party' and state.settings.show_buffs) then
        return math.max(layout.row_height, LIMITS.party_row_height_with_buffs_min);
    end
    if (unit.kind == 'target' and state.settings.show_target_debuffs and target_debuff_target_eligible(unit)) then
        return math.max(layout.row_height, LIMITS.target_row_height_with_debuffs_min);
    end

    return layout.row_height;
end

local function render_window(title, open_state, x, y, layout, units, position_callback)
    local settings = state.settings;
    if (#units == 0) then
        return;
    end

    local locked = settings.locked == true;
    local window_flags = locked and WINDOW_FLAGS_LOCKED or WINDOW_FLAGS_BASE;
    local pad = locked and 4 or 8;
    local alpha = layout.opacity / 100;

    imgui.SetNextWindowPos({ x, y }, locked and ImGuiCond_Always or ImGuiCond_FirstUseEver);
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { pad, pad });
    imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, locked and 0.0 or 1.0);
    imgui.PushStyleColor(ImGuiCol_WindowBg, apply_alpha(COLORS.panel_bg, alpha));
    imgui.PushStyleColor(ImGuiCol_Border, apply_alpha(COLORS.panel_border, alpha));

    if (imgui.Begin(title, open_state, window_flags)) then
        local current_x, current_y = imgui.GetWindowPos();
        position_callback(current_x, current_y);

        for _, unit in ipairs(units) do
            draw_unit_row(unit, layout, effective_row_height(unit, layout));
        end
    end

    imgui.End();
    imgui.PopStyleColor(2);
    imgui.PopStyleVar(2);
end

local function party_grid_size(layout, unit_count)
    unit_count = math.max(tonumber(unit_count) or 0, 1);
    local columns = clamp_int(layout.columns, 1, unit_count);
    local rows = clamp_int(layout.rows, 1, unit_count);

    if ((columns * rows) < unit_count) then
        rows = math.ceil(unit_count / columns);
    end

    return columns, rows;
end

local function render_party_grid_window(title, open_state, x, y, layout, units, position_callback)
    local settings = state.settings;
    if (#units == 0) then
        return;
    end

    local locked = settings.locked == true;
    local window_flags = locked and WINDOW_FLAGS_LOCKED or WINDOW_FLAGS_BASE;
    local pad = locked and 4 or 8;
    local alpha = layout.opacity / 100;
    local columns, rows = party_grid_size(layout, #units);
    local row_height = layout.row_height;
    for _, unit in ipairs(units) do
        row_height = math.max(row_height, effective_row_height(unit, layout));
    end

    local gap = layout.row_gap;
    local total_width = (columns * layout.width) + ((columns - 1) * gap);
    local total_height = (rows * row_height) + ((rows - 1) * gap);

    imgui.SetNextWindowPos({ x, y }, locked and ImGuiCond_Always or ImGuiCond_FirstUseEver);
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { pad, pad });
    imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, locked and 0.0 or 1.0);
    imgui.PushStyleColor(ImGuiCol_WindowBg, apply_alpha(COLORS.panel_bg, alpha));
    imgui.PushStyleColor(ImGuiCol_Border, apply_alpha(COLORS.panel_border, alpha));

    if (imgui.Begin(title, open_state, window_flags)) then
        local current_x, current_y = imgui.GetWindowPos();
        position_callback(current_x, current_y);

        local start_x, start_y = imgui.GetCursorScreenPos();
        for index, unit in ipairs(units) do
            local column = (index - 1) % columns;
            local row = math.floor((index - 1) / columns);
            imgui.SetCursorScreenPos({ start_x + (column * (layout.width + gap)), start_y + (row * (row_height + gap)) });
            draw_unit_row(unit, layout, row_height, true);
        end

        imgui.SetCursorScreenPos({ start_x, start_y });
        imgui.Dummy({ total_width, total_height });
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
        frame_layout('target'),
        { unit },
        function (x, y)
            state.target_window_x = math.floor(x + 0.5);
            state.target_window_y = math.floor(y + 0.5);
        end);
end

function render_self()
    if (not state.settings.show_self) then
        return;
    end

    local unit = collect_self_unit();
    if (unit == nil) then
        return;
    end

    render_window(
        'AshitaFrames Self###AshitaFramesSelf',
        state.visible,
        state.self_window_x,
        state.self_window_y,
        frame_layout('self'),
        { unit },
        function (x, y)
            state.self_window_x = math.floor(x + 0.5);
            state.self_window_y = math.floor(y + 0.5);
        end);
end

local function render_party()
    if (not state.settings.show_party) then
        return;
    end

    local units = collect_party_units();
    local size = party_size_from_units(units);
    if (state.config_visible[1] == true) then
        size = party_size(state.settings.party_preview_size);
        units = party_preview_units(units, size);
    end

    local layout = party_layout_for_size(size);
    render_party_grid_window(
        ('AshitaFrames Party %d###AshitaFramesParty'):fmt(size),
        state.visible,
        layout.x,
        layout.y,
        layout,
        units,
        function (x, y)
            update_party_layout_position(size, x, y);
        end);
end

function render_pet()
    if (not state.settings.show_pet) then
        return;
    end

    local unit = collect_pet_unit();
    if (unit == nil) then
        return;
    end

    render_window(
        'AshitaFrames Pet###AshitaFramesPet',
        state.visible,
        state.pet_window_x,
        state.pet_window_y,
        frame_layout('pet'),
        { unit },
        function (x, y)
            state.pet_window_x = math.floor(x + 0.5);
            state.pet_window_y = math.floor(y + 0.5);
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

function render_frame_layout_controls(kind, label)
    local width_field = ('%s_frame_width'):fmt(kind);
    local height_field = ('%s_height'):fmt(kind);
    local row_height_field = ('%s_row_height'):fmt(kind);
    local row_gap_field = ('%s_row_gap'):fmt(kind);
    local opacity_field = ('%s_opacity'):fmt(kind);

    imgui.TextColored(COLORS.accent, label);
    render_int_control('Width', ('%s_frame_width'):fmt(kind), state.settings[width_field], LIMITS.width_min, LIMITS.width_max, function (value)
        state.settings[width_field] = normalize_frame_width(value, state.settings.frame_width);
        mark_config_changed();
    end);
    render_int_control('Height', ('%s_height'):fmt(kind), state.settings[height_field], LIMITS.row_height_min, LIMITS.row_height_max, function (value)
        local normalized = normalize_frame_row_height(value, state.settings.row_height);
        state.settings[height_field] = normalized;
        state.settings[row_height_field] = normalized;
        mark_config_changed();
    end);
    render_int_control('Row Gap', ('%s_row_gap'):fmt(kind), state.settings[row_gap_field], LIMITS.row_gap_min, LIMITS.row_gap_max, function (value)
        state.settings[row_gap_field] = normalize_frame_row_gap(value, state.settings.row_gap);
        mark_config_changed();
    end);
    render_int_control('Opacity', ('%s_opacity'):fmt(kind), state.settings[opacity_field], LIMITS.opacity_min, LIMITS.opacity_max, function (value)
        state.settings[opacity_field] = normalize_frame_opacity(value, state.settings.opacity);
        mark_config_changed();
    end, '%');
end

function render_frame_bar_controls(kind, label)
    local show_mp_field = ('%s_show_mp'):fmt(kind);
    local show_tp_field = ('%s_show_tp'):fmt(kind);
    local mp_threshold_field = ('%s_mp_text_threshold'):fmt(kind);
    local tp_threshold_field = ('%s_tp_text_threshold'):fmt(kind);

    imgui.TextColored(COLORS.accent, label);

    local show_mp = state.settings[show_mp_field] == true;
    if (imgui.Checkbox(('Show MP Bar##ashitaframes_%s_show_mp'):fmt(kind), { show_mp })) then
        state.settings[show_mp_field] = not show_mp;
        mark_config_changed();
    end
    render_int_control('MP Text At', ('%s_mp_text_threshold'):fmt(kind), state.settings[mp_threshold_field], LIMITS.mp_text_threshold_min, LIMITS.mp_text_threshold_max, function (value)
        state.settings[mp_threshold_field] = normalize_mp_text_threshold(value, state.settings.mp_text_threshold);
        mark_config_changed();
    end, '%');

    local show_tp = state.settings[show_tp_field] == true;
    if (imgui.Checkbox(('Show TP Bar##ashitaframes_%s_show_tp'):fmt(kind), { show_tp })) then
        state.settings[show_tp_field] = not show_tp;
        mark_config_changed();
    end
    render_int_control('TP Text At', ('%s_tp_text_threshold'):fmt(kind), state.settings[tp_threshold_field], LIMITS.tp_text_threshold_min, LIMITS.tp_text_threshold_max, function (value)
        state.settings[tp_threshold_field] = normalize_tp_text_threshold(value, state.settings.tp_text_threshold);
        mark_config_changed();
    end, 'TP');
end

function render_party_size_layout_controls()
    render_int_control('Party Size', 'party_preview_size', state.settings.party_preview_size, 1, 6, function (value)
        state.settings.party_preview_size = party_size(value);
        mark_config_changed();
    end, 'members');

    local size = party_size(state.settings.party_preview_size);
    local layout = party_layout_for_size(size);
    imgui.TextColored(COLORS.accent, ('Party Frame %d'):fmt(size));
    render_int_control('Width', ('party_%d_frame_width'):fmt(size), layout.width, LIMITS.width_min, LIMITS.width_max, function (value)
        layout.width = normalize_frame_width(value, state.settings.party_frame_width);
        mark_config_changed();
    end);
    render_int_control('Height', ('party_%d_row_height'):fmt(size), layout.row_height, LIMITS.row_height_min, LIMITS.row_height_max, function (value)
        layout.row_height = normalize_frame_row_height(value, state.settings.party_row_height);
        mark_config_changed();
    end);
    render_int_control('Row Gap', ('party_%d_row_gap'):fmt(size), layout.row_gap, LIMITS.row_gap_min, LIMITS.row_gap_max, function (value)
        layout.row_gap = normalize_frame_row_gap(value, state.settings.party_row_gap);
        mark_config_changed();
    end);
    render_int_control('Opacity', ('party_%d_opacity'):fmt(size), layout.opacity, LIMITS.opacity_min, LIMITS.opacity_max, function (value)
        layout.opacity = normalize_frame_opacity(value, state.settings.party_opacity);
        mark_config_changed();
    end, '%');

    local max_members = math.max(party_display_count_for_size(size), 1);
    render_int_control('Columns', ('party_%d_columns'):fmt(size), layout.columns, 1, max_members, function (value)
        layout.columns = normalize_party_grid_columns(value, size);
        fit_party_grid(layout, size, 'columns');
        mark_config_changed();
    end, 'cols');
    render_int_control('Rows', ('party_%d_rows'):fmt(size), layout.rows, 1, max_members, function (value)
        layout.rows = normalize_party_grid_rows(value, size);
        fit_party_grid(layout, size, 'rows');
        mark_config_changed();
    end, 'rows');
end

function render_general_config_tab()
    imgui.TextColored(COLORS.accent, 'Global');

    local visible = state.visible[1] == true;
    if (imgui.Checkbox('Show Frames##ashitaframes_show_frames', { visible })) then
        state.visible[1] = not visible;
        state.settings.visible = state.visible[1];
        mark_config_changed();
    end

    local locked = state.settings.locked == true;
    if (imgui.Checkbox('Lock Frames##ashitaframes_lock_frames', { locked })) then
        state.settings.locked = not locked;
        mark_config_changed();
    end

    render_int_control('Max Buffs', 'max_buffs', state.settings.max_buffs, LIMITS.max_buffs_min, LIMITS.max_buffs_max, function (value)
        state.settings.max_buffs = clamp_int(value, LIMITS.max_buffs_min, LIMITS.max_buffs_max);
        mark_config_changed();
    end, 'buffs');
end

function render_self_frame_config_tab()
    local show_self = state.settings.show_self == true;
    if (imgui.Checkbox('Show Self Frame##ashitaframes_show_self', { show_self })) then
        state.settings.show_self = not show_self;
        mark_config_changed();
    end

    imgui.Separator();
    render_frame_layout_controls('self', 'Self Frame');
    imgui.Separator();
    render_frame_bar_controls('self', 'Self Bars');
end

function render_party_frame_config_tab()
    local show_party = state.settings.show_party == true;
    if (imgui.Checkbox('Show Party Frame##ashitaframes_show_party', { show_party })) then
        state.settings.show_party = not show_party;
        mark_config_changed();
    end

    local show_alliance = state.settings.show_alliance == true;
    if (imgui.Checkbox('Alliance Slots##ashitaframes_show_alliance', { show_alliance })) then
        state.settings.show_alliance = not show_alliance;
        mark_config_changed();
    end

    local same_zone_dim = state.settings.same_zone_dim == true;
    if (imgui.Checkbox('Dim Different Zone##ashitaframes_same_zone_dim', { same_zone_dim })) then
        state.settings.same_zone_dim = not same_zone_dim;
        mark_config_changed();
    end

    local show_buffs = state.settings.show_buffs == true;
    if (imgui.Checkbox('Party Buffs##ashitaframes_show_buffs', { show_buffs })) then
        state.settings.show_buffs = not show_buffs;
        state.settings = normalize_settings(state.settings);
        mark_config_changed();
    end

    local show_buff_reminders = state.settings.show_buff_reminders == true;
    if (imgui.Checkbox('Missing Buff Reminders##ashitaframes_show_buff_reminders', { show_buff_reminders })) then
        state.settings.show_buff_reminders = not show_buff_reminders;
        mark_config_changed();
    end

    imgui.Separator();
    render_party_size_layout_controls();
    imgui.Separator();
    render_frame_bar_controls('party', 'Party Bars');
    imgui.Separator();
    render_buff_reminder_config();
end

function render_pet_frame_config_tab()
    local show_pet = state.settings.show_pet == true;
    if (imgui.Checkbox('Show Pet Frame##ashitaframes_show_pet', { show_pet })) then
        state.settings.show_pet = not show_pet;
        mark_config_changed();
    end

    imgui.Separator();
    render_frame_layout_controls('pet', 'Pet Frame');
    imgui.Separator();
    render_frame_bar_controls('pet', 'Pet Bars');
end

function render_target_frame_config_tab()
    local show_target = state.settings.show_target == true;
    if (imgui.Checkbox('Show Target Frame##ashitaframes_show_target', { show_target })) then
        state.settings.show_target = not show_target;
        mark_config_changed();
    end

    local show_empty_target = state.settings.show_empty_target == true;
    if (imgui.Checkbox('Show Empty Target##ashitaframes_show_empty_target', { show_empty_target })) then
        state.settings.show_empty_target = not show_empty_target;
        mark_config_changed();
    end

    local show_target_debuffs = state.settings.show_target_debuffs == true;
    if (imgui.Checkbox('Target Debuffs##ashitaframes_show_target_debuffs', { show_target_debuffs })) then
        state.settings.show_target_debuffs = not show_target_debuffs;
        mark_config_changed();
    end

    local show_target_debuff_reminders = state.settings.show_target_debuff_reminders == true;
    if (imgui.Checkbox('Missing Target Debuffs##ashitaframes_show_target_debuff_reminders', { show_target_debuff_reminders })) then
        state.settings.show_target_debuff_reminders = not show_target_debuff_reminders;
        mark_config_changed();
    end

    imgui.Separator();
    render_frame_layout_controls('target', 'Target Frame');
    imgui.Separator();
    render_frame_bar_controls('target', 'Target Bars');
    imgui.Separator();
    render_target_debuff_reminder_config();
end

function render_frame_config_tabs()
    if (imgui.BeginTabBar('##ashitaframes_config_tabs', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton)) then
        if (imgui.BeginTabItem('General##ashitaframes_config_general', nil)) then
            render_general_config_tab();
            imgui.EndTabItem();
        end
        if (imgui.BeginTabItem('Self##ashitaframes_config_self', nil)) then
            render_self_frame_config_tab();
            imgui.EndTabItem();
        end
        if (imgui.BeginTabItem('Party##ashitaframes_config_party', nil)) then
            render_party_frame_config_tab();
            imgui.EndTabItem();
        end
        if (imgui.BeginTabItem('Pet##ashitaframes_config_pet', nil)) then
            render_pet_frame_config_tab();
            imgui.EndTabItem();
        end
        if (imgui.BeginTabItem('Target##ashitaframes_config_target', nil)) then
            render_target_frame_config_tab();
            imgui.EndTabItem();
        end

        imgui.EndTabBar();
    end
end

local function render_profile_bool(profile, field, label, id)
    local value = profile[field] == true;
    if (imgui.Checkbox(('%s##ashitaframes_%s'):fmt(label, id), { value })) then
        profile[field] = not value;
        mark_config_changed();
    end
end

local function render_profile_buff_toggle(profile, key, label)
    if (not reminder_spell_available(key)) then
        return false;
    end

    local enabled = buff_list_has(profile.buffs, key);
    if (imgui.Checkbox(('%s##ashitaframes_buff_reminder_%s'):fmt(label, key), { enabled })) then
        set_profile_buff_enabled(profile, key, not enabled);
        mark_config_changed();
    end

    return true;
end

local function render_profile_target_debuff_toggle(profile, key, label)
    if (not target_debuff_spell_available(key)) then
        return false;
    end

    local enabled = target_debuff_list_has(profile.debuffs, key);
    if (imgui.Checkbox(('%s##ashitaframes_target_debuff_reminder_%s'):fmt(label, key), { enabled })) then
        set_profile_target_debuff_enabled(profile, key, not enabled);
        mark_config_changed();
    end

    return true;
end

function render_buff_reminder_config()
    imgui.Separator();
    imgui.TextColored(COLORS.accent, 'Buff Reminders');

    local hide_in_towns = state.settings.hide_buff_reminders_in_towns == true;
    if (imgui.Checkbox('Hide Missing In Towns##ashitaframes_hide_buff_reminders_in_towns', { hide_in_towns })) then
        state.settings.hide_buff_reminders_in_towns = not hide_in_towns;
        mark_config_changed();
    end

    local zone_id = current_player_zone_id();
    local zone_label = zone_id ~= nil and ('%s (%d)'):fmt(zone_name(zone_id), zone_id) or 'Unknown';
    local zone_suppressed = buff_reminders_suppressed_for_zone(zone_id);
    imgui.TextColored(COLORS.text_muted, ('Current zone: %s - %s'):fmt(zone_label, zone_suppressed and 'hidden' or 'shown'));

    if (zone_id ~= nil and not (state.settings.hide_buff_reminders_in_towns and TOWN_ZONE_IDS[math.floor(zone_id + 0.5)] == true)) then
        local explicit_suppressed = zone_list_has(state.settings.buff_reminder_suppressed_zone_ids, zone_id);
        if (explicit_suppressed) then
            if (imgui.Button('Allow Current Zone##ashitaframes_allow_current_zone')) then
                set_zone_suppressed(zone_id, false);
                mark_config_changed();
            end
        else
            if (imgui.Button('Suppress Current Zone##ashitaframes_suppress_current_zone')) then
                set_zone_suppressed(zone_id, true);
                mark_config_changed();
            end
        end
    end

    local current_job = current_player_job_key();
    local selected_job = current_config_job_key();

    if (imgui.Button('<##ashitaframes_reminder_job_prev', { 26, 0 })) then
        step_config_job(-1);
        selected_job = current_config_job_key();
    end
    imgui.SameLine(0, 6);
    imgui.Text(('Job: %s'):fmt(selected_job));
    imgui.SameLine(0, 6);
    if (imgui.Button('>##ashitaframes_reminder_job_next', { 26, 0 })) then
        step_config_job(1);
        selected_job = current_config_job_key();
    end
    imgui.SameLine(0, 10);
    if (imgui.Button('Current##ashitaframes_reminder_job_current')) then
        if (current_job ~= 'default') then
            state.config_job_key = current_job;
            selected_job = current_config_job_key();
            mark_config_changed();
        end
    end
    imgui.SameLine(0, 8);
    imgui.TextColored(COLORS.text_muted, ('Now: %s'):fmt(current_job));

    local profile = ensure_reminder_profile(selected_job);
    render_profile_bool(profile, 'enabled', 'Enable Job Profile', ('reminder_%s_enabled'):fmt(selected_job));

    imgui.TextColored(COLORS.text_muted, 'Units');
    render_profile_bool(profile, 'self', 'Self', ('reminder_%s_self'):fmt(selected_job));
    imgui.SameLine(0, 12);
    render_profile_bool(profile, 'players', 'Players', ('reminder_%s_players'):fmt(selected_job));
    imgui.SameLine(0, 12);
    render_profile_bool(profile, 'trusts', 'Trusts', ('reminder_%s_trusts'):fmt(selected_job));

    imgui.TextColored(COLORS.text_muted, 'Buffs');
    local any_buff = false;
    if (render_profile_buff_toggle(profile, 'protect', 'Protect')) then
        any_buff = true;
    end
    if (reminder_spell_available('shell')) then
        if (any_buff) then
            imgui.SameLine(0, 12);
        end
        if (render_profile_buff_toggle(profile, 'shell', 'Shell')) then
            any_buff = true;
        end
    end
    if (not any_buff) then
        imgui.TextColored(COLORS.text_muted, 'No supported buffs available for current job/subjob.');
    elseif (buff_list_has(profile.buffs, 'shell') and not reminder_spell_available('shell')) then
        imgui.TextColored(COLORS.text_muted, 'Shell is configured on but unavailable on current job/subjob.');
    end
end

function render_target_debuff_reminder_config()
    imgui.Separator();
    imgui.TextColored(COLORS.accent, 'Target Debuff Reminders');

    local current_job = current_player_job_key();
    local selected_job = current_config_debuff_job_key();

    if (imgui.Button('<##ashitaframes_debuff_reminder_job_prev', { 26, 0 })) then
        step_config_debuff_job(-1);
        selected_job = current_config_debuff_job_key();
    end
    imgui.SameLine(0, 6);
    imgui.Text(('Job: %s'):fmt(selected_job));
    imgui.SameLine(0, 6);
    if (imgui.Button('>##ashitaframes_debuff_reminder_job_next', { 26, 0 })) then
        step_config_debuff_job(1);
        selected_job = current_config_debuff_job_key();
    end
    imgui.SameLine(0, 10);
    if (imgui.Button('Current##ashitaframes_debuff_reminder_job_current')) then
        if (current_job ~= 'default') then
            state.config_debuff_job_key = current_job;
            selected_job = current_config_debuff_job_key();
            mark_config_changed();
        end
    end
    imgui.SameLine(0, 8);
    imgui.TextColored(COLORS.text_muted, ('Now: %s'):fmt(current_job));

    local profile = ensure_target_debuff_reminder_profile(selected_job);
    render_profile_bool(profile, 'enabled', 'Enable Job Profile', ('target_debuff_reminder_%s_enabled'):fmt(selected_job));

    imgui.TextColored(COLORS.text_muted, 'Debuffs');
    local any_debuff = false;
    if (render_profile_target_debuff_toggle(profile, 'dia', 'Dia')) then
        any_debuff = true;
    end
    if (render_profile_target_debuff_toggle(profile, 'paralyze', 'Paralyze')) then
        any_debuff = true;
    end
    if (render_profile_target_debuff_toggle(profile, 'slow', 'Slow')) then
        any_debuff = true;
    end

    if (not any_debuff) then
        imgui.TextColored(COLORS.text_muted, 'No supported target debuffs available for current job/subjob.');
    else
        if (target_debuff_list_has(profile.debuffs, 'dia') and not target_debuff_spell_available('dia')) then
            imgui.TextColored(COLORS.text_muted, 'Dia is configured on but unavailable on current job/subjob.');
        end
        if (target_debuff_list_has(profile.debuffs, 'paralyze') and not target_debuff_spell_available('paralyze')) then
            imgui.TextColored(COLORS.text_muted, 'Paralyze is configured on but unavailable on current job/subjob.');
        end
        if (target_debuff_list_has(profile.debuffs, 'slow') and not target_debuff_spell_available('slow')) then
            imgui.TextColored(COLORS.text_muted, 'Slow is configured on but unavailable on current job/subjob.');
        end
    end
end

local function render_config_window()
    if (not state.config_visible[1]) then
        return;
    end

    imgui.SetNextWindowSize({ 430, 0 }, ImGuiCond_FirstUseEver);
    if (imgui.Begin(('AshitaFrames v%s Configuration###AshitaFramesConfig'):fmt(addon.version), state.config_visible, ImGuiWindowFlags_AlwaysAutoResize)) then
        render_frame_config_tabs();

        imgui.Separator();
        local party_layout = party_layout_for_size(state.settings.party_preview_size);
        imgui.Text(('Self pos: %d, %d'):fmt(state.self_window_x, state.self_window_y));
        imgui.Text(('Party %d pos: %d, %d'):fmt(party_size(state.settings.party_preview_size), party_layout.x, party_layout.y));
        imgui.Text(('Pet pos: %d, %d'):fmt(state.pet_window_x, state.pet_window_y));
        imgui.Text(('Target pos: %d, %d'):fmt(state.target_window_x, state.target_window_y));

        if (imgui.Button('Save##ashitaframes_config_save')) then
            local ok, message = save_config();
            state.config_save_message = ok and 'Saved.' or 'Save failed.';
            state.config_save_message_color = ok and COLORS.accent or COLORS.warning;
            if (ok) then
                log_info(message);
            else
                log_error(message);
            end
        end

        if (state.config_save_message ~= nil) then
            imgui.SameLine(0, 8);
            imgui.TextColored(state.config_save_message_color or COLORS.accent, state.config_save_message);
        end

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

local function observed_buff_summary()
    local names = { };

    for name, buffs in pairs(state.observed_buffs) do
        local buff_names = { };
        if (type(buffs) == 'table') then
            for key, enabled in pairs(buffs) do
                if (enabled == true) then
                    table.insert(buff_names, key);
                end
            end
        end

        if (#buff_names > 0) then
            table.sort(buff_names);
            table.insert(names, ('%s:%s'):fmt(name, table.concat(buff_names, '+')));
        end
    end

    if (#names == 0) then
        return 'none';
    end

    table.sort(names);
    return table.concat(names, ', ');
end

local function print_status()
    local reminder_job = current_player_job_key();
    local reminder_profile = reminder_profile_for_job(reminder_job);
    local status_party_size = party_size(state.settings.party_preview_size);
    local status_party_layout = party_layout_for_size(status_party_size);

    log_info(('visible=%s locked=%s self=%s target=%s party=%s pet=%s alliance=%s buffs=%s reminders=%s targetDebuffs=%s targetDebuffReminders=%s reminderJob=%s reminderProfile=%s observed=%s observedEvents=%d observedLogEvents=%d maxBuffs=%d self=(%d,%d %dx%d gap=%d op=%d) partySize=%d party=(%d,%d %dx%d gap=%d op=%d cols=%d rows=%d) pet=(%d,%d %dx%d gap=%d op=%d) target=(%d,%d %dx%d gap=%d op=%d)'):fmt(
        tostring(state.visible[1] == true),
        tostring(state.settings.locked == true),
        tostring(state.settings.show_self == true),
        tostring(state.settings.show_target == true),
        tostring(state.settings.show_party == true),
        tostring(state.settings.show_pet == true),
        tostring(state.settings.show_alliance == true),
        tostring(state.settings.show_buffs == true),
        tostring(state.settings.show_buff_reminders == true),
        tostring(state.settings.show_target_debuffs == true),
        tostring(state.settings.show_target_debuff_reminders == true),
        reminder_job,
        reminder_profile.enabled and 'on' or 'off',
        observed_buff_summary(),
        state.observed_text_events,
        state.observed_log_events,
        state.settings.max_buffs,
        state.self_window_x,
        state.self_window_y,
        state.settings.self_frame_width,
        state.settings.self_row_height,
        state.settings.self_row_gap,
        state.settings.self_opacity,
        status_party_size,
        status_party_layout.x,
        status_party_layout.y,
        status_party_layout.width,
        status_party_layout.row_height,
        status_party_layout.row_gap,
        status_party_layout.opacity,
        status_party_layout.columns,
        status_party_layout.rows,
        state.pet_window_x,
        state.pet_window_y,
        state.settings.pet_frame_width,
        state.settings.pet_row_height,
        state.settings.pet_row_gap,
        state.settings.pet_opacity,
        state.target_window_x,
        state.target_window_y,
        state.settings.target_frame_width,
        state.settings.target_row_height,
        state.settings.target_row_gap,
        state.settings.target_opacity));

    if (state.config_error ~= nil) then
        log_error('Config load warning: ' .. state.config_error);
    end
end

local TARGET_DEBUFF_APPLY_MESSAGES = {
    [2] = true,
    [236] = true,
    [237] = true,
    [252] = true,
    [268] = true,
    [271] = true,
};
local TARGET_DEBUFF_OFF_MESSAGES = {
    [64] = true,
    [159] = true,
    [168] = true,
    [204] = true,
    [206] = true,
    [321] = true,
    [322] = true,
    [341] = true,
    [342] = true,
    [343] = true,
    [344] = true,
    [350] = true,
    [378] = true,
    [531] = true,
    [647] = true,
    [805] = true,
    [806] = true,
};
local TARGET_DEBUFF_DEATH_MESSAGES = {
    [6] = true,
    [20] = true,
    [97] = true,
    [113] = true,
    [406] = true,
    [605] = true,
    [646] = true,
};

local function local_player_server_id()
    local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
    local party = memory ~= nil and safe_read(function () return memory:GetParty(); end, nil) or nil;
    return party ~= nil and tonumber(safe_read(function () return party:GetMemberServerId(0); end, nil)) or nil;
end

local function target_debuff_duration_seconds(key, spell_id)
    key = normalize_target_debuff_key(key);
    spell_id = tonumber(spell_id);
    if (spell_id ~= nil and TARGET_DEBUFF_SPELL_DURATIONS[spell_id] ~= nil) then
        return clamp_int(TARGET_DEBUFF_SPELL_DURATIONS[spell_id], 1, 86400);
    end

    local definition = key ~= nil and TARGET_DEBUFF_DEFINITIONS[key] or nil;
    return clamp_int(definition ~= nil and definition.duration_seconds or 120, 1, 86400);
end

local function set_observed_target_debuff(server_id, key, enabled, spell_id)
    local target_id = tonumber(server_id);
    key = normalize_target_debuff_key(key);
    if (target_id == nil or target_id == 0 or key == nil or target_debuff_id_for_key(key) == nil) then
        return false;
    end

    if (enabled == true) then
        state.observed_target_debuffs[target_id] = state.observed_target_debuffs[target_id] or { };
        state.observed_target_debuffs[target_id][key] = {
            status_id = target_debuff_id_for_key(key),
            spell_id = tonumber(spell_id),
            expires_at = os.time() + target_debuff_duration_seconds(key, spell_id),
        };
        return true;
    end

    local entry = state.observed_target_debuffs[target_id];
    if (type(entry) ~= 'table') then
        return false;
    end

    entry[key] = nil;
    if (next(entry) == nil) then
        state.observed_target_debuffs[target_id] = nil;
    end

    return true;
end

function set_observed_target_debuff_name(name, key, enabled, spell_id)
    local name_key = observed_target_name_key(name);
    key = normalize_target_debuff_key(key);
    if (name_key == nil or key == nil or target_debuff_id_for_key(key) == nil) then
        return false;
    end

    if (enabled == true) then
        state.observed_target_debuff_names[name_key] = state.observed_target_debuff_names[name_key] or { };
        state.observed_target_debuff_names[name_key][key] = {
            status_id = target_debuff_id_for_key(key),
            spell_id = tonumber(spell_id),
            expires_at = os.time() + target_debuff_duration_seconds(key, spell_id),
        };
        return true;
    end

    local entry = state.observed_target_debuff_names[name_key];
    if (type(entry) ~= 'table') then
        return false;
    end

    entry[key] = nil;
    if (next(entry) == nil) then
        state.observed_target_debuff_names[name_key] = nil;
    end

    return true;
end

function clear_observed_target_debuff_name(name)
    local name_key = observed_target_name_key(name);
    if (name_key == nil or state.observed_target_debuff_names[name_key] == nil) then
        return false;
    end

    state.observed_target_debuff_names[name_key] = nil;
    return true;
end

function clear_observed_target_debuff_name_status(name, status)
    local key = normalize_target_debuff_key(status);
    if (key == nil) then
        return false;
    end

    return set_observed_target_debuff_name(name, key, false);
end

local function clear_observed_target_debuff_status(server_id, status_id)
    local key = target_debuff_key_from_id(status_id);
    if (key == nil) then
        return false;
    end

    return set_observed_target_debuff(server_id, key, false);
end

local function read_le_uint(data, offset, size)
    local result = 0;
    local multiplier = 1;
    for index = 0, size - 1, 1 do
        local value = data:byte(offset + index);
        if (value == nil) then
            return nil;
        end

        result = result + (value * multiplier);
        multiplier = multiplier * 256;
    end

    return result;
end

local function parse_action_packet(data)
    if (type(data) ~= 'string' or data:byte(1) ~= 0x28) then
        return nil;
    end

    local bytes = safe_read(function () return data:totable(); end, nil);
    if (type(bytes) ~= 'table') then
        return nil;
    end

    local action = {
        actor_id = safe_read(function () return ashita.bits.unpack_be(bytes, 40, 32); end, nil),
        target_count = safe_read(function () return ashita.bits.unpack_be(bytes, 72, 10); end, 0),
        action_type = safe_read(function () return ashita.bits.unpack_be(bytes, 82, 4); end, nil),
        param = safe_read(function () return ashita.bits.unpack_be(bytes, 86, 16); end, nil),
        targets = { },
    };

    local offset = 150;
    local target_count = clamp_int(action.target_count or 0, 0, 32);
    for _ = 1, target_count, 1 do
        local target = {
            id = safe_read(function () return ashita.bits.unpack_be(bytes, offset, 32); end, nil),
            action_count = safe_read(function () return ashita.bits.unpack_be(bytes, offset + 32, 4); end, 0),
            actions = { },
        };

        offset = offset + 36;
        local action_count = clamp_int(target.action_count or 0, 0, 32);
        for _ = 1, action_count, 1 do
            local target_action = {
                param = safe_read(function () return ashita.bits.unpack_be(bytes, offset + 27, 17); end, nil),
                message = safe_read(function () return ashita.bits.unpack_be(bytes, offset + 44, 10); end, nil),
                has_add_effect = safe_read(function () return ashita.bits.unpack_be(bytes, offset + 85, 1); end, 0) == 1,
            };

            offset = offset + 86;
            if (target_action.has_add_effect) then
                offset = offset + 37;
            end

            local has_spike_effect = safe_read(function () return ashita.bits.unpack_be(bytes, offset, 1); end, 0) == 1;
            offset = offset + 1;
            if (has_spike_effect) then
                offset = offset + 34;
            end

            table.insert(target.actions, target_action);
        end

        table.insert(action.targets, target);
    end

    return action;
end

local function handle_target_debuff_action_packet(data)
    local action = parse_action_packet(data);
    local player_id = local_player_server_id();
    if (action == nil or player_id == nil or tonumber(action.actor_id) ~= player_id or tonumber(action.action_type) ~= 4) then
        return;
    end

    local spell_id_value = tonumber(action.param);
    local key = TARGET_DEBUFF_SPELL_IDS[spell_id_value];
    if (key == nil) then
        return;
    end

    for _, target in ipairs(action.targets or { }) do
        for _, target_action in ipairs(target.actions or { }) do
            local message = tonumber(target_action.message);
            if (TARGET_DEBUFF_APPLY_MESSAGES[message] == true) then
                set_observed_target_debuff(target.id, key, true, spell_id_value);
            end
        end
    end
end

local function handle_target_debuff_message_packet(data)
    if (type(data) ~= 'string') then
        return;
    end

    local target_id = read_le_uint(data, 0x09, 4);
    local param = read_le_uint(data, 0x0D, 4);
    local message_id = read_le_uint(data, 0x19, 2);
    if (message_id ~= nil) then
        message_id = math.fmod(message_id, 32768);
    end

    if (target_id == nil or message_id == nil) then
        return;
    end

    if (TARGET_DEBUFF_DEATH_MESSAGES[message_id] == true) then
        state.observed_target_debuffs[target_id] = nil;
    elseif (TARGET_DEBUFF_OFF_MESSAGES[message_id] == true and param ~= nil) then
        clear_observed_target_debuff_status(target_id, param);
    end
end

local function handle_incoming_packet(e)
    if (e == nil or e.blocked == true) then
        return;
    end

    if (e.id == 0x028) then
        handle_target_debuff_action_packet(e.data_modified or e.data);
    elseif (e.id == 0x029) then
        handle_target_debuff_message_packet(e.data_modified or e.data);
    elseif (e.id == 0x00A) then
        clear_observed_target_debuffs();
    end
end

local function clean_event_message(message)
    local text = tostring(message or ''):gsub('\r', ' '):gsub('\n', ' '):gsub('%z', '');
    text = text:gsub('.', function (character)
        local value = character:byte();
        if (value ~= nil and value < 32 and value ~= 9) then
            return '';
        end

        return character;
    end);

    while true do
        local changed = 0;
        text, changed = text:gsub('^%[%d%d:%d%d:%d%d%]%s*', '', 1);
        if (changed == 0) then
            break;
        end
    end

    return clean_string(text);
end

local function current_party_contains_name(name)
    local target_key = observed_name_key(name);
    if (target_key == nil) then
        return false;
    end

    local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
    local party = memory ~= nil and safe_read(function () return memory:GetParty(); end, nil) or nil;
    if (party == nil) then
        return false;
    end

    local self_zone = safe_read(function () return party:GetMemberZone(0); end, nil);
    for index = 0, 5, 1 do
        local active = truthy(safe_read(function () return party:GetMemberIsActive(index); end, false));
        local member_name = clean_string(safe_read(function () return party:GetMemberName(index); end, ''));
        local member_zone = safe_read(function () return party:GetMemberZone(index); end, nil);
        local same_zone = self_zone == nil or member_zone == nil or member_zone == self_zone;

        if (active and same_zone and observed_name_key(member_name) == target_key) then
            return true;
        end
    end

    return false;
end

local function set_observed_buff(name, key, enabled)
    local name_key = observed_name_key(name);
    key = normalize_buff_key(key);
    if (name_key == nil or key == nil or buff_id_for_key(key) == nil or not current_party_contains_name(name)) then
        return false;
    end

    if (enabled == true) then
        state.observed_buffs[name_key] = state.observed_buffs[name_key] or { };
        state.observed_buffs[name_key][key] = true;
        return true;
    end

    local entry = state.observed_buffs[name_key];
    if (type(entry) ~= 'table') then
        return false;
    end

    entry[key] = nil;
    for _, value in pairs(entry) do
        if (value == true) then
            return true;
        end
    end

    state.observed_buffs[name_key] = nil;
    return true;
end

local function observed_buff_event(text)
    local name, buff = text:match('^(.-) gains the effect of (.-)%.?$');
    if (name ~= nil and buff ~= nil) then
        return name, buff, true;
    end

    name, buff = text:match('^(.-) loses the effect of (.-)%.?$');
    if (name ~= nil and buff ~= nil) then
        return name, buff, false;
    end

    name, buff = text:match("^(.-)'s (.-) effect wears off%.?$");
    if (name ~= nil and buff ~= nil) then
        return name, buff, false;
    end

    return nil, nil, nil;
end

local function process_observed_buff_text(message)
    local name, buff, enabled = observed_buff_event(clean_event_message(message));
    local key = buff_key_from_name(buff);
    if (name == nil or key == nil) then
        return false;
    end

    return set_observed_buff(name, key, enabled);
end

function current_player_name()
    local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
    local party = memory ~= nil and safe_read(function () return memory:GetParty(); end, nil) or nil;
    return party ~= nil and clean_string(safe_read(function () return party:GetMemberName(0); end, '')) or '';
end

function target_debuff_key_from_spell_name(spell_name)
    local key = normalize_target_debuff_key(spell_name);
    if (key ~= nil) then
        return key;
    end

    key = clean_string(spell_name):lower():gsub('[%s%-]+', '_');
    if (key == 'dia_ii' or key == 'dia_iii' or key == 'dia_iv' or key == 'dia_v' or key == 'diaga') then
        return 'dia';
    end
    if (key == 'paralyze_ii') then
        return 'paralyze';
    end

    return nil;
end

function target_debuff_spell_id_from_name(spell_name)
    local key = clean_string(spell_name):lower():gsub('[%s%-]+', '_');
    local ids = {
        dia = 23,
        dia_ii = 24,
        dia_iii = 25,
        dia_iv = 26,
        dia_v = 27,
        diaga = 33,
        paralyze = 58,
        paralyze_ii = 80,
        slow = 56,
        slow_ii = 79,
    };

    return ids[key];
end

function set_pending_target_debuff_cast(spell_name, target_name)
    local key = target_debuff_key_from_spell_name(spell_name);
    local target_key = observed_target_name_key(target_name);
    if (key == nil) then
        return false;
    end

    state.pending_target_debuff_cast = {
        key = key,
        spell_name = clean_string(spell_name),
        spell_id = target_debuff_spell_id_from_name(spell_name),
        target_name = clean_string(target_name),
        target_key = target_key,
        started_at = os.time(),
    };
    return true;
end

function pending_target_debuff_cast()
    local pending = state.pending_target_debuff_cast;
    if (type(pending) ~= 'table') then
        return nil;
    end

    if ((os.time() - (tonumber(pending.started_at) or 0)) > 20) then
        state.pending_target_debuff_cast = nil;
        return nil;
    end

    return pending;
end

function pending_target_matches(name, key)
    local pending = pending_target_debuff_cast();
    if (pending == nil or (key ~= nil and pending.key ~= key)) then
        return nil;
    end

    if (pending.target_key ~= nil and observed_target_name_key(name) ~= pending.target_key) then
        return nil;
    end

    return pending;
end

function clear_pending_target_debuff_if_matches(name)
    local pending = pending_target_debuff_cast();
    if (pending ~= nil and (pending.target_key == nil or observed_target_name_key(name) == pending.target_key)) then
        state.pending_target_debuff_cast = nil;
        return true;
    end

    return false;
end

function process_observed_target_debuff_text(message)
    local text = clean_event_message(message);
    if (#text == 0) then
        return false;
    end

    local player = current_player_name();
    if (#player > 0) then
        local actor, spell, target = text:match('^(.-) starts casting (.-) on (.-)%.$');
        if (actor == player and spell ~= nil and target ~= nil) then
            return set_pending_target_debuff_cast(spell, target);
        end

        actor, spell = text:match('^(.-) casts (.-)%.$');
        if (actor == player and spell ~= nil and target_debuff_key_from_spell_name(spell) ~= nil) then
            local pending = pending_target_debuff_cast();
            if (pending == nil or target_debuff_key_from_spell_name(spell) ~= pending.key) then
                return set_pending_target_debuff_cast(spell, nil);
            end

            pending.spell_name = clean_string(spell);
            pending.spell_id = target_debuff_spell_id_from_name(spell) or pending.spell_id;
            pending.started_at = os.time();
            return true;
        end

        actor, spell, target = text:match("^(.-)'s (.-) has no effect on (.-)%.$");
        if (actor == player and spell ~= nil and target ~= nil and clear_pending_target_debuff_if_matches(target)) then
            return true;
        end

        if (text == (player .. "'s casting is interrupted.")) then
            state.pending_target_debuff_cast = nil;
            return true;
        end
    end

    local target, status = text:match("^(.-)'s (.-) effect wears off%.?$");
    if (target ~= nil and status ~= nil and clear_observed_target_debuff_name_status(target, status)) then
        return true;
    end

    target = text:match('^(.-) falls to the ground%.$');
    if (target ~= nil) then
        local cleared = clear_observed_target_debuff_name(target);
        clear_pending_target_debuff_if_matches(target);
        return cleared;
    end

    target = text:match('^.- defeats (.-)%.$');
    if (target ~= nil) then
        local cleared = clear_observed_target_debuff_name(target);
        clear_pending_target_debuff_if_matches(target);
        return cleared;
    end

    target = text:match('^Unable to see (.-)%.$') or text:match('^You lose sight of (.-)%.$') or text:match('^(.-) is out of range%.$') or text:match('^(.-) is too far away%.$');
    if (target ~= nil and clear_pending_target_debuff_if_matches(target)) then
        return true;
    end

    target = text:match('^(.-) resists the spell%.$');
    if (target ~= nil and clear_pending_target_debuff_if_matches(target)) then
        return true;
    end

    target = text:match('^(.-) takes %d+ points of damage%.$');
    local pending = pending_target_matches(target, 'dia');
    if (pending ~= nil) then
        state.pending_target_debuff_cast = nil;
        return set_observed_target_debuff_name(target, pending.key, true, pending.spell_id);
    end

    target = text:match('^(.-) is paralyzed%.$');
    pending = pending_target_matches(target, 'paralyze');
    if (pending ~= nil) then
        state.pending_target_debuff_cast = nil;
        return set_observed_target_debuff_name(target, pending.key, true, pending.spell_id);
    end

    target = text:match('^(.-) is slowed%.$');
    pending = pending_target_matches(target, 'slow');
    if (pending ~= nil) then
        state.pending_target_debuff_cast = nil;
        return set_observed_target_debuff_name(target, pending.key, true, pending.spell_id);
    end

    return false;
end

function process_observed_text(message)
    local handled = process_observed_buff_text(message);
    return process_observed_target_debuff_text(message) or handled;
end

local function current_chat_log_path()
    local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
    local party = memory ~= nil and safe_read(function () return memory:GetParty(); end, nil) or nil;
    local character = party ~= nil and clean_string(safe_read(function () return party:GetMemberName(0); end, '')) or '';
    if (#character == 0) then
        return nil;
    end

    local install_path = clean_string(safe_read(function () return AshitaCore:GetInstallPath(); end, ''));
    if (#install_path == 0) then
        return nil;
    end

    return ('%schatlogs\\%s_%s.log'):fmt(install_path, character, os.date('%Y.%m.%d'));
end

local function seed_observed_buffs_from_chat_log()
    local path = current_chat_log_path();
    if (path == nil) then
        return;
    end

    local file = io.open(path, 'r');
    if (file == nil) then
        return;
    end

    local lines = { };
    for line in file:lines() do
        table.insert(lines, line);
        if (#lines > OBSERVED_LOG_SEED_MAX_LINES) then
            table.remove(lines, 1);
        end
    end
    local position = file:seek('end') or 0;
    file:close();

    local start_index = 1;
    for index = #lines, 1, -1 do
        if (clean_event_message(lines[index]):find('^=== Area: ') ~= nil) then
            start_index = index + 1;
            break;
        end
    end

    for index = start_index, #lines, 1 do
        process_observed_text(lines[index]);
    end

    state.observed_log_path = path;
    state.observed_log_position = position;
end

local function poll_observed_buffs_from_chat_log()
    local now = os.time();
    if (state.observed_log_last_check == now) then
        return;
    end
    state.observed_log_last_check = now;

    local path = current_chat_log_path();
    if (path == nil) then
        return;
    end

    if (state.observed_log_path ~= path) then
        state.observed_log_path = path;
        state.observed_log_position = 0;
        seed_observed_buffs_from_chat_log();
        return;
    end

    local file = io.open(path, 'r');
    if (file == nil) then
        return;
    end

    local size = file:seek('end') or 0;
    local position = tonumber(state.observed_log_position) or 0;
    if (position <= 0 or position > size) then
        state.observed_log_position = size;
        file:close();
        return;
    end

    file:seek('set', position);
    for line in file:lines() do
        if (process_observed_text(line)) then
            state.observed_log_events = state.observed_log_events + 1;
        end
    end

    state.observed_log_position = file:seek() or size;
    file:close();
end

local function handle_text_in(e)
    local candidates = {
        e.message,
        e.message_modified,
        e.modified_message,
    };

    local seen = { };
    for _, message in ipairs(candidates) do
        local text = tostring(message or '');
        if (#text > 0 and seen[text] ~= true) then
            seen[text] = true;
            if (process_observed_text(text)) then
                state.observed_text_events = state.observed_text_events + 1;
                return;
            end
        end
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
    seed_observed_buffs_from_chat_log();
    log_info('Loaded. Use /ashitaframes config to position frames.');
end);

ashita.events.register('command', 'command_cb', function (e)
    handle_command(e);
end);

ashita.events.register('text_in', 'text_in_cb', function (e)
    handle_text_in(e);
end);

ashita.events.register('incoming_packet', 'incoming_packet_cb', function (e)
    handle_incoming_packet(e);
end);

ashita.events.register('d3d_present', 'present_cb', function ()
    poll_observed_buffs_from_chat_log();
    prune_observed_target_debuffs();

    if (not state.visible[1]) then
        render_config_window();
        return;
    end

    render_target();
    render_self();
    render_pet();
    render_party();
    render_config_window();
end);

