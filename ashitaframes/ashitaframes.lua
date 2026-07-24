addon.name      = 'ashitaframes';
addon.author    = 'EflfK';
addon.version   = '0.8.3';
addon.desc      = 'Party and target unit frames for Ashita with attended self-buff cancellation.';
addon.link      = 'https://github.com/EflfK/ashitaframes';

require('common');

local bit   = require('bit');
local chat  = require('chat');
local d3d8  = require('d3d8');
local ffi   = require('ffi');
local imgui = require('imgui');
local mobdb = require('ashitaframes_mobdb');

local d3d8_device = nil;
PARTY_SELECTION = {
    PROTOCOL_COMMAND = '/ashitaui',
    TTL_SECONDS = 22.0,
};
SELF_BUFF_CANCELLATION = {
    PACKET_ID = 0xF1,
};

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
    show_battle_targets = true,
    show_party = true,
    show_pet = true,
    show_alliance = false,
    show_empty_target = true,
    same_zone_dim = true,
    show_jobs = true,
    show_percent = true,
    show_mp = true,
    show_tp = true,
    show_cast = true,
    show_buffs = true,
    show_buff_reminders = true,
    show_target_debuffs = true,
    show_target_debuff_reminders = true,
    show_target_mobdb = true,
    show_battle_target_debuffs = true,
    hide_buff_reminders_in_towns = true,
    buff_reminder_suppressed_zone_ids = { },
    signet_reminder_enabled = true,
    signet_warning_minutes = 30,
    max_buffs = 8,
    party_preview_size = 6,
    battle_target_max_entries = 8,
    mp_text_threshold = 1,
    tp_text_threshold = 1000,
    cast_text_threshold = 1,
    self_window_x = 36,
    self_window_y = 164,
    party_window_x = 36,
    party_window_y = 362,
    pet_window_x = 36,
    pet_window_y = 230,
    target_window_x = 36,
    target_window_y = 296,
    battle_window_x = 285,
    battle_window_y = 296,
    frame_width = 232,
    height = -1,
    row_height = 56,
    row_gap = 5,
    opacity = 88,
    hp_bar_height = 38,
    mp_bar_height = 18,
    tp_bar_height = 18,
    cast_bar_height = 18,
    self_frame_width = -1,
    self_height = -1,
    self_row_height = -1,
    self_row_gap = -1,
    self_opacity = -1,
    self_hp_bar_height = -1,
    self_mp_bar_height = -1,
    self_tp_bar_height = -1,
    self_cast_bar_height = -1,
    self_show_mp = 'default',
    self_show_tp = 'default',
    self_show_cast = 'default',
    self_mp_text_threshold = -1,
    self_tp_text_threshold = -1,
    self_cast_text_threshold = -1,
    party_frame_width = -1,
    party_height = -1,
    party_row_height = -1,
    party_row_gap = -1,
    party_opacity = -1,
    party_hp_bar_height = -1,
    party_mp_bar_height = -1,
    party_tp_bar_height = -1,
    party_cast_bar_height = -1,
    party_show_mp = 'default',
    party_show_tp = 'default',
    party_show_cast = 'default',
    party_mp_text_threshold = -1,
    party_tp_text_threshold = -1,
    party_cast_text_threshold = -1,
    party_size_layouts = { },
    pet_frame_width = -1,
    pet_height = -1,
    pet_row_height = -1,
    pet_row_gap = -1,
    pet_opacity = -1,
    pet_hp_bar_height = -1,
    pet_mp_bar_height = -1,
    pet_tp_bar_height = -1,
    pet_cast_bar_height = -1,
    pet_show_mp = 'default',
    pet_show_tp = 'default',
    pet_show_cast = 'default',
    pet_mp_text_threshold = -1,
    pet_tp_text_threshold = -1,
    pet_cast_text_threshold = -1,
    target_frame_width = -1,
    target_height = -1,
    target_row_height = -1,
    target_row_gap = -1,
    target_opacity = -1,
    target_hp_bar_height = -1,
    target_mp_bar_height = -1,
    target_tp_bar_height = -1,
    target_cast_bar_height = -1,
    target_show_mp = false,
    target_show_tp = false,
    target_show_cast = 'default',
    target_mp_text_threshold = -1,
    target_tp_text_threshold = -1,
    target_cast_text_threshold = -1,
    battle_frame_width = -1,
    battle_height = -1,
    battle_row_height = -1,
    battle_row_gap = -1,
    battle_opacity = -1,
    battle_hp_bar_height = -1,
    battle_mp_bar_height = -1,
    battle_tp_bar_height = -1,
    battle_cast_bar_height = -1,
    battle_show_mp = false,
    battle_show_tp = false,
    battle_show_cast = 'default',
    battle_mp_text_threshold = -1,
    battle_tp_text_threshold = -1,
    battle_cast_text_threshold = -1,
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
    party_selection_fill = { 0.62, 0.42, 1.00, 0.16 },
    party_selection_border = { 0.86, 0.72, 1.00, 1.00 },
    hp = { 0.25, 0.76, 0.35, 0.90 },
    mobdb_hp = { 0.29, 0.46, 0.34, 0.94 },
    hp_low = { 0.92, 0.30, 0.22, 0.92 },
    mp = { 0.28, 0.52, 0.98, 0.82 },
    tp = { 0.96, 0.78, 0.26, 0.86 },
    cast = { 0.42, 0.82, 0.94, 0.92 },
    bar_empty = { 0.08, 0.08, 0.08, 0.78 },
    text = { 0.94, 0.91, 0.82, 1.00 },
    text_muted = { 0.66, 0.66, 0.68, 0.92 },
    text_dim = { 0.45, 0.45, 0.48, 0.84 },
    hp_text = { 0.98, 1.00, 0.98, 1.00 },
    mp_text = { 0.94, 0.98, 1.00, 1.00 },
    tp_text = { 0.13, 0.10, 0.02, 1.00 },
    cast_text = { 0.03, 0.10, 0.12, 1.00 },
    light_text_shadow = { 0.00, 0.00, 0.00, 0.90 },
    dark_text_shadow = { 1.00, 1.00, 0.92, 0.52 },
    accent = { 0.42, 0.82, 0.94, 1.00 },
    shadow = { 0.00, 0.00, 0.00, 0.90 },
    warning = { 1.00, 0.56, 0.26, 1.00 },
    buff_active_border = { 0.08, 0.10, 0.10, 0.90 },
    buff_missing_bg = { 0.70, 0.05, 0.03, 0.76 },
    buff_missing_border = { 1.00, 0.10, 0.05, 1.00 },
    buff_missing_flash = { 1.00, 0.94, 0.18, 1.00 },
    buff_expiring_bg = { 0.52, 0.28, 0.02, 0.76 },
    buff_expiring_border = { 1.00, 0.58, 0.08, 1.00 },
    buff_expiring_flash = { 1.00, 0.94, 0.18, 1.00 },
    mobdb_weak_bg = { 0.02, 0.18, 0.28, 0.88 },
    mobdb_weak_border = { 0.20, 0.82, 1.00, 0.92 },
    mobdb_strong_bg = { 0.30, 0.07, 0.05, 0.88 },
    mobdb_strong_border = { 1.00, 0.42, 0.24, 0.92 },
};

local BUFF_ICON_SIZE = 54;
local BUFF_ICON_GAP = 6;
local BUFF_RAIL = {
    width = 48,
    icon_size = 22,
    icon_gap = 5,
    badge_width = 24,
    badge_height = 18,
};
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
TARGET_DEBUFF_EFFECT_OVERRIDES = {
    [23] = 134,  -- Dia
    [24] = 134,  -- Dia II
    [25] = 134,  -- Dia III
    [26] = 134,  -- Dia IV
    [27] = 134,  -- Dia V
    [33] = 134,  -- Diaga
    [230] = 135, -- Bio
    [231] = 135, -- Bio II
    [232] = 135, -- Bio III
    [233] = 135, -- Bio IV
    [234] = 135, -- Bio V
    [201] = 386, -- Quickstep
    [202] = 391, -- Box Step
    [203] = 396, -- Stutter Step
    [312] = 448, -- Feather Step
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
    width_max = 750,
    row_height_min = 32,
    target_row_height_with_debuffs_min = 119,
    party_row_height_with_buffs_min = 92,
    row_height_max = 132,
    row_gap_min = 0,
    row_gap_max = 14,
    bar_height_min = 8,
    bar_height_max = 64,
    max_buffs_min = 1,
    max_buffs_max = 16,
    battle_target_max_entries_min = 1,
    battle_target_max_entries_max = 16,
    signet_warning_minutes_min = 1,
    signet_warning_minutes_max = 240,
    mp_text_threshold_min = 0,
    mp_text_threshold_max = 100,
    tp_text_threshold_min = 0,
    tp_text_threshold_max = 3000,
    cast_text_threshold_min = 0,
    cast_text_threshold_max = 100,
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
    buff_id_cache = { },
    status_description_cache = { },
    buff_icon_cache = { },
    status_icon_cache = { },
    mobdb_icon_cache = { },
    item_icon_cache = { },
    observed_buffs = { },
    observed_target_buffs = { },
    observed_target_buff_names = { },
    observed_target_debuffs = { },
    observed_target_debuff_names = { },
    observed_target_checks = { },
    pending_target_debuff_cast = nil,
    active_casts_by_id = { },
    active_casts_by_name = { },
    cast_events = 0,
    suppress_cast_tracking = false,
    observed_buff_zone_id = nil,
    observed_text_events = 0,
    observed_log_path = nil,
    observed_log_position = 0,
    observed_log_last_check = 0,
    observed_log_events = 0,
    window_lock_state = { },
    self_window_x = 36,
    self_window_y = 164,
    party_window_x = 36,
    party_window_y = 362,
    pet_window_x = 36,
    pet_window_y = 230,
    target_window_x = 36,
    target_window_y = 296,
    battle_window_x = 285,
    battle_window_y = 296,
    battle_targets = { },
    battle_target_last_scan = 0,
    party_selection = nil,
};

function PARTY_SELECTION.clear(token)
    local selection = state.party_selection;
    if (selection == nil or token == nil or tostring(selection.token) == tostring(token)) then
        state.party_selection = nil;
    end
end

function PARTY_SELECTION.set(token, slot, server_id)
    slot = tonumber(slot);
    server_id = tonumber(server_id);
    if (token == nil or slot == nil or slot < 0 or slot > 5 or server_id == nil or server_id < 0) then
        return false;
    end

    state.party_selection = {
        token = tostring(token),
        slot = math.floor(slot),
        server_id = math.floor(server_id),
        expires_at = os.clock() + PARTY_SELECTION.TTL_SECONDS,
    };
    return true;
end

function PARTY_SELECTION.prune()
    local selection = state.party_selection;
    if (selection ~= nil and os.clock() >= (tonumber(selection.expires_at) or 0)) then
        state.party_selection = nil;
    end
end

function PARTY_SELECTION.matches(unit)
    PARTY_SELECTION.prune();
    local selection = state.party_selection;
    if (selection == nil or type(unit) ~= 'table' or unit.kind ~= 'party') then
        return false;
    end

    return tonumber(unit.index) == selection.slot
        and tonumber(unit.server_id) == selection.server_id;
end

