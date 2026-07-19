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
- Shows HP, MP, TP, job/subjob, level, and same-zone dimming where Ashita
  exposes that data.
- Shows compact party status icons for mapped buffs when Ashita exposes them
  for the first party. Protect and Shell are mapped first.
- Shows large missing-buff reminders for mapped buffs configured per current
  player job. Missing reminders flash with a crossed icon; active buffs show
  as normal icons. Protect and Shell are mapped first.
- Includes a persistent in-game configuration window for visibility, locking,
  sizing, opacity, party buff display, missing-buff reminders, and alliance
  display.
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

The Buff Reminders section lets you pick a main-job profile, enable reminders
for that job, choose self/player/trust targets, and toggle Protect or Shell.
Use Save to write the current window layout and reminder settings to
`ashitaframes_config.lua`. Reminder options are filtered to spells your current
main/sub job can actually cast and that your character has learned.

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
        show_alliance = false,
        show_empty_target = true,
        same_zone_dim = true,
        show_jobs = true,
        show_percent = true,
        show_tp = true,
        show_buffs = true,
        show_buff_reminders = true,
        max_buffs = 8,
        party_window_x = 36,
        party_window_y = 362,
        target_window_x = 36,
        target_window_y = 296,
        frame_width = 232,
        row_height = 56,
        row_gap = 5,
        opacity = 88,

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
    },
}
```

`buff_reminders` is keyed by your current main job. Each profile can enable or
disable reminders for yourself (`self`), other players (`players`), and trusts
(`trusts`). Supported reminder keys are currently `protect` and `shell`;
configured reminders only display when the spell is learned and usable on your
current main/sub job.

## Development

Validate the safe surface checks:

```powershell
.\scripts\validate.ps1
```

