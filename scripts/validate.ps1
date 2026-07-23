$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$addon = Join-Path $root "ashitaframes\ashitaframes.lua"
$mobdb = Join-Path $root "ashitaframes\ashitaframes_mobdb.lua"
$config = Join-Path $root "ashitaframes\ashitaframes_config.lua"
$readme = Join-Path $root "README.md"

foreach ($path in @($addon, $mobdb, $config, $readme)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing required file: $path"
    }
}

$lua = Get-Content -LiteralPath $addon -Raw
$mobdbLua = Get-Content -LiteralPath $mobdb -Raw
$allLua = $lua + "`n" + $mobdbLua
$configText = Get-Content -LiteralPath $config -Raw

$topLevelLocalCount = ([regex]::Matches($lua, "(?m)^local\s+")).Count
if ($topLevelLocalCount -gt 190) {
    throw "Addon has $topLevelLocalCount top-level local declarations; keep this below Lua 5.1's 200-local chunk limit."
}

$required = @(
    "addon.name",
    "ashita.events.register('d3d_present'",
    "ashita.events.register('command'",
    "memory:GetParty()",
    "memory:GetTarget()"
)

foreach ($needle in $required) {
    if (-not $lua.Contains($needle)) {
        throw "Expected pattern not found in addon: $needle"
    }
}

$forbidden = @(
    "QueueCommand",
    "AddIncomingPacket",
    "ashita.memory.write_",
    "/ma ",
    "/ja ",
    "/item ",
    "/target ",
    "/attack "
)

foreach ($needle in $forbidden) {
    if ($allLua.Contains($needle)) {
        throw "Forbidden active-helper surface found in addon: $needle"
    }
}

foreach ($needle in @(
    "unit.kind == 'party'",
    "tonumber(unit.index) == 0",
    "item.state ~= 'missing'",
    "SELF_BUFF_CANCELLATION.is_active(status_id)",
    "local item_right_clicked = imgui.IsItemClicked(1)",
    "item_hovered and item_right_clicked and SELF_BUFF_CANCELLATION.is_self_buff(unit, item)",
    "struct.pack('bbbbhbb', SELF_BUFF_CANCELLATION.PACKET_ID, 0x04, 0x00, 0x00, status_id, 0x00, 0x00)",
    "packet_manager:AddOutgoingPacket(SELF_BUFF_CANCELLATION.PACKET_ID, packet)"
)) {
    if (-not $lua.Contains($needle)) {
        throw "Expected attended self-buff cancellation guard not found: $needle"
    }
}

$outgoingPacketCalls = ([regex]::Matches($allLua, "AddOutgoingPacket")).Count
if ($outgoingPacketCalls -ne 1) {
    throw "Expected exactly one narrowly scoped outgoing packet call; found $outgoingPacketCalls."
}

foreach ($needle in @("addons/mobdb/data/", "Modifiers", "Immunities", "Drops", "Spells")) {
    if (-not $mobdbLua.Contains($needle)) {
        throw "Expected MobDB integration pattern not found: $needle"
    }
}

if (-not $lua.Contains("draw_target_mobdb_overlay")) {
    throw "Expected compact MobDB target overlay was not found."
}

if (-not $lua.Contains("local icon = load_status_icon(buff_id);")) {
    throw "Party status rendering must use native icons for every reported status id."
}

foreach ($needle in @("status_description(item.id)", "resource.Description[1]", "imgui.TextWrapped(description)")) {
    if (-not $lua.Contains($needle)) {
        throw "Expected native status tooltip pattern not found: $needle"
    }
}

foreach ($needle in @("GetStatusTimers()", "player_status_remaining_seconds", "monitored_signet_item", "state = 'expiring'", "signet_warning_minutes")) {
    if (-not $lua.Contains($needle)) {
        throw "Expected Signet reminder pattern not found: $needle"
    }
}

