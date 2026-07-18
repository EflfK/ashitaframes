$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$addon = Join-Path $root "ashitaframes\ashitaframes.lua"
$config = Join-Path $root "ashitaframes\ashitaframes_config.lua"
$readme = Join-Path $root "README.md"

foreach ($path in @($addon, $config, $readme)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing required file: $path"
    }
}

$lua = Get-Content -LiteralPath $addon -Raw
$configText = Get-Content -LiteralPath $config -Raw

$required = @(
    "addon.name",
    "ashita.events.register('d3d_beginscene'",
    "ashita.events.register('d3d_present'",
    "ashita.events.register('command'",
    "memory:GetParty()",
    "memory:GetTarget()",
    "memory:GetEntity()",
    "world_to_screen",
    "GetLocalPositionX"
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
    if ($lua.Contains($needle)) {
        throw "Forbidden active-helper surface found in addon: $needle"
    }
}

if (-not $configText.Contains("settings")) {
    throw "Config file must return a settings table."
}

Write-Host "AshitaFrames validation passed."
