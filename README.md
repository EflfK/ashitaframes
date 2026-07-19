# AshitaFrames

Read-only unit frame overlay for Ashita v4 on CatsEyeXI.

AshitaFrames is an experimental UI addon intended to pair with native name
hiding addons such as `noname`. It draws compact party/alliance and target
frames using local Ashita memory-manager state, so the game world can stay
clean while important unit information remains visible elsewhere on screen.

## Current Scope

- Draws a draggable target frame with name, HP percent, and distance when
  available.
- Draws draggable party frames for the first party by default, with optional
  alliance slots. Trust slots that linger in Ashita memory after zoning are
  hidden once they are no longer in your current zone.
- Draws a draggable pet frame when your local player has an active pet, using
  the pet entity for name/HP/distance and Ashita pet state for MP and TP.
- Shows HP, MP, TP, job/subjob, level, and same-zone dimming where Ashita
  exposes that data.
- Shows compact party status icons for mapped buffs from Ashita status memory
  when available, plus observed party effect messages for trusts. Protect and
  Shell are mapped first.
- Shows large missing-buff reminders for mapped buffs configured per current
  player job. Missing reminders flash with a crossed icon; active buffs show
  as normal icons. Trust reminders clear after observed gain messages and reset
  on zoning or party changes, even if another chat addon modifies or hides the
  native incoming line. On load, recent current-zone effect messages seed the
  observed state, and a bounded live chat-log tail keeps trust buffs updated
  after reloads and new casts.
  Protect and Shell are mapped first.
- Shows target-frame icons for owned mapped debuffs and flashes missing
  target-debuff reminders only when the spell is learned, usable by the current
  main/sub job, and off cooldown. Dia, Paralyze, and Slow are mapped first.
- Includes a persistent in-game configuration window for visibility, locking,
  sizing, opacity, party/pet/target display, party buff display, target debuff
  display, missing-buff reminders, and alliance display.
- Provides local UI commands only. It does not target, cast, click-cast, send
  gameplay commands, inject packets, write memory, or automate actions.

## Safety Boundary

This addon is display-only. Keep it in the CatsEyeXI T0/T2 lane:

- Allowed: local UI drawing, display-only party/target/entity information,
  local config toggles.
- Not allowed here: `/ma`, `/ja`, `/item`, `/target`, `/attack`, command
  queuing, packet injection, input simulation, unattended behavior, timers that
  choose actions, or state-driven automation.

If click-casting or frame-click targeting is ever considered, treat that as a
separate active-helper design and get CatsEyeXI policy review before normal use.
Right-click buff cancellation belongs in the same active-helper category unless
it is delegated to an approved addon; AshitaFrames does not do it.

## Install

From this repository:

```powershell
.\install.ps1
```

The installer copies the addon and adds `/addon load ashitaframes` to
`Ashita\scripts\default.txt` if it is not already present. To install without
changing the startup script:

```powershell
.\install.ps1 -SkipAutoload
```

To load immediately in game:

```text
/addon load ashitaframes
```

Useful pairing:

```text
/addon load noname
```

`noname` handles hiding native overhead names locally. AshitaFrames only draws
replacement unit information in fixed UI frames.

## Commands

```text
/ashitaframes
/ashitaframes show
/ashitaframes hide
/ashitaframes toggle
/ashitaframes lock
/ashitaframes unlock
/ashitaframes config
/ashitaframes reload
/ashitaframes status
```

Short alias:

```text
/aframes
```

## Configure

Open the in-game configuration window:

```text
/ashitaframes config
```

The configuration window is organized into General, Party, Pet, and Target
tabs. The Party, Pet, and Target tabs each include that frame's persisted
on/off toggle (`show_party`, `show_pet`, or `show_target`) plus its layout
controls. The Party tab includes Protect/Shell reminders. The Target tab
includes Dia, Paralyze, and Slow reminders.
Use Save to write the current window layout and reminder settings to
`ashitaframes_config.lua`. Party, Pet, and Target frame width, base row height,
row gap, and opacity are configured independently. Party frame layout is also
configured separately for party sizes 1 through 6; while the configuration
window is open, the party frame fills missing rows with preview members for the
selected size. Reminder options are filtered to spells your current main/sub
job can actually cast and that your character has learned. Missing
target-debuff reminders are also hidden while the spell is on cooldown. Missing
party-buff reminder flashes are hidden in towns by default; the config window
can also suppress or allow the current non-town zone.

Manual config is still supported:

Edit:

```text
ashitaframes/ashitaframes_config.lua
```

The defaults are intentionally conservative:

```lua
return {
    settings = {
        visible = true,
        locked = false,
        show_target = true,
        show_party = true,
        show_pet = true,
        show_alliance = false,
        show_empty_target = true,
        same_zone_dim = true,
        show_jobs = true,
        show_percent = true,
        show_tp = true,
        show_buffs = true,
        show_buff_reminders = true,
        show_target_debuffs = true,
        show_target_debuff_reminders = true,
        hide_buff_reminders_in_towns = true,
        buff_reminder_suppressed_zone_ids = { },
        max_buffs = 8,
        party_preview_size = 6,
        party_window_x = 36,
        party_window_y = 362,
        pet_window_x = 36,
        pet_window_y = 230,
        target_window_x = 36,
        target_window_y = 296,
        frame_width = 232,
        row_height = 56,
        row_gap = 5,
        opacity = 88,
        party_frame_width = 232,
        party_row_height = 56,
        party_row_gap = 5,
        party_opacity = 88,
        party_size_layouts = {
            [1] = { x = 36, y = 362, frame_width = 232, row_height = 56, row_gap = 5, opacity = 88 },
            [2] = { x = 36, y = 362, frame_width = 232, row_height = 56, row_gap = 5, opacity = 88 },
            [3] = { x = 36, y = 362, frame_width = 232, row_height = 56, row_gap = 5, opacity = 88 },
            [4] = { x = 36, y = 362, frame_width = 232, row_height = 56, row_gap = 5, opacity = 88 },
            [5] = { x = 36, y = 362, frame_width = 232, row_height = 56, row_gap = 5, opacity = 88 },
            [6] = { x = 36, y = 362, frame_width = 232, row_height = 56, row_gap = 5, opacity = 88 },
        },
        pet_frame_width = 232,
        pet_row_height = 56,
        pet_row_gap = 5,
        pet_opacity = 88,
        target_frame_width = 232,
        target_row_height = 56,
        target_row_gap = 5,
        target_opacity = 88,

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
    },
}
```

The base `frame_width`, `row_height`, `row_gap`, and `opacity` keys are kept as
fallbacks for older configs. New saves write separate `party_*`, `pet_*`, and
`target_*` layout values; party frame saves also write the `party_size_layouts`
table for size-specific positions and dimensions.

`buff_reminders` is keyed by your current main job. Each profile can enable or
disable reminders for yourself (`self`), other players (`players`), and trusts
(`trusts`). Supported reminder keys are currently `protect` and `shell`;
configured reminders only display when the spell is learned and usable on your
current main/sub job.

`hide_buff_reminders_in_towns` hides missing-buff flashes in town and safe hub
zones. Add zone ids to `buff_reminder_suppressed_zone_ids` to hide missing
reminders in additional zones.

`target_debuff_reminders` is keyed by your current main job. Supported target
debuff reminder keys are currently `dia`, `paralyze`, and `slow`; configured
reminders only display on attackable targets when the spell is learned, usable
on your current main/sub job, and not on cooldown. Active target debuff icons
are owned state observed from local player casts.

## Development

Validate the safe surface checks:

```powershell
.\scripts\validate.ps1
```