function PARTY_SELECTION.handle_command(e, args)
    local command = tostring(args[1] or ''):lower();
    local topic = tostring(args[2] or ''):lower();
    if (#args < 3 or command ~= PARTY_SELECTION.PROTOCOL_COMMAND or topic ~= 'partyselect') then
        return false;
    end

    e.blocked = true;
    local action = tostring(args[3] or ''):lower();
    if (action == 'set' and #args >= 6) then
        PARTY_SELECTION.set(args[4], args[5], args[6]);
    elseif (action == 'clear' and #args >= 4) then
        PARTY_SELECTION.clear(args[4]);
    end
    return true;
end

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

local WINDOW_PADDING_UNLOCKED = 8;
local WINDOW_PADDING_LOCKED = 4;
local WINDOW_TITLE_HEIGHT_FALLBACK = 22;

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

function resource_text_height()
    local ok, height = pcall(function () return imgui.GetFontSize(); end);
    if (not ok) then
        height = nil;
    end

    return math.ceil(tonumber(height) or 14);
end

function resource_bar_min_height()
    return math.max(LIMITS.bar_height_min, resource_text_height() + 4);
end

function normalize_resource_bar_height(value, fallback)
    value = tonumber(value);
    if (value == nil or value <= 0) then
        value = fallback;
    end

    return clamp_int(value, resource_bar_min_height(), LIMITS.bar_height_max);
end

function effective_resource_bar_height(value)
    return normalize_resource_bar_height(value, value);
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

function normalize_cast_text_threshold(value, fallback)
    value = tonumber(value);
    if (value == nil or value < 0) then
        value = fallback;
    end

    return clamp_int(value, LIMITS.cast_text_threshold_min, LIMITS.cast_text_threshold_max);
end

function apply_frame_bar_options(layout, kind)
    layout.kind = kind;
    layout.hp_bar_height = state.settings[('%s_hp_bar_height'):fmt(kind)] or state.settings.hp_bar_height;
    layout.mp_bar_height = state.settings[('%s_mp_bar_height'):fmt(kind)] or state.settings.mp_bar_height;
    layout.tp_bar_height = state.settings[('%s_tp_bar_height'):fmt(kind)] or state.settings.tp_bar_height;
    layout.cast_bar_height = state.settings[('%s_cast_bar_height'):fmt(kind)] or state.settings.cast_bar_height;
    layout.show_mp = state.settings[('%s_show_mp'):fmt(kind)] == true;
    layout.show_tp = state.settings[('%s_show_tp'):fmt(kind)] == true;
    layout.show_cast = state.settings[('%s_show_cast'):fmt(kind)] == true;
    layout.mp_text_threshold = state.settings[('%s_mp_text_threshold'):fmt(kind)] or state.settings.mp_text_threshold;
    layout.tp_text_threshold = state.settings[('%s_tp_text_threshold'):fmt(kind)] or state.settings.tp_text_threshold;
    layout.cast_text_threshold = state.settings[('%s_cast_text_threshold'):fmt(kind)] or state.settings.cast_text_threshold;

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

    return (tostring(value):gsub('%z', ''):gsub('^%s+', ''):gsub('%s+$', ''));
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

local function ashita_install_path()
    return clean_string(safe_read(function () return AshitaCore:GetInstallPath(); end, ''));
end

local function config_addons_dir_path()
    local root = ashita_install_path();
    if (#root == 0) then
        return '';
    end

    return path_join(path_join(root, 'config'), 'addons');
end

local function config_dir_path()
    local parent = config_addons_dir_path();
    if (#parent == 0) then
        return '';
    end

    return path_join(parent, addon.name);
end

local function legacy_config_file_path()
    return path_join(addon.path, 'ashitaframes_config.lua');
end

local function config_file_path()
    local dir = config_dir_path();
    if (#dir == 0) then
        return legacy_config_file_path();
    end

    return path_join(dir, 'ashitaframes_config.lua');
end

local function file_exists(path)
    local file = io.open(path, 'r');
    if (file == nil) then
        return false;
    end

    file:close();
    return true;
end

local function ensure_directory(path)
    if (#clean_string(path) == 0) then
        return false, 'empty directory path';
    end
    if (ashita ~= nil and ashita.fs ~= nil and ashita.fs.exists ~= nil and ashita.fs.exists(path)) then
        return true;
    end

    local create_dir = ashita ~= nil and ashita.fs ~= nil and (ashita.fs.create_dir or ashita.fs.create_directory) or nil;
    if (create_dir == nil) then
        return false, 'ashita.fs directory creation is unavailable';
    end
    if (create_dir(path) == false) then
        return false, ('failed to create directory: %s'):fmt(path);
    end

    return true;
end

local function ensure_config_dir()
    local parent = config_addons_dir_path();
    local dir = config_dir_path();
    if (#parent == 0 or #dir == 0) then
        return false, 'could not determine Ashita config directory';
    end

    local ok, err = ensure_directory(parent);
    if (not ok) then
        return false, err;
    end

    return ensure_directory(dir);
end

local function load_lua_config(path)
    local chunk, load_error = loadfile(path);
    if (chunk == nil) then
        return false, nil, tostring(load_error or 'load failed');
    end

    local ok, config = pcall(chunk);
    if (not ok) then
        return false, nil, tostring(config or 'execution failed');
    end

    return true, config, nil;
end

local function copy_file(source, target)
    local input, input_error = io.open(source, 'rb');
    if (input == nil) then
        return false, tostring(input_error or 'open source failed');
    end

    local data = input:read('*a');
    input:close();

    local output, output_error = io.open(target, 'wb');
    if (output == nil) then
        return false, tostring(output_error or 'open target failed');
    end

    output:write(data or '');
    output:close();
    return true;
end

local function migrate_legacy_config_if_needed()
    local path = config_file_path();
    local legacy_path = legacy_config_file_path();
    if (path:lower() == legacy_path:lower() or file_exists(path) or not file_exists(legacy_path)) then
        return true, nil;
    end

    local ok, err = ensure_config_dir();
    if (not ok) then
        return false, err;
    end

    ok, err = copy_file(legacy_path, path);
    if (not ok) then
        return false, err;
    end

    return true, ('Migrated legacy config to %s.'):fmt(path);
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
    settings.show_battle_targets = settings.show_battle_targets ~= false;
    settings.show_party = settings.show_party ~= false;
    settings.show_pet = settings.show_pet ~= false;
    settings.show_alliance = settings.show_alliance == true;
    settings.show_empty_target = settings.show_empty_target ~= false;
    settings.same_zone_dim = settings.same_zone_dim ~= false;
    settings.show_jobs = settings.show_jobs ~= false;
    settings.show_percent = settings.show_percent ~= false;
    settings.show_mp = settings.show_mp ~= false;
    settings.show_tp = settings.show_tp ~= false;
    settings.show_cast = settings.show_cast ~= false;
    settings.show_buffs = settings.show_buffs ~= false;
    settings.show_buff_reminders = settings.show_buff_reminders ~= false;
    settings.show_target_debuffs = settings.show_target_debuffs ~= false;
    settings.show_target_debuff_reminders = settings.show_target_debuff_reminders ~= false;
    settings.show_target_mobdb = settings.show_target_mobdb ~= false;
    settings.show_battle_target_debuffs = settings.show_battle_target_debuffs ~= false;
    settings.hide_buff_reminders_in_towns = settings.hide_buff_reminders_in_towns ~= false;
    settings.signet_reminder_enabled = settings.signet_reminder_enabled ~= false;

    settings.self_window_x = clamp_int(settings.self_window_x, -2000, 4000);
    settings.self_window_y = clamp_int(settings.self_window_y, -2000, 4000);
    settings.party_window_x = clamp_int(settings.party_window_x, -2000, 4000);
    settings.party_window_y = clamp_int(settings.party_window_y, -2000, 4000);
    settings.pet_window_x = clamp_int(settings.pet_window_x, -2000, 4000);
    settings.pet_window_y = clamp_int(settings.pet_window_y, -2000, 4000);
    settings.target_window_x = clamp_int(settings.target_window_x, -2000, 4000);
    settings.target_window_y = clamp_int(settings.target_window_y, -2000, 4000);
    settings.battle_window_x = clamp_int(settings.battle_window_x, -2000, 4000);
    settings.battle_window_y = clamp_int(settings.battle_window_y, -2000, 4000);
    settings.frame_width = clamp_int(settings.frame_width, LIMITS.width_min, LIMITS.width_max);
    settings.row_height = normalize_frame_row_height(settings.height or settings.row_height, settings.row_height);
    settings.height = settings.row_height;
    settings.row_gap = clamp_int(settings.row_gap, LIMITS.row_gap_min, LIMITS.row_gap_max);
    settings.hp_bar_height = normalize_resource_bar_height(settings.hp_bar_height, DEFAULT_SETTINGS.hp_bar_height);
    settings.mp_bar_height = normalize_resource_bar_height(settings.mp_bar_height, DEFAULT_SETTINGS.mp_bar_height);
    settings.tp_bar_height = normalize_resource_bar_height(settings.tp_bar_height, DEFAULT_SETTINGS.tp_bar_height);
    settings.cast_bar_height = normalize_resource_bar_height(settings.cast_bar_height, DEFAULT_SETTINGS.cast_bar_height);
    settings.max_buffs = clamp_int(settings.max_buffs, LIMITS.max_buffs_min, LIMITS.max_buffs_max);
    settings.battle_target_max_entries = clamp_int(settings.battle_target_max_entries, LIMITS.battle_target_max_entries_min, LIMITS.battle_target_max_entries_max);
    settings.signet_warning_minutes = clamp_int(settings.signet_warning_minutes, LIMITS.signet_warning_minutes_min, LIMITS.signet_warning_minutes_max);
    settings.party_preview_size = party_size(settings.party_preview_size);
    settings.mp_text_threshold = normalize_mp_text_threshold(settings.mp_text_threshold, 1);
    settings.tp_text_threshold = normalize_tp_text_threshold(settings.tp_text_threshold, 1000);
    settings.cast_text_threshold = normalize_cast_text_threshold(settings.cast_text_threshold, 1);
    settings.opacity = clamp_int(settings.opacity, LIMITS.opacity_min, LIMITS.opacity_max);
    settings.self_frame_width = normalize_frame_width(settings.self_frame_width, settings.frame_width);
    settings.self_row_height = normalize_frame_row_height(settings.self_height or settings.self_row_height, settings.row_height);
    settings.self_height = settings.self_row_height;
    settings.self_row_gap = normalize_frame_row_gap(settings.self_row_gap, settings.row_gap);
    settings.self_opacity = normalize_frame_opacity(settings.self_opacity, settings.opacity);
    settings.self_hp_bar_height = normalize_resource_bar_height(settings.self_hp_bar_height, settings.hp_bar_height);
    settings.self_mp_bar_height = normalize_resource_bar_height(settings.self_mp_bar_height, settings.mp_bar_height);
    settings.self_tp_bar_height = normalize_resource_bar_height(settings.self_tp_bar_height, settings.tp_bar_height);
    settings.self_cast_bar_height = normalize_resource_bar_height(settings.self_cast_bar_height, settings.cast_bar_height);
    settings.self_show_mp = normalize_frame_bar_enabled(settings.self_show_mp, settings.show_mp);
    settings.self_show_tp = normalize_frame_bar_enabled(settings.self_show_tp, settings.show_tp);
    settings.self_show_cast = normalize_frame_bar_enabled(settings.self_show_cast, settings.show_cast);
    settings.self_mp_text_threshold = normalize_mp_text_threshold(settings.self_mp_text_threshold, settings.mp_text_threshold);
    settings.self_tp_text_threshold = normalize_tp_text_threshold(settings.self_tp_text_threshold, settings.tp_text_threshold);
    settings.self_cast_text_threshold = normalize_cast_text_threshold(settings.self_cast_text_threshold, settings.cast_text_threshold);
    settings.party_frame_width = normalize_frame_width(settings.party_frame_width, settings.frame_width);
    settings.party_row_height = normalize_frame_row_height(settings.party_height or settings.party_row_height, settings.row_height);
    settings.party_height = settings.party_row_height;
    settings.party_row_gap = normalize_frame_row_gap(settings.party_row_gap, settings.row_gap);
    settings.party_opacity = normalize_frame_opacity(settings.party_opacity, settings.opacity);
    settings.party_hp_bar_height = normalize_resource_bar_height(settings.party_hp_bar_height, settings.hp_bar_height);
    settings.party_mp_bar_height = normalize_resource_bar_height(settings.party_mp_bar_height, settings.mp_bar_height);
    settings.party_tp_bar_height = normalize_resource_bar_height(settings.party_tp_bar_height, settings.tp_bar_height);
    settings.party_cast_bar_height = normalize_resource_bar_height(settings.party_cast_bar_height, settings.cast_bar_height);
    settings.party_show_mp = normalize_frame_bar_enabled(settings.party_show_mp, settings.show_mp);
    settings.party_show_tp = normalize_frame_bar_enabled(settings.party_show_tp, settings.show_tp);
    settings.party_show_cast = normalize_frame_bar_enabled(settings.party_show_cast, settings.show_cast);
    settings.party_mp_text_threshold = normalize_mp_text_threshold(settings.party_mp_text_threshold, settings.mp_text_threshold);
    settings.party_tp_text_threshold = normalize_tp_text_threshold(settings.party_tp_text_threshold, settings.tp_text_threshold);
    settings.party_cast_text_threshold = normalize_cast_text_threshold(settings.party_cast_text_threshold, settings.cast_text_threshold);
    settings.party_size_layouts = normalize_party_size_layouts(settings.party_size_layouts, settings);
    settings.pet_frame_width = normalize_frame_width(settings.pet_frame_width, settings.frame_width);
    settings.pet_row_height = normalize_frame_row_height(settings.pet_height or settings.pet_row_height, settings.row_height);
    settings.pet_height = settings.pet_row_height;
    settings.pet_row_gap = normalize_frame_row_gap(settings.pet_row_gap, settings.row_gap);
    settings.pet_opacity = normalize_frame_opacity(settings.pet_opacity, settings.opacity);
    settings.pet_hp_bar_height = normalize_resource_bar_height(settings.pet_hp_bar_height, settings.hp_bar_height);
    settings.pet_mp_bar_height = normalize_resource_bar_height(settings.pet_mp_bar_height, settings.mp_bar_height);
    settings.pet_tp_bar_height = normalize_resource_bar_height(settings.pet_tp_bar_height, settings.tp_bar_height);
    settings.pet_cast_bar_height = normalize_resource_bar_height(settings.pet_cast_bar_height, settings.cast_bar_height);
    settings.pet_show_mp = normalize_frame_bar_enabled(settings.pet_show_mp, settings.show_mp);
    settings.pet_show_tp = normalize_frame_bar_enabled(settings.pet_show_tp, settings.show_tp);
    settings.pet_show_cast = normalize_frame_bar_enabled(settings.pet_show_cast, settings.show_cast);
    settings.pet_mp_text_threshold = normalize_mp_text_threshold(settings.pet_mp_text_threshold, settings.mp_text_threshold);
    settings.pet_tp_text_threshold = normalize_tp_text_threshold(settings.pet_tp_text_threshold, settings.tp_text_threshold);
    settings.pet_cast_text_threshold = normalize_cast_text_threshold(settings.pet_cast_text_threshold, settings.cast_text_threshold);
    settings.target_frame_width = normalize_frame_width(settings.target_frame_width, settings.frame_width);
    settings.target_row_height = normalize_frame_row_height(settings.target_height or settings.target_row_height, settings.row_height);
    settings.target_height = settings.target_row_height;
    settings.target_row_gap = normalize_frame_row_gap(settings.target_row_gap, settings.row_gap);
    settings.target_opacity = normalize_frame_opacity(settings.target_opacity, settings.opacity);
    settings.target_hp_bar_height = normalize_resource_bar_height(settings.target_hp_bar_height, settings.hp_bar_height);
    settings.target_mp_bar_height = normalize_resource_bar_height(settings.target_mp_bar_height, settings.mp_bar_height);
    settings.target_tp_bar_height = normalize_resource_bar_height(settings.target_tp_bar_height, settings.tp_bar_height);
    settings.target_cast_bar_height = normalize_resource_bar_height(settings.target_cast_bar_height, settings.cast_bar_height);
    settings.target_show_mp = normalize_frame_bar_enabled(settings.target_show_mp, false);
    settings.target_show_tp = normalize_frame_bar_enabled(settings.target_show_tp, false);
    settings.target_show_cast = normalize_frame_bar_enabled(settings.target_show_cast, settings.show_cast);
    settings.target_mp_text_threshold = normalize_mp_text_threshold(settings.target_mp_text_threshold, settings.mp_text_threshold);
    settings.target_tp_text_threshold = normalize_tp_text_threshold(settings.target_tp_text_threshold, settings.tp_text_threshold);
    settings.target_cast_text_threshold = normalize_cast_text_threshold(settings.target_cast_text_threshold, settings.cast_text_threshold);
    settings.battle_frame_width = normalize_frame_width(settings.battle_frame_width, settings.frame_width);
    settings.battle_row_height = normalize_frame_row_height(settings.battle_height or settings.battle_row_height, settings.row_height);
    settings.battle_height = settings.battle_row_height;
    settings.battle_row_gap = normalize_frame_row_gap(settings.battle_row_gap, settings.row_gap);
    settings.battle_opacity = normalize_frame_opacity(settings.battle_opacity, settings.opacity);
    settings.battle_hp_bar_height = normalize_resource_bar_height(settings.battle_hp_bar_height, settings.hp_bar_height);
    settings.battle_mp_bar_height = normalize_resource_bar_height(settings.battle_mp_bar_height, settings.mp_bar_height);
    settings.battle_tp_bar_height = normalize_resource_bar_height(settings.battle_tp_bar_height, settings.tp_bar_height);
    settings.battle_cast_bar_height = normalize_resource_bar_height(settings.battle_cast_bar_height, settings.cast_bar_height);
    settings.battle_show_mp = normalize_frame_bar_enabled(settings.battle_show_mp, false);
    settings.battle_show_tp = normalize_frame_bar_enabled(settings.battle_show_tp, false);
    settings.battle_show_cast = normalize_frame_bar_enabled(settings.battle_show_cast, settings.show_cast);
    settings.battle_mp_text_threshold = normalize_mp_text_threshold(settings.battle_mp_text_threshold, settings.mp_text_threshold);
    settings.battle_tp_text_threshold = normalize_tp_text_threshold(settings.battle_tp_text_threshold, settings.tp_text_threshold);
    settings.battle_cast_text_threshold = normalize_cast_text_threshold(settings.battle_cast_text_threshold, settings.cast_text_threshold);
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

    local path = config_file_path();
    local migrated, migration_message = migrate_legacy_config_if_needed();
    if (not migrated) then
        state.config_error = ('Config migration warning: %s'):fmt(tostring(migration_message));
    end

    local load_path = file_exists(path) and path or legacy_config_file_path();
    if (file_exists(load_path)) then
        local ok, config, error_message = load_lua_config(load_path);
        if (not ok) then
            state.config_error = ('%s: %s'):fmt(load_path, tostring(error_message));
        elseif (type(config) == 'table') then
            overlay_settings(settings, config.settings);
        end
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
    state.battle_window_x = state.settings.battle_window_x;
    state.battle_window_y = state.settings.battle_window_y;
    state.battle_targets = { };
    state.battle_target_last_scan = 0;
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

function resource_percent_from_pair(current, max)
    current = resource_current_value(current);
    max = resource_current_value(max);

    if (current == nil or max == nil or max <= 0) then
        return nil;
    end

    return clamp((current / max) * 100, 0, 100);
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

function player_status_remaining_seconds(raw_timer)
    raw_timer = tonumber(raw_timer);
    if (raw_timer == nil) then
        return nil;
    end
    if (raw_timer == 0x7FFFFFFF) then
        return -1;
    end

    local comparand = (os.time() - 0x3C307D70) * 60;
    local remaining = raw_timer - comparand;
    while (remaining < -2147483648) do
        remaining = remaining + 0xFFFFFFFF;
    end

    if (remaining < 1) then
        return 0;
    end

    return math.ceil(remaining / 60);
end

local function player_buffs()
    local player = safe_read(function () return AshitaCore:GetMemoryManager():GetPlayer(); end, nil);
    local icons = player ~= nil and safe_read(function () return player:GetStatusIcons(); end, nil) or nil;
    local timers = player ~= nil and safe_read(function () return player:GetStatusTimers(); end, nil) or nil;
    local result = { };
    local remaining = { };
    local seen = { };

    if (icons == nil) then
        return result, remaining;
    end

    for index = 1, 32, 1 do
        local buff_id = safe_read(function () return icons[index]; end, nil);
        if (buff_id == 255) then
            break;
        end

        append_buff_id(result, seen, buff_id);
        if (buff_id ~= nil and timers ~= nil) then
            local seconds = player_status_remaining_seconds(safe_read(function () return timers[index]; end, nil));
            if (seconds ~= nil) then
                remaining[tonumber(buff_id)] = seconds;
            end
        end
    end

    return result, remaining;
end

function SELF_BUFF_CANCELLATION.is_self_buff(unit, item)
    return type(unit) == 'table'
        and unit.kind == 'party'
        and tonumber(unit.index) == 0
        and type(item) == 'table'
        and item.state ~= 'missing'
        and tonumber(item.id) ~= nil;
end

function SELF_BUFF_CANCELLATION.is_active(status_id)
    status_id = math.floor(tonumber(status_id) or 0);
    if (status_id <= 0 or status_id > 0x3FF) then
        return false;
    end

    local buffs = player_buffs();
    for _, buff_id in ipairs(buffs) do
        if (tonumber(buff_id) == status_id) then
            return true;
        end
    end

    return false;
end

function SELF_BUFF_CANCELLATION.cancel(status_id)
    status_id = math.floor(tonumber(status_id) or 0);
    if (not SELF_BUFF_CANCELLATION.is_active(status_id)) then
        return false;
    end

    local packet_manager = safe_read(function () return AshitaCore:GetPacketManager(); end, nil);
    if (packet_manager == nil) then
        log_error(('Could not remove status #%d: packet manager unavailable.'):fmt(status_id));
        return false;
    end

    local packet = struct.pack('bbbbhbb', SELF_BUFF_CANCELLATION.PACKET_ID, 0x04, 0x00, 0x00, status_id, 0x00, 0x00):totable();
    local sent, err = pcall(function ()
        packet_manager:AddOutgoingPacket(SELF_BUFF_CANCELLATION.PACKET_ID, packet);
    end);
    if (not sent) then
        log_error(('Could not remove status #%d: %s'):fmt(status_id, clean_string(err)));
        return false;
    end

    return true;
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

function status_icon_ids_from_indexed_source(source)
    local result = { };
    local seen = { };
    local saw_value = false;

    if (source == nil) then
        return result;
    end

    for index = 1, 32, 1 do
        local buff_id = safe_read(function () return source[index]; end, nil);
        if (buff_id ~= nil) then
            saw_value = true;
        end
        if (buff_id == 255) then
            break;
        end

        append_buff_id(result, seen, buff_id);
    end

    if (saw_value) then
        return result;
    end

    for index = 0, 31, 1 do
        local buff_id = safe_read(function () return source[index]; end, nil);
        if (buff_id == 255) then
            break;
        end

        append_buff_id(result, seen, buff_id);
    end

    return result;
end

function target_entity_buffs(entity, target_index)
    if (not state.settings.show_buffs or target_index == nil or target_index <= 0) then
        return { };
    end

    local result = status_icon_ids_from_indexed_source(entity ~= nil and safe_read(function () return entity:GetStatusIcons(target_index); end, nil) or nil);
    if (#result > 0) then
        return result;
    end

    local target_entity = safe_read(function () return GetEntity(target_index); end, nil);
    result = status_icon_ids_from_indexed_source(target_entity ~= nil and safe_read(function () return target_entity.StatusIcons; end, nil) or nil);
    if (#result > 0) then
        return result;
    end

    result = status_icon_ids_from_indexed_source(target_entity ~= nil and safe_read(function () return target_entity.Buffs; end, nil) or nil);
    if (#result > 0) then
        return result;
    end

    return status_icon_ids_from_indexed_source(target_entity ~= nil and safe_read(function () return target_entity.StatusEffects; end, nil) or nil);
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

    for buff_id, enabled in pairs(entry) do
        if (enabled == true) then
            append_buff_id(result, seen, buff_id);
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
    state.observed_target_buffs = { };
    state.observed_target_buff_names = { };
    state.observed_target_debuffs = { };
    state.observed_target_debuff_names = { };
    state.observed_target_checks = { };
    state.pending_target_debuff_cast = nil;
end

local function target_debuff_id_for_key(key)
    key = normalize_target_debuff_key(key);
    local definition = key ~= nil and TARGET_DEBUFF_DEFINITIONS[key] or nil;
    return definition ~= nil and tonumber(definition.id) or nil;
end

function target_debuff_status_id(value)
    local status_id = tonumber(value);
    if (status_id == nil) then
        status_id = target_debuff_id_for_key(value);
    end
    if (status_id == nil or status_id <= 0 or status_id == 255 or status_id > 0x3FF) then
        return nil;
    end

    return math.floor(status_id);
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

local function observed_target_debuff_status_lookup(server_id)
    prune_observed_target_debuffs();

    local target_id = tonumber(server_id);
    local entry = target_id ~= nil and state.observed_target_debuffs[target_id] or nil;
    local result = { };
    if (type(entry) ~= 'table') then
        return result;
    end

    for status_id, value in pairs(entry) do
        if (type(value) == 'table' and tonumber(value.expires_at) ~= nil and value.expires_at > os.time()) then
            result[tonumber(status_id) or status_id] = true;
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

    for status_id, value in pairs(entry) do
        if (type(value) == 'table' and tonumber(value.expires_at) ~= nil and value.expires_at > os.time()) then
            result[tonumber(status_id) or status_id] = true;
        end
    end

    return result;
end

function observed_target_debuffs_for_unit(server_id, name)
    local active = observed_target_debuff_status_lookup(server_id);
    for status_id, enabled in pairs(observed_target_debuff_name_lookup(name)) do
        if (enabled == true) then
            active[status_id] = true;
        end
    end

    local result = { };
    local seen = { };

    for status_id, _ in pairs(active) do
        append_buff_id(result, seen, status_id);
    end

    table.sort(result);

    return result;
end

function prune_observed_target_buffs()
    local now = os.time();
    for target_id, entry in pairs(state.observed_target_buffs) do
        if (type(entry) ~= 'table') then
            state.observed_target_buffs[target_id] = nil;
        else
            local has_active = false;
            for buff_id, value in pairs(entry) do
                if (type(value) ~= 'table' or tonumber(value.expires_at) == nil or value.expires_at <= now) then
                    entry[buff_id] = nil;
                else
                    has_active = true;
                end
            end

            if (not has_active) then
                state.observed_target_buffs[target_id] = nil;
            end
        end
    end

    for name, entry in pairs(state.observed_target_buff_names) do
        if (type(entry) ~= 'table') then
            state.observed_target_buff_names[name] = nil;
        else
            local has_active = false;
            for buff_id, value in pairs(entry) do
                if (type(value) ~= 'table' or tonumber(value.expires_at) == nil or value.expires_at <= now) then
                    entry[buff_id] = nil;
                else
                    has_active = true;
                end
            end

            if (not has_active) then
                state.observed_target_buff_names[name] = nil;
            end
        end
    end
end

function observed_target_buff_id_lookup(server_id)
    prune_observed_target_buffs();

    local target_id = tonumber(server_id);
    local entry = target_id ~= nil and state.observed_target_buffs[target_id] or nil;
    local result = { };
    if (type(entry) ~= 'table') then
        return result;
    end

    for buff_id, value in pairs(entry) do
        if (type(value) == 'table' and tonumber(value.expires_at) ~= nil and value.expires_at > os.time()) then
            result[tonumber(buff_id)] = true;
        end
    end

    return result;
end

function observed_target_buff_name_lookup(name)
    prune_observed_target_buffs();

    local name_key = observed_target_name_key(name);
    local entry = name_key ~= nil and state.observed_target_buff_names[name_key] or nil;
    local result = { };
    if (type(entry) ~= 'table') then
        return result;
    end

    for buff_id, value in pairs(entry) do
        if (type(value) == 'table' and tonumber(value.expires_at) ~= nil and value.expires_at > os.time()) then
            result[tonumber(buff_id)] = true;
        end
    end

    return result;
end

function observed_target_buffs_for_unit(server_id, name)
    local active = observed_target_buff_id_lookup(server_id);
    for buff_id, enabled in pairs(observed_target_buff_name_lookup(name)) do
        if (enabled == true) then
            active[buff_id] = true;
        end
    end

    local result = { };
    local seen = { };

    for buff_id, _ in pairs(active) do
        append_buff_id(result, seen, buff_id);
    end

    table.sort(result);
    return result;
end

function ensure_observed_target_checks()
    if (type(state.observed_target_checks) ~= 'table') then
        state.observed_target_checks = { };
    end
    if (type(state.observed_target_checks.by_id) ~= 'table') then
        state.observed_target_checks.by_id = { };
    end
    if (type(state.observed_target_checks.by_name) ~= 'table') then
        state.observed_target_checks.by_name = { };
    end

    return state.observed_target_checks;
end

function prune_observed_target_checks()
    local checks = ensure_observed_target_checks();
    local now = os.time();

    for key, entry in pairs(checks.by_id) do
        if (type(entry) ~= 'table' or ((now - (tonumber(entry.checked_at) or 0)) > 1800)) then
            checks.by_id[key] = nil;
        end
    end

    for key, entry in pairs(checks.by_name) do
        if (type(entry) ~= 'table' or ((now - (tonumber(entry.checked_at) or 0)) > 1800)) then
            checks.by_name[key] = nil;
        end
    end
end

function set_observed_target_check(name, server_id, toughness, level)
    local name_key = observed_target_name_key(name);
    local target_id = tonumber(server_id);
    if (name_key == nil and (target_id == nil or target_id == 0)) then
        return false;
    end

    local entry = {
        toughness = clean_string(toughness),
        level = tonumber(level),
        checked_at = os.time(),
    };
    local checks = ensure_observed_target_checks();

    if (target_id ~= nil and target_id ~= 0) then
        checks.by_id[target_id] = entry;
    end
    if (name_key ~= nil) then
        checks.by_name[name_key] = entry;
    end

    return true;
end

function observed_target_check_for_unit(server_id, name)
    prune_observed_target_checks();

    local checks = ensure_observed_target_checks();
    local target_id = tonumber(server_id);
    local entry = target_id ~= nil and checks.by_id[target_id] or nil;
    if (type(entry) == 'table') then
        return entry;
    end

    local name_key = observed_target_name_key(name);
    entry = name_key ~= nil and checks.by_name[name_key] or nil;
    if (type(entry) == 'table') then
        return entry;
    end

    return nil;
end

local function sync_observed_buffs_for_party(party, self_zone)
    local zone_id = tonumber(self_zone);
    if (zone_id ~= nil) then
        zone_id = math.floor(zone_id + 0.5);
        if (state.observed_buff_zone_id ~= nil and state.observed_buff_zone_id ~= zone_id) then
            clear_observed_buffs();
            clear_observed_target_debuffs();
            clear_active_casts();
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
        return { }, { };
    end

    local observed = observed_buffs_for_name(name);
    if (index == 0) then
        local buffs, timers = player_buffs();
        return merge_buff_lists(buffs, observed), timers;
    end

    return merge_buff_lists(party_status_buffs(index, server_id), observed), { };
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

function status_description(status_id)
    status_id = tonumber(status_id) or 0;
    if (state.status_description_cache[status_id] ~= nil) then
        return state.status_description_cache[status_id];
    end

    local resources = safe_read(function () return AshitaCore:GetResourceManager(); end, nil);
    local resource = resources ~= nil and safe_read(function () return resources:GetStatusIconByIndex(status_id); end, nil) or nil;
    local description = resource ~= nil and clean_string(safe_read(function () return resource.Description[1]; end, '')) or '';
    state.status_description_cache[status_id] = description;
    return description;
end

function format_status_duration(seconds)
    seconds = math.max(0, math.floor((tonumber(seconds) or 0) + 0.5));
    if (seconds >= 3600) then
        return ('%dh %dm'):fmt(math.floor(seconds / 3600), math.floor(math.fmod(seconds, 3600) / 60));
    end
    if (seconds >= 60) then
        return ('%dm %ds'):fmt(math.floor(seconds / 60), math.fmod(seconds, 60));
    end

    return ('%ds'):fmt(seconds);
end

function normalized_status_name(name)
    name = clean_string(name):lower():gsub('%s+', ' ');
    if (#name == 0) then
        return nil;
    end

    return name;
end

function buff_id_from_name(name)
    name = clean_string(name);
    local cache_key = normalized_status_name(name);
    if (cache_key == nil) then
        return nil;
    end
    if (state.buff_id_cache[cache_key] == false) then
        return nil;
    end
    if (state.buff_id_cache[cache_key] ~= nil) then
        return state.buff_id_cache[cache_key];
    end

    local resources = safe_read(function () return AshitaCore:GetResourceManager(); end, nil);
    if (resources == nil) then
        return nil;
    end

    local id = tonumber(safe_read(function () return resources:GetString('buffs.names', name, 2); end, nil));
    if (id ~= nil) then
        id = math.floor(id);
        local resolved = clean_string(safe_read(function () return resources:GetString('buffs.names', id); end, ''));
        if (#resolved > 0 and id > 0 and id <= 0x3FF) then
            state.buff_id_cache[cache_key] = id;
            return id;
        end
    end

    for scan_id = 1, 0x3FF, 1 do
        local resolved = clean_string(safe_read(function () return resources:GetString('buffs.names', scan_id); end, ''));
        if (normalized_status_name(resolved) == cache_key) then
            state.buff_id_cache[cache_key] = scan_id;
            return scan_id;
        end
    end

    state.buff_id_cache[cache_key] = false;
    return nil;
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

function load_mobdb_icon(icon_name)
    icon_name = clean_string(icon_name);
    if (#icon_name == 0 or state.mobdb_icon_cache[icon_name] == false) then
        return nil;
    end
    if (state.mobdb_icon_cache[icon_name] ~= nil) then
        return state.mobdb_icon_cache[icon_name];
    end

    local device = ensure_d3d_device();
    if (device == nil) then
        return nil;
    end

    local install_path = clean_string(safe_read(function () return AshitaCore:GetInstallPath(); end, ''));
    local path = ('%saddons/mobdb/icons/%s.png'):fmt(install_path, icon_name);
    if (not ashita.fs.exists(path)) then
        state.mobdb_icon_cache[icon_name] = false;
        return nil;
    end

    local texture_ptr = ffi.new('IDirect3DTexture8*[1]');
    local result = safe_read(function () return ffi.C.D3DXCreateTextureFromFileA(device, path, texture_ptr); end, nil);
    if (result ~= 0 or texture_ptr[0] == nil) then
        state.mobdb_icon_cache[icon_name] = false;
        return nil;
    end

    local texture = d3d8.gc_safe_release(ffi.cast('IDirect3DTexture8*', texture_ptr[0]));
    local icon = {
        texture = texture,
        handle = tonumber(ffi.cast('uint32_t', texture)),
    };
    state.mobdb_icon_cache[icon_name] = icon;
    return icon;
end

function load_item_icon(item_id)
    item_id = tonumber(item_id);
    if (item_id == nil or item_id <= 0 or state.item_icon_cache[item_id] == false) then
        return nil;
    end
    if (state.item_icon_cache[item_id] ~= nil) then
        return state.item_icon_cache[item_id];
    end

    local device = ensure_d3d_device();
    local resources = safe_read(function () return AshitaCore:GetResourceManager(); end, nil);
    local resource = resources ~= nil and safe_read(function () return resources:GetItemById(item_id); end, nil) or nil;
    local image_size = resource ~= nil and tonumber(safe_read(function () return resource.ImageSize; end, nil)) or nil;
    local bitmap = resource ~= nil and safe_read(function () return resource.Bitmap; end, nil) or nil;
    if (device == nil or bitmap == nil or image_size == nil or image_size <= 0) then
        state.item_icon_cache[item_id] = false;
        return nil;
    end

    local texture_ptr = ffi.new('IDirect3DTexture8*[1]');
    local result = safe_read(function ()
        return ffi.C.D3DXCreateTextureFromFileInMemoryEx(
            device,
            bitmap,
            image_size,
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
        state.item_icon_cache[item_id] = false;
        return nil;
    end

    local texture = d3d8.gc_safe_release(ffi.cast('IDirect3DTexture8*', texture_ptr[0]));
    local icon = {
        texture = texture,
        handle = tonumber(ffi.cast('uint32_t', texture)),
    };
    state.item_icon_cache[item_id] = icon;
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

function monitored_signet_item(unit)
    if (state.settings.signet_reminder_enabled ~= true or unit == nil or unit.category ~= 'self' or type(unit.buffs) ~= 'table') then
        return nil, nil;
    end

    local signet_id = buff_id_from_name('Signet');
    if (signet_id == nil) then
        return nil, nil;
    end

    local active = false;
    for _, buff_id in ipairs(unit.buffs) do
        if (tonumber(buff_id) == signet_id) then
            active = true;
            break;
        end
    end

    local icon = load_status_icon(signet_id);
    if (icon == nil) then
        return nil, signet_id;
    end

    if (not active) then
        return {
            id = signet_id,
            name = buff_name(signet_id),
            handle = icon.handle,
            state = 'missing',
            kind = 'status_reminder',
        }, signet_id;
    end

    local remaining = type(unit.buff_timers) == 'table' and unit.buff_timers[signet_id] or nil;
    local warning_seconds = (state.settings.signet_warning_minutes or DEFAULT_SETTINGS.signet_warning_minutes) * 60;
    if (remaining == -1 or (remaining ~= nil and remaining > warning_seconds)) then
        return nil, signet_id;
    end

    return {
        id = signet_id,
        name = buff_name(signet_id),
        handle = icon.handle,
        state = 'expiring',
        kind = 'status_reminder',
        remaining_seconds = remaining,
    }, signet_id;
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
    if (unit == nil or (unit.kind ~= 'target' and unit.kind ~= 'battle_target') or unit.target_type ~= 2 or target_debuff_suppressed_name(unit.name)) then
        return false;
    end

    if (unit.spawn_flags ~= nil and not target_debuff_has_monster_spawn_flag(unit.spawn_flags)) then
        return false;
    end

    return true;
end

local function target_debuff_reminder_keys(unit)
    if (unit == nil or unit.kind ~= 'target' or not state.settings.show_target_debuff_reminders or not target_debuff_target_eligible(unit) or tonumber(unit.server_id) == nil or tonumber(unit.server_id) == 0) then
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

local function missing_buff_icon_items(unit, active_keys)
    local items = { };
    active_keys = active_keys or active_buff_key_lookup(unit.buffs);

    for _, key in ipairs(reminder_buff_keys(unit)) do
        local definition = BUFF_DEFINITIONS[key];
        local icon = definition ~= nil and load_buff_icon(definition.file) or nil;
        if (definition ~= nil and active_keys[key] ~= true) then
            table.insert(items, {
                id = definition.id,
                key = key,
                name = definition.label,
                handle = icon ~= nil and icon.handle or nil,
                state = 'missing',
            });
        end
    end

    return items;
end

local function buff_icon_items(unit, missing_items)
    local items = { };
    if (type(unit.buffs) ~= 'table') then
        return items;
    end

    local max_buffs = state.settings.max_buffs or DEFAULT_SETTINGS.max_buffs;
    local active_keys = active_buff_key_lookup(unit.buffs);
    missing_items = missing_items or missing_buff_icon_items(unit, active_keys);
    local signet_item, monitored_signet_id = monitored_signet_item(unit);

    if (signet_item ~= nil and #items < max_buffs) then
        table.insert(items, signet_item);
    end

    for index = 1, #unit.buffs, 1 do
        if (#items >= max_buffs) then
            break;
        end

        local buff_id = unit.buffs[index];
        local key = buff_key_from_id(buff_id);
        local icon = buff_id ~= monitored_signet_id and load_status_icon(buff_id) or nil;
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

    for _, item in ipairs(missing_items) do
        if (#items >= max_buffs) then
            break;
        end

        if (item.handle ~= nil) then
            table.insert(items, item);
        end
    end

    return items;
end

function target_buff_icon_items(unit)
    local items = { };
    if (not state.settings.show_buffs or (unit.kind ~= 'target' and unit.kind ~= 'battle_target') or type(unit.buffs) ~= 'table') then
        return items;
    end

    local max_buffs = state.settings.max_buffs or DEFAULT_SETTINGS.max_buffs;
    for index = 1, #unit.buffs, 1 do
        if (#items >= max_buffs) then
            break;
        end

        local buff_id = unit.buffs[index];
        if (target_debuff_key_from_id(buff_id) == nil) then
            local icon = load_status_icon(buff_id);
            if (icon ~= nil) then
                table.insert(items, {
                    id = buff_id,
                    name = buff_name(buff_id),
                    handle = icon.handle,
                    state = 'active',
                    kind = 'buff',
                });
            end
        end
    end

    return items;
end

local function target_debuff_icon_items(unit)
    local items = { };
    local enabled = unit ~= nil and ((unit.kind == 'battle_target' and state.settings.show_battle_target_debuffs) or (unit.kind == 'target' and state.settings.show_target_debuffs));
    if (not enabled or type(unit.debuffs) ~= 'table') then
        return items;
    end

    local active_keys = active_target_debuff_key_lookup(unit.debuffs);

    for index = 1, #unit.debuffs, 1 do
        local debuff_id = unit.debuffs[index];
        local key = target_debuff_key_from_id(debuff_id);
        local icon = load_status_icon(debuff_id);
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
        local definition = TARGET_DEBUFF_DEFINITIONS[key];
        local icon = definition ~= nil and load_status_icon(definition.id) or nil;
        if (icon ~= nil and active_keys[key] ~= true) then
            table.insert(items, {
                id = definition.id,
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
    state.settings.battle_window_x = state.battle_window_x;
    state.settings.battle_window_y = state.battle_window_y;
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
        ('        show_battle_targets = %s,'):fmt(bool_text(settings.show_battle_targets)),
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
        ('        show_cast = %s,'):fmt(bool_text(settings.show_cast)),
        ('        show_buffs = %s,'):fmt(bool_text(settings.show_buffs)),
        ('        show_buff_reminders = %s,'):fmt(bool_text(settings.show_buff_reminders)),
        ('        show_target_debuffs = %s,'):fmt(bool_text(settings.show_target_debuffs)),
        ('        show_target_debuff_reminders = %s,'):fmt(bool_text(settings.show_target_debuff_reminders)),
        ('        show_target_mobdb = %s,'):fmt(bool_text(settings.show_target_mobdb)),
        ('        show_battle_target_debuffs = %s,'):fmt(bool_text(settings.show_battle_target_debuffs)),
        ('        hide_buff_reminders_in_towns = %s,'):fmt(bool_text(settings.hide_buff_reminders_in_towns)),
        ('        buff_reminder_suppressed_zone_ids = %s,'):fmt(zone_id_list_text(settings.buff_reminder_suppressed_zone_ids)),
        ('        signet_reminder_enabled = %s,'):fmt(bool_text(settings.signet_reminder_enabled)),
        ('        signet_warning_minutes = %d,'):fmt(settings.signet_warning_minutes),
        ('        max_buffs = %d,'):fmt(settings.max_buffs),
        ('        party_preview_size = %d,'):fmt(settings.party_preview_size),
        ('        battle_target_max_entries = %d,'):fmt(settings.battle_target_max_entries),
        ('        mp_text_threshold = %d,'):fmt(settings.mp_text_threshold),
        ('        tp_text_threshold = %d,'):fmt(settings.tp_text_threshold),
        ('        cast_text_threshold = %d,'):fmt(settings.cast_text_threshold),
        '',
        ('        self_window_x = %d,'):fmt(state.self_window_x),
        ('        self_window_y = %d,'):fmt(state.self_window_y),
        ('        party_window_x = %d,'):fmt(state.party_window_x),
        ('        party_window_y = %d,'):fmt(state.party_window_y),
        ('        pet_window_x = %d,'):fmt(state.pet_window_x),
        ('        pet_window_y = %d,'):fmt(state.pet_window_y),
        ('        target_window_x = %d,'):fmt(state.target_window_x),
        ('        target_window_y = %d,'):fmt(state.target_window_y),
        ('        battle_window_x = %d,'):fmt(state.battle_window_x),
        ('        battle_window_y = %d,'):fmt(state.battle_window_y),
        '',
        ('        frame_width = %d,'):fmt(settings.frame_width),
        ('        height = %d,'):fmt(settings.height),
        ('        row_height = %d,'):fmt(settings.row_height),
        ('        row_gap = %d,'):fmt(settings.row_gap),
        ('        opacity = %d,'):fmt(settings.opacity),
        ('        hp_bar_height = %d,'):fmt(settings.hp_bar_height),
        ('        mp_bar_height = %d,'):fmt(settings.mp_bar_height),
        ('        tp_bar_height = %d,'):fmt(settings.tp_bar_height),
        ('        cast_bar_height = %d,'):fmt(settings.cast_bar_height),
        '',
        ('        self_frame_width = %d,'):fmt(settings.self_frame_width),
        ('        self_height = %d,'):fmt(settings.self_height),
        ('        self_row_height = %d,'):fmt(settings.self_row_height),
        ('        self_row_gap = %d,'):fmt(settings.self_row_gap),
        ('        self_opacity = %d,'):fmt(settings.self_opacity),
        ('        self_hp_bar_height = %d,'):fmt(settings.self_hp_bar_height),
        ('        self_mp_bar_height = %d,'):fmt(settings.self_mp_bar_height),
        ('        self_tp_bar_height = %d,'):fmt(settings.self_tp_bar_height),
        ('        self_cast_bar_height = %d,'):fmt(settings.self_cast_bar_height),
        ('        self_show_mp = %s,'):fmt(bool_text(settings.self_show_mp)),
        ('        self_show_tp = %s,'):fmt(bool_text(settings.self_show_tp)),
        ('        self_show_cast = %s,'):fmt(bool_text(settings.self_show_cast)),
        ('        self_mp_text_threshold = %d,'):fmt(settings.self_mp_text_threshold),
        ('        self_tp_text_threshold = %d,'):fmt(settings.self_tp_text_threshold),
        ('        self_cast_text_threshold = %d,'):fmt(settings.self_cast_text_threshold),
        ('        party_frame_width = %d,'):fmt(settings.party_frame_width),
        ('        party_height = %d,'):fmt(settings.party_height),
        ('        party_row_height = %d,'):fmt(settings.party_row_height),
        ('        party_row_gap = %d,'):fmt(settings.party_row_gap),
        ('        party_opacity = %d,'):fmt(settings.party_opacity),
        ('        party_hp_bar_height = %d,'):fmt(settings.party_hp_bar_height),
        ('        party_mp_bar_height = %d,'):fmt(settings.party_mp_bar_height),
        ('        party_tp_bar_height = %d,'):fmt(settings.party_tp_bar_height),
        ('        party_cast_bar_height = %d,'):fmt(settings.party_cast_bar_height),
        ('        party_show_mp = %s,'):fmt(bool_text(settings.party_show_mp)),
        ('        party_show_tp = %s,'):fmt(bool_text(settings.party_show_tp)),
        ('        party_show_cast = %s,'):fmt(bool_text(settings.party_show_cast)),
        ('        party_mp_text_threshold = %d,'):fmt(settings.party_mp_text_threshold),
        ('        party_tp_text_threshold = %d,'):fmt(settings.party_tp_text_threshold),
        ('        party_cast_text_threshold = %d,'):fmt(settings.party_cast_text_threshold),
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
        ('        pet_hp_bar_height = %d,'):fmt(settings.pet_hp_bar_height),
        ('        pet_mp_bar_height = %d,'):fmt(settings.pet_mp_bar_height),
        ('        pet_tp_bar_height = %d,'):fmt(settings.pet_tp_bar_height),
        ('        pet_cast_bar_height = %d,'):fmt(settings.pet_cast_bar_height),
        ('        pet_show_mp = %s,'):fmt(bool_text(settings.pet_show_mp)),
        ('        pet_show_tp = %s,'):fmt(bool_text(settings.pet_show_tp)),
        ('        pet_show_cast = %s,'):fmt(bool_text(settings.pet_show_cast)),
        ('        pet_mp_text_threshold = %d,'):fmt(settings.pet_mp_text_threshold),
        ('        pet_tp_text_threshold = %d,'):fmt(settings.pet_tp_text_threshold),
        ('        pet_cast_text_threshold = %d,'):fmt(settings.pet_cast_text_threshold),
        ('        target_frame_width = %d,'):fmt(settings.target_frame_width),
        ('        target_height = %d,'):fmt(settings.target_height),
        ('        target_row_height = %d,'):fmt(settings.target_row_height),
        ('        target_row_gap = %d,'):fmt(settings.target_row_gap),
        ('        target_opacity = %d,'):fmt(settings.target_opacity),
        ('        target_hp_bar_height = %d,'):fmt(settings.target_hp_bar_height),
        ('        target_mp_bar_height = %d,'):fmt(settings.target_mp_bar_height),
        ('        target_tp_bar_height = %d,'):fmt(settings.target_tp_bar_height),
        ('        target_cast_bar_height = %d,'):fmt(settings.target_cast_bar_height),
        ('        target_show_mp = %s,'):fmt(bool_text(settings.target_show_mp)),
        ('        target_show_tp = %s,'):fmt(bool_text(settings.target_show_tp)),
        ('        target_show_cast = %s,'):fmt(bool_text(settings.target_show_cast)),
        ('        target_mp_text_threshold = %d,'):fmt(settings.target_mp_text_threshold),
        ('        target_tp_text_threshold = %d,'):fmt(settings.target_tp_text_threshold),
        ('        target_cast_text_threshold = %d,'):fmt(settings.target_cast_text_threshold),
        ('        battle_frame_width = %d,'):fmt(settings.battle_frame_width),
        ('        battle_height = %d,'):fmt(settings.battle_height),
        ('        battle_row_height = %d,'):fmt(settings.battle_row_height),
        ('        battle_row_gap = %d,'):fmt(settings.battle_row_gap),
        ('        battle_opacity = %d,'):fmt(settings.battle_opacity),
        ('        battle_hp_bar_height = %d,'):fmt(settings.battle_hp_bar_height),
        ('        battle_mp_bar_height = %d,'):fmt(settings.battle_mp_bar_height),
        ('        battle_tp_bar_height = %d,'):fmt(settings.battle_tp_bar_height),
        ('        battle_cast_bar_height = %d,'):fmt(settings.battle_cast_bar_height),
        ('        battle_show_mp = %s,'):fmt(bool_text(settings.battle_show_mp)),
        ('        battle_show_tp = %s,'):fmt(bool_text(settings.battle_show_tp)),
        ('        battle_show_cast = %s,'):fmt(bool_text(settings.battle_show_cast)),
        ('        battle_mp_text_threshold = %d,'):fmt(settings.battle_mp_text_threshold),
        ('        battle_tp_text_threshold = %d,'):fmt(settings.battle_tp_text_threshold),
        ('        battle_cast_text_threshold = %d,'):fmt(settings.battle_cast_text_threshold),
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
    local ok, err = ensure_config_dir();
    if (not ok) then
        return false, tostring(err or 'failed to create config directory');
    end

    local file, error_message = io.open(path, 'w');
    if (file == nil) then
        return false, tostring(error_message or 'open failed');
    end

    file:write(config_text_from_settings(settings));
    file:close();

    state.settings = settings;
    return true, ('Saved %s.'):fmt(path);
end

function cast_name_key(name)
    return observed_target_name_key(name);
end

function entity_name_by_server_id(server_id)
    server_id = tonumber(server_id);
    if (server_id == nil or server_id == 0) then
        return '';
    end

    local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
    local entity = memory ~= nil and safe_read(function () return memory:GetEntity(); end, nil) or nil;
    if (entity == nil) then
        return '';
    end

    local scan_max = math.min(tonumber(safe_read(function () return entity:GetEntityMapSize(); end, 0x8FF)) or 0x8FF, 0x8FF);
    for index = 0, scan_max, 1 do
        local candidate_id = tonumber(safe_read(function () return entity:GetServerId(index); end, 0));
        if (candidate_id == server_id) then
            return clean_string(safe_read(function () return entity:GetName(index); end, ''));
        end
    end

    return '';
end

function localized_resource_name_value(name)
    if (name == nil) then
        return '';
    end

    if (type(name) == 'string') then
        return clean_string(name);
    end

    if (type(name) == 'table') then
        return clean_string(name[1] or name[2] or name[0] or name.en or name.English or '');
    end

    local indexed = safe_read(function () return name[1]; end, nil)
        or safe_read(function () return name[2]; end, nil)
        or safe_read(function () return name[0]; end, nil);
    local resolved = clean_string(indexed);
    if (#resolved > 0) then
        return resolved;
    end

    local fallback = clean_string(name);
    if (fallback:match('^userdata:%s*0x%x+$') ~= nil) then
        return '';
    end

    return fallback;
end

function cast_resource_name(resource)
    if (resource == nil) then
        return '';
    end

    return localized_resource_name_value(safe_read(function () return resource.Name; end, nil));
end

function cast_resource_id(resource)
    if (resource == nil) then
        return nil;
    end

    return tonumber(safe_read(function () return resource.Index; end, safe_read(function () return resource.Id; end, nil)));
end

function cast_duration_from_resource(resource)
    if (resource == nil) then
        return 3.0;
    end

    local cast_time = tonumber(safe_read(function () return resource.CastTime; end, nil));
    if (cast_time == nil) then
        return 3.0;
    end

    return clamp(cast_time * 0.25, 0.5, 60.0);
end

function spell_cast_info_by_id(spell_id_value)
    spell_id_value = tonumber(spell_id_value);
    if (spell_id_value == nil or spell_id_value <= 0) then
        return nil;
    end

    local resources = safe_read(function () return AshitaCore:GetResourceManager(); end, nil);
    local spell = resources ~= nil and safe_read(function () return resources:GetSpellById(spell_id_value); end, nil) or nil;
    if (spell == nil) then
        return nil;
    end

    return {
        id = cast_resource_id(spell) or spell_id_value,
        kind = 'spell',
        label = cast_resource_name(spell),
        duration = cast_duration_from_resource(spell),
    };
end

function item_cast_info_by_id(item_id)
    item_id = tonumber(item_id);
    if (item_id == nil or item_id <= 0) then
        return nil;
    end

    local resources = safe_read(function () return AshitaCore:GetResourceManager(); end, nil);
    local item = resources ~= nil and safe_read(function () return resources:GetItemById(item_id); end, nil) or nil;
    if (item == nil) then
        return nil;
    end

    return {
        id = cast_resource_id(item) or item_id,
        kind = 'item',
        label = cast_resource_name(item),
        duration = cast_duration_from_resource(item),
    };
end

function spell_cast_info_by_name(spell_name)
    spell_name = clean_string(spell_name);
    if (#spell_name == 0) then
        return nil;
    end

    local resources = safe_read(function () return AshitaCore:GetResourceManager(); end, nil);
    local spell = resources ~= nil and safe_read(function () return resources:GetSpellByName(spell_name, 0); end, nil) or nil;
    if (spell == nil) then
        return {
            id = nil,
            kind = 'spell',
            label = spell_name,
            duration = 3.0,
        };
    end

    return {
        id = spell_id(spell),
        kind = 'spell',
        label = cast_resource_name(spell),
        duration = cast_duration_from_resource(spell),
    };
end

function normalize_cast_actor_name(actor_name, actor_id)
    local name = clean_string(actor_name);
    if ((name == '' or name == 'You') and tonumber(actor_id) ~= nil) then
        local entity_name = entity_name_by_server_id(actor_id);
        if (#entity_name > 0) then
            name = entity_name;
        end
    end
    if (name == 'You') then
        local player_name = current_player_name();
        if (#player_name > 0) then
            name = player_name;
        end
    end

    return name;
end

function monster_ability_cast_info_by_id(ability_id)
    ability_id = tonumber(ability_id);
    if (ability_id == nil or ability_id <= 256) then
        return nil;
    end

    local resources = safe_read(function () return AshitaCore:GetResourceManager(); end, nil);
    local ability = resources ~= nil and safe_read(function () return resources:GetAbilityById(ability_id); end, nil) or nil;
    local label = cast_resource_name(ability);
    if (#label == 0) then
        label = 'TP Move';
    end

    return {
        id = cast_resource_id(ability) or ability_id,
        kind = 'mob_ability',
        label = label,
        duration = 6.0,
    };
end

function normalize_cast_target_name(target_name, target_id)
    local name = clean_string(target_name);
    if ((name == '' or name == 'You') and tonumber(target_id) ~= nil) then
        local entity_name = entity_name_by_server_id(target_id);
        if (#entity_name > 0) then
            name = entity_name;
        end
    end
    if (name == 'You') then
        local player_name = current_player_name();
        if (#player_name > 0) then
            name = player_name;
        end
    end

    return name;
end

function cast_display_label(label, target_name, target_id)
    local cast_label = clean_string(label);
    if (#cast_label == 0) then
        cast_label = 'Casting';
    end

    local target_label = normalize_cast_target_name(target_name, target_id);
    if (#target_label > 0) then
        return ('%s on %s'):fmt(cast_label, target_label);
    end

    return cast_label;
end

function set_active_cast(actor_id, actor_name, label, duration, kind, resource_id)
    actor_id = tonumber(actor_id);
    actor_name = normalize_cast_actor_name(actor_name, actor_id);
    local name_key = cast_name_key(actor_name);
    local existing = name_key ~= nil and state.active_casts_by_name[name_key] or nil;
    if ((actor_id == nil or actor_id == 0) and type(existing) == 'table') then
        actor_id = tonumber(existing.server_id);
    end
    if ((actor_id == nil or actor_id == 0) and name_key == nil) then
        return false;
    end

    local cast = {
        server_id = actor_id,
        name = actor_name,
        name_key = name_key,
        label = clean_string(label),
        started_at = os.clock(),
        duration = clamp(tonumber(duration) or 3.0, 0.5, 60.0),
        kind = clean_string(kind),
        resource_id = tonumber(resource_id),
    };

    if (#cast.label == 0) then
        cast.label = 'Casting';
    end

    if (actor_id ~= nil and actor_id ~= 0) then
        state.active_casts_by_id[actor_id] = cast;
    end
    if (name_key ~= nil) then
        state.active_casts_by_name[name_key] = cast;
    end

    state.cast_events = state.cast_events + 1;
    return true;
end

function clear_active_cast(actor_id, actor_name)
    actor_id = tonumber(actor_id);
    if (actor_id ~= nil and actor_id ~= 0) then
        local cast = state.active_casts_by_id[actor_id];
        if (type(cast) == 'table' and cast.name_key ~= nil) then
            state.active_casts_by_name[cast.name_key] = nil;
        end
        state.active_casts_by_id[actor_id] = nil;
    end

    local name_key = cast_name_key(normalize_cast_actor_name(actor_name, actor_id));
    if (name_key ~= nil) then
        local cast = state.active_casts_by_name[name_key];
        local server_id = type(cast) == 'table' and tonumber(cast.server_id) or nil;
        if (server_id ~= nil and server_id ~= 0) then
            state.active_casts_by_id[server_id] = nil;
        end
        state.active_casts_by_name[name_key] = nil;
    end
end

function clear_active_casts()
    state.active_casts_by_id = { };
    state.active_casts_by_name = { };
end

function cast_progress_percent(cast)
    if (type(cast) ~= 'table') then
        return nil;
    end

    local duration = tonumber(cast.duration) or 0;
    if (duration <= 0) then
        return nil;
    end

    return clamp(((os.clock() - (tonumber(cast.started_at) or 0)) / duration) * 100, 0, 100);
end

function active_cast_current(cast)
    local percent = cast_progress_percent(cast);
    if (percent == nil or percent >= 100) then
        return nil;
    end

    return {
        label = clean_string(cast.label),
        percent = percent,
        duration = cast.duration,
        kind = cast.kind,
        resource_id = cast.resource_id,
    };
end

function self_castbar_percent()
    local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
    local cast_bar = memory ~= nil and safe_read(function () return memory:GetCastBar(); end, nil) or nil;
    local percent = cast_bar ~= nil and tonumber(safe_read(function () return cast_bar:GetPercent(); end, nil)) or nil;
    if (percent == nil) then
        return nil;
    end
    if (percent > 0 and percent <= 1) then
        percent = percent * 100;
    end

    percent = percent_value(percent);
    if (percent == nil or percent <= 0 or percent >= 100) then
        return nil;
    end

    return percent;
end

function active_cast_lookup(server_id, name)
    local id = tonumber(server_id);
    if (id ~= nil and id ~= 0 and state.active_casts_by_id[id] ~= nil) then
        return state.active_casts_by_id[id];
    end

    local name_key = cast_name_key(name);
    if (name_key ~= nil) then
        return state.active_casts_by_name[name_key];
    end

    return nil;
end

function active_cast_for_unit(server_id, name, is_self)
    local cast = active_cast_lookup(server_id, name);
    local current = cast ~= nil and active_cast_current(cast) or nil;

    if (current == nil and cast ~= nil) then
        clear_active_cast(server_id, name);
    end

    if (is_self == true) then
        local percent = self_castbar_percent();
        if (percent ~= nil) then
            return {
                label = current ~= nil and current.label or 'Casting',
                percent = percent,
                duration = current ~= nil and current.duration or nil,
                kind = current ~= nil and current.kind or 'spell',
                resource_id = current ~= nil and current.resource_id or nil,
            };
        end
    end

    return current;
end

function prune_active_casts()
    local now = os.clock();

    for actor_id, cast in pairs(state.active_casts_by_id) do
        if (type(cast) ~= 'table' or (now - (tonumber(cast.started_at) or 0)) > ((tonumber(cast.duration) or 0) + 1.5)) then
            state.active_casts_by_id[actor_id] = nil;
        end
    end

    for name_key, cast in pairs(state.active_casts_by_name) do
        if (type(cast) ~= 'table' or (now - (tonumber(cast.started_at) or 0)) > ((tonumber(cast.duration) or 0) + 1.5)) then
            state.active_casts_by_name[name_key] = nil;
        end
    end
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
    local tag = index == 0 and '' or tostring(index);
    local category = party_member_category(index, target_index, server_id);

    if (category == 'trust' and same_zone == false) then
        return nil;
    end

    local player = index == 0 and safe_read(function () return AshitaCore:GetMemoryManager():GetPlayer(); end, nil) or nil;
    local hp_pct = safe_read(function () return party:GetMemberHPPercent(index); end, nil);
    local mp_pct = safe_read(function () return party:GetMemberMPPercent(index); end, nil);
    local hp = resource_current_value(safe_read(function () return party:GetMemberHP(index); end, nil));
    local mp = resource_current_value(safe_read(function () return party:GetMemberMP(index); end, nil));
    local hp_max = nil;
    local mp_max = nil;

    if (player ~= nil) then
        hp = resource_current_value(safe_read(function () return player:GetHP(); end, nil)) or hp;
        mp = resource_current_value(safe_read(function () return player:GetMP(); end, nil)) or mp;
        hp_max = resource_current_value(safe_read(function () return player:GetHPMax(); end, nil));
        mp_max = resource_current_value(safe_read(function () return player:GetMPMax(); end, nil));
        hp_pct = percent_value(safe_read(function () return player:GetHPP(); end, nil)) or resource_percent_from_pair(hp, hp_max) or hp_pct;
        mp_pct = percent_value(safe_read(function () return player:GetMPP(); end, nil)) or resource_percent_from_pair(mp, mp_max) or mp_pct;
    end

    hp_max = hp_max or estimate_resource_max(hp, hp_pct);
    mp_max = mp_max or estimate_resource_max(mp, mp_pct);
    local buffs, buff_timers = party_member_buffs(party, index, server_id, same_zone, name);

    return {
        kind = 'party',
        tag = tag,
        index = index,
        server_id = server_id,
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
        cast = active_cast_for_unit(server_id, name, index == 0),
        buffs = buffs,
        buff_timers = buff_timers,
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
        cast = index == 2 and { label = 'Cure II', percent = 46, duration = 3.0, kind = 'spell' } or nil,
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
                tag = '',
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
    local party = safe_read(function () return memory:GetParty(); end, nil);
    local zone_id = party ~= nil and safe_read(function () return party:GetMemberZone(0); end, nil) or nil;
    local mobdb_info = nil;
    if (state.settings.show_target_mobdb and target_type == 2 and target_debuff_has_monster_spawn_flag(spawn_flags)) then
        mobdb_info = safe_read(function () return mobdb:snapshot(zone_id, active_index, name, server_id); end, nil);
    end

    return {
        kind = 'target',
        tag = '',
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
        cast = active_cast_for_unit(server_id, name, false),
        buffs = merge_buff_lists(target_entity_buffs(entity, active_index), observed_target_buffs_for_unit(server_id, name)),
        debuffs = observed_target_debuffs_for_unit(server_id, name),
        check = observed_target_check_for_unit(server_id, name),
        mobdb = mobdb_info,
        same_zone = true,
        dim = false,
    };
end

function battle_target_party_ids(party)
    local result = { };
    if (party == nil) then
        return result;
    end

    for index = 0, 17, 1 do
        if (truthy(safe_read(function () return party:GetMemberIsActive(index); end, false))) then
            local server_id = tonumber(safe_read(function () return party:GetMemberServerId(index); end, 0)) or 0;
            if (server_id ~= 0) then
                result[server_id] = true;
                result[bit.band(server_id, 0xFFFF)] = true;
            end
        end
    end

    return result;
end

function battle_target_entity_valid(entity, index)
    index = tonumber(index);
    if (entity == nil or index == nil or index <= 0) then
        return false;
    end

    local render_flags = tonumber(safe_read(function () return entity:GetRenderFlags0(index); end, 0)) or 0;
    if (bit.band(render_flags, 0x200) ~= 0x200 or bit.band(render_flags, 0x4000) ~= 0) then
        return false;
    end

    local hp_pct = tonumber(safe_read(function () return entity:GetHPPercent(index); end, 0)) or 0;
    local target_type = tonumber(safe_read(function () return entity:GetType(index); end, 0)) or 0;
    local spawn_flags = tonumber(safe_read(function () return entity:GetSpawnFlags(index); end, 0)) or 0;
    return hp_pct > 0
        and target_type == 2
        and target_debuff_has_monster_spawn_flag(spawn_flags)
        and #clean_string(safe_read(function () return entity:GetName(index); end, '')) > 0;
end

function battle_target_remember(index, server_id)
    index = tonumber(index);
    server_id = tonumber(server_id);
    if (index == nil or index <= 0 or server_id == nil or server_id == 0) then
        return false;
    end

    local existing = state.battle_targets[index];
    state.battle_targets[index] = {
        index = index,
        server_id = server_id,
        seen_at = type(existing) == 'table' and existing.seen_at or os.clock(),
    };
    return true;
end

function battle_target_index_by_server_id(entity, server_id)
    server_id = tonumber(server_id);
    if (entity == nil or server_id == nil or server_id == 0) then
        return nil;
    end

    for index, entry in pairs(state.battle_targets) do
        if (type(entry) == 'table' and tonumber(entry.server_id) == server_id) then
            return tonumber(index);
        end
    end

    local scan_max = math.min(tonumber(safe_read(function () return entity:GetEntityMapSize(); end, 0x8FF)) or 0x8FF, 0x8FF);
    for index = 1, scan_max, 1 do
        if (tonumber(safe_read(function () return entity:GetServerId(index); end, 0)) == server_id) then
            return index;
        end
    end

    return nil;
end

function scan_claimed_battle_targets(memory, force)
    local now = os.clock();
    if (force ~= true and (now - (tonumber(state.battle_target_last_scan) or 0)) < 1.0) then
        return;
    end
    state.battle_target_last_scan = now;

    local entity = memory ~= nil and safe_read(function () return memory:GetEntity(); end, nil) or nil;
    local party = memory ~= nil and safe_read(function () return memory:GetParty(); end, nil) or nil;
    if (entity == nil or party == nil) then
        return;
    end

    local party_ids = battle_target_party_ids(party);
    local scan_max = math.min(tonumber(safe_read(function () return entity:GetEntityMapSize(); end, 0x8FF)) or 0x8FF, 0x8FF);
    for index = 1, scan_max, 1 do
        if (battle_target_entity_valid(entity, index)) then
            local claim_status = tonumber(safe_read(function () return entity:GetClaimStatus(index); end, 0)) or 0;
            local claim_id = bit.band(claim_status, 0xFFFF);
            if (claim_id ~= 0 and party_ids[claim_id] == true) then
                battle_target_remember(index, safe_read(function () return entity:GetServerId(index); end, 0));
            end
        end
    end
end

function collect_battle_target_units()
    local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
    local entity = memory ~= nil and safe_read(function () return memory:GetEntity(); end, nil) or nil;
    if (memory == nil or entity == nil) then
        return { };
    end

    scan_claimed_battle_targets(memory, false);

    local target = safe_read(function () return memory:GetTarget(); end, nil);
    local primary_index = target ~= nil and tonumber(safe_read(function () return target:GetTargetIndex(0); end, 0)) or 0;
    local sub_index = target ~= nil and tonumber(safe_read(function () return target:GetTargetIndex(1); end, 0)) or 0;
    local selected_index = target ~= nil and truthy(safe_read(function () return target:GetIsSubTargetActive(); end, false)) and sub_index or primary_index;
    local entries = { };

    for index, entry in pairs(state.battle_targets) do
        if (battle_target_entity_valid(entity, index)) then
            entry.index = tonumber(index);
            entry.server_id = tonumber(safe_read(function () return entity:GetServerId(index); end, entry.server_id)) or entry.server_id;
            table.insert(entries, entry);
        else
            state.battle_targets[index] = nil;
        end
    end

    table.sort(entries, function (left, right)
        local left_selected = tonumber(left.index) == tonumber(selected_index);
        local right_selected = tonumber(right.index) == tonumber(selected_index);
        if (left_selected ~= right_selected) then
            return left_selected;
        end
        if (left.seen_at ~= right.seen_at) then
            return (tonumber(left.seen_at) or 0) < (tonumber(right.seen_at) or 0);
        end
        return (tonumber(left.index) or 0) < (tonumber(right.index) or 0);
    end);

    local units = { };
    local max_entries = state.settings.battle_target_max_entries or DEFAULT_SETTINGS.battle_target_max_entries;
    for _, entry in ipairs(entries) do
        if (#units >= max_entries) then
            break;
        end

        local index = entry.index;
        local server_id = entry.server_id;
        local name = clean_string(safe_read(function () return entity:GetName(index); end, ''));
        local spawn_flags = safe_read(function () return entity:GetSpawnFlags(index); end, nil);
        table.insert(units, {
            kind = 'battle_target',
            tag = '',
            index = index,
            server_id = server_id,
            target_type = safe_read(function () return entity:GetType(index); end, nil),
            spawn_flags = spawn_flags,
            name = name,
            hp_pct = safe_read(function () return entity:GetHPPercent(index); end, nil),
            distance = entity_distance(entity, index),
            reminder_job = current_player_job_key(),
            cast = active_cast_for_unit(server_id, '', false),
            buffs = { },
            debuffs = observed_target_debuffs_for_unit(server_id, ''),
            selected = tonumber(index) == tonumber(selected_index),
            same_zone = true,
            dim = false,
        });
    end

    return units;
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
        cast = active_cast_for_unit(safe_read(function () return pet.ServerId; end, nil), name, false),
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

function text_line_height()
    return resource_text_height();
end

local function fit_text(text, max_width)
    text = clean_string(text);
    max_width = tonumber(max_width) or 0;
    if (max_width <= 0) then
        return '';
    end

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

local function draw_text(draw_list, x, y, color, text, bold, shadow_color)
    text = tostring(text or '');
    if (shadow_color ~= false) then
        draw_list:AddText({ x + 1, y + 1 }, color_u32(shadow_color or COLORS.shadow), text);
    end
    draw_list:AddText({ x, y }, color_u32(color), text);
    if (bold == true) then
        draw_list:AddText({ x + 1, y }, color_u32(color), text);
    end
end

local function window_bg_color(locked, alpha)
    if (locked == true) then
        return { COLORS.panel_bg[1], COLORS.panel_bg[2], COLORS.panel_bg[3], 0.0 };
    end

    return apply_alpha(COLORS.panel_bg, alpha);
end

local function window_title_height()
    local style = safe_read(function () return imgui.GetStyle(); end, nil);
    local title_height = WINDOW_TITLE_HEIGHT_FALLBACK;

    if (style ~= nil and style.FramePadding ~= nil) then
        local frame_y = tonumber(style.FramePadding.y) or tonumber(style.FramePadding[2]);
        local font_size = safe_read(function () return imgui.GetFontSize(); end, nil);
        if (frame_y ~= nil and font_size ~= nil) then
            title_height = font_size + (frame_y * 2);
        end
    end

    return title_height;
end

local function locked_window_offset()
    local pad_delta = WINDOW_PADDING_UNLOCKED - WINDOW_PADDING_LOCKED;
    return pad_delta, window_title_height() + pad_delta;
end

local function display_window_position(x, y, locked)
    if (locked == true) then
        local offset_x, offset_y = locked_window_offset();
        return x + offset_x, y + offset_y;
    end

    return x, y;
end

local function stored_window_position(x, y, locked)
    if (locked == true) then
        local offset_x, offset_y = locked_window_offset();
        return x - offset_x, y - offset_y;
    end

    return x, y;
end

function frame_window_id(title)
    return tostring(title or ''):match('###(.+)$') or tostring(title or '');
end

function frame_window_position_condition(title, locked)
    local key = frame_window_id(title);
    local was_locked = state.window_lock_state[key] == true;
    state.window_lock_state[key] = locked == true;

    if (locked == true or was_locked == true) then
        return ImGuiCond_Always;
    end

    return ImGuiCond_FirstUseEver;
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

local function draw_hp_background(draw_list, x, y, width, height, percent, fill_color, alpha)
    percent = percent_value(percent);
    if (percent == nil or percent <= 0) then
        return;
    end

    local fill_width = math.floor(width * (percent / 100));
    if (fill_width <= 0) then
        return;
    end

    draw_list:AddRectFilled({ x, y }, { x + fill_width, y + height }, color_u32(apply_alpha(fill_color, alpha * 0.78)), 4.0);
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

    if (unit.kind == 'target' and unit.distance ~= nil) then
        return ('%s: %.1f'):fmt(percent_text, unit.distance);
    end

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

function unit_has_cast(unit)
    return type(unit.cast) == 'table' and percent_value(unit.cast.percent) ~= nil;
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

function cast_status_text(unit, layout)
    if (layout.show_cast ~= true or not unit_has_cast(unit)) then
        return nil;
    end

    local percent = percent_value(unit.cast.percent);
    if (percent == nil or percent < layout.cast_text_threshold) then
        return nil;
    end

    local label = clean_string(unit.cast.label);
    if (#label == 0) then
        label = 'Casting';
    end

    return ('%s %d%%'):fmt(label, math.floor(percent + 0.5));
end

function target_check_display_text(entry)
    if (type(entry) ~= 'table') then
        return '?? Lv.??';
    end

    local toughness = clean_string(entry.toughness);
    if (#toughness == 0) then
        toughness = '??';
    end

    local level = tonumber(entry.level);
    local level_text = level ~= nil and tostring(math.floor(level + 0.5)) or '??';
    return ('%s Lv.%s'):fmt(toughness, level_text);
end

function target_check_label(unit)
    if (unit.kind ~= 'target' or clean_string(unit.name) == 'No target') then
        return '';
    end

    if (not target_debuff_target_eligible(unit)) then
        if (unit.distance ~= nil) then
            return ('%.1f'):fmt(unit.distance);
        end

        return '';
    end

    if (type(unit.mobdb) == 'table') then
        local toughness = type(unit.check) == 'table' and clean_string(unit.check.toughness) or '??';
        if (#toughness == 0) then toughness = '??'; end
        local observed_level = type(unit.check) == 'table' and tonumber(unit.check.level) or nil;
        local level = observed_level ~= nil and tostring(math.floor(observed_level + 0.5)) or clean_string(unit.mobdb.level);
        if (#level == 0) then level = '??'; end
        local job = clean_string(unit.mobdb.job);
        return ('%s Lv.%s%s'):fmt(toughness, level, #job > 0 and (' ' .. job) or '');
    end

    return target_check_display_text(unit.check);
end

local function unit_right_label(unit)
    if (unit.kind == 'target') then
        return target_check_label(unit);
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

local function draw_buff_icon_frame(draw_list, item, icon_x, icon_y, alpha, tint, icon_size)
    icon_size = tonumber(icon_size) or BUFF_ICON_SIZE;
    local pad = icon_size >= 40 and 3 or 2;
    local min = { icon_x - pad, icon_y - pad };
    local max = { icon_x + icon_size + pad, icon_y + icon_size + pad };

    if (item.state == 'missing') then
        local pulse = (math.sin(os.clock() * 7.0) + 1.0) * 0.5;
        local pulse_alpha = alpha * (0.62 + (pulse * 0.38));
        local border_color = pulse > 0.5 and COLORS.buff_missing_flash or COLORS.buff_missing_border;
        local border_width = icon_size >= 40 and 3.0 or 2.0;

        draw_list:AddRectFilled(min, max, color_u32(apply_alpha(COLORS.buff_missing_bg, pulse_alpha)), 4.0);
        draw_list:AddRect(min, max, color_u32(apply_alpha(border_color, alpha)), 4.0, ImDrawCornerFlags_All, border_width);
    elseif (item.state == 'expiring') then
        local pulse = (math.sin(os.clock() * 7.0) + 1.0) * 0.5;
        local pulse_alpha = alpha * (0.62 + (pulse * 0.38));
        local border_color = pulse > 0.5 and COLORS.buff_expiring_flash or COLORS.buff_expiring_border;
        local border_width = icon_size >= 40 and 3.0 or 2.0;

        draw_list:AddRectFilled(min, max, color_u32(apply_alpha(COLORS.buff_expiring_bg, pulse_alpha)), 4.0);
        draw_list:AddRect(min, max, color_u32(apply_alpha(border_color, alpha)), 4.0, ImDrawCornerFlags_All, border_width);
    else
        draw_list:AddRectFilled(min, max, color_u32(apply_alpha(COLORS.shadow, alpha * 0.56)), 4.0);
        draw_list:AddRect(min, max, color_u32(apply_alpha(COLORS.buff_active_border, alpha)), 4.0, ImDrawCornerFlags_All, 1.0);
    end

    imgui.SetCursorScreenPos({ icon_x, icon_y });
    imgui.Image(item.handle, { icon_size, icon_size }, { 0, 0 }, { 1, 1 }, tint, { 0, 0, 0, 0 });

    if (item.state == 'missing') then
        local mark_color = color_u32(apply_alpha(COLORS.buff_missing_border, alpha));
        local mark_pad = math.max(4, math.floor(icon_size * 0.13));
        local mark_width = icon_size >= 40 and 3.0 or 2.0;
        draw_list:AddLine({ icon_x + mark_pad, icon_y + mark_pad }, { icon_x + icon_size - mark_pad, icon_y + icon_size - mark_pad }, mark_color, mark_width);
        draw_list:AddLine({ icon_x + icon_size - mark_pad, icon_y + mark_pad }, { icon_x + mark_pad, icon_y + icon_size - mark_pad }, mark_color, mark_width);
    end
end

local function draw_buff_item_tooltip(unit, item)
    imgui.BeginTooltip();
    imgui.PushTextWrapPos(340);
    if (item.state == 'missing') then
        imgui.TextColored(COLORS.warning, ('Missing: %s'):fmt(item.name));
    elseif (item.state == 'expiring') then
        imgui.TextColored(COLORS.buff_expiring_flash, ('Expiring: %s'):fmt(item.name));
        if (item.remaining_seconds ~= nil) then
            imgui.TextUnformatted(('Remaining: %s'):fmt(format_status_duration(item.remaining_seconds)));
        else
            imgui.TextColored(COLORS.text_muted, 'Remaining time unavailable');
        end
    else
        imgui.TextUnformatted(item.name);
    end

    local description = status_description(item.id);
    if (#description > 0) then
        imgui.Separator();
        imgui.TextWrapped(description);
    end
    if (SELF_BUFF_CANCELLATION.is_self_buff(unit, item)) then
        imgui.Separator();
        imgui.TextColored(COLORS.text_muted, 'Right-click to remove.');
    end
    imgui.PopTextWrapPos();
    imgui.EndTooltip();
end

local function draw_missing_buff_tooltip(items)
    imgui.BeginTooltip();
    if (#items == 1) then
        imgui.TextColored(COLORS.warning, ('Missing: %s'):fmt(items[1].name));
    else
        imgui.TextColored(COLORS.warning, ('Missing buffs: %d'):fmt(#items));
        for _, item in ipairs(items) do
            imgui.Text(('- %s'):fmt(item.name));
        end
    end
    imgui.EndTooltip();
end

local function buff_rail_visible(unit, items, missing_items)
    if (not state.settings.show_buffs or unit.kind ~= 'party') then
        return false;
    end

    return (#items > 0 or #missing_items > 0);
end

local function draw_buff_missing_badge(draw_list, x, y, alpha, items)
    local count = #items;
    if (count == 0) then
        return;
    end

    local label = tostring(count);
    local min = { x, y };
    local max = { x + BUFF_RAIL.badge_width, y + BUFF_RAIL.badge_height };

    draw_list:AddRectFilled(min, max, color_u32(apply_alpha(COLORS.buff_missing_bg, alpha)), 4.0);
    draw_list:AddRect(min, max, color_u32(apply_alpha(COLORS.buff_missing_border, alpha)), 4.0, ImDrawCornerFlags_All, 1.0);
    draw_text(
        draw_list,
        x + math.max(1, math.floor((BUFF_RAIL.badge_width - calc_text_width(label)) / 2)),
        y + math.max(1, math.floor((BUFF_RAIL.badge_height - text_line_height()) / 2)),
        apply_alpha(COLORS.hp_text, alpha),
        label,
        true,
        apply_alpha(COLORS.light_text_shadow, alpha));

    imgui.SetCursorScreenPos({ x, y });
    imgui.Dummy({ BUFF_RAIL.badge_width, BUFF_RAIL.badge_height });
    if (imgui.IsItemHovered()) then
        draw_missing_buff_tooltip(items);
    end
end

function status_icon_rail_slots_per_column(row_height, missing_count)
    local badge_reserved = (tonumber(missing_count) or 0) > 0 and (BUFF_RAIL.badge_height + BUFF_RAIL.icon_gap) or 0;
    local available_height = row_height - 16 - badge_reserved;
    return math.max(1, math.floor((available_height + BUFF_RAIL.icon_gap) / (BUFF_RAIL.icon_size + BUFF_RAIL.icon_gap)));
end

function draw_status_icon_rail(unit, x, y, row_height, alpha, items, missing_items, align_right, rail_width)
    items = items or { };
    missing_items = missing_items or { };
    if (#items == 0 and #missing_items == 0) then
        return;
    end

    local draw_list = imgui.GetWindowDrawList();
    local tint = unit.dim and { 0.62, 0.62, 0.62, 0.62 } or { 1.00, 1.00, 1.00, 1.00 };
    rail_width = math.max(BUFF_RAIL.width, tonumber(rail_width) or BUFF_RAIL.width);
    local columns = math.max(1, math.floor(rail_width / BUFF_RAIL.width));
    local icon_x = x + math.floor((BUFF_RAIL.width - BUFF_RAIL.icon_size) / 2);
    local icon_y = y + 8;
    local slots_per_column = status_icon_rail_slots_per_column(row_height, #missing_items);
    local max_slots = slots_per_column * columns;
    local slot_index = 0;
    local display_items = { };

    draw_list:AddRectFilled({ x + 1, y + 1 }, { x + rail_width - 1, y + row_height - 1 }, color_u32(apply_alpha(COLORS.shadow, alpha * 0.22)), 3.0);
    if (align_right == true) then
        draw_list:AddLine({ x, y + 5 }, { x, y + row_height - 5 }, color_u32(apply_alpha(COLORS.row_border, alpha * 0.75)), 1.0);
    else
        draw_list:AddLine({ x + rail_width - 1, y + 5 }, { x + rail_width - 1, y + row_height - 5 }, color_u32(apply_alpha(COLORS.row_border, alpha * 0.75)), 1.0);
    end

    for _, item in ipairs(items) do
        if (item.state == 'missing' and item.handle ~= nil) then
            table.insert(display_items, item);
        end
    end
    for _, item in ipairs(items) do
        if (item.state ~= 'missing' and item.handle ~= nil) then
            table.insert(display_items, item);
        end
    end

    for _, item in ipairs(display_items) do
        if (max_slots <= 0) then
            break;
        end

        draw_buff_icon_frame(draw_list, item, icon_x, icon_y, alpha, tint, BUFF_RAIL.icon_size);
        local item_hovered = imgui.IsItemHovered();
        local item_right_clicked = imgui.IsItemClicked(1);
        if (item_hovered) then
            draw_buff_item_tooltip(unit, item);
        end
        if (item_hovered and item_right_clicked and SELF_BUFF_CANCELLATION.is_self_buff(unit, item)) then
            SELF_BUFF_CANCELLATION.cancel(item.id);
        end

        slot_index = slot_index + 1;
        local column = math.floor(slot_index / slots_per_column);
        local row = math.fmod(slot_index, slots_per_column);
        icon_x = x + (column * BUFF_RAIL.width) + math.floor((BUFF_RAIL.width - BUFF_RAIL.icon_size) / 2);
        icon_y = y + 8 + (row * (BUFF_RAIL.icon_size + BUFF_RAIL.icon_gap));
        max_slots = max_slots - 1;
    end

    if (#missing_items > 0) then
        draw_buff_missing_badge(
            draw_list,
            x + math.floor((BUFF_RAIL.width - BUFF_RAIL.badge_width) / 2),
            y + row_height - BUFF_RAIL.badge_height - 7,
            alpha,
            missing_items);
    end

    imgui.SetCursorScreenPos({ x, y });
end

local function draw_buff_icon_rail(unit, x, y, row_height, alpha, items, missing_items)
    items = items or buff_icon_items(unit);
    missing_items = missing_items or missing_buff_icon_items(unit);
    if (not buff_rail_visible(unit, items, missing_items)) then
        return;
    end

    draw_status_icon_rail(unit, x, y, row_height, alpha, items, missing_items, false);
end

function target_buff_rail_visible(unit, items)
    return state.settings.show_buffs
        and (unit.kind == 'target' or unit.kind == 'battle_target')
        and type(items) == 'table'
        and #items > 0;
end

function target_debuff_rail_visible(unit, items)
    local enabled = unit ~= nil and ((unit.kind == 'battle_target' and state.settings.show_battle_target_debuffs) or (unit.kind == 'target' and state.settings.show_target_debuffs));
    return enabled and target_debuff_target_eligible(unit) and type(items) == 'table' and #items > 0;
end

function target_debuff_rail_width(unit, items, row_height)
    if (not target_debuff_rail_visible(unit, items)) then
        return 0;
    end

    local slots_per_column = status_icon_rail_slots_per_column(row_height, 0);
    return math.max(1, math.ceil(#items / slots_per_column)) * BUFF_RAIL.width;
end

function draw_target_buff_icon_rail(unit, x, y, row_height, alpha, items)
    items = items or target_buff_icon_items(unit);
    if (not target_buff_rail_visible(unit, items)) then
        return;
    end

    draw_status_icon_rail(unit, x, y, row_height, alpha, items, { }, false);
end

function draw_target_debuff_icon_rail(unit, x, y, row_height, alpha, items, rail_width)
    items = items or target_debuff_icon_items(unit);
    if (not target_debuff_rail_visible(unit, items)) then
        return;
    end

    draw_status_icon_rail(unit, x, y, row_height, alpha, items, { }, true, rail_width);
end

function active_resource_bar_height(unit, layout)
    local height = effective_resource_bar_height(layout.hp_bar_height);

    if (layout.show_mp == true and unit_has_mp(unit)) then
        height = height + effective_resource_bar_height(layout.mp_bar_height);
    end
    if (layout.show_tp == true and unit_has_tp(unit)) then
        height = height + effective_resource_bar_height(layout.tp_bar_height);
    end
    if (layout.show_cast == true and unit_has_cast(unit)) then
        height = height + effective_resource_bar_height(layout.cast_bar_height);
    end

    return height;
end

function resource_bar_text_y(y, height)
    return y + math.max(2, math.floor((height - text_line_height()) / 2));
end

function draw_bar_text(draw_list, x, y, color, text, alpha, shadow_color)
    draw_text(draw_list, x, y, apply_alpha(color, alpha), text, true, apply_alpha(shadow_color or COLORS.light_text_shadow, alpha));
end

function draw_right_bar_text(draw_list, x, y, width, color, text, alpha, shadow_color)
    text = fit_text(text, width - 12);
    draw_bar_text(draw_list, x + width - calc_text_width(text) - 7, y, color, text, alpha, shadow_color);
end

function draw_simple_bar_text(draw_list, x, y, width, height, color, text, alpha, shadow_color)
    if (text == nil) then
        return;
    end

    draw_bar_text(draw_list, x + 7, resource_bar_text_y(y, height), color, fit_text(text, width - 14), alpha, shadow_color);
end

function draw_hp_bar_text(draw_list, unit, x, y, width, height, alpha)
    local tag = clean_string(unit.tag or '');
    local name = clean_string(unit.name);
    local left = #tag > 0 and (tag .. ' ' .. name) or name;
    local right = unit_right_label(unit);
    local hp_text = state.settings.show_percent == true and hp_status_text(unit) or nil;
    local color = unit.dim and COLORS.text_dim or COLORS.hp_text;
    local text_h = text_line_height();
    local two_lines = height >= ((text_h * 2) + 8);

    if (two_lines) then
        local top_y = y + 4;
        local bottom_y = y + height - text_h - 4;
        local right_width = calc_text_width(right);
        local name_width = width - right_width - 22;

        draw_bar_text(draw_list, x + 8, top_y, color, fit_text(left, name_width), alpha, COLORS.light_text_shadow);
        if (#right > 0) then
            draw_right_bar_text(draw_list, x, top_y, width, color, right, alpha, COLORS.light_text_shadow);
        end
        if (hp_text ~= nil) then
            draw_right_bar_text(draw_list, x, bottom_y, width, color, hp_text, alpha, COLORS.light_text_shadow);
        end

        return;
    end

    local inline_right = hp_text or right;
    local inline_y = resource_bar_text_y(y, height);
    local right_width = calc_text_width(inline_right);
    local name_width = width - right_width - 22;

    draw_bar_text(draw_list, x + 8, inline_y, color, fit_text(left, name_width), alpha, COLORS.light_text_shadow);
    if (#inline_right > 0) then
        draw_right_bar_text(draw_list, x, inline_y, width, color, inline_right, alpha, COLORS.light_text_shadow);
    end
end

function draw_resource_bars(draw_list, unit, layout, x, y, width, height, alpha)
    local hp = percent_value(unit.hp_pct);
    local hp_color = hp ~= nil and hp <= 35 and COLORS.hp_low or COLORS.hp;
    if (unit.kind == 'target' and type(unit.mobdb) == 'table' and state.settings.show_target_mobdb) then
        hp_color = hp ~= nil and hp <= 35 and COLORS.hp_low or COLORS.mobdb_hp;
    end
    local hp_h = effective_resource_bar_height(layout.hp_bar_height);
    local mp_h = layout.show_mp == true and unit_has_mp(unit) and effective_resource_bar_height(layout.mp_bar_height) or 0;
    local tp_h = layout.show_tp == true and unit_has_tp(unit) and effective_resource_bar_height(layout.tp_bar_height) or 0;
    local cast_h = layout.show_cast == true and unit_has_cast(unit) and effective_resource_bar_height(layout.cast_bar_height) or 0;
    local total_h = hp_h + mp_h + tp_h + cast_h;
    local current_y = y;

    if (height > total_h) then
        hp_h = hp_h + (height - total_h);
    end

    draw_bar(draw_list, x, current_y, width, hp_h, unit.hp_pct, hp_color, alpha);
    draw_hp_bar_text(draw_list, unit, x, current_y, width, hp_h, alpha);
    current_y = current_y + hp_h;

    if (mp_h > 0) then
        draw_bar(draw_list, x, current_y, width, mp_h, unit.mp_pct, COLORS.mp, alpha);
        draw_simple_bar_text(draw_list, x, current_y, width, mp_h, COLORS.mp_text, mp_status_text(unit, layout), alpha, COLORS.light_text_shadow);
        current_y = current_y + mp_h;
    end

    if (tp_h > 0) then
        draw_bar(draw_list, x, current_y, width, tp_h, tp_percent_value(unit.tp), COLORS.tp, alpha);
        draw_simple_bar_text(draw_list, x, current_y, width, tp_h, COLORS.tp_text, tp_status_text(unit, layout), alpha, COLORS.dark_text_shadow);
        current_y = current_y + tp_h;
    end

    if (cast_h > 0) then
        draw_bar(draw_list, x, current_y, width, cast_h, unit.cast.percent, COLORS.cast, alpha);
        draw_simple_bar_text(draw_list, x, current_y, width, cast_h, COLORS.cast_text, cast_status_text(unit, layout), alpha, COLORS.dark_text_shadow);
    end
end

function mobdb_join_lists(first, second)
    local result = { };
    for _, item in ipairs(first or { }) do table.insert(result, item); end
    for _, item in ipairs(second or { }) do table.insert(result, item); end
    return result;
end

function mobdb_absolute_percent_text(percent)
    local text = string.format('%.2f', math.abs(tonumber(percent) or 0)):gsub('0+$', ''):gsub('%.$', '');
    return text;
end

function mobdb_modifier_groups(info)
    local weak = { };
    local strong = { };
    for _, modifier in ipairs(mobdb_join_lists(info.physical, info.magical)) do
        if (tonumber(modifier.percent) or 0) > 0 then
            table.insert(weak, modifier);
        elseif (tonumber(modifier.percent) or 0) < 0 then
            table.insert(strong, modifier);
        end
    end
    local function effectiveness(left, right)
        local left_percent = tonumber(left.percent) or 0;
        local right_percent = tonumber(right.percent) or 0;
        if (left_percent == right_percent) then return clean_string(left.key) < clean_string(right.key); end
        return left_percent > right_percent;
    end
    table.sort(weak, effectiveness);
    table.sort(strong, effectiveness);
    return weak, strong;
end

function mobdb_modifier_tile_width(modifier, icon_size)
    return icon_size + 3 + calc_text_width(mobdb_absolute_percent_text(modifier.percent)) + 8;
end

function mobdb_group_width(items, icon_size, gap)
    local width = 0;
    for _, item in ipairs(items or { }) do
        if (width > 0) then width = width + gap; end
        width = width + mobdb_modifier_tile_width(item, icon_size);
    end
    return width;
end

function draw_mobdb_modifier_group(draw_list, items, x, y, max_width, icon_size, gap, alpha, background, border)
    local cursor_x = x;
    local max_x = x + math.max(0, max_width);
    for _, item in ipairs(items or { }) do
        local tile_width = mobdb_modifier_tile_width(item, icon_size);
        if (cursor_x + tile_width > max_x) then break; end
        draw_list:AddRectFilled(
            { cursor_x, y - 2 },
            { cursor_x + tile_width, y + icon_size + 2 },
            color_u32(apply_alpha(background, alpha)),
            2.0);
        draw_list:AddRect(
            { cursor_x, y - 2 },
            { cursor_x + tile_width, y + icon_size + 2 },
            color_u32(apply_alpha(border, alpha * 0.62)),
            2.0,
            ImDrawCornerFlags_All,
            1.0);
        local icon = load_mobdb_icon(item.icon);
        if (icon ~= nil) then
            imgui.SetCursorScreenPos({ cursor_x + 3, y });
            imgui.Image(icon.handle, { icon_size, icon_size }, { 0, 0 }, { 1, 1 }, { 1, 1, 1, alpha }, { 0, 0, 0, 0 });
            if (imgui.IsItemHovered()) then
                imgui.BeginTooltip();
                imgui.TextUnformatted(('%s: %s%%'):fmt(clean_string(item.key), mobdb_absolute_percent_text(item.percent)));
                imgui.EndTooltip();
            end
        end
        draw_text(
            draw_list,
            cursor_x + icon_size + 6,
            y + 1,
            apply_alpha(COLORS.hp_text, alpha),
            mobdb_absolute_percent_text(item.percent),
            true,
            apply_alpha(COLORS.shadow, alpha));
        cursor_x = cursor_x + tile_width + gap;
    end
    return cursor_x;
end

function draw_mobdb_item_tooltip(drop)
    local item_id = tonumber(drop ~= nil and drop.id or nil);
    local resources = safe_read(function () return AshitaCore:GetResourceManager(); end, nil);
    local resource = resources ~= nil and item_id ~= nil and safe_read(function () return resources:GetItemById(item_id); end, nil) or nil;
    local name = clean_string(drop ~= nil and drop.name or '');
    imgui.BeginTooltip();
    imgui.PushTextWrapPos(340);
    local large_icon = load_item_icon(item_id);
    if (large_icon ~= nil) then
        imgui.Image(large_icon.handle, { 32, 32 });
        imgui.SameLine(0, 8);
    end
    imgui.TextUnformatted(#name > 0 and name or 'Unknown item');
    local stack_size = resource ~= nil and tonumber(safe_read(function () return resource.StackSize; end, nil)) or nil;
    if (stack_size ~= nil and stack_size > 1) then
        imgui.TextUnformatted(('Stack: %d'):fmt(stack_size));
    end
    local description = resource ~= nil and clean_string(safe_read(function () return resource.Description[1]; end, '')) or '';
    if (#description > 0) then
        imgui.Separator();
        imgui.TextUnformatted(description);
    end
    imgui.PopTextWrapPos();
    imgui.EndTooltip();
end

function draw_target_mobdb_overlay(unit, x, y, width, row_height, alpha, left_inset, right_inset)
    local info = unit ~= nil and unit.mobdb or nil;
    if (not state.settings.show_target_mobdb or type(info) ~= 'table') then
        return;
    end

    local draw_list = imgui.GetWindowDrawList();
    local icon_size = 18;
    local icon_gap = 4;
    local content_x = x + left_inset + 8;
    local content_right = x + width - right_inset - 8;
    local content_width = math.max(0, content_right - content_x);
    if (content_width < 110) then
        return;
    end

    local weak, strong = mobdb_modifier_groups(info);
    local flag_count = #(info.flags or { });
    local flag_width = flag_count > 0 and ((flag_count * icon_size) + ((flag_count - 1) * icon_gap)) or 0;
    local flag_x = content_x + math.floor((content_width - flag_width) / 2);
    for _, flag_item in ipairs(info.flags or { }) do
        local icon = load_mobdb_icon(flag_item.icon);
        if (icon ~= nil) then
            imgui.SetCursorScreenPos({ flag_x, y + 3 });
            imgui.Image(icon.handle, { icon_size, icon_size }, { 0, 0 }, { 1, 1 }, { 1, 1, 1, alpha }, { 0, 0, 0, 0 });
            if (imgui.IsItemHovered()) then
                imgui.BeginTooltip();
                imgui.TextUnformatted(clean_string(flag_item.key));
                imgui.EndTooltip();
            end
        end
        flag_x = flag_x + icon_size + icon_gap;
    end

    local middle_y = y + math.max(28, math.floor((row_height - icon_size) / 2));
    local strong_tiles_width = mobdb_group_width(strong, icon_size, icon_gap);
    local strong_max_width = math.floor(content_width * 0.44);
    local strong_display_width = math.min(strong_tiles_width, strong_max_width);
    local strong_x = content_right - strong_display_width;

    if (#strong > 0) then
        draw_mobdb_modifier_group(
            draw_list,
            strong,
            strong_x,
            middle_y,
            strong_display_width,
            icon_size,
            icon_gap,
            alpha,
            COLORS.mobdb_strong_bg,
            COLORS.mobdb_strong_border);
    end

    if (#weak > 0) then
        local weak_tiles_x = content_x;
        local weak_max_x = #strong > 0 and (strong_x - 10) or content_right;
        draw_mobdb_modifier_group(
            draw_list,
            weak,
            weak_tiles_x,
            middle_y,
            math.max(0, weak_max_x - weak_tiles_x),
            icon_size,
            icon_gap,
            alpha,
            COLORS.mobdb_weak_bg,
            COLORS.mobdb_weak_border);
    end

    local footer_y = y + row_height - text_line_height() - 4;
    local footer_icon_size = 16;
    local drop_x = content_x;
    local drop_max_x = content_x + math.floor(content_width * 0.44);
    for _, drop in ipairs(info.drops or { }) do
        local item_width = footer_icon_size + icon_gap;
        if (drop_x + item_width > drop_max_x) then break; end
        local icon = load_item_icon(drop.id);
        if (icon ~= nil) then
            imgui.SetCursorScreenPos({ drop_x, footer_y });
            imgui.Image(icon.handle, { footer_icon_size, footer_icon_size }, { 0, 0 }, { 1, 1 }, { 1, 1, 1, alpha }, { 0, 0, 0, 0 });
            if (imgui.IsItemHovered()) then draw_mobdb_item_tooltip(drop); end
        end
        drop_x = drop_x + item_width;
    end

    local respawn = clean_string(info.respawn);
    if (#respawn > 0 and respawn ~= 'Not recorded') then
        local respawn_width = 18 + calc_text_width(respawn);
        local respawn_x = content_x + math.floor((content_width - respawn_width) / 2);
        local clock_x = respawn_x + 7;
        local clock_y = footer_y + 8;
        local clock_color = color_u32(apply_alpha(COLORS.hp_text, alpha));
        draw_list:AddCircle({ clock_x, clock_y }, 6.0, clock_color, 16, 1.0);
        draw_list:AddLine({ clock_x, clock_y }, { clock_x, clock_y - 4 }, clock_color, 1.0);
        draw_list:AddLine({ clock_x, clock_y }, { clock_x + 3, clock_y + 2 }, clock_color, 1.0);
        draw_text(draw_list, respawn_x + 16, footer_y, apply_alpha(COLORS.hp_text, alpha), respawn, false, apply_alpha(COLORS.shadow, alpha));
    end
end

local function draw_unit_row(unit, layout, row_height, skip_spacing)
    local x, y = imgui.GetCursorScreenPos();
    local draw_list = imgui.GetWindowDrawList();
    local width = layout.width;
    local alpha = (layout.opacity / 100) * (unit.dim and 0.62 or 1.0);
    local row_bg = unit.dim and COLORS.row_dim or COLORS.row_bg;
    local border = (unit.kind == 'target' or unit.selected == true) and COLORS.row_border_active or COLORS.row_border;
    local buff_missing_items = { };
    local buff_items = { };
    local target_buff_items = { };
    local target_debuff_items = { };
    local buff_rail_width = 0;
    local debuff_rail_width = 0;

    if (state.settings.show_buffs and unit.kind == 'party') then
        buff_missing_items = missing_buff_icon_items(unit);
        buff_items = buff_icon_items(unit, buff_missing_items);
        if (buff_rail_visible(unit, buff_items, buff_missing_items)) then
            buff_rail_width = BUFF_RAIL.width;
        end
    elseif (unit.kind == 'target' or unit.kind == 'battle_target') then
        target_buff_items = target_buff_icon_items(unit);
        target_debuff_items = target_debuff_icon_items(unit);
        if (target_buff_rail_visible(unit, target_buff_items)) then
            buff_rail_width = BUFF_RAIL.width;
        end
        if (target_debuff_rail_visible(unit, target_debuff_items)) then
            debuff_rail_width = target_debuff_rail_width(unit, target_debuff_items, row_height);
        end
    end

    draw_list:AddRectFilled({ x, y }, { x + width, y + row_height }, color_u32(apply_alpha(row_bg, alpha)), 4.0);
    draw_resource_bars(draw_list, unit, layout, x + buff_rail_width, y, math.max(1, width - buff_rail_width - debuff_rail_width), row_height, alpha);
    draw_list:AddRect({ x, y }, { x + width, y + row_height }, color_u32(apply_alpha(border, alpha)), 4.0, ImDrawCornerFlags_All, 1.0);
    if (PARTY_SELECTION.matches(unit)) then
        draw_list:AddRectFilled({ x, y }, { x + width, y + row_height }, color_u32(apply_alpha(COLORS.party_selection_fill, alpha)), 4.0);
        draw_list:AddRect({ x, y }, { x + width, y + row_height }, color_u32(apply_alpha(COLORS.party_selection_border, alpha)), 4.0, ImDrawCornerFlags_All, 2.5);
    end

    draw_buff_icon_rail(unit, x, y, row_height, alpha, buff_items, buff_missing_items);
    draw_target_buff_icon_rail(unit, x, y, row_height, alpha, target_buff_items);
    draw_target_debuff_icon_rail(unit, x + width - debuff_rail_width, y, row_height, alpha, target_debuff_items, debuff_rail_width);
    if (unit.kind == 'target') then
        draw_target_mobdb_overlay(unit, x, y, width, row_height, alpha, buff_rail_width, debuff_rail_width);
    end

    if (skip_spacing ~= true) then
        imgui.Dummy({ width, row_height + layout.row_gap });
    end
end

local function effective_row_height(unit, layout)
    local row_height = math.max(layout.row_height, active_resource_bar_height(unit, layout));

    if (unit.kind == 'party' and state.settings.show_buffs) then
        return math.max(row_height, LIMITS.party_row_height_with_buffs_min);
    end
    if (unit.kind == 'target'
        and ((state.settings.show_buffs and type(unit.buffs) == 'table' and #unit.buffs > 0)
            or (state.settings.show_target_debuffs and target_debuff_target_eligible(unit)))) then
        return math.max(row_height, LIMITS.target_row_height_with_debuffs_min);
    end

    return row_height;
end

local function render_window(title, open_state, x, y, layout, units, position_callback)
    local settings = state.settings;
    if (#units == 0) then
        return;
    end

    local locked = settings.locked == true;
    local window_flags = locked and WINDOW_FLAGS_LOCKED or WINDOW_FLAGS_BASE;
    local pad = locked and WINDOW_PADDING_LOCKED or WINDOW_PADDING_UNLOCKED;
    local alpha = layout.opacity / 100;
    local window_x, window_y = display_window_position(x, y, locked);
    local position_condition = frame_window_position_condition(title, locked);

    imgui.SetNextWindowPos({ window_x, window_y }, position_condition);
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { pad, pad });
    imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, locked and 0.0 or 1.0);
    imgui.PushStyleColor(ImGuiCol_WindowBg, window_bg_color(locked, alpha));
    imgui.PushStyleColor(ImGuiCol_Border, apply_alpha(COLORS.panel_border, alpha));

    if (imgui.Begin(title, open_state, window_flags)) then
        local current_x, current_y = imgui.GetWindowPos();
        local stored_x, stored_y = stored_window_position(current_x, current_y, locked);
        position_callback(stored_x, stored_y);

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
    local pad = locked and WINDOW_PADDING_LOCKED or WINDOW_PADDING_UNLOCKED;
    local alpha = layout.opacity / 100;
    local columns, rows = party_grid_size(layout, #units);
    local row_height = layout.row_height;
    for _, unit in ipairs(units) do
        row_height = math.max(row_height, effective_row_height(unit, layout));
    end

    local gap = layout.row_gap;
    local total_width = (columns * layout.width) + ((columns - 1) * gap);
    local total_height = (rows * row_height) + ((rows - 1) * gap);
    local window_x, window_y = display_window_position(x, y, locked);
    local position_condition = frame_window_position_condition(title, locked);

    imgui.SetNextWindowPos({ window_x, window_y }, position_condition);
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { pad, pad });
    imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, locked and 0.0 or 1.0);
    imgui.PushStyleColor(ImGuiCol_WindowBg, window_bg_color(locked, alpha));
    imgui.PushStyleColor(ImGuiCol_Border, apply_alpha(COLORS.panel_border, alpha));

    if (imgui.Begin(title, open_state, window_flags)) then
        local current_x, current_y = imgui.GetWindowPos();
        local stored_x, stored_y = stored_window_position(current_x, current_y, locked);
        position_callback(stored_x, stored_y);

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

function battle_target_preview_units()
    return {
        {
            kind = 'battle_target',
            tag = '',
            index = 1,
            server_id = 0x01000001,
            target_type = 2,
            spawn_flags = TARGET_DEBUFF_MONSTER_SPAWN_FLAG,
            name = 'Desert Beetle',
            hp_pct = 92,
            cast = nil,
            buffs = { },
            debuffs = { 4, 13 },
            selected = true,
            same_zone = true,
            dim = false,
        },
        {
            kind = 'battle_target',
            tag = '',
            index = 2,
            server_id = 0x01000002,
            target_type = 2,
            spawn_flags = TARGET_DEBUFF_MONSTER_SPAWN_FLAG,
            name = 'Desert Beetle',
            hp_pct = 22,
            cast = { label = 'Sand Veil', percent = 64, duration = 3.0, kind = 'ability' },
            buffs = { },
            debuffs = { 134 },
            selected = false,
            same_zone = true,
            dim = false,
        },
    };
end

function render_battle_targets()
    if (not state.settings.show_battle_targets) then
        return;
    end

    local units = collect_battle_target_units();
    if (#units == 0 and state.config_visible[1] == true) then
        units = battle_target_preview_units();
    end
    if (#units == 0) then
        return;
    end

    render_window(
        'AshitaFrames Battle Targets###AshitaFramesBattleTargets',
        state.visible,
        state.battle_window_x,
        state.battle_window_y,
        frame_layout('battle'),
        units,
        function (x, y)
            state.battle_window_x = math.floor(x + 0.5);
            state.battle_window_y = math.floor(y + 0.5);
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
    local hp_height_field = ('%s_hp_bar_height'):fmt(kind);
    local mp_height_field = ('%s_mp_bar_height'):fmt(kind);
    local tp_height_field = ('%s_tp_bar_height'):fmt(kind);
    local cast_height_field = ('%s_cast_bar_height'):fmt(kind);
    local show_mp_field = ('%s_show_mp'):fmt(kind);
    local show_tp_field = ('%s_show_tp'):fmt(kind);
    local show_cast_field = ('%s_show_cast'):fmt(kind);
    local mp_threshold_field = ('%s_mp_text_threshold'):fmt(kind);
    local tp_threshold_field = ('%s_tp_text_threshold'):fmt(kind);
    local cast_threshold_field = ('%s_cast_text_threshold'):fmt(kind);

    imgui.TextColored(COLORS.accent, label);
    render_int_control('HP Bar Height', ('%s_hp_bar_height'):fmt(kind), state.settings[hp_height_field], resource_bar_min_height(), LIMITS.bar_height_max, function (value)
        state.settings[hp_height_field] = normalize_resource_bar_height(value, state.settings.hp_bar_height);
        mark_config_changed();
    end);

    local show_mp = state.settings[show_mp_field] == true;
    if (imgui.Checkbox(('Show MP Bar##ashitaframes_%s_show_mp'):fmt(kind), { show_mp })) then
        state.settings[show_mp_field] = not show_mp;
        mark_config_changed();
    end
    render_int_control('MP Bar Height', ('%s_mp_bar_height'):fmt(kind), state.settings[mp_height_field], resource_bar_min_height(), LIMITS.bar_height_max, function (value)
        state.settings[mp_height_field] = normalize_resource_bar_height(value, state.settings.mp_bar_height);
        mark_config_changed();
    end);
    render_int_control('MP Text At', ('%s_mp_text_threshold'):fmt(kind), state.settings[mp_threshold_field], LIMITS.mp_text_threshold_min, LIMITS.mp_text_threshold_max, function (value)
        state.settings[mp_threshold_field] = normalize_mp_text_threshold(value, state.settings.mp_text_threshold);
        mark_config_changed();
    end, '%');

    local show_tp = state.settings[show_tp_field] == true;
    if (imgui.Checkbox(('Show TP Bar##ashitaframes_%s_show_tp'):fmt(kind), { show_tp })) then
        state.settings[show_tp_field] = not show_tp;
        mark_config_changed();
    end
    render_int_control('TP Bar Height', ('%s_tp_bar_height'):fmt(kind), state.settings[tp_height_field], resource_bar_min_height(), LIMITS.bar_height_max, function (value)
        state.settings[tp_height_field] = normalize_resource_bar_height(value, state.settings.tp_bar_height);
        mark_config_changed();
    end);
    render_int_control('TP Text At', ('%s_tp_text_threshold'):fmt(kind), state.settings[tp_threshold_field], LIMITS.tp_text_threshold_min, LIMITS.tp_text_threshold_max, function (value)
        state.settings[tp_threshold_field] = normalize_tp_text_threshold(value, state.settings.tp_text_threshold);
        mark_config_changed();
    end, 'TP');

    local show_cast = state.settings[show_cast_field] == true;
    if (imgui.Checkbox(('Show Cast Bar##ashitaframes_%s_show_cast'):fmt(kind), { show_cast })) then
        state.settings[show_cast_field] = not show_cast;
        mark_config_changed();
    end
    render_int_control('Cast Bar Height', ('%s_cast_bar_height'):fmt(kind), state.settings[cast_height_field], resource_bar_min_height(), LIMITS.bar_height_max, function (value)
        state.settings[cast_height_field] = normalize_resource_bar_height(value, state.settings.cast_bar_height);
        mark_config_changed();
    end);
    render_int_control('Cast Text At', ('%s_cast_text_threshold'):fmt(kind), state.settings[cast_threshold_field], LIMITS.cast_text_threshold_min, LIMITS.cast_text_threshold_max, function (value)
        state.settings[cast_threshold_field] = normalize_cast_text_threshold(value, state.settings.cast_text_threshold);
        mark_config_changed();
    end, '%');
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

function render_signet_reminder_config()
    imgui.TextColored(COLORS.accent, 'Signet Reminder');

    local enabled = state.settings.signet_reminder_enabled == true;
    if (imgui.Checkbox('Monitor Signet##ashitaframes_signet_reminder_enabled', { enabled })) then
        state.settings.signet_reminder_enabled = not enabled;
        mark_config_changed();
    end

    if (state.settings.signet_reminder_enabled == true) then
        render_int_control(
            'Warn Under',
            'signet_warning_minutes',
            state.settings.signet_warning_minutes,
            LIMITS.signet_warning_minutes_min,
            LIMITS.signet_warning_minutes_max,
            function (value)
                state.settings.signet_warning_minutes = clamp_int(value, LIMITS.signet_warning_minutes_min, LIMITS.signet_warning_minutes_max);
                mark_config_changed();
            end,
            'min');
        imgui.TextColored(COLORS.text_muted, 'Hidden while healthy; flashes amber near expiry and red when missing.');
    end
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
    imgui.Separator();
    render_signet_reminder_config();
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
    if (imgui.Checkbox('Party Status Icons##ashitaframes_show_buffs', { show_buffs })) then
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

    local show_target_mobdb = state.settings.show_target_mobdb == true;
    if (imgui.Checkbox('MobDB Target Intelligence##ashitaframes_show_target_mobdb', { show_target_mobdb })) then
        state.settings.show_target_mobdb = not show_target_mobdb;
        mark_config_changed();
    end

    if (state.settings.show_target_mobdb) then
        imgui.TextColored(COLORS.text_muted, 'MobDB field card with split damage chips, behavior icons, drops, and respawn time.');
    end

    imgui.Separator();
    render_frame_layout_controls('target', 'Target Frame');
    imgui.Separator();
    render_frame_bar_controls('target', 'Target Bars');
    imgui.Separator();
    render_target_debuff_reminder_config();
end

function render_battle_target_config_tab()
    local show_battle_targets = state.settings.show_battle_targets == true;
    if (imgui.Checkbox('Show Battle Targets##ashitaframes_show_battle_targets', { show_battle_targets })) then
        state.settings.show_battle_targets = not show_battle_targets;
        mark_config_changed();
    end

    local show_debuffs = state.settings.show_battle_target_debuffs == true;
    if (imgui.Checkbox('Observed Debuff Icons##ashitaframes_show_battle_target_debuffs', { show_debuffs })) then
        state.settings.show_battle_target_debuffs = not show_debuffs;
        mark_config_changed();
    end

    render_int_control(
        'Max Targets',
        'battle_target_max_entries',
        state.settings.battle_target_max_entries,
        LIMITS.battle_target_max_entries_min,
        LIMITS.battle_target_max_entries_max,
        function (value)
            state.settings.battle_target_max_entries = clamp_int(value, LIMITS.battle_target_max_entries_min, LIMITS.battle_target_max_entries_max);
            mark_config_changed();
        end,
        'targets');

    imgui.TextColored(COLORS.text_muted, 'Shows enemies claimed by or acting against your party. The current target is highlighted and sorted first.');
    imgui.Separator();
    render_frame_layout_controls('battle', 'Battle Targets Frame');
    imgui.Separator();
    render_frame_bar_controls('battle', 'Battle Target Bars');
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
        if (imgui.BeginTabItem('Battle##ashitaframes_config_battle', nil)) then
            render_battle_target_config_tab();
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
        imgui.Text(('Battle pos: %d, %d'):fmt(state.battle_window_x, state.battle_window_y));

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

function print_help()
    log_info('Commands:');
    print(chat.header(addon.name):append(chat.message('/ashitaframes show | hide | toggle')));
    print(chat.header(addon.name):append(chat.message('/ashitaframes lock | unlock | config')));
    print(chat.header(addon.name):append(chat.message('/ashitaframes reload | status')));
end

function observed_buff_summary()
    local names = { };

    for name, buffs in pairs(state.observed_buffs) do
        local buff_names = { };
        if (type(buffs) == 'table') then
            for buff_id, enabled in pairs(buffs) do
                if (enabled == true) then
                    table.insert(buff_names, buff_name(buff_id));
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

function print_status()
    local reminder_job = current_player_job_key();
    local reminder_profile = reminder_profile_for_job(reminder_job);
    local status_party_size = party_size(state.settings.party_preview_size);
    local status_party_layout = party_layout_for_size(status_party_size);

    log_info(('visible=%s locked=%s self=%s target=%s party=%s pet=%s alliance=%s buffs=%s reminders=%s targetDebuffs=%s targetDebuffReminders=%s reminderJob=%s reminderProfile=%s observed=%s observedEvents=%d observedLogEvents=%d castEvents=%d maxBuffs=%d self=(%d,%d %dx%d gap=%d op=%d) partySize=%d party=(%d,%d %dx%d gap=%d op=%d cols=%d rows=%d) pet=(%d,%d %dx%d gap=%d op=%d) target=(%d,%d %dx%d gap=%d op=%d)'):fmt(
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
        state.cast_events,
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
    -- Damaging spells that also apply a status effect.
    [2] = true,
    [252] = true,
    [264] = true,
    [265] = true,

    -- Abilities, weapon skills, spells, and additional effects that report
    -- the applied status id in the target-action parameter.
    [127] = true,
    [160] = true,
    [164] = true,
    [166] = true,
    [186] = true,
    [194] = true,
    [203] = true,
    [205] = true,
    [230] = true,
    [236] = true,
    [237] = true,
    [266] = true,
    [267] = true,
    [268] = true,
    [269] = true,
    [271] = true,
    [272] = true,
    [277] = true,
    [278] = true,
    [279] = true,
    [280] = true,
    [319] = true,
    [320] = true,
    [327] = true,
    [375] = true,
    [412] = true,
    [519] = true,
    [520] = true,
    [645] = true,
    [754] = true,
    [755] = true,
    [804] = true,
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

function local_player_server_id()
    local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
    local party = memory ~= nil and safe_read(function () return memory:GetParty(); end, nil) or nil;
    return party ~= nil and tonumber(safe_read(function () return party:GetMemberServerId(0); end, nil)) or nil;
end

function target_debuff_duration_seconds(key, spell_id)
    key = normalize_target_debuff_key(key);
    spell_id = tonumber(spell_id);
    if (spell_id ~= nil and TARGET_DEBUFF_SPELL_DURATIONS[spell_id] ~= nil) then
        return clamp_int(TARGET_DEBUFF_SPELL_DURATIONS[spell_id], 1, 86400);
    end

    local definition = key ~= nil and TARGET_DEBUFF_DEFINITIONS[key] or nil;
    return clamp_int(definition ~= nil and definition.duration_seconds or 600, 1, 86400);
end

function set_observed_target_debuff(server_id, key_or_status_id, enabled, spell_id)
    local target_id = tonumber(server_id);
    local key = normalize_target_debuff_key(key_or_status_id);
    local status_id = target_debuff_status_id(key_or_status_id);
    if (target_id == nil or target_id == 0 or status_id == nil) then
        return false;
    end

    if (enabled == true) then
        state.observed_target_debuffs[target_id] = state.observed_target_debuffs[target_id] or { };
        state.observed_target_debuffs[target_id][status_id] = {
            status_id = status_id,
            spell_id = tonumber(spell_id),
            expires_at = os.time() + target_debuff_duration_seconds(key, spell_id),
        };
        return true;
    end

    local entry = state.observed_target_debuffs[target_id];
    if (type(entry) ~= 'table') then
        return false;
    end

    entry[status_id] = nil;
    if (next(entry) == nil) then
        state.observed_target_debuffs[target_id] = nil;
    end

    return true;
end

function set_observed_target_debuff_name(name, key_or_status_id, enabled, spell_id)
    local name_key = observed_target_name_key(name);
    local key = normalize_target_debuff_key(key_or_status_id);
    local status_id = target_debuff_status_id(key_or_status_id);
    if (name_key == nil or status_id == nil) then
        return false;
    end

    if (enabled == true) then
        state.observed_target_debuff_names[name_key] = state.observed_target_debuff_names[name_key] or { };
        state.observed_target_debuff_names[name_key][status_id] = {
            status_id = status_id,
            spell_id = tonumber(spell_id),
            expires_at = os.time() + target_debuff_duration_seconds(key, spell_id),
        };
        return true;
    end

    local entry = state.observed_target_debuff_names[name_key];
    if (type(entry) ~= 'table') then
        return false;
    end

    entry[status_id] = nil;
    if (next(entry) == nil) then
        state.observed_target_debuff_names[name_key] = nil;
    end

    return true;
end

function set_observed_target_debuff_for_name(name, key_or_status_id, enabled, spell_id)
    local name_key = observed_target_name_key(name);
    if (name_key == nil) then
        return false;
    end

    local current_name, server_id = current_target_identity();
    local is_current_target = name_key == observed_target_name_key(current_name)
        and tonumber(server_id) ~= nil
        and tonumber(server_id) ~= 0;

    if (enabled == true and is_current_target) then
        return set_observed_target_debuff(server_id, key_or_status_id, true, spell_id);
    end

    local handled = set_observed_target_debuff_name(name, key_or_status_id, enabled, spell_id);
    if (enabled ~= true and is_current_target) then
        handled = set_observed_target_debuff(server_id, key_or_status_id, false, spell_id) or handled;
    end

    return handled;
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
    local status_id = buff_id_from_name(status) or target_debuff_status_id(status);
    if (status_id == nil) then
        return false;
    end

    return set_observed_target_debuff_for_name(name, status_id, false);
end

function clear_observed_target_debuff_status(server_id, status_id)
    return set_observed_target_debuff(server_id, status_id, false);
end

function set_observed_target_buff(server_id, status_id, enabled)
    local target_id = tonumber(server_id);
    local buff_id = tonumber(status_id);
    if (target_id == nil or target_id == 0 or buff_id == nil or buff_id <= 0 or buff_id > 0x3FF or target_debuff_key_from_id(buff_id) ~= nil) then
        return false;
    end

    if (enabled == true) then
        state.observed_target_buffs[target_id] = state.observed_target_buffs[target_id] or { };
        state.observed_target_buffs[target_id][buff_id] = {
            status_id = buff_id,
            expires_at = os.time() + 600,
        };
        return true;
    end

    local entry = state.observed_target_buffs[target_id];
    if (type(entry) ~= 'table') then
        return false;
    end

    entry[buff_id] = nil;
    if (next(entry) == nil) then
        state.observed_target_buffs[target_id] = nil;
    end

    return true;
end

function set_observed_target_buff_name(name, status_id, enabled)
    local name_key = observed_target_name_key(name);
    local buff_id = tonumber(status_id);
    if (name_key == nil or buff_id == nil or buff_id <= 0 or buff_id > 0x3FF or target_debuff_key_from_id(buff_id) ~= nil) then
        return false;
    end

    if (enabled == true) then
        state.observed_target_buff_names[name_key] = state.observed_target_buff_names[name_key] or { };
        state.observed_target_buff_names[name_key][buff_id] = {
            status_id = buff_id,
            expires_at = os.time() + 600,
        };
        return true;
    end

    local entry = state.observed_target_buff_names[name_key];
    if (type(entry) ~= 'table') then
        return false;
    end

    entry[buff_id] = nil;
    if (next(entry) == nil) then
        state.observed_target_buff_names[name_key] = nil;
    end

    return true;
end

function set_observed_target_buff_for_name(name, status_id, enabled)
    local handled = set_observed_target_buff_name(name, status_id, enabled);
    local current_name, server_id = current_target_identity();
    if (observed_target_name_key(name) ~= nil and observed_target_name_key(name) == observed_target_name_key(current_name)) then
        handled = set_observed_target_buff(server_id, status_id, enabled) or handled;
    end

    return handled;
end

function clear_observed_target_buff_name(name)
    local name_key = observed_target_name_key(name);
    if (name_key == nil or state.observed_target_buff_names[name_key] == nil) then
        return false;
    end

    state.observed_target_buff_names[name_key] = nil;
    return true;
end

function clear_observed_target_buff_for_name(name)
    local cleared = clear_observed_target_buff_name(name);
    local current_name, server_id = current_target_identity();
    if (observed_target_name_key(name) ~= nil and observed_target_name_key(name) == observed_target_name_key(current_name)) then
        local target_id = tonumber(server_id);
        if (target_id ~= nil and state.observed_target_buffs[target_id] ~= nil) then
            state.observed_target_buffs[target_id] = nil;
            cleared = true;
        end
    end

    return cleared;
end

function read_le_uint(data, offset, size)
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

function parse_action_packet(data)
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

function action_first_target_param(action)
    if (type(action) ~= 'table') then
        return nil;
    end

    for _, target in ipairs(action.targets or { }) do
        for _, target_action in ipairs(target.actions or { }) do
            local param = tonumber(target_action.param);
            if (param ~= nil and param > 0) then
                return param;
            end
        end
    end

    return nil;
end

function action_first_target_id(action)
    if (type(action) ~= 'table') then
        return nil;
    end

    for _, target in ipairs(action.targets or { }) do
        local target_id = tonumber(target.id);
        if (target_id ~= nil and target_id ~= 0) then
            return target_id;
        end
    end

    return nil;
end

function handle_battle_target_action_packet(data)
    local action = parse_action_packet(data);
    if (action == nil) then
        return;
    end

    local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
    local entity = memory ~= nil and safe_read(function () return memory:GetEntity(); end, nil) or nil;
    local party = memory ~= nil and safe_read(function () return memory:GetParty(); end, nil) or nil;
    if (entity == nil or party == nil) then
        return;
    end

    local party_ids = battle_target_party_ids(party);
    local actor_id = tonumber(action.actor_id);
    local actor_is_party = party_ids[actor_id] == true;
    local actor_index = not actor_is_party and battle_target_index_by_server_id(entity, actor_id) or nil;
    local actor_hit_party = false;

    for _, target in ipairs(action.targets or { }) do
        local target_id = tonumber(target.id);
        if (party_ids[target_id] == true) then
            actor_hit_party = true;
        end

        if (actor_is_party and target_id ~= nil and target_id ~= 0) then
            local target_index = battle_target_index_by_server_id(entity, target_id);
            if (battle_target_entity_valid(entity, target_index)) then
                battle_target_remember(target_index, target_id);
            end
        end
    end

    if (actor_hit_party and battle_target_entity_valid(entity, actor_index)) then
        battle_target_remember(actor_index, actor_id);
    end
end

function handle_battle_target_update_packet(data)
    if (type(data) ~= 'string') then
        return;
    end

    local update_flags = read_le_uint(data, 0x0B, 1);
    if (update_flags == nil or bit.band(update_flags, 0x02) ~= 0x02) then
        return;
    end

    local index = read_le_uint(data, 0x09, 2);
    local claim_id = read_le_uint(data, 0x2D, 4);
    local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
    local entity = memory ~= nil and safe_read(function () return memory:GetEntity(); end, nil) or nil;
    local party = memory ~= nil and safe_read(function () return memory:GetParty(); end, nil) or nil;
    local party_ids = battle_target_party_ids(party);

    if (battle_target_entity_valid(entity, index)
        and claim_id ~= nil
        and claim_id ~= 0
        and (party_ids[claim_id] == true or party_ids[bit.band(claim_id, 0xFFFF)] == true)) then
        battle_target_remember(index, safe_read(function () return entity:GetServerId(index); end, 0));
    end
end

function handle_cast_action_packet(data)
    local action = parse_action_packet(data);
    if (action == nil) then
        return;
    end

    local action_type = tonumber(action.action_type);
    local actor_id = tonumber(action.actor_id);
    if (action_type == 7 and tonumber(action.param) == 0x6163) then
        local resource_id = action_first_target_param(action);
        local info = monster_ability_cast_info_by_id(resource_id);
        if (info ~= nil) then
            local target_id = action_first_target_id(action);
            set_active_cast(
                actor_id,
                entity_name_by_server_id(actor_id),
                cast_display_label(info.label, entity_name_by_server_id(target_id), target_id),
                info.duration,
                info.kind,
                info.id);
            return;
        end
    end

    if ((action_type == 8 or action_type == 9) and tonumber(action.param) == 0x6163) then
        local resource_id = action_first_target_param(action);
        local target_id = action_first_target_id(action);
        local target_name = entity_name_by_server_id(target_id);
        local info = action_type == 8 and spell_cast_info_by_id(resource_id) or item_cast_info_by_id(resource_id);
        if (info ~= nil) then
            set_active_cast(actor_id, entity_name_by_server_id(actor_id), cast_display_label(info.label, target_name, target_id), info.duration, info.kind, info.id);
        else
            set_active_cast(actor_id, entity_name_by_server_id(actor_id), cast_display_label('Casting', target_name, target_id), 3.0, action_type == 8 and 'spell' or 'item', resource_id);
        end
        return;
    end

    if (actor_id ~= nil
        and state.active_casts_by_id[actor_id] ~= nil
        and action_type ~= 7
        and action_type ~= 8
        and action_type ~= 9) then
        clear_active_cast(actor_id, nil);
    end
end

function handle_target_debuff_action_packet(data)
    local action = parse_action_packet(data);
    if (action == nil) then
        return;
    end

    local action_type = tonumber(action.action_type);
    if (action_type ~= 3 and action_type ~= 4 and action_type ~= 14) then
        return;
    end

    local resource_id = tonumber(action.param);
    local override_status_id = TARGET_DEBUFF_EFFECT_OVERRIDES[resource_id];
    for _, target in ipairs(action.targets or { }) do
        for _, target_action in ipairs(target.actions or { }) do
            local message = tonumber(target_action.message);
            if (TARGET_DEBUFF_APPLY_MESSAGES[message] == true) then
                local status_id = override_status_id;
                if (status_id == nil and message ~= 2 and message ~= 252) then
                    status_id = target_debuff_status_id(target_action.param);
                end
                if (status_id ~= nil) then
                    set_observed_target_debuff(target.id, status_id, true, action_type == 4 and resource_id or nil);
                end
            end
        end
    end
end

function handle_target_debuff_message_packet(data)
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

function handle_incoming_packet(e)
    if (e == nil) then
        return;
    end

    -- Combat-log addons such as SimpleLog can rewrite and block incoming
    -- packets after rendering replacement chat text. AshitaFrames is a
    -- passive observer, so read the untouched server payload without changing
    -- the packet's blocked state or modified data.
    local packet_data = e.data or e.data_modified;
    if (packet_data == nil) then
        return;
    end

    if (e.id == 0x028) then
        handle_battle_target_action_packet(packet_data);
        handle_cast_action_packet(packet_data);
        handle_target_debuff_action_packet(packet_data);
    elseif (e.id == 0x00E) then
        handle_battle_target_update_packet(packet_data);
    elseif (e.id == 0x029) then
        handle_target_debuff_message_packet(packet_data);
    elseif (e.id == 0x00A) then
        clear_observed_target_debuffs();
        clear_active_casts();
        state.battle_targets = { };
        state.battle_target_last_scan = 0;
    end
end

function clean_event_message(message)
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

function current_party_contains_name(name)
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

function current_target_identity()
    local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
    local target = memory ~= nil and safe_read(function () return memory:GetTarget(); end, nil) or nil;
    local entity = memory ~= nil and safe_read(function () return memory:GetEntity(); end, nil) or nil;
    if (target == nil) then
        return '', nil;
    end

    local primary_index = safe_read(function () return target:GetTargetIndex(0); end, 0);
    local sub_index = safe_read(function () return target:GetTargetIndex(1); end, 0);
    local is_sub_target_active = truthy(safe_read(function () return target:GetIsSubTargetActive(); end, false));
    local active_index = is_sub_target_active and sub_index or primary_index;
    if (active_index == nil or active_index <= 0) then
        return '', nil;
    end

    local name = entity ~= nil and clean_string(safe_read(function () return entity:GetName(active_index); end, '')) or '';
    if (#name == 0) then
        name = clean_string(safe_read(function () return target:GetWindowName(); end, ''));
    end
    if (#name == 0) then
        name = clean_string(safe_read(function () return target:GetLastTargetName(); end, ''));
    end

    local server_id = entity ~= nil and safe_read(function () return entity:GetServerId(active_index); end, nil) or nil;
    if (server_id == nil or server_id == 0) then
        server_id = safe_read(function () return target:GetServerId(0); end, nil);
    end

    return name, server_id;
end

function target_check_toughness_from_text(text)
    local lower = clean_string(text):lower();
    if (#lower == 0) then
        return nil;
    end

    if (lower:find('impossible to gauge', 1, true) ~= nil) then
        return '??';
    end
    if (lower:find('too weak', 1, true) ~= nil) then
        return 'Too Weak';
    end
    if (lower:find('incredibly easy prey', 1, true) ~= nil or lower:find('very easy prey', 1, true) ~= nil) then
        return 'Very Easy';
    end
    if (lower:find('easy prey', 1, true) ~= nil) then
        return 'Easy Prey';
    end
    if (lower:find('decent challenge', 1, true) ~= nil) then
        return 'Decent';
    end
    if (lower:find('even match', 1, true) ~= nil) then
        return 'Even Match';
    end
    if (lower:find('incredibly tough', 1, true) ~= nil) then
        return 'Incred. Tough';
    end
    if (lower:find('very tough', 1, true) ~= nil) then
        return 'Very Tough';
    end
    if (lower:find('tough', 1, true) ~= nil) then
        return 'Tough';
    end

    return nil;
end

function target_check_level_from_text(text)
    local lower = clean_string(text):lower();
    local level = lower:match('level%s*:%s*(%d+)')
        or lower:match('level%s+(%d+)')
        or lower:match('lv%.%s*:%s*(%d+)')
        or lower:match('lv%.%s*(%d+)')
        or lower:match('lv%s*:%s*(%d+)')
        or lower:match('lv%s*(%d+)');

    level = tonumber(level);
    if (level == nil or level <= 0 or level > 255) then
        return nil;
    end

    return math.floor(level + 0.5);
end

function target_check_name_from_text(text)
    local name = text:match("^The%s+(.+)'s%s+strength%s+is%s+impossible%s+to%s+gauge")
        or text:match("^(.+)'s%s+strength%s+is%s+impossible%s+to%s+gauge")
        or text:match('^The%s+(.+)%s+seems')
        or text:match('^(.+)%s+seems')
        or text:match('^The%s+(.+)%s+checks%s+as')
        or text:match('^(.+)%s+checks%s+as')
        or text:match('^The%s+(.+)%s+is%s+level')
        or text:match('^(.+)%s+is%s+level');

    return clean_string(name);
end

function process_observed_target_check_text(message)
    local text = clean_event_message(message);
    if (#text == 0) then
        return false;
    end

    local lower = text:lower();
    local name = target_check_name_from_text(text);
    if (lower:find('seems', 1, true) == nil and lower:find('checks as', 1, true) == nil and lower:find('check', 1, true) == nil and lower:find('impossible to gauge', 1, true) == nil and #name == 0) then
        return false;
    end

    local toughness = target_check_toughness_from_text(text);
    local level = target_check_level_from_text(text);
    if (toughness == nil and level == nil) then
        return false;
    end

    local current_name, server_id = current_target_identity();
    if (#name == 0) then
        name = current_name;
    elseif (observed_target_name_key(name) ~= observed_target_name_key(current_name)) then
        server_id = nil;
    end

    return set_observed_target_check(name, server_id, toughness or '??', level);
end

function set_observed_buff(name, status, enabled)
    local name_key = observed_name_key(name);
    local buff_id = tonumber(status) or buff_id_from_name(status);
    if (name_key == nil or buff_id == nil or buff_id <= 0 or buff_id > 0x3FF or not current_party_contains_name(name)) then
        return false;
    end

    if (enabled == true) then
        state.observed_buffs[name_key] = state.observed_buffs[name_key] or { };
        state.observed_buffs[name_key][buff_id] = true;
        return true;
    end

    local entry = state.observed_buffs[name_key];
    if (type(entry) ~= 'table') then
        return false;
    end

    entry[buff_id] = nil;
    for _, value in pairs(entry) do
        if (value == true) then
            return true;
        end
    end

    state.observed_buffs[name_key] = nil;
    return true;
end

function observed_buff_event(text)
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

function process_observed_buff_text(message)
    local name, buff, enabled = observed_buff_event(clean_event_message(message));
    if (name == nil or buff == nil) then
        return false;
    end

    return set_observed_buff(name, buff, enabled);
end

function process_observed_target_buff_text(message)
    local name, buff, enabled = observed_buff_event(clean_event_message(message));
    if (name == nil or buff == nil or current_party_contains_name(name)) then
        return false;
    end

    local buff_id = buff_id_from_name(buff);
    if (buff_id == nil or target_debuff_key_from_id(buff_id) ~= nil) then
        return false;
    end

    return set_observed_target_buff_for_name(name, buff_id, enabled);
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
        local cleared_buffs = clear_observed_target_buff_for_name(target);
        clear_pending_target_debuff_if_matches(target);
        return cleared or cleared_buffs;
    end

    target = text:match('^.- defeats (.-)%.$');
    if (target ~= nil) then
        local cleared = clear_observed_target_debuff_name(target);
        local cleared_buffs = clear_observed_target_buff_for_name(target);
        clear_pending_target_debuff_if_matches(target);
        return cleared or cleared_buffs;
    end

    target = text:match('^Unable to see (.-)%.$') or text:match('^You lose sight of (.-)%.$') or text:match('^(.-) is out of range%.$') or text:match('^(.-) is too far away%.$');
    if (target ~= nil and clear_pending_target_debuff_if_matches(target)) then
        return true;
    end

    target = text:match('^(.-) resists the spell%.$');
    if (target ~= nil and clear_pending_target_debuff_if_matches(target)) then
        return true;
    end

    local target_status;
    target, target_status = text:match('^(.-) is afflicted with (.-)%.$');
    if (target == nil or target_status == nil) then
        target, target_status = text:match('^(.-) receives the effect of (.-)%.$');
    end
    if (target ~= nil and target_status ~= nil) then
        local status_id = buff_id_from_name(target_status);
        if (status_id ~= nil) then
            return set_observed_target_debuff_for_name(target, status_id, true);
        end
    end

    target = text:match('^(.-) takes %d+ points of damage%.$');
    local pending = pending_target_matches(target, 'dia');
    if (pending ~= nil) then
        state.pending_target_debuff_cast = nil;
        return set_observed_target_debuff_for_name(target, pending.key, true, pending.spell_id);
    end

    target = text:match('^(.-) is paralyzed%.$');
    pending = pending_target_matches(target, 'paralyze');
    if (pending ~= nil) then
        state.pending_target_debuff_cast = nil;
        return set_observed_target_debuff_for_name(target, pending.key, true, pending.spell_id);
    elseif (target ~= nil) then
        return set_observed_target_debuff_for_name(target, 'paralyze', true);
    end

    target = text:match('^(.-) is slowed%.$');
    pending = pending_target_matches(target, 'slow');
    if (pending ~= nil) then
        state.pending_target_debuff_cast = nil;
        return set_observed_target_debuff_for_name(target, pending.key, true, pending.spell_id);
    elseif (target ~= nil) then
        return set_observed_target_debuff_for_name(target, 'slow', true);
    end

    return false;
end

function process_observed_cast_text(message)
    if (state.suppress_cast_tracking == true) then
        return false;
    end

    local text = clean_event_message(message);
    if (#text == 0) then
        return false;
    end

    local actor, ability = text:match('^(.-) readies (.-)%.$');
    if (actor ~= nil and ability ~= nil) then
        return set_active_cast(nil, actor, ability, 6.0, 'mob_ability', nil);
    end

    actor, ability = text:match('^(.-) uses (.-)%.$');
    if (actor ~= nil and ability ~= nil) then
        clear_active_cast(nil, actor);
        return true;
    end

    actor = text:match("^(.-)'s readying is interrupted%.$");
    if (actor ~= nil) then
        clear_active_cast(nil, actor);
        return true;
    end

    local spell, target;
    actor, spell, target = text:match('^(.-) starts casting (.-) on (.-)%.$');
    if (actor == nil or spell == nil) then
        actor, spell = text:match('^(.-) starts casting (.-)%.$');
    end
    if (actor ~= nil and spell ~= nil) then
        local info = spell_cast_info_by_name(spell);
        if (info ~= nil) then
            return set_active_cast(nil, actor, cast_display_label(info.label, target), info.duration, info.kind, info.id);
        end

        return set_active_cast(nil, actor, cast_display_label(spell, target), 3.0, 'spell', nil);
    end

    actor = text:match("^(.-)'s casting is interrupted%.$");
    if (actor ~= nil) then
        clear_active_cast(nil, actor);
        return true;
    end
    if (text == 'Your casting is interrupted.') then
        clear_active_cast(local_player_server_id(), current_player_name());
        return true;
    end

    actor, spell, target = text:match('^(.-) casts (.-) on (.-)%.$');
    if (actor == nil or spell == nil) then
        actor, spell = text:match('^(.-) casts (.-)%.$');
    end
    if (actor ~= nil and spell ~= nil) then
        clear_active_cast(nil, actor);
        return true;
    end

    return false;
end

function process_observed_text(message, allow_target_buffs)
    local handled_buff = process_observed_buff_text(message);
    local handled_target_buff = allow_target_buffs == true and process_observed_target_buff_text(message) or false;
    local handled_debuff = process_observed_target_debuff_text(message);
    local handled_check = process_observed_target_check_text(message);
    local handled_cast = process_observed_cast_text(message);
    return handled_buff or handled_target_buff or handled_debuff or handled_check or handled_cast;
end

function current_chat_log_path()
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

function seed_observed_buffs_from_chat_log()
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

    state.suppress_cast_tracking = true;
    for index = start_index, #lines, 1 do
        process_observed_text(lines[index], false);
    end
    state.suppress_cast_tracking = false;

    state.observed_log_path = path;
    state.observed_log_position = position;
end

function poll_observed_buffs_from_chat_log()
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
        if (process_observed_text(line, true)) then
            state.observed_log_events = state.observed_log_events + 1;
        end
    end

    state.observed_log_position = file:seek() or size;
    file:close();
end

function handle_text_in(e)
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
            if (process_observed_text(text, true)) then
                state.observed_text_events = state.observed_text_events + 1;
                return;
            end
        end
    end
end

function handle_command(e)
    local args = e.command:args();
    if (PARTY_SELECTION.handle_command(e, args)) then
        return;
    end
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
    PARTY_SELECTION.prune();
    poll_observed_buffs_from_chat_log();
    prune_observed_target_buffs();
    prune_observed_target_debuffs();
    prune_active_casts();

    if (not state.visible[1]) then
        render_config_window();
        return;
    end

    render_target();
    render_battle_targets();
    render_self();
    render_pet();
    render_party();
    render_config_window();
end);

