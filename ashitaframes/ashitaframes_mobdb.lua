local bit = require('bit');

local bridge = {
    current_zone = nil,
    indices = { },
    names = { },
    last_error = nil,
};

local JOBS = {
    [1] = 'WAR', [2] = 'MNK', [3] = 'WHM', [4] = 'BLM', [5] = 'RDM', [6] = 'THF',
    [7] = 'PLD', [8] = 'DRK', [9] = 'BST', [10] = 'BRD', [11] = 'RNG', [12] = 'SAM',
    [13] = 'NIN', [14] = 'DRG', [15] = 'SMN', [16] = 'BLU', [17] = 'COR', [18] = 'PUP',
    [19] = 'DNC', [20] = 'SCH', [21] = 'GEO', [22] = 'RUN',
};

local PHYSICAL_ORDER = { 'Slashing', 'Piercing', 'H2H', 'Impact' };
local MAGICAL_ORDER = { 'Fire', 'Ice', 'Wind', 'Earth', 'Lightning', 'Water', 'Light', 'Dark' };
local STATUS_ORDER = {
    'Sleep', 'Gravity', 'Bind', 'Stun', 'Silence', 'Paralyze', 'Blind', 'Slow',
    'Poison', 'Elegy', 'Requiem', 'LightSleep', 'DarkSleep', 'Petrify', 'Amnesia',
    'Virus', 'Charm', 'Terror',
};
local IMMUNITIES = {
    { mask = 0x0001, key = 'Sleep', icon = 'ImmuneSleep' },
    { mask = 0x0002, key = 'Gravity', icon = 'ImmuneGravity' },
    { mask = 0x0004, key = 'Bind', icon = 'ImmuneBind' },
    { mask = 0x0008, key = 'Stun', icon = 'ImmuneStun' },
    { mask = 0x0010, key = 'Silence', icon = 'ImmuneSilence' },
    { mask = 0x0020, key = 'Paralyze', icon = 'ImmuneParalyze' },
    { mask = 0x0040, key = 'Blind', icon = 'ImmuneBlind' },
    { mask = 0x0080, key = 'Slow', icon = 'ImmuneSlow' },
    { mask = 0x0100, key = 'Poison', icon = 'ImmunePoison' },
    { mask = 0x0200, key = 'Elegy', icon = 'ImmuneElegy' },
    { mask = 0x0400, key = 'Requiem', icon = 'ImmuneRequiem' },
    { mask = 0x0800, key = 'Light Sleep', icon = 'ImmuneLightSleep' },
    { mask = 0x1000, key = 'Dark Sleep', icon = 'ImmuneDarkSleep' },
    { mask = 0x2000, key = 'Petrify', icon = 'ImmunePetrify' },
};

local function safe_read(callback, fallback)
    local ok, value = pcall(callback);
    if ok and value ~= nil then
        return value;
    end
    return fallback;
end

