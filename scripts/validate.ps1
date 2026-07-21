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
    "AddOutgoingPacket",
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

foreach ($needle in @("addons/mobdb/data/", "Modifiers", "Immunities", "Drops", "Spells")) {
    if (-not $mobdbLua.Contains($needle)) {
        throw "Expected MobDB integration pattern not found: $needle"
    }
}

if (-not $lua.Contains("draw_target_mobdb_overlay")) {
    throw "Expected compact MobDB target overlay was not found."
}

if ($lua.Contains("draw_target_mobdb_panel")) {
    throw "Intrusive standalone MobDB panel renderer must not be restored."
}

foreach ($unsafeMobdbText in @("imgui.Text(line)", "imgui.Text(item.tooltip)")) {
    if ($lua.Contains($unsafeMobdbText)) {
        throw "MobDB dynamic text must use TextUnformatted: $unsafeMobdbText"
    }
}

if (-not $lua.Contains("imgui.TextUnformatted(line)")) {
    throw "Expected safe unformatted MobDB dossier text rendering was not found."
}

if (-not $configText.Contains("settings")) {
    throw "Config file must return a settings table."
}

Write-Host "AshitaFrames validation passed."