foreach ($needle in @("TARGET_DEBUFF_EFFECT_OVERRIDES", "target_debuff_status_id(target_action.param)", "target_debuff_rail_width", "status_icon_rail_slots_per_column")) {
    if (-not $lua.Contains($needle)) {
        throw "Expected all-target-debuff display pattern not found: $needle"
    }
}

foreach ($needle in @(
    "show_battle_targets",
    "collect_battle_target_units",
    "scan_claimed_battle_targets",
    "handle_battle_target_action_packet",
    "render_battle_targets",
    "render_battle_target_config_tab",
    "battle_target_max_entries",
    "GetClaimStatus(index)"
)) {
    if (-not $lua.Contains($needle)) {
        throw "Expected passive battle-target frame pattern not found: $needle"
    }
}

foreach ($needle in @("show_battle_targets", "show_battle_target_debuffs", "battle_target_max_entries", "battle_window_x", "battle_frame_width")) {
    if (-not $configText.Contains($needle)) {
        throw "Expected battle-target config key not found: $needle"
    }
}

foreach ($needle in @("PARTY_SELECTION.handle_command", "PARTY_SELECTION.matches(unit)", "party_selection_border", "'/ashitaui'")) {
    if (-not $lua.Contains($needle)) {
        throw "Expected passive party-selection highlight pattern not found: $needle"
    }
}

if (-not $lua.Contains("draw_bar(draw_list, x, current_y, width, hp_h, unit.hp_pct, hp_color, alpha);")) {
    throw "HP background fill must use the live unit HP percentage for every frame, including self."
}

foreach ($needle in @("signet_reminder_enabled", "signet_warning_minutes")) {
    if (-not $configText.Contains($needle)) {
        throw "Expected Signet reminder config key not found: $needle"
    }
}

if ($lua.Contains("draw_target_mobdb_panel")) {
    throw "Intrusive standalone MobDB panel renderer must not be restored."
}

foreach ($unsafeMobdbText in @("imgui.Text(line)", "imgui.Text(item.tooltip)")) {
    if ($lua.Contains($unsafeMobdbText)) {
        throw "MobDB dynamic text must use TextUnformatted: $unsafeMobdbText"
    }
}

foreach ($needle in @("mobdb_modifier_groups", "mobdb_absolute_percent_text", "load_item_icon", "draw_mobdb_item_tooltip")) {
    if (-not $lua.Contains($needle)) {
        throw "Expected split-rail MobDB renderer pattern not found: $needle"
    }
}

foreach ($mockPattern in @("flag_x", "footer_y", "load_item_icon(drop.id)", "strong_x = content_right - strong_display_width")) {
    if (-not $lua.Contains($mockPattern)) {
        throw "Expected selected field-card mock pattern not found: $mockPattern"
    }
}

foreach ($removedLabel in @("draw_mobdb_group_label", "'WEAK', true", "'STRONG', false", "draw_text(draw_list, drop_x + footer_icon_size")) {
    if ($lua.Contains($removedLabel)) {
        throw "Removed MobDB label must not be restored: $removedLabel"
    }
}

if (-not $lua.Contains("tag = '',")) {
    throw "Target name prefix must remain hidden."
}

foreach ($removedDossierPattern in @("draw_mobdb_dossier_tooltip", "mobdb_info_lines", "trigger_label")) {
    if ($lua.Contains($removedDossierPattern)) {
        throw "MobDB dossier trigger must not be restored: $removedDossierPattern"
    }
}

if (-not $lua.Contains("return left_percent > right_percent")) {
    throw "MobDB modifiers must remain sorted by damage effectiveness."
}

if (-not $mobdbLua.Contains("sorted_item_entries")) {
    throw "Expected structured MobDB drop entries were not found."
}

if (-not $mobdbLua.Contains("fallback:match('^userdata:%s*0x%x+$')")) {
    throw "Expected MobDB userdata name filtering was not found."
}

if (-not $configText.Contains("settings")) {
    throw "Config file must return a settings table."
}

Write-Host "AshitaFrames validation passed."