local function clean_string(value)
    return (tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', ''));
end

local function value_name(resource)
    if resource == nil then
        return '';
    end

    local value = safe_read(function () return resource.Name; end, nil);
    if type(value) == 'string' then
        return clean_string(value);
    end
    if type(value) == 'table' then
        return clean_string(value[1] or value[2] or value[0] or value.en or value.English or '');
    end

    -- Ashita resource names are commonly indexable userdata rather than Lua
    -- tables. Resolve the localized string instead of stringifying the
    -- userdata container into an implementation address.
    local indexed = safe_read(function () return value[1]; end, nil)
        or safe_read(function () return value[2]; end, nil)
        or safe_read(function () return value[0]; end, nil);
    local name = clean_string(indexed);
    if (#name > 0) then
        return name;
    end

    local fallback = clean_string(value);
    if (fallback:match('^userdata:%s*0x%x+$') ~= nil) then
        return '';
    end
    return fallback;
end

local function resolve_job_name(resources, job_id)
    job_id = tonumber(job_id) or 0;
    if job_id <= 0 then
        return '';
    end
    local name = clean_string(safe_read(function () return resources:GetString('jobs.names_abbr', job_id); end, ''));
    return #name > 0 and name or (JOBS[job_id] or '');
end

local function resolve_item_name(resources, item_id)
    local resource = safe_read(function () return resources:GetItemById(item_id); end, nil);
    local name = value_name(resource);
    return #name > 0 and name or ('Item %d'):fmt(tonumber(item_id) or 0);
end

local function resolve_spell_name(resources, spell_id)
    local resource = safe_read(function () return resources:GetSpellById(spell_id); end, nil);
    local name = value_name(resource);
    return #name > 0 and name or ('Spell %d'):fmt(tonumber(spell_id) or 0);
end

local function sorted_resource_names(resources, values, resolver)
    local result = { };
    local seen = { };
    if type(values) ~= 'table' then
        return result;
    end
    for _, value in ipairs(values) do
        local name = clean_string(resolver(resources, value));
        if (#name > 0 and name:match('^userdata:%s*0x%x+$') == nil and not seen[name]) then
            seen[name] = true;
            table.insert(result, name);
        end
    end
    table.sort(result);
    return result;
end

local function sorted_item_entries(resources, values)
    local result = { };
    local seen = { };
    if type(values) ~= 'table' then
        return result;
    end
    for _, value in ipairs(values) do
        local item_id = tonumber(value);
        local name = clean_string(resolve_item_name(resources, item_id));
        if (item_id ~= nil and item_id > 0 and #name > 0 and not seen[item_id]) then
            seen[item_id] = true;
            table.insert(result, { id = item_id, name = name });
        end
    end
    table.sort(result, function (left, right)
        if left.name == right.name then return left.id < right.id; end
        return left.name < right.name;
    end);
    return result;
end

local function modifiers(resource, order, include_neutral)
    local result = { };
    local values = type(resource.Modifiers) == 'table' and resource.Modifiers or { };
    for _, key in ipairs(order) do
        local potency = tonumber(values[key]);
        if potency ~= nil and (include_neutral or potency ~= 1.0) then
            table.insert(result, {
                key = key,
                icon = key,
                potency = potency,
                percent = (potency - 1.0) * 100,
            });
        end
    end
    return result;
end

local function status_resistances(resource)
    return modifiers(resource, STATUS_ORDER, false);
end

local function immunities(resource)
    local result = { };
    local mask = tonumber(resource.Immunities) or 0;
    for _, definition in ipairs(IMMUNITIES) do
        if bit.band(mask, definition.mask) ~= 0 then
            table.insert(result, definition);
        end
    end
    return result;
end

local function behavior_flags(resource)
    local result = { };
    table.insert(result, {
        key = (resource.Aggro == true and 'Aggro' or 'Passive') .. (resource.Notorious == true and ' NM' or ''),
        icon = resource.Notorious == true
            and (resource.Aggro == true and 'AggroHQ' or 'PassiveHQ')
            or (resource.Aggro == true and 'AggroNQ' or 'PassiveNQ'),
        active = true,
    });
    local definitions = {
        { field = 'Link', key = 'Links', icon = 'Link' },
        { field = 'TrueSight', key = 'True sight', icon = 'TrueSight' },
        { field = 'Sight', key = 'Sight', icon = 'Sight' },
        { field = 'Sound', key = 'Sound', icon = 'Sound' },
        { field = 'Scent', key = 'Scent', icon = 'Scent' },
        { field = 'Magic', key = 'Magic', icon = 'Magic' },
        { field = 'JA', key = 'Job ability', icon = 'JA' },
        { field = 'Blood', key = 'Low HP', icon = 'Blood' },
    };
    for _, definition in ipairs(definitions) do
        if resource[definition.field] == true then
            table.insert(result, definition);
        end
    end
    return result;
end

local function direction(entity, player_index, target_index)
    if entity == nil or tonumber(player_index) == nil or tonumber(target_index) == nil then
        return 'Unknown';
    end
    local player_x = safe_read(function () return entity:GetLocalPositionX(player_index); end, nil);
    local player_y = safe_read(function () return entity:GetLocalPositionY(player_index); end, nil);
    local target_x = safe_read(function () return entity:GetLocalPositionX(target_index); end, nil);
    local target_y = safe_read(function () return entity:GetLocalPositionY(target_index); end, nil);
    if player_x == nil or player_y == nil or target_x == nil or target_y == nil then
        return 'Unknown';
    end
    local radians = math.atan2(target_x - player_x, target_y - player_y);
    if radians > 2.74 then return 'South'; end
    if radians > 1.96 then return 'South-East'; end
    if radians > 1.17 then return 'East'; end
    if radians > 0.39 then return 'North-East'; end
    if radians > -0.39 then return 'North'; end
    if radians > -1.17 then return 'North-West'; end
    if radians > -1.96 then return 'West'; end
    if radians > -2.70 then return 'South-West'; end
    return 'South';
end

local function position(entity, target_index)
    local x = safe_read(function () return entity:GetLocalPositionX(target_index); end, nil);
    local y = safe_read(function () return entity:GetLocalPositionY(target_index); end, nil);
    local z = safe_read(function () return entity:GetLocalPositionZ(target_index); end, nil);
    if x == nil or y == nil or z == nil then
        return 'Unknown';
    end
    return ('(%.2f, %.2f) Z: %.2f'):fmt(x, y, z);
end

local function speed(entity, target_index)
    local raw = safe_read(function () return entity:GetRawEntity(target_index); end, nil);
    if raw == nil then
        return 'Unknown';
    end
    local value = tonumber(safe_read(function () return entity:GetAnimationSpeed(target_index); end, nil));
    local baseline = 4;
    if target_index > 0x3FF and target_index < 0x700 then
        value = tonumber(safe_read(function () return entity:GetMovementSpeed(target_index); end, nil));
        baseline = 5;
    end
    if value == nil then
        return 'Unknown';
    end
    return ('%.2f y/s (%+.0f%%)'):fmt(value, ((value / baseline) - 1.0) * 100);
end

local function respawn_text(seconds)
    seconds = tonumber(seconds) or 0;
    if seconds <= 0 then
        return 'Not recorded';
    end
    local days = math.floor(seconds / 86400);
    seconds = seconds % 86400;
    local hours = math.floor(seconds / 3600);
    seconds = seconds % 3600;
    local minutes = math.floor(seconds / 60);
    seconds = seconds % 60;
    if days > 0 then
        return ('%dd %02d:%02d:%02d'):fmt(days, hours, minutes, seconds);
    end
    if hours > 0 then
        return ('%d:%02d:%02d'):fmt(hours, minutes, seconds);
    end
    return ('%d:%02d'):fmt(minutes, seconds);
end

local function level_text(resource)
    local level = tonumber(resource.Level);
    if level ~= nil then
        return tostring(math.floor(level + 0.5));
    end
    local min_level = tonumber(resource.MinLevel);
    local max_level = tonumber(resource.MaxLevel);
    if min_level == nil and max_level == nil then
        return 'Unknown';
    end
    min_level = math.floor((min_level or max_level) + 0.5);
    max_level = math.floor((max_level or min_level) + 0.5);
    return min_level == max_level and tostring(min_level) or ('%d-%d'):fmt(min_level, max_level);
end

function bridge:load(zone_id)
    zone_id = tonumber(zone_id) or 0;
    if zone_id == self.current_zone then
        return;
    end
    self.current_zone = zone_id;
    self.indices = { };
    self.names = { };
    self.last_error = nil;
    if zone_id <= 0 then
        return;
    end
    local install_path = clean_string(safe_read(function () return AshitaCore:GetInstallPath(); end, ''));
    local path = ('%saddons/mobdb/data/%d.lua'):fmt(install_path, zone_id);
    if not ashita.fs.exists(path) then
        self.last_error = ('MobDB data not found for zone %d.'):fmt(zone_id);
        return;
    end
    local chunk, load_error = loadfile(path);
    if chunk == nil then
        self.last_error = clean_string(load_error);
        return;
    end
    local ok, output = pcall(chunk);
    if not ok or type(output) ~= 'table' then
        self.last_error = clean_string(output);
        return;
    end
    self.indices = type(output.Indices) == 'table' and output.Indices or { };
    self.names = type(output.Names) == 'table' and output.Names or { };
end

function bridge:lookup(zone_id, target_index, target_name)
    self:load(zone_id);
    local resource = self.indices[tonumber(target_index) or -1];
    if resource == nil then
        resource = self.names[clean_string(target_name)];
    end
    return resource;
end

function bridge:snapshot(zone_id, target_index, target_name, server_id)
    local resource = self:lookup(zone_id, target_index, target_name);
    if type(resource) ~= 'table' then
        return nil;
    end
    local memory = safe_read(function () return AshitaCore:GetMemoryManager(); end, nil);
    local entity = memory ~= nil and safe_read(function () return memory:GetEntity(); end, nil) or nil;
    local party = memory ~= nil and safe_read(function () return memory:GetParty(); end, nil) or nil;
    local resources = safe_read(function () return AshitaCore:GetResourceManager(); end, nil);
    local player_index = party ~= nil and safe_read(function () return party:GetMemberTargetIndex(0); end, nil) or nil;
    local job = resources ~= nil and resolve_job_name(resources, resource.Job) or '';
    local sub_job = resources ~= nil and resolve_job_name(resources, resource.SubJob) or '';
    if #sub_job > 0 then
        job = #job > 0 and (job .. '/' .. sub_job) or sub_job;
    end
    local notes = { };
    if type(resource.Notes) == 'table' then
        for _, note in ipairs(resource.Notes) do
            if #clean_string(note) > 0 then table.insert(notes, clean_string(note)); end
        end
    elseif #clean_string(resource.Notes) > 0 then
        table.insert(notes, clean_string(resource.Notes));
    end
    return {
        name = #clean_string(resource.Name) > 0 and clean_string(resource.Name) or clean_string(target_name),
        level = level_text(resource),
        job = job,
        respawn = respawn_text(resource.Respawn),
        flags = behavior_flags(resource),
        physical = modifiers(resource, PHYSICAL_ORDER, false),
        physical_all = modifiers(resource, PHYSICAL_ORDER, true),
        magical = modifiers(resource, MAGICAL_ORDER, false),
        magical_all = modifiers(resource, MAGICAL_ORDER, true),
        status_resistances = status_resistances(resource),
        immunities = immunities(resource),
        drops = resources ~= nil and sorted_item_entries(resources, resource.Drops) or { },
        spells = resources ~= nil and sorted_resource_names(resources, resource.Spells, resolve_spell_name) or { },
        notes = notes,
        position = entity ~= nil and position(entity, target_index) or 'Unknown',
        direction = entity ~= nil and direction(entity, player_index, target_index) or 'Unknown',
        speed = entity ~= nil and speed(entity, target_index) or 'Unknown',
        index = tonumber(target_index),
        server_id = tonumber(server_id),
        custom = tonumber(target_index) ~= nil and target_index >= 0x700 and target_index < 0x900,
        source_error = self.last_error,
    };
end

return bridge;
